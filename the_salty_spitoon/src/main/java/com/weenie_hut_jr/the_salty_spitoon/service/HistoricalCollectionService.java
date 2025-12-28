package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.dto.CollectionProgress;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.io.*;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 과거 데이터 수집 서비스
 * - nasdaq100_tickers.csv에서 종목 목록 읽기
 * - Python historical_loader.py 호출하여 데이터 수집
 * - MySQL에 UPSERT
 * - WebSocket으로 진행률 전송
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-26
 */
@Slf4j
@Service
public class HistoricalCollectionService {
    
    private static final DateTimeFormatter DT_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    
    private final StockCandle1mRepository stockCandle1mRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;
    
    @Value("${python.path:python}")
    private String pythonPath;
    
    @Value("${python.script.dir:python}")
    private String pythonScriptDir;
    
    @Value("${python.output.dir:python/output}")
    private String pythonOutputDir;
    
    @Value("${nasdaq.tickers.file:python/nasdaq100_tickers.csv}")
    private String tickersFilePath;
    
    // 수집 중 여부 플래그
    private final AtomicBoolean isCollecting = new AtomicBoolean(false);
    
    // API 보호를 위한 딜레이 (밀리초)
    private static final long API_DELAY_MS = 2000;
    
    public HistoricalCollectionService(StockCandle1mRepository stockCandle1mRepository,
                                        SimpMessagingTemplate messagingTemplate,
                                        ObjectMapper objectMapper) {
        this.stockCandle1mRepository = stockCandle1mRepository;
        this.messagingTemplate = messagingTemplate;
        this.objectMapper = objectMapper;
    }
    
    /**
     * 수집 중 여부 확인
     */
    public boolean isCollecting() {
        return isCollecting.get();
    }
    
    /**
     * 비동기로 과거 데이터 수집 시작 (전체 종목)
     */
    @Async
    public void startCollection(int days) {
        startCollection(days, null);
    }
    
    /**
     * 비동기로 과거 데이터 수집 시작 (특정 종목)
     * @param days 수집할 일수
     * @param targetSymbols 특정 종목 리스트 (null이면 전체)
     */
    @Async
    public void startCollection(int days, List<String> targetSymbols) {
        if (!isCollecting.compareAndSet(false, true)) {
            sendProgress(CollectionProgress.error("이미 수집이 진행 중입니다."));
            return;
        }
        
        long startTime = System.currentTimeMillis();
        
        // 특정 종목이 지정되었으면 그것만, 아니면 CSV에서 읽기
        List<String> symbols;
        if (targetSymbols != null && !targetSymbols.isEmpty()) {
            symbols = targetSymbols;
            log.info("특정 종목 수집 모드: {}개", symbols.size());
        } else {
            symbols = loadTickers();
        }
        
        if (symbols.isEmpty()) {
            isCollecting.set(false);
            sendProgress(CollectionProgress.error("종목 목록을 불러올 수 없습니다."));
            return;
        }
        
        log.info("========================================");
        log.info("과거 데이터 수집 시작: {} 종목, {}일", symbols.size(), days);
        log.info("========================================");
        
        int total = symbols.size();
        int successCount = 0;
        int failedCount = 0;
        int totalCandles = 0;
        List<String> failedSymbols = new ArrayList<>();
        
        try {
            for (int i = 0; i < symbols.size(); i++) {
                String symbol = symbols.get(i);
                int current = i + 1;
                
                // 진행 중 상태 전송
                sendProgress(CollectionProgress.progress(
                    current, total, symbol, "processing", 
                    "데이터 수집 중...", 0
                ));
                
                try {
                    // Python 스크립트 실행 및 데이터 저장
                    int candleCount = collectAndSave(symbol, days);
                    
                    if (candleCount > 0) {
                        successCount++;
                        totalCandles += candleCount;
                        log.info("[{}/{}] {} ✅ {} candles", current, total, symbol, candleCount);
                        sendProgress(CollectionProgress.progress(
                            current, total, symbol, "success",
                            candleCount + " candles 수집 완료", candleCount
                        ));
                    } else {
                        failedCount++;
                        failedSymbols.add(symbol);
                        log.warn("[{}/{}] {} ⚠️ 데이터 없음", current, total, symbol);
                        sendProgress(CollectionProgress.progress(
                            current, total, symbol, "failed",
                            "데이터 없음", 0
                        ));
                    }
                    
                } catch (Exception e) {
                    failedCount++;
                    failedSymbols.add(symbol);
                    log.error("[{}/{}] {} ❌ {}", current, total, symbol, e.getMessage());
                    sendProgress(CollectionProgress.progress(
                        current, total, symbol, "failed",
                        e.getMessage(), 0
                    ));
                }
                
                // API 보호를 위한 딜레이 (마지막 종목 제외)
                if (i < symbols.size() - 1) {
                    Thread.sleep(API_DELAY_MS);
                }
            }
            
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("수집이 중단되었습니다.");
        } finally {
            isCollecting.set(false);
        }
        
        // 완료 통계 계산
        long duration = System.currentTimeMillis() - startTime;
        String durationStr = formatDuration(duration);
        
        log.info("========================================");
        log.info("과거 데이터 수집 완료");
        log.info("  성공: {}", successCount);
        log.info("  실패: {}", failedCount);
        log.info("  총 캔들: {}", totalCandles);
        log.info("  소요시간: {}", durationStr);
        log.info("========================================");
        
        // 완료 상태 전송
        sendProgress(CollectionProgress.complete(
            successCount, failedCount, totalCandles, failedSymbols, durationStr
        ));
    }
    
