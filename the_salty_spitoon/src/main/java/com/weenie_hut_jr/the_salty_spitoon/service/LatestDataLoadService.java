package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.dto.CollectionResult;
import com.weenie_hut_jr.the_salty_spitoon.dto.DataStatus;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 최신 데이터 로드 서비스
 * 
 * Phase 3 (2025-12-26): Yahoo Finance 최신 시각 기반 GAP 계산
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-25
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LatestDataLoadService {

    private final StockCandle1mRepository candleRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 날짜 포맷터
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // CSV에서 로드할 종목 정보
    private final Map<String, String> symbolNames = new HashMap<>();

    /**
     * ========================================
     * 초기화: CSV 파일에서 종목 정보 로드
     * ========================================
     */
    @PostConstruct
    public void init() {
        loadSymbolNamesFromCsv();
    }

    /**
     * CSV 파일에서 종목 이름 로드
     */
    private void loadSymbolNamesFromCsv() {
        try {
            Path csvPath = Paths.get("python/nasdaq100_tickers.csv");

            log.info("========================================");
            log.info("Loading NASDAQ 100 tickers from CSV");
            log.info("========================================");
            log.info("CSV path: {}", csvPath.toAbsolutePath());

            try (BufferedReader br = new BufferedReader(new FileReader(csvPath.toFile()))) {
                String line;
                boolean isFirstLine = true;

                while ((line = br.readLine()) != null) {
                    if (isFirstLine) {
                        isFirstLine = false;
                        continue;
                    }

                    String[] parts = line.split(",");

                    if (parts.length >= 2) {
                        String symbol = parts[0].trim();
                        String name = parts[1].trim();
                        symbolNames.put(symbol, name);
                    }
                }
            }

            log.info("✅ Loaded {} symbols from CSV", symbolNames.size());
            log.info("========================================");

        } catch (Exception e) {
            log.error("❌ Failed to load symbols from CSV", e);
            log.warn("Using empty symbol map - symbol names will be displayed as symbols");
        }
    }

    /**
     * 종목 이름 조회
     */
    public String getSymbolName(String symbol) {
        return symbolNames.getOrDefault(symbol, symbol);
    }

    /**
     * ========================================
     * Yahoo Finance에서 최신 데이터 시각 조회
     * ========================================
     */
    private LocalDateTime getYahooLatestTimestamp(String symbol) throws Exception {
        // 1. Request JSON 생성 (check_latest 모드)
        String requestId = String.valueOf(System.currentTimeMillis());
        Map<String, Object> request = new HashMap<>();
        request.put("symbol", symbol);
        request.put("mode", "check_latest");

        File requestFile = new File("python/requests/request_" + requestId + ".json");
        requestFile.getParentFile().mkdirs();

        objectMapper.writerWithDefaultPrettyPrinter()
                .writeValue(requestFile, request);

        // 2. Python 실행
        executePythonLoader(requestFile);

        // 3. Result JSON 읽기
        File resultFile = new File("python/results/result_" + requestId + ".json");

        if (!resultFile.exists()) {
            throw new RuntimeException("Result file not created");
        }

        JsonNode result = objectMapper.readTree(resultFile);

        // 4. 최신 시각 추출
        JsonNode latestNode = result.get("latest_timestamp");

        if (latestNode == null || latestNode.isNull()) {
            throw new RuntimeException("No latest timestamp available from Yahoo Finance");
        }

        String latestStr = latestNode.asText();
        LocalDateTime yahooLatest = LocalDateTime.parse(latestStr, FORMATTER);

        // 5. 임시 파일 정리
        cleanupFiles(requestFile, resultFile);

        log.debug("Yahoo Finance latest for {}: {}", symbol, latestStr);

        return yahooLatest;
    }

    /**
     * ========================================
     * 데이터 상태 확인 (Yahoo Finance 최신 시각 포함)
     * ========================================
     */
    public List<DataStatus> checkAllDataStatus() {
        log.info("[LatestDataLoad] Checking data status for all symbols...");

        List<DataStatus> statusList = new ArrayList<>();
        Map<String, StockCandle1m> latestData = getLatestDataForAllSymbols();

        for (Map.Entry<String, StockCandle1m> entry : latestData.entrySet()) {
            String symbol = entry.getKey();
            StockCandle1m candle = entry.getValue();

            DataStatus status = new DataStatus();

            // 기본 정보
            status.setSymbol(symbol);
            status.setName(getSymbolName(symbol));
            status.setLastUpdate(candle.getTimestamp());
            status.setLastPrice(candle.getClose());
            status.setLastVolume(candle.getVolume());

            // MySQL 최신 시각
            status.setMysqlLatest(candle.getTimestamp().format(FORMATTER));

            try {
                // ✅ Yahoo Finance 최신 시각 조회
                LocalDateTime yahooLatest = getYahooLatestTimestamp(symbol);
                status.setYahooLatest(yahooLatest.format(FORMATTER));

                // ✅ 실제 GAP 계산 (Yahoo 기준)
                long minutesSinceUpdate = java.time.Duration.between(
                        candle.getTimestamp(),
                        yahooLatest).toMinutes();

                status.setGapMinutes(minutesSinceUpdate);

                // 상태 판정
                if (minutesSinceUpdate < 5) {
                    status.setStatus("OK");
                } else if (minutesSinceUpdate < 60) {
                    status.setStatus("GAP");
                } else {
                    status.setStatus("NO_DATA");
                }

            } catch (Exception e) {
                log.error("Failed to get Yahoo latest for {}: {}", symbol, e.getMessage());

                // Yahoo 조회 실패 시 현재 시각 사용 (폴백)
                LocalDateTime now = LocalDateTime.now();
                status.setYahooLatest(now.format(FORMATTER));

                long minutesSinceUpdate = java.time.Duration.between(
                        candle.getTimestamp(),
                        now).toMinutes();

                status.setGapMinutes(minutesSinceUpdate);
                status.setStatus("GAP");
            }

            statusList.add(status);
        }

        log.info("[LatestDataLoad] Checked {} symbols", statusList.size());

        return statusList;
    }

    /**
     * ========================================
     * 데이터 갭 채우기 (개선된 로직 - Yahoo 최신 시각 기반)
     * ========================================
     */
    public CollectionResult fillAllGaps() {
        log.info("========================================");
        log.info("[LatestDataLoad] Filling data gaps...");
        log.info("========================================");

        CollectionResult result = CollectionResult.builder()
                .startTime(LocalDateTime.now().format(FORMATTER))
                .build();

        int totalSymbols = 0;
        int successCount = 0;
        int failureCount = 0;
        int totalCandles = 0;

        List<CollectionResult.SymbolResult> symbolResults = new ArrayList<>();

        try {
            // 1. 데이터 상태 확인 (Yahoo 최신 시각 포함)
            List<DataStatus> statusList = checkAllDataStatus();

            // 2. GAP이 있는 종목만 필터링
            List<DataStatus> gapSymbols = statusList.stream()
                    .filter(s -> "GAP".equals(s.getStatus()) || "NO_DATA".equals(s.getStatus()))
                    .toList();

            log.info("Found {} symbols with gaps", gapSymbols.size());

            if (gapSymbols.isEmpty()) {
                result.setTotalSymbols(0);
                result.setSuccessCount(0);
                result.setFailureCount(0);
                result.setTotalCandles(0);
                result.setSuccess(true);
                result.setMessage("No gaps found! All data is up to date.");
                result.setEndTime(LocalDateTime.now().format(FORMATTER));
                result.setSymbolResults(new ArrayList<>());
                return result;
            }

            totalSymbols = gapSymbols.size();

            // 3. 각 종목별로 갭 채우기
            for (DataStatus status : gapSymbols) {
                try {
                    log.info("Processing {}: MySQL={}, Yahoo={}, Gap={}min",
                            status.getSymbol(),
                            status.getMysqlLatest(),
                            status.getYahooLatest(),
                            status.getGapMinutes());

                    // ✅ Yahoo 최신 시각을 endTime으로 사용
                    LocalDateTime yahooLatest = LocalDateTime.parse(
                            status.getYahooLatest(),
                            FORMATTER);

                    // Python historical_loader.py 호출
                    int candlesCollected = fillGapForSymbol(
                            status.getSymbol(),
                            status.getLastUpdate(), // MySQL 최신
                            yahooLatest // Yahoo 최신
                    );

                    successCount++;
                    totalCandles += candlesCollected;

                    symbolResults.add(CollectionResult.SymbolResult.builder()
                            .symbol(status.getSymbol())
                            .success(true)
                            .candlesCollected(candlesCollected)
                            .message(candlesCollected + " candles collected")
                            .build());

                    log.info("✅ {}: {} candles collected", status.getSymbol(), candlesCollected);

                } catch (Exception e) {
                    failureCount++;

                    symbolResults.add(CollectionResult.SymbolResult.builder()
                            .symbol(status.getSymbol())
                            .success(false)
                            .candlesCollected(0)
                            .message("Error: " + e.getMessage())
                            .build());

                    log.error("❌ {}: {}", status.getSymbol(), e.getMessage());
                }
            }

            result.setTotalSymbols(totalSymbols);
            result.setSuccessCount(successCount);
            result.setFailureCount(failureCount);
            result.setTotalCandles(totalCandles);
            result.setSuccess(failureCount == 0);
            result.setMessage(String.format("Completed: %d success, %d failure", successCount, failureCount));
            result.setSymbolResults(symbolResults);
            result.setEndTime(LocalDateTime.now().format(FORMATTER));

            log.info("========================================");
            log.info("[LatestDataLoad] Gap filling completed");
            log.info("  Total: {}", totalSymbols);
            log.info("  Success: {}", successCount);
            log.info("  Failure: {}", failureCount);
            log.info("  Candles: {}", totalCandles);
            log.info("========================================");

            return result;

        } catch (Exception e) {
            log.error("Gap filling failed", e);

            result.setTotalSymbols(totalSymbols);
            result.setSuccessCount(successCount);
            result.setFailureCount(failureCount);
            result.setTotalCandles(totalCandles);
            result.setSuccess(false);
            result.setMessage("Error: " + e.getMessage());
            result.setEndTime(LocalDateTime.now().format(FORMATTER));
            result.setSymbolResults(symbolResults);

            return result;
        }
    }

    /**
     * ========================================
     * 특정 종목의 갭 채우기
     * ========================================
     */
    private int fillGapForSymbol(String symbol, LocalDateTime startTime, LocalDateTime endTime) throws Exception {
        // 1. Request JSON 생성
        String requestId = String.valueOf(System.currentTimeMillis());
        File requestFile = createRequestFile(requestId, symbol, startTime, endTime);

        // 2. Python 실행
        executePythonLoader(requestFile);

        // 3. Result JSON 읽기
        File resultFile = new File("python/results/result_" + requestId + ".json");

        if (!resultFile.exists()) {
            throw new RuntimeException("Result file not created");
        }

        JsonNode result = objectMapper.readTree(resultFile);

        String status = result.get("status").asText();

        if ("error".equals(status)) {
            String error = result.get("error").asText();
            throw new RuntimeException("Python error: " + error);
        }

        // 4. 데이터 MySQL 저장
        int savedCount = saveHistoricalData(result, symbol);

        // 5. 임시 파일 정리
        cleanupFiles(requestFile, resultFile);

        return savedCount;
    }

    /**
     * ========================================
     * Request JSON 파일 생성
     * ========================================
     */
    private File createRequestFile(String requestId, String symbol,
            LocalDateTime startTime, LocalDateTime endTime) throws Exception {
        Map<String, Object> request = new HashMap<>();
        request.put("symbol", symbol);
        request.put("start_time", startTime.format(FORMATTER));
        request.put("end_time", endTime.format(FORMATTER));

        File requestFile = new File("python/requests/request_" + requestId + ".json");
        requestFile.getParentFile().mkdirs();

        objectMapper.writerWithDefaultPrettyPrinter()
                .writeValue(requestFile, request);

        log.debug("Created request file: {}", requestFile.getName());

        return requestFile;
    }

    /**
     * ========================================
     * Python historical_loader.py 실행
     * ========================================
     */
    private void executePythonLoader(File requestFile) throws Exception {
        String pythonExe = getPythonExecutable();

        log.debug("🐍 Executing Python: {} {}", pythonExe, requestFile.getAbsolutePath());

        ProcessBuilder pb = new ProcessBuilder(
                pythonExe,
                "python/historical_loader.py",
                requestFile.getAbsolutePath());

        pb.redirectErrorStream(true);
        pb.inheritIO();

        Process process = pb.start();
        int exitCode = process.waitFor();

        if (exitCode != 0) {
            throw new RuntimeException("Python loader failed with exit code: " + exitCode);
        }

        log.debug("✅ Python execution completed");
    }

    /**
     * ========================================
     * OS별 Python 실행 파일 경로
     * ========================================
     */
    private String getPythonExecutable() {
        String os = System.getProperty("os.name").toLowerCase();

        if (os.contains("win")) {
            return "python/venv/Scripts/python.exe";
        } else {
            return "python/venv/bin/python";
        }
    }

    /**
     * ========================================
     * Result JSON 데이터를 MySQL에 저장
     * ========================================
     */
    private int saveHistoricalData(JsonNode result, String symbol) {
        JsonNode dataArray = result.get("data");

        if (dataArray == null || !dataArray.isArray()) {
            log.warn("No data to save for {}", symbol);
            return 0;
        }

        int savedCount = 0;
        int skippedCount = 0;

        for (JsonNode candleNode : dataArray) {
            try {
                LocalDateTime timestamp = LocalDateTime.parse(
                        candleNode.get("timestamp").asText(),
                        FORMATTER);

                // 중복 체크
                if (candleRepository.findBySymbolAndTimestamp(symbol, timestamp).isPresent()) {
                    skippedCount++;
                    continue;
                }

                // 엔티티 생성 및 저장
                StockCandle1m candle = StockCandle1m.builder()
                        .symbol(symbol)
                        .timestamp(timestamp)
                        .open(new BigDecimal(candleNode.get("open").asText()))
                        .high(new BigDecimal(candleNode.get("high").asText()))
                        .low(new BigDecimal(candleNode.get("low").asText()))
                        .close(new BigDecimal(candleNode.get("close").asText()))
                        .volume(candleNode.get("volume").asLong())
                        .build();

                candleRepository.save(candle);
                savedCount++;

            } catch (Exception e) {
                log.error("Failed to save candle for {}: {}", symbol, e.getMessage());
            }
        }

        log.info("💾 {}: Saved {}, Skipped {}", symbol, savedCount, skippedCount);

        return savedCount;
    }

    /**
     * ========================================
     * 임시 파일 정리
     * ========================================
     */
    private void cleanupFiles(File... files) {
        for (File file : files) {
            try {
                if (file.exists()) {
                    Files.delete(file.toPath());
                    log.debug("🗑️  Deleted: {}", file.getName());
                }
            } catch (Exception e) {
                log.warn("Failed to delete {}: {}", file.getName(), e.getMessage());
            }
        }
    }

    /**
     * ========================================
     * 기타 유틸리티 메서드
     * ========================================
     */

    /**
     * 모든 종목의 최신 데이터 조회
     */
    public Map<String, StockCandle1m> getLatestDataForAllSymbols() {
        log.info("[LatestDataLoad] Loading latest data for all symbols...");

        Map<String, StockCandle1m> latestData = new HashMap<>();
        List<StockCandle1m> allCandles = candleRepository.findAll();

        for (StockCandle1m candle : allCandles) {
            String symbol = candle.getSymbol();

            if (!latestData.containsKey(symbol)) {
                latestData.put(symbol, candle);
            } else {
                StockCandle1m existing = latestData.get(symbol);
                if (candle.getTimestamp().isAfter(existing.getTimestamp())) {
                    latestData.put(symbol, candle);
                }
            }
        }

        log.info("[LatestDataLoad] Loaded latest data for {} symbols", latestData.size());

        return latestData;
    }

    /**
     * 특정 종목의 최신 데이터 조회
     */
    public Optional<StockCandle1m> getLatestData(String symbol) {
        return candleRepository.findTopBySymbolOrderByTimestampDesc(symbol);
    }

    /**
     * 여러 종목의 최신 데이터 조회
     */
    public Map<String, StockCandle1m> getLatestDataForSymbols(List<String> symbols) {
        log.info("[LatestDataLoad] Loading latest data for {} symbols", symbols.size());

        Map<String, StockCandle1m> result = new HashMap<>();

        for (String symbol : symbols) {
            Optional<StockCandle1m> latest = getLatestData(symbol);
            latest.ifPresent(candle -> result.put(symbol, candle));
        }

        return result;
    }

    /**
     * 최근 N분 데이터 조회
     */
    public List<StockCandle1m> getRecentData(String symbol, int minutes) {
        LocalDateTime endTime = LocalDateTime.now();
        LocalDateTime startTime = endTime.minusMinutes(minutes);

        return candleRepository.findBySymbolAndTimestampBetweenOrderByTimestampAsc(
                symbol,
                startTime,
                endTime);
    }

    /**
     * 오늘 데이터만 조회
     */
    public List<StockCandle1m> getTodayData(String symbol) {
        LocalDateTime startOfDay = LocalDateTime.now().toLocalDate().atStartOfDay();
        LocalDateTime endOfDay = LocalDateTime.now();

        return candleRepository.findBySymbolAndTimestampBetweenOrderByTimestampAsc(
                symbol,
                startOfDay,
                endOfDay);
    }

    /**
     * 통계 정보 조회
     */
    public Map<String, Object> getStatistics(String symbol) {
        List<StockCandle1m> todayData = getTodayData(symbol);

        Map<String, Object> stats = new HashMap<>();
        stats.put("symbol", symbol);
        stats.put("totalCandles", todayData.size());

        long activeCandlesCount = todayData.stream()
                .filter(c -> c.getVolume() != null && c.getVolume() > 0)
                .count();
        stats.put("activeCandles", activeCandlesCount);

        if (!todayData.isEmpty()) {
            StockCandle1m latest = todayData.get(todayData.size() - 1);
            stats.put("latestPrice", latest.getClose());
            stats.put("latestVolume", latest.getVolume());
            stats.put("latestTimestamp", latest.getTimestamp());
        }

        return stats;
    }
}