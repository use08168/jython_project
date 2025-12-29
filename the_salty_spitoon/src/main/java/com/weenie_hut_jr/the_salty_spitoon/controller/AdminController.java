package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import com.weenie_hut_jr.the_salty_spitoon.scheduler.NewsScheduler;
import com.weenie_hut_jr.the_salty_spitoon.service.FinancialDataService;
import com.weenie_hut_jr.the_salty_spitoon.service.HistoricalCollectionService;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsCollectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.weenie_hut_jr.the_salty_spitoon.model.Stock;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockRepository;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 관리자 컨트롤러 (리팩토링 버전)
 * 
 * ========================================
 * Phase 5 (2025-12-30) - 뉴스 스케줄러 통합
 * ========================================
 * - 뉴스 수집: NewsScheduler로 통합
 * - 20분 자동 수집 스케줄러 추가
 * - 수집 로그 실시간 확인
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
    private final StockRepository stockRepository;
    private final NewsScheduler newsScheduler;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // 재무 데이터 수집 상태 추적
    private volatile boolean isFinancialCollecting = false;
    private volatile String financialCollectionStatus = "Ready";

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
        
        // 뉴스 수집 상태 (NewsScheduler에서 조회)
        model.addAttribute("isNewsCollecting", newsScheduler.isCollecting());
        model.addAttribute("newsCollectionStatus", newsScheduler.getLastCollectionStatus());
        model.addAttribute("newsSchedulerEnabled", newsScheduler.isSchedulerEnabled());
        model.addAttribute("newsCollectionLogs", newsScheduler.getCollectionLogs());
        model.addAttribute("lastNewsCollectionTime", newsScheduler.getLastCollectionTime());
        model.addAttribute("lastNewsCollectionCount", newsScheduler.getLastCollectionCount());

        return "admin/admin";
    }

    // ========================================
    // Phase 4: 과거 데이터 수집 (WebSocket 기반)
    // ========================================

    /**
     * 과거 데이터 수집 시작
     */
    @PostMapping("/collect-historical")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> startHistoricalCollection(
            @RequestParam(defaultValue = "1") int days,
            @RequestParam(defaultValue = "") String symbols) {
        
        Map<String, Object> response = new HashMap<>();
        
        if (days < 1 || days > 7) {
            response.put("success", false);
            response.put("message", "일수는 1~7 사이여야 합니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
        if (historicalCollectionService.isCollecting()) {
            response.put("success", false);
            response.put("message", "이미 수집이 진행 중입니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
        List<String> targetSymbols = null;
        String trimmedSymbols = symbols.trim();
        if (!trimmedSymbols.isEmpty()) {
            targetSymbols = Arrays.stream(trimmedSymbols.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .map(String::toUpperCase)
                    .collect(Collectors.toList());
        }
        
        log.info("========================================");
        log.info("과거 데이터 수집 요청: {}일", days);
        log.info("========================================");
        
        historicalCollectionService.startCollection(days, targetSymbols);
        
        response.put("success", true);
        response.put("message", "수집이 시작되었습니다.");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/historical-collection-status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getHistoricalCollectionStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("isCollecting", historicalCollectionService.isCollecting());
        return ResponseEntity.ok(response);
    }

    // ========================================
    // 재무 데이터 수집
    // ========================================

    @PostMapping("/collect-financial-data")
    @ResponseBody
    public String collectFinancialData() {
        log.info("Financial Data Collection Requested");

        if (isFinancialCollecting) {
            return "⚠️ Collection already in progress!";
        }

        new Thread(() -> {
            isFinancialCollecting = true;
            financialCollectionStatus = "Starting...";

            try {
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
                financialCollectionStatus = exitCode == 0 ? "Completed!" : "Failed!";

            } catch (Exception e) {
                log.error("Error during financial data collection", e);
                financialCollectionStatus = "Error: " + e.getMessage();
            } finally {
                isFinancialCollecting = false;
            }
        }).start();

        return "✅ Financial data collection started!";
    }

    @GetMapping("/financial-collection-status")
    @ResponseBody
    public String getFinancialCollectionStatus() {
        return isFinancialCollecting ? 
            "🔄 Status: " + financialCollectionStatus : 
            "✅ Status: Ready";
    }

    @PostMapping("/load-financial-data")
    @ResponseBody
    public String loadFinancialData(@RequestParam String jsonFileName) {
        try {
            Path jsonPath = Paths.get("python", "results", jsonFileName);
            File jsonFile = jsonPath.toFile();

            if (!jsonFile.exists()) {
                return "❌ JSON file not found: " + jsonFileName;
            }

            return financialDataService.loadFinancialDataFromJson(jsonFile.getAbsolutePath());

        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }

    @PostMapping("/load-latest-financial-data")
    @ResponseBody
    public String loadLatestFinancialData() {
        try {
            List<String> jsonFiles = getFinancialJsonFiles();

            if (jsonFiles.isEmpty()) {
                return "❌ No financial data JSON files found";
            }

            String latestFile = jsonFiles.get(0);
            Path jsonPath = Paths.get("python", "results", latestFile);
            return "✅ Loaded from: " + latestFile + "\n" + 
                   financialDataService.loadFinancialDataFromJson(jsonPath.toAbsolutePath().toString());

        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }

    @PostMapping("/load-nasdaq100")
    @ResponseBody
    public String loadNasdaq100() {
        try {
            ProcessBuilder pb = new ProcessBuilder("python", "python/load_nasdaq100.py");
            pb.redirectErrorStream(true);
            Process process = pb.start();
            int exitCode = process.waitFor();

            return exitCode == 0 ? 
                "✅ NASDAQ 100 stocks loaded successfully" : 
                "❌ Failed to load NASDAQ 100 stocks";

        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }

    // ========================================
    // 뉴스 수집 (NewsScheduler 사용)
    // ========================================

    /**
     * 뉴스 수집 시작 (수동)
     * NewsScheduler를 통해 실행
     */
    @PostMapping("/collect-news")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> startNewsCollection() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            newsScheduler.triggerManualCollection();
            response.put("success", true);
            response.put("message", "뉴스 수집이 시작되었습니다.");
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    /**
     * 뉴스 수집 상태 확인
     */
    @GetMapping("/news-collection-status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getNewsCollectionStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("isCollecting", newsScheduler.isCollecting());
        response.put("status", newsScheduler.getLastCollectionStatus());
        response.put("schedulerEnabled", newsScheduler.isSchedulerEnabled());
        response.put("lastCollectionTime", newsScheduler.getLastCollectionTime());
        response.put("lastCollectionCount", newsScheduler.getLastCollectionCount());
        response.put("logs", newsScheduler.getCollectionLogs());
        return ResponseEntity.ok(response);
    }
    
    /**
     * 뉴스 스케줄러 활성화/비활성화
     */
    @PostMapping("/news-scheduler-toggle")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> toggleNewsScheduler(@RequestParam boolean enabled) {
        Map<String, Object> response = new HashMap<>();
        
        newsScheduler.setSchedulerEnabled(enabled);
        
        response.put("success", true);
        response.put("enabled", enabled);
        response.put("message", enabled ? "뉴스 스케줄러가 활성화되었습니다." : "뉴스 스케줄러가 비활성화되었습니다.");
        
        log.info("뉴스 스케줄러 상태 변경: {}", enabled ? "활성화" : "비활성화");
        
        return ResponseEntity.ok(response);
    }

    // ========================================
    // 유틸리티
    // ========================================

    private List<String> getFinancialJsonFiles() {
        List<String> jsonFiles = new ArrayList<>();

        try {
            Path resultsDir = Paths.get("python", "results");
            File dir = resultsDir.toFile();

            if (!dir.exists() || !dir.isDirectory()) {
                return jsonFiles;
            }

            File[] files = dir.listFiles((d, name) -> 
                name.startsWith("financial_data_") && name.endsWith(".json"));

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
    // CSV 동기화 및 자동 완성
    // ========================================

    @GetMapping("/csv-symbols")
    @ResponseBody
    public ResponseEntity<List<Map<String, String>>> getCsvSymbols() {
        List<Map<String, String>> symbols = new ArrayList<>();
        
        try {
            Path csvPath = Paths.get("python", "nasdaq100_tickers.csv");
            
            if (!csvPath.toFile().exists()) {
                return ResponseEntity.ok(symbols);
            }
            
            try (BufferedReader reader = new BufferedReader(new FileReader(csvPath.toFile()))) {
                String line;
                boolean isHeader = true;
                
                while ((line = reader.readLine()) != null) {
                    if (isHeader) {
                        isHeader = false;
                        continue;
                    }
                    
                    String[] parts = parseCsvLine(line);
                    if (parts.length >= 2) {
                        Map<String, String> item = new HashMap<>();
                        item.put("symbol", parts[0].trim());
                        item.put("name", parts[1].trim());
                        if (parts.length >= 3) {
                            item.put("logoUrl", parts[2].trim());
                        }
                        symbols.add(item);
                    }
                }
            }
            
        } catch (Exception e) {
            log.error("CSV 읽기 실패", e);
        }
        
        return ResponseEntity.ok(symbols);
    }

    @GetMapping("/missing-symbols")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getMissingSymbols() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            List<Map<String, String>> csvSymbols = getCsvSymbolsList();
            Set<String> csvSymbolSet = csvSymbols.stream()
                    .map(m -> m.get("symbol"))
                    .collect(Collectors.toSet());
            
            List<Stock> dbStocks = stockRepository.findAll();
            Set<String> dbSymbolSet = dbStocks.stream()
                    .map(Stock::getSymbol)
                    .collect(Collectors.toSet());
            
            List<Map<String, String>> missingSymbols = csvSymbols.stream()
                    .filter(m -> !dbSymbolSet.contains(m.get("symbol")))
                    .collect(Collectors.toList());
            
            response.put("success", true);
            response.put("csvCount", csvSymbolSet.size());
            response.put("dbCount", dbSymbolSet.size());
            response.put("missingCount", missingSymbols.size());
            response.put("missingSymbols", missingSymbols);
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/sync-csv-to-db")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> syncCsvToDb() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            List<Map<String, String>> csvSymbols = getCsvSymbolsList();
            List<Stock> dbStocks = stockRepository.findAll();
            Map<String, Stock> dbStockMap = dbStocks.stream()
                    .collect(Collectors.toMap(Stock::getSymbol, s -> s));
            
            int addedCount = 0;
            int updatedCount = 0;
            
            for (Map<String, String> csvItem : csvSymbols) {
                String symbol = csvItem.get("symbol");
                String name = csvItem.get("name");
                String logoUrl = csvItem.get("logoUrl");
                
                Stock existingStock = dbStockMap.get(symbol);
                
                if (existingStock == null) {
                    Stock newStock = new Stock();
                    newStock.setSymbol(symbol);
                    newStock.setName(name);
                    newStock.setLogoUrl(logoUrl);
                    newStock.setIsActive(true);
                    stockRepository.save(newStock);
                    addedCount++;
                } else {
                    boolean needsUpdate = false;
                    
                    if (logoUrl != null && !logoUrl.isEmpty()) {
                        if (existingStock.getLogoUrl() == null || 
                            !existingStock.getLogoUrl().equals(logoUrl)) {
                            existingStock.setLogoUrl(logoUrl);
                            needsUpdate = true;
                        }
                    }
                    
                    if (!existingStock.getName().equals(name)) {
                        existingStock.setName(name);
                        needsUpdate = true;
                    }
                    
                    if (needsUpdate) {
                        stockRepository.save(existingStock);
                        updatedCount++;
                    }
                }
            }
            
            response.put("success", true);
            response.put("addedCount", addedCount);
            response.put("updatedCount", updatedCount);
            response.put("message", addedCount + "개 종목 추가, " + updatedCount + "개 종목 업데이트");
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "동기화 실패: " + e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    private List<Map<String, String>> getCsvSymbolsList() throws Exception {
        List<Map<String, String>> symbols = new ArrayList<>();
        Path csvPath = Paths.get("python", "nasdaq100_tickers.csv");
        
        if (!csvPath.toFile().exists()) {
            throw new RuntimeException("CSV 파일을 찾을 수 없습니다: " + csvPath);
        }
        
        try (BufferedReader reader = new BufferedReader(new FileReader(csvPath.toFile()))) {
            String line;
            boolean isHeader = true;
            
            while ((line = reader.readLine()) != null) {
                if (isHeader) {
                    isHeader = false;
                    continue;
                }
                
                String[] parts = parseCsvLine(line);
                if (parts.length >= 2) {
                    Map<String, String> item = new HashMap<>();
                    item.put("symbol", parts[0].trim());
                    item.put("name", parts[1].trim());
                    if (parts.length >= 3) {
                        item.put("logoUrl", parts[2].trim());
                    }
                    symbols.add(item);
                }
            }
        }
        
        return symbols;
    }
    
    private String[] parseCsvLine(String line) {
        List<String> result = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;
        
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                result.add(current.toString());
                current = new StringBuilder();
            } else {
                current.append(c);
            }
        }
        result.add(current.toString());
        
        return result.toArray(new String[0]);
    }
}
