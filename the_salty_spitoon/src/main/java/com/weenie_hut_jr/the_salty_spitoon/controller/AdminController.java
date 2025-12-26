package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.weenie_hut_jr.the_salty_spitoon.dto.CollectionResult;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import com.weenie_hut_jr.the_salty_spitoon.service.FinancialDataService;
import com.weenie_hut_jr.the_salty_spitoon.service.HistoricalCollectionService;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsCollectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 관리자 컨트롤러 (리팩토링 버전)
 * 
 * ========================================
 * Phase 4 (2025-12-26) - 리팩토링
 * ========================================
 * - 과거 데이터 수집: WebSocket 기반 실시간 진행률
 * - 무결성 검사/LatestDataLoad 제거 (통합)
 * - 재무 데이터 수집 기능 유지
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-26
 */
@Slf4j
@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final HistoricalCollectionService historicalCollectionService;
    private final FinancialDataService financialDataService;
    private final NewsCollectionService newsCollectionService;
    private final StockNewsRepository stockNewsRepository;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // 재무 데이터 수집 상태 추적
    private volatile boolean isFinancialCollecting = false;
    private volatile String financialCollectionStatus = "Ready";

    // 뉴스 수집 상태 추적
    private volatile boolean isNewsCollecting = false;
    private volatile String newsCollectionStatus = "Ready";
    private volatile int newsCollectionProgress = 0;
    private volatile int newsCollectionTotal = 0;

    // ========================================
    // 관리자 페이지
    // ========================================

    /**
     * 관리자 페이지 메인
     */
    @GetMapping
    public String adminPage(Model model) {
        log.info("Admin page accessed");

        // 재무 데이터 JSON 파일 목록 조회
        List<String> financialJsonFiles = getFinancialJsonFiles();
        model.addAttribute("financialJsonFiles", financialJsonFiles);

        // 수집 상태 추가
        model.addAttribute("isCollecting", historicalCollectionService.isCollecting());
        model.addAttribute("isFinancialCollecting", isFinancialCollecting);
        model.addAttribute("financialCollectionStatus", financialCollectionStatus);
        model.addAttribute("isNewsCollecting", isNewsCollecting);
        model.addAttribute("newsCollectionStatus", newsCollectionStatus);

        return "admin/admin";
    }

    // ========================================
    // Phase 4: 과거 데이터 수집 (WebSocket 기반)
    // ========================================

    /**
     * 과거 데이터 수집 시작
     * 
     * @param days 수집할 일수 (1~7)
     */
    @PostMapping("/collect-historical")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> startHistoricalCollection(
            @RequestParam(defaultValue = "1") int days) {
        
        Map<String, Object> response = new HashMap<>();
        
        // 유효성 검사
        if (days < 1 || days > 7) {
            response.put("success", false);
            response.put("message", "일수는 1~7 사이여야 합니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
        // 이미 수집 중인지 확인
        if (historicalCollectionService.isCollecting()) {
            response.put("success", false);
            response.put("message", "이미 수집이 진행 중입니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
        // 비동기로 수집 시작
        log.info("========================================");
        log.info("과거 데이터 수집 요청: {}일", days);
        log.info("========================================");
        
        historicalCollectionService.startCollection(days);
        
        response.put("success", true);
        response.put("message", "수집이 시작되었습니다. 진행 상황은 화면에서 확인하세요.");
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * 과거 데이터 수집 상태 확인
     */
    @GetMapping("/historical-collection-status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getHistoricalCollectionStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("isCollecting", historicalCollectionService.isCollecting());
        return ResponseEntity.ok(response);
    }

    // ========================================
    // 재무 데이터 수집 (기존 유지)
    // ========================================

    /**
     * 재무 데이터 수집 (Python 실행) - 비동기 방식
     */
    @PostMapping("/collect-financial-data")
    @ResponseBody
    public String collectFinancialData() {
        log.info("========================================");
        log.info("Financial Data Collection Requested");
        log.info("========================================");

        if (isFinancialCollecting) {
            return "⚠️ Collection already in progress!\n" +
                    "Status: " + financialCollectionStatus + "\n" +
                    "Please wait for completion or check Spring Boot console.";
        }

        new Thread(() -> {
            isFinancialCollecting = true;
            financialCollectionStatus = "Starting...";

            try {
                log.info("🐍 Starting Python script: load_nasdaq100_financial.py");
                financialCollectionStatus = "Python script running...";

                ProcessBuilder pb = new ProcessBuilder(
                        "python", "python/load_nasdaq100_financial.py");
                pb.redirectErrorStream(true);

                Process process = pb.start();

                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process.getInputStream()))) {
                    String line;
                    int processedCount = 0;

                    while ((line = reader.readLine()) != null) {
                        log.info("[Python] {}", line);

                        if (line.contains("PROGRESS")) {
                            processedCount++;
                            financialCollectionStatus = "Processing: " + processedCount + "/101";
                        }
                    }
                }

                int exitCode = process.waitFor();

                if (exitCode == 0) {
                    log.info("========================================");
                    log.info("✅ Financial Data Collection Completed!");
                    log.info("========================================");
                    financialCollectionStatus = "Completed successfully!";
                } else {
                    log.error("❌ Financial data collection failed. Exit code: {}", exitCode);
                    financialCollectionStatus = "Failed! Exit code: " + exitCode;
                }

            } catch (Exception e) {
                log.error("❌ Error during financial data collection", e);
                financialCollectionStatus = "Error: " + e.getMessage();
            } finally {
                isFinancialCollecting = false;
            }

        }).start();

        return "✅ Financial data collection started in background!\n\n" +
                "📊 Processing 101 symbols\n" +
                "⏱️  Expected time: 10-15 minutes\n" +
                "📝 Check Spring Boot console for real-time logs\n" +
                "📁 Result will be saved to: python/results/financial_data_{timestamp}.json\n\n" +
                "💡 Tip: You can close this window and come back later!\n" +
                "Refresh the page after 10-15 minutes to load the data.";
    }

    /**
     * 재무 데이터 수집 상태 확인
     */
    @GetMapping("/financial-collection-status")
    @ResponseBody
    public String getFinancialCollectionStatus() {
        if (isFinancialCollecting) {
            return "🔄 Status: " + financialCollectionStatus;
        } else {
            return "✅ Status: Ready (No collection in progress)";
        }
    }

    /**
     * 재무 데이터 로드 (JSON → MySQL)
     */
    @PostMapping("/load-financial-data")
    @ResponseBody
    public String loadFinancialData(@RequestParam String jsonFileName) {
        log.info("========================================");
        log.info("Financial Data Load Started");
        log.info("========================================");
        log.info("JSON File: {}", jsonFileName);

        try {
            Path jsonPath = Paths.get("python", "results", jsonFileName);
            File jsonFile = jsonPath.toFile();

            if (!jsonFile.exists()) {
                log.error("❌ JSON file not found: {}", jsonPath);
                return "❌ JSON file not found: " + jsonFileName;
            }

            String result = financialDataService.loadFinancialDataFromJson(jsonFile.getAbsolutePath());

            log.info("========================================");
            log.info("Financial Data Load Completed");
            log.info("========================================");

            return result;

        } catch (Exception e) {
            log.error("❌ Error loading financial data", e);
            return "❌ Error: " + e.getMessage();
        }
    }

    /**
     * 최신 재무 데이터 자동 로드
     */
    @PostMapping("/load-latest-financial-data")
    @ResponseBody
    public String loadLatestFinancialData() {
        log.info("========================================");
        log.info("Latest Financial Data Load Started");
        log.info("========================================");

        try {
            List<String> jsonFiles = getFinancialJsonFiles();

            if (jsonFiles.isEmpty()) {
                log.warn("❌ No financial data JSON files found");
                return "❌ No financial data JSON files found in python/results/";
            }

            String latestFile = jsonFiles.get(0);
            log.info("Latest JSON file: {}", latestFile);

            Path jsonPath = Paths.get("python", "results", latestFile);
            String result = financialDataService.loadFinancialDataFromJson(jsonPath.toAbsolutePath().toString());

            log.info("========================================");
            log.info("Latest Financial Data Load Completed");
            log.info("========================================");

            return "✅ Loaded from: " + latestFile + "\n" + result;

        } catch (Exception e) {
            log.error("❌ Error loading latest financial data", e);
            return "❌ Error: " + e.getMessage();
        }
    }

    /**
     * NASDAQ 100 종목 로드
     */
    @PostMapping("/load-nasdaq100")
    @ResponseBody
    public String loadNasdaq100() {
        log.info("Loading NASDAQ 100 stocks...");

        try {
            ProcessBuilder pb = new ProcessBuilder(
                    "python", "python/load_nasdaq100.py");
            pb.redirectErrorStream(true);
            Process process = pb.start();

            int exitCode = process.waitFor();

            if (exitCode == 0) {
                log.info("NASDAQ 100 stocks loaded successfully");
                return "✅ NASDAQ 100 stocks loaded successfully";
            } else {
                log.error("Failed to load NASDAQ 100 stocks. Exit code: {}", exitCode);
                return "❌ Failed to load NASDAQ 100 stocks";
            }

        } catch (Exception e) {
            log.error("Error loading NASDAQ 100 stocks", e);
            return "❌ Error: " + e.getMessage();
        }
    }

    // ========================================
    // 유틸리티
    // ========================================

    /**
     * 재무 데이터 JSON 파일 목록 조회
     */
    private List<String> getFinancialJsonFiles() {
        List<String> jsonFiles = new ArrayList<>();

        try {
            Path resultsDir = Paths.get("python", "results");
            File dir = resultsDir.toFile();

            if (!dir.exists() || !dir.isDirectory()) {
                return jsonFiles;
            }

            File[] files = dir.listFiles((d, name) -> name.startsWith("financial_data_") && name.endsWith(".json"));

            if (files != null) {
                for (File file : files) {
                    jsonFiles.add(file.getName());
                }
                jsonFiles.sort(Comparator.reverseOrder());
            }

        } catch (Exception e) {
            log.error("Error listing financial JSON files", e);
        }

        return jsonFiles;
    }

    // ========================================
    // 뉴스 수집 (Python 스크립트 실행)
    // ========================================

    /**
     * 뉴스 수집 시작 (비동기)
     * Step 1: news_api_collector.py 실행 → news_links.json
     * Step 2: Java가 news_links.json 읽기 → MySQL과 비교 → 중복 제거 → 덤어쓰기
     * Step 3: news_detail_crawler.py 실행 → news_details.json
     * Step 4: news_details.json → MySQL 저장
     * 
     * @param symbols 수집할 종목 (비우면 전체, 쉼표 구분)
     * @param count 종목당 뉴스 개수 (1-10)
     */
    @PostMapping("/collect-news")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> startNewsCollection(
            @RequestParam(defaultValue = "") String symbols,
            @RequestParam(defaultValue = "5") int count) {
        
        Map<String, Object> response = new HashMap<>();
        
        if (isNewsCollecting) {
            response.put("success", false);
            response.put("message", "이미 뉴스 수집이 진행 중입니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
        // 파라미터 유효성 검사
        final int newsCount = Math.max(1, Math.min(count, 10));
        final String targetSymbols = symbols.trim();
        
        log.info("========================================");
        log.info("뉴스 수집 요청");
        log.info("종목: {}", targetSymbols.isEmpty() ? "전체 (NASDAQ 100)" : targetSymbols);
        log.info("종목당 개수: {}", newsCount);
        log.info("========================================");
        
        // 비동기 실행
        new Thread(() -> {
            isNewsCollecting = true;
            newsCollectionStatus = "Starting...";
            newsCollectionProgress = 0;
            newsCollectionTotal = 0;
            
            try {
                // ========================================
                // Step 1: API로 뉴스 링크 수집
                // ========================================
                log.info("🐍 Step 1/4: news_api_collector.py 실행");
                newsCollectionStatus = "Step 1/4: API에서 뉴스 링크 수집 중...";
                
                // Python 명령어 구성
                List<String> command = new ArrayList<>();
                command.add("python");
                command.add("python/news_api_collector.py");
                command.add("--count");
                command.add(String.valueOf(newsCount));
                
                if (!targetSymbols.isEmpty()) {
                    command.add("--symbols");
                    command.add(targetSymbols);
                }
                
                ProcessBuilder pb1 = new ProcessBuilder(command);
                pb1.redirectErrorStream(true);
                Process process1 = pb1.start();
                
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process1.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        log.info("[API Collector] {}", line);
                    }
                }
                
                int exitCode1 = process1.waitFor();
                if (exitCode1 != 0) {
                    throw new RuntimeException("news_api_collector.py 실패 (exit code: " + exitCode1 + ")");
                }
                log.info("✅ Step 1 완료: news_links.json 생성");
                
                // ========================================
                // Step 2: MySQL과 비교하여 중복 제거
                // ========================================
                log.info("📊 Step 2/4: MySQL과 비교하여 중복 제거");
                newsCollectionStatus = "Step 2/4: 중복 뉴스 필터링 중...";
                
                int filteredCount = filterDuplicateNews();
                log.info("✅ Step 2 완료: {} 개 뉴스 필터링 완료 (중복 제거)", filteredCount);
                
                // 필터링 후 뉴스가 없으면 종료
                if (filteredCount == 0) {
                    newsCollectionStatus = "✅ 완료! (새로운 뉴스 없음)";
                    log.info("========================================");
                    log.info("✅ 새로운 뉴스가 없습니다. 수집 종료.");
                    log.info("========================================");
                    return;
                }
                
                // ========================================
                // Step 3: Selenium으로 본문 크롤링
                // ========================================
                log.info("🐍 Step 3/4: news_detail_crawler.py 실행");
                newsCollectionStatus = "Step 3/4: 기사 본문 크롤링 중...";
                
                ProcessBuilder pb2 = new ProcessBuilder("python", "-u", "python/news_detail_crawler.py");
                pb2.redirectErrorStream(true);
                pb2.environment().put("PYTHONUNBUFFERED", "1");
                Process process2 = pb2.start();
                
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process2.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        log.info("[Crawler] {}", line);
                        
                        // PROGRESS:파싱 (PROGRESS:5/100:AAPL)
                        if (line.startsWith("PROGRESS:")) {
                            try {
                                String[] parts = line.split(":");
                                if (parts.length >= 2) {
                                    String[] progressParts = parts[1].split("/");
                                    newsCollectionProgress = Integer.parseInt(progressParts[0]);
                                    newsCollectionTotal = Integer.parseInt(progressParts[1]);
                                    String symbol = parts.length > 2 ? parts[2] : "";
                                    newsCollectionStatus = String.format(
                                        "Step 3/4: 크롤링 %d/%d (%s)", 
                                        newsCollectionProgress, newsCollectionTotal, symbol
                                    );
                                }
                            } catch (Exception e) {
                                // 파싱 실패 무시
                            }
                        }
                    }
                }
                
                int exitCode2 = process2.waitFor();
                if (exitCode2 != 0) {
                    throw new RuntimeException("news_detail_crawler.py 실패 (exit code: " + exitCode2 + ")");
                }
                log.info("✅ Step 3 완료: news_details.json 생성");
                
                // ========================================
                // Step 4: JSON → MySQL 저장
                // ========================================
                log.info("💾 Step 4/4: MySQL에 저장");
                newsCollectionStatus = "Step 4/4: MySQL에 저장 중...";
                
                Path jsonPath = Paths.get("python", "output", "news_details.json");
                if (jsonPath.toFile().exists()) {
                    newsCollectionService.loadNewsFromJson(jsonPath.toAbsolutePath().toString());
                    log.info("✅ Step 4 완료: MySQL 저장 완료");
                } else {
                    log.warn("⚠️  news_details.json 파일이 없습니다");
                }
                
                newsCollectionStatus = "✅ 완료!";
                log.info("========================================");
                log.info("✅ 뉴스 수집 완료!");
                log.info("========================================");
                
            } catch (Exception e) {
                log.error("❌ 뉴스 수집 실패", e);
                newsCollectionStatus = "❌ 실패: " + e.getMessage();
            } finally {
                isNewsCollecting = false;
            }
        }).start();
        
        response.put("success", true);
        response.put("message", "뉴스 수집이 시작되었습니다.");
        return ResponseEntity.ok(response);
    }
    
    /**
     * news_links.json에서 MySQL에 이미 있는 뉴스 제거
     * @return 필터링 후 남은 뉴스 개수
     */
    private int filterDuplicateNews() throws Exception {
        Path jsonPath = Paths.get("python", "output", "news_links.json");
        
        if (!jsonPath.toFile().exists()) {
            throw new RuntimeException("news_links.json 파일이 없습니다.");
        }
        
        // JSON 읽기
        String jsonContent = Files.readString(jsonPath);
        JsonNode rootNode = objectMapper.readTree(jsonContent);
        JsonNode dataArray = rootNode.get("data");
        
        if (dataArray == null || !dataArray.isArray()) {
            throw new RuntimeException("news_links.json 형식이 잘못되었습니다.");
        }
        
        int originalCount = dataArray.size();
        log.info("📊 원본 뉴스 개수: {}", originalCount);
        
        // 중복 제거
        ArrayNode filteredArray = objectMapper.createArrayNode();
        int duplicateCount = 0;
        
        for (JsonNode newsNode : dataArray) {
            String title = newsNode.get("title").asText();
            String publishedAtStr = newsNode.get("published_at").asText();
            
            try {
                LocalDateTime publishedAt = LocalDateTime.parse(publishedAtStr, DATE_FORMATTER);
                
                // MySQL에서 중복 체크
                boolean exists = stockNewsRepository.existsByTitleAndPublishedAt(title, publishedAt);
                
                if (exists) {
                    duplicateCount++;
                    log.debug("중복 제거: {}", title);
                } else {
                    filteredArray.add(newsNode);
                }
            } catch (Exception e) {
                // 날짜 파싱 실패 시 포함
                filteredArray.add(newsNode);
                log.warn("날짜 파싱 실패, 포함 처리: {}", title);
            }
        }
        
        log.info("📊 중복 제거: {} → {} (중복 {}개)", 
                originalCount, filteredArray.size(), duplicateCount);
        
        // 수정된 JSON 저장 (덤어쓰기)
        ObjectNode newRoot = objectMapper.createObjectNode();
        newRoot.put("timestamp", rootNode.get("timestamp").asText());
        newRoot.put("total_news", filteredArray.size());
        newRoot.set("data", filteredArray);
        
        String newJsonContent = objectMapper.writerWithDefaultPrettyPrinter()
                .writeValueAsString(newRoot);
        Files.writeString(jsonPath, newJsonContent);
        
        log.info("✅ news_links.json 덤어쓰기 완료");
        
        return filteredArray.size();
    }
    
    /**
     * 뉴스 수집 상태 확인
     */
    @GetMapping("/news-collection-status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getNewsCollectionStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("isCollecting", isNewsCollecting);
        response.put("status", newsCollectionStatus);
        response.put("progress", newsCollectionProgress);
        response.put("total", newsCollectionTotal);
        return ResponseEntity.ok(response);
    }
}