    /**
     * 단일 종목 데이터 수집 및 저장
     */
    private int collectAndSave(String symbol, int days) throws Exception {
        // 출력 파일 경로
        String outputFileName = String.format("historical_%s_%d.json", symbol, System.currentTimeMillis());
        Path outputPath = Paths.get(pythonOutputDir, outputFileName);
        
        // 디렉토리 생성
        Files.createDirectories(outputPath.getParent());
        
        try {
            // Python 스크립트 실행
            ProcessBuilder pb = new ProcessBuilder(
                pythonPath,
                Paths.get(pythonScriptDir, "historical_loader.py").toString(),
                "--symbol", symbol,
                "--days", String.valueOf(days),
                "--output", outputPath.toString()
            );
            
            pb.redirectErrorStream(true);
            Process process = pb.start();
            
            // 로그 수집
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                    log.debug("[Python] {}", line);
                }
            }
            
            // 프로세스 완료 대기 (최대 60초)
            boolean finished = process.waitFor(60, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new Exception("Python 스크립트 타임아웃");
            }
            
            // 결과 파일 읽기
            if (!Files.exists(outputPath)) {
                throw new Exception("결과 파일이 생성되지 않았습니다: " + output.toString().trim());
            }
            
            JsonNode result = objectMapper.readTree(outputPath.toFile());
            
            if (!result.path("success").asBoolean(false)) {
                throw new Exception(result.path("message").asText("Unknown error"));
            }
            
            // 캔들 데이터 저장
            JsonNode candles = result.path("candles");
            int savedCount = 0;
            
            for (JsonNode candle : candles) {
                try {
                    String sym = candle.path("symbol").asText();
                    LocalDateTime timestamp = LocalDateTime.parse(
                        candle.path("datetime").asText(), DT_FORMATTER
                    );
                    
                    // 기존 데이터 확인 (UPSERT)
                    Optional<StockCandle1m> existing = stockCandle1mRepository
                        .findBySymbolAndTimestamp(sym, timestamp);
                    
                    StockCandle1m entity;
                    if (existing.isPresent()) {
                        entity = existing.get();
                    } else {
                        entity = new StockCandle1m();
                        entity.setSymbol(sym);
                        entity.setTimestamp(timestamp);
                    }
                    
                    entity.setOpen(BigDecimal.valueOf(candle.path("open").asDouble()));
                    entity.setHigh(BigDecimal.valueOf(candle.path("high").asDouble()));
                    entity.setLow(BigDecimal.valueOf(candle.path("low").asDouble()));
                    entity.setClose(BigDecimal.valueOf(candle.path("close").asDouble()));
                    entity.setVolume(candle.path("volume").asLong());
                    
                    stockCandle1mRepository.save(entity);
                    savedCount++;
                    
                } catch (Exception e) {
                    log.warn("캔들 저장 실패: {}", e.getMessage());
                }
            }
            
            return savedCount;
            
        } finally {
            // 임시 파일 삭제
            try {
                Files.deleteIfExists(outputPath);
            } catch (IOException e) {
                log.warn("임시 파일 삭제 실패: {}", outputPath);
            }
        }
    }
    
    /**
     * nasdaq100_tickers.csv에서 종목 목록 읽기
     */
    private List<String> loadTickers() {
        List<String> symbols = new ArrayList<>();
        Path path = Paths.get(tickersFilePath);
        
        try {
            List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);
            boolean isFirstLine = true;
            
            for (String line : lines) {
                // 첫 줄(헤더) 스킵
                if (isFirstLine) {
                    isFirstLine = false;
                    continue;
                }
                
                line = line.trim();
                if (line.isEmpty()) continue;
                
                // CSV 파싱 (첫 번째 컬럼이 심볼)
                String[] parts = line.split(",");
                if (parts.length > 0) {
                    String symbol = parts[0].trim().replace("\"", "");
                    if (!symbol.isEmpty()) {
                        symbols.add(symbol);
                    }
                }
            }
            
            log.info("{}개 종목 로드 완료", symbols.size());
            
        } catch (IOException e) {
            log.error("종목 파일 읽기 실패: {}", e.getMessage());
        }
        
        return symbols;
    }
    
    /**
     * WebSocket으로 진행률 전송
     */
    private void sendProgress(CollectionProgress progress) {
        try {
            messagingTemplate.convertAndSend("/topic/admin/progress", progress);
        } catch (Exception e) {
            log.warn("진행률 전송 실패: {}", e.getMessage());
        }
    }
    
    /**
     * 밀리초를 "X분 Y초" 형식으로 변환
     */
    private String formatDuration(long millis) {
        long seconds = millis / 1000;
        long minutes = seconds / 60;
        seconds = seconds % 60;
        
        if (minutes > 0) {
            return String.format("%d분 %d초", minutes, seconds);
        } else {
            return String.format("%d초", seconds);
        }
    }
}
