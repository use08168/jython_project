package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Iterator;
import java.util.Map;
import java.util.Optional;

/**
 * 파일 기반 실시간 데이터 수집 서비스
 * 
 * ========================================
 * 최종 수정 (2025-12-25)
 * ========================================
 * - UPSERT 방식 구현 (UPDATE + INSERT)
 * - Duplicate entry 에러 해결
 * - @Transactional 추가
 * - 60초마다 폴링
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-25
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FileDataCollector {

    private final StockCandle1mRepository candleRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String DATA_FILE = "python/output/latest_data.json";
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private long lastModified = 0;

    /**
     * 주기적 파일 변경 확인 (60초)
     * 
     * initialDelay: 10초 (Spring Boot 시작 후 대기)
     * fixedDelay: 60초 (작업 완료 후 대기)
     */
    @Scheduled(fixedDelay = 60000, initialDelay = 10000)
    public void checkForUpdates() {
        try {
            File file = new File(DATA_FILE);

            if (!file.exists()) {
                if (lastModified == 0) {
                    log.debug("[FileCollector] Data file not found yet: {}", DATA_FILE);
                }
                return;
            }

            long currentModified = file.lastModified();

            if (currentModified > lastModified) {
                log.info("[FileCollector] File changed detected: {}", DATA_FILE);
                lastModified = currentModified;
                processDataFile(file);
            } else {
                log.debug("[FileCollector] No change detected");
            }

        } catch (Exception e) {
            log.error("[FileCollector] Error checking data file", e);
        }
    }

    /**
     * JSON 파일 읽기 및 데이터 처리
     * 
     * @Transactional: 모든 데이터를 한 트랜잭션으로 처리
     */
    @Transactional
    private void processDataFile(File file) {
        log.info("[FileCollector] ========================================");
        log.info("[FileCollector] Processing data file: {}", file.getName());

        try {
            // JSON 파일 읽기
            JsonNode root = objectMapper.readTree(file);
            JsonNode dataNode = root.get("data");

            if (dataNode == null || !dataNode.isObject()) {
                log.error("[FileCollector] Invalid JSON structure - missing 'data' field");
                return;
            }

            String timestamp = root.has("timestamp") ? root.get("timestamp").asText() : "Unknown";
            log.info("[FileCollector] File timestamp: {}", timestamp);

            // 통계 변수
            int insertedCount = 0;
            int updatedCount = 0;
            int errorCount = 0;

            // 각 종목 데이터 처리
            Iterator<Map.Entry<String, JsonNode>> fields = dataNode.fields();

            while (fields.hasNext()) {
                Map.Entry<String, JsonNode> entry = fields.next();
                String symbol = entry.getKey();
                JsonNode candleData = entry.getValue();

                try {
                    SaveResult result = upsertCandle(symbol, candleData);

                    switch (result) {
                        case INSERTED:
                            insertedCount++;
                            break;
                        case UPDATED:
                            updatedCount++;
                            break;
                        case ERROR:
                            errorCount++;
                            break;
                    }

                } catch (Exception e) {
                    log.error("[FileCollector] Failed to process {}: {}", symbol, e.getMessage());
                    errorCount++;
                }
            }

            // 처리 결과 로깅
            log.info("[FileCollector] ========================================");
            log.info("[FileCollector] Processing completed");
            log.info("[FileCollector]   Inserted: {} (new records)", insertedCount);
            log.info("[FileCollector]   Updated:  {} (existing records)", updatedCount);
            log.info("[FileCollector]   Errors:   {} (failed)", errorCount);
            log.info("[FileCollector] ========================================");

        } catch (Exception e) {
            log.error("[FileCollector] Error processing data file", e);
            throw new RuntimeException("Failed to process data file", e);
        }
    }

    /**
     * 저장 결과 열거형
     */
    private enum SaveResult {
        INSERTED, // 새로 삽입
        UPDATED, // 기존 데이터 업데이트
        ERROR // 에러
    }

    /**
     * UPSERT: UPDATE if exists, INSERT if not
     * 
     * ========================================
     * 로직:
     * ========================================
     * 1. findBySymbolAndTimestamp() 조회
     * 2. 존재하면: 기존 엔티티 업데이트 (UPDATE)
     * 3. 없으면: 새 엔티티 생성 (INSERT)
     * 4. save() 호출
     * 5. WebSocket 전송
     * 
     * 장점:
     * - Duplicate entry 에러 없음
     * - ID 낭비 없음
     * - 트랜잭션 안전
     */
    private SaveResult upsertCandle(String symbol, JsonNode candleData) {
        try {
            // ========================================
            // 1. 필수 필드 체크
            // ========================================
            String[] requiredFields = { "timestamp", "open", "high", "low", "close", "volume" };

            for (String field : requiredFields) {
                if (!candleData.has(field)) {
                    log.error("[{}] Missing required field: {}", symbol, field);
                    return SaveResult.ERROR;
                }
            }

            // ========================================
            // 2. 타임스탬프 파싱
            // ========================================
            String timestampStr = candleData.get("timestamp").asText();
            LocalDateTime timestamp;

            try {
                timestamp = LocalDateTime.parse(timestampStr, FORMATTER);
            } catch (Exception e) {
                log.error("[{}] Invalid timestamp format: {} - {}", symbol, timestampStr, e.getMessage());
                return SaveResult.ERROR;
            }

            // ========================================
            // 3. OHLCV 파싱
            // ========================================
            BigDecimal open, high, low, close;
            Long volume;

            try {
                open = new BigDecimal(candleData.get("open").asText());
                high = new BigDecimal(candleData.get("high").asText());
                low = new BigDecimal(candleData.get("low").asText());
                close = new BigDecimal(candleData.get("close").asText());
                volume = candleData.get("volume").asLong();
            } catch (Exception e) {
                log.error("[{}] Failed to parse OHLCV data: {}", symbol, e.getMessage());
                return SaveResult.ERROR;
            }

            // ========================================
            // 4. UPSERT 로직
            // ========================================
            Optional<StockCandle1m> existing = candleRepository.findBySymbolAndTimestamp(symbol, timestamp);

            StockCandle1m candle;
            SaveResult result;

            if (existing.isPresent()) {
                // ========================================
                // UPDATE: 기존 데이터 업데이트
                // ========================================
                candle = existing.get();
                candle.setOpen(open);
                candle.setHigh(high);
                candle.setLow(low);
                candle.setClose(close);
                candle.setVolume(volume);

                result = SaveResult.UPDATED;

                log.debug("[{}] UPDATE existing record: {} @ {}",
                        symbol, close, timestamp.format(DateTimeFormatter.ofPattern("HH:mm")));

            } else {
                // ========================================
                // INSERT: 새 데이터 생성
                // ========================================
                candle = StockCandle1m.builder()
                        .symbol(symbol)
                        .timestamp(timestamp)
                        .open(open)
                        .high(high)
                        .low(low)
                        .close(close)
                        .volume(volume)
                        .build();

                result = SaveResult.INSERTED;

                log.debug("[{}] INSERT new record: {} @ {}",
                        symbol, close, timestamp.format(DateTimeFormatter.ofPattern("HH:mm")));
            }

            // ========================================
            // 5. 저장 (INSERT 또는 UPDATE)
            // ========================================
            StockCandle1m saved = candleRepository.save(candle);

            // ========================================
            // 6. WebSocket 전송
            // ========================================
            try {
                messagingTemplate.convertAndSend(
                        "/topic/stock/" + symbol,
                        saved);
            } catch (Exception e) {
                log.warn("[{}] WebSocket send failed: {}", symbol, e.getMessage());
            }

            // ========================================
            // 7. 성공 로그
            // ========================================
            log.info("[{}] ✅ {}: ${} @ {} (vol={})",
                    symbol,
                    result == SaveResult.INSERTED ? "INSERTED" : "UPDATED",
                    close,
                    timestamp.format(DateTimeFormatter.ofPattern("HH:mm")),
                    volume);

            return result;

        } catch (Exception e) {
            log.error("[{}] Unexpected error: {}", symbol, e.getMessage());
            return SaveResult.ERROR;
        }
    }
}