package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.dto.CollectionResult;
import com.weenie_hut_jr.the_salty_spitoon.dto.DataStatus;
import com.weenie_hut_jr.the_salty_spitoon.dto.IntegrityIssue;
import com.weenie_hut_jr.the_salty_spitoon.service.DataIntegrityService;
import com.weenie_hut_jr.the_salty_spitoon.service.FinancialDataService;
import com.weenie_hut_jr.the_salty_spitoon.service.HistoricalDataService;
import com.weenie_hut_jr.the_salty_spitoon.service.LatestDataLoadService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * 관리자 컨트롤러
 * 
 * ========================================
 * Phase 3 추가 (2025-12-23)
 * ========================================
 * - Data Integrity Check API 추가
 * - Fix Issues API 추가
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-23
 */
@Slf4j
@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final HistoricalDataService historicalDataService;
    private final FinancialDataService financialDataService;
    private final LatestDataLoadService latestDataLoadService;
    private final DataIntegrityService dataIntegrityService; // ← Phase 3 추가

    // 재무 데이터 수집 상태 추적
    private volatile boolean isCollecting = false;
    private volatile String collectionStatus = "Ready";

    // ========================================
    // Phase 2: Latest Data Load
    // ========================================

    /**
     * 전체 종목 데이터 상태 확인
     */
    @GetMapping("/check-data-status")
    @ResponseBody
    public List<DataStatus> checkDataStatus() {
        log.info("========================================");
        log.info("Check Data Status API Called");
        log.info("========================================");

        try {
            List<DataStatus> statusList = latestDataLoadService.checkAllDataStatus();
            log.info("Data status check completed: {} symbols", statusList.size());
            return statusList;

        } catch (Exception e) {
            log.error("Failed to check data status", e);
            throw new RuntimeException("Failed to check data status: " + e.getMessage());
        }
    }

    /**
     * 최신 데이터 로드 (공백 채우기)
     */
    @PostMapping("/load-latest-data")
    @ResponseBody
    public CollectionResult loadLatestData() {
        log.info("========================================");
        log.info("Load Latest Data API Called");
        log.info("========================================");

        try {
            CollectionResult result = latestDataLoadService.fillAllGaps();

            log.info("========================================");
            log.info("Load Latest Data Completed");
            log.info("  Total: {}", result.getTotalSymbols());
            log.info("  Success: {}", result.getSuccessCount());
            log.info("  Failure: {}", result.getFailureCount());
            log.info("  Candles: {}", result.getTotalCandles());
            log.info("========================================");

            return result;

        } catch (Exception e) {
            log.error("Failed to load latest data", e);

            return CollectionResult.builder()
                    .success(false)
                    .message("Error: " + e.getMessage())
                    .build();
        }
    }

    // ========================================
    // Phase 3: Data Integrity Check (신규 추가)
    // ========================================

    /**
     * 데이터 무결성 검사
     * 
     * API: GET /admin/check-integrity
     * 
     * 기능:
     * - 전체 종목 데이터 무결성 검사
     * - 공백, NULL, 이상치 감지
     * - 문제 리스트 반환
     * 
     * Returns:
     * List<IntegrityIssue> 문제 리스트
     */
    @GetMapping("/check-integrity")
    @ResponseBody
    public List<IntegrityIssue> checkIntegrity() {
        log.info("========================================");
        log.info("Check Integrity API Called");
        log.info("========================================");

        try {
            List<IntegrityIssue> issues = dataIntegrityService.checkAllIntegrity();

            log.info("Integrity check completed: {} issues found", issues.size());

            return issues;

        } catch (Exception e) {
            log.error("Failed to check integrity", e);
            throw new RuntimeException("Failed to check integrity: " + e.getMessage());
        }
    }

    /**
     * 데이터 무결성 문제 수정
     * 
     * API: POST /admin/fix-issues
     * 
     * 기능:
     * - 수정 가능한 문제 자동 수정
     * - Python으로 데이터 재수집
     * - 결과 반환
     * 
     * Body:
     * List<IntegrityIssue> 수정할 문제 리스트
     * 
     * Returns:
     * CollectionResult 수정 결과
     */
    @PostMapping("/fix-issues")
    @ResponseBody
    public CollectionResult fixIssues(@RequestBody List<IntegrityIssue> issues) {
        log.info("========================================");
        log.info("Fix Issues API Called");
        log.info("========================================");
        log.info("Issues to fix: {}", issues.size());

        try {
            CollectionResult result = dataIntegrityService.fixIssues(issues);

            log.info("========================================");
            log.info("Fix Issues Completed");
            log.info("  Total: {}", result.getTotalSymbols());
            log.info("  Success: {}", result.getSuccessCount());
            log.info("  Failure: {}", result.getFailureCount());
            log.info("  Candles: {}", result.getTotalCandles());
            log.info("========================================");

            return result;

        } catch (Exception e) {
            log.error("Failed to fix issues", e);

            return CollectionResult.builder()
                    .success(false)
                    .message("Error: " + e.getMessage())
                    .build();
        }
    }

    // ========================================
    // 기존 코드 (변경 없음)
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
        model.addAttribute("isCollecting", isCollecting);
        model.addAttribute("collectionStatus", collectionStatus);

        return "admin/admin";
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

    /**
     * 과거 데이터 로드 (레거시)
     */
    @PostMapping("/load-historical-data")
    @ResponseBody
    public String loadHistoricalData() {
        log.info("Loading historical data from config file");

        try {
            String result = historicalDataService.loadHistoricalData();
            log.info("Historical data loaded: {}", result);
            return result;

        } catch (Exception e) {
            log.error("Error loading historical data", e);
            return "❌ Error: " + e.getMessage();
        }
    }

    /**
     * 재무 데이터 수집 (Python 실행) - 비동기 방식
     */
    @PostMapping("/collect-financial-data")
    @ResponseBody
    public String collectFinancialData() {
        log.info("========================================");
        log.info("Financial Data Collection Requested");
        log.info("========================================");

        if (isCollecting) {
            return "⚠️ Collection already in progress!\n" +
                    "Status: " + collectionStatus + "\n" +
                    "Please wait for completion or check Spring Boot console.";
        }

        new Thread(() -> {
            isCollecting = true;
            collectionStatus = "Starting...";

            try {
                log.info("🐍 Starting Python script: load_nasdaq100_financial.py");
                collectionStatus = "Python script running...";

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
                            collectionStatus = "Processing: " + processedCount + "/101";
                        }
                    }
                }

                int exitCode = process.waitFor();

                if (exitCode == 0) {
                    log.info("========================================");
                    log.info("✅ Financial Data Collection Completed!");
                    log.info("========================================");
                    collectionStatus = "Completed successfully!";
                } else {
                    log.error("❌ Financial data collection failed. Exit code: {}", exitCode);
                    collectionStatus = "Failed! Exit code: " + exitCode;
                }

            } catch (Exception e) {
                log.error("❌ Error during financial data collection", e);
                collectionStatus = "Error: " + e.getMessage();
            } finally {
                isCollecting = false;
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
     * 수집 상태 확인
     */
    @GetMapping("/collection-status")
    @ResponseBody
    public String getCollectionStatus() {
        if (isCollecting) {
            return "🔄 Status: " + collectionStatus;
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
}