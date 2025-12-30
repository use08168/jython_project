package com.weenie_hut_jr.the_salty_spitoon.scheduler;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsCollectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * 뉴스 자동 수집 스케줄러
 * 
 * 20분마다 자동으로 뉴스를 수집합니다.
 * 
 * 수집 과정:
 * 1. news_collector.py 실행 (API + 크롤링 + 번역 + 인코딩)
 * 2. MySQL과 비교하여 중복 필터링
 * 3. news_details.json → MySQL 저장
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-30
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NewsScheduler {

    private final NewsCollectionService newsCollectionService;
    private final StockNewsRepository stockNewsRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    // 스케줄러 활성화 여부 (application.properties에서 설정 가능)
    @Value("${news.scheduler.enabled:true}")
    private boolean schedulerEnabled;
    
    // 종목당 뉴스 개수
    @Value("${news.scheduler.count:10}")
    private int newsCount;
    
    // 수집 상태 추적
    private volatile boolean isCollecting = false;
    private volatile String lastCollectionStatus = "Ready";
    private volatile LocalDateTime lastCollectionTime = null;
    private volatile int lastCollectionCount = 0;
    
    // 수집 로그 (최근 10개)
    private final List<String> collectionLogs = new ArrayList<>();
    private static final int MAX_LOG_SIZE = 50;

    /**
     * 20분마다 뉴스 자동 수집
     * 
     * cron: 0 0/20 * * * * (매 20분)
     * - 0분, 20분, 40분에 실행
     */
    @Scheduled(cron = "0 0/20 * * * *")
    public void collectNewsAutomatically() {
        if (!schedulerEnabled) {
            log.debug("뉴스 스케줄러 비활성화됨");
            return;
        }
        
        if (isCollecting) {
            addLog("⏭️ 이미 수집 중, 스킵");
            log.info("이미 뉴스 수집이 진행 중입니다. 스킵.");
            return;
        }
        
        log.info("========================================");
        log.info("📰 [자동] 뉴스 수집 시작 (20분 스케줄)");
        log.info("========================================");
        
        collectNews();
    }
    
    /**
     * 수동 수집 트리거 (Admin에서 호출)
     */
    public void triggerManualCollection() {
        if (isCollecting) {
            throw new IllegalStateException("이미 뉴스 수집이 진행 중입니다.");
        }
        
        log.info("========================================");
        log.info("📰 [수동] 뉴스 수집 시작");
        log.info("========================================");
        
        // 비동기로 실행
        new Thread(this::collectNews).start();
    }
    
    /**
     * 뉴스 수집 실행
     */
    private void collectNews() {
        isCollecting = true;
        lastCollectionStatus = "수집 중...";
        lastCollectionTime = LocalDateTime.now();
        lastCollectionCount = 0;
        
        addLog("🚀 뉴스 수집 시작");
        
        try {
            // ========================================
            // Step 1: Python 스크립트 실행
            // ========================================
            log.info("🐍 Step 1: news_collector.py 실행");
            lastCollectionStatus = "Step 1: Python 스크립트 실행 중...";
            addLog("🐍 Python 스크립트 실행");
            
            List<String> command = new ArrayList<>();
            command.add("python");
            command.add("-u");
            command.add("python/news_collector.py");
            command.add("--count");
            command.add(String.valueOf(newsCount));
            
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            pb.environment().put("PYTHONUNBUFFERED", "1");
            
            Process process = pb.start();
            
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[Python] {}", line);
                    
                    // PROGRESS 파싱
                    if (line.startsWith("PROGRESS:")) {
                        try {
                            String[] parts = line.split(":");
                            if (parts.length >= 2) {
                                String[] progressParts = parts[1].split("/");
                                int current = Integer.parseInt(progressParts[0]);
                                int total = Integer.parseInt(progressParts[1]);
                                String symbol = parts.length > 2 ? parts[2] : "";
                                lastCollectionStatus = String.format(
                                    "Step 1: 처리 중 %d/%d (%s)", current, total, symbol
                                );
                            }
                        } catch (Exception e) {
                            // 파싱 실패 무시
                        }
                    }
                }
            }
            
            int exitCode = process.waitFor();
            
            if (exitCode != 0) {
                throw new RuntimeException("news_collector.py 실패 (exit code: " + exitCode + ")");
            }
            
            log.info("✅ Step 1 완료: news_details.json 생성");
            addLog("✅ Python 스크립트 완료");
            
            // ========================================
            // Step 2: JSON → MySQL 저장
            // ========================================
            log.info("💾 Step 2: MySQL에 저장");
            lastCollectionStatus = "Step 2: MySQL 저장 중...";
            addLog("💾 MySQL 저장 시작");
            
            Path jsonPath = Paths.get("python", "output", "news_details.json");
            
            if (jsonPath.toFile().exists()) {
                // 중복 필터링 후 저장
                int savedCount = filterAndSaveNews(jsonPath);
                lastCollectionCount = savedCount;
                
                log.info("✅ Step 2 완료: {}개 뉴스 저장", savedCount);
                addLog(String.format("✅ %d개 뉴스 저장 완료", savedCount));
            } else {
                log.warn("⚠️ news_details.json 파일이 없습니다");
                addLog("⚠️ 저장할 뉴스 없음");
            }
            
            lastCollectionStatus = "✅ 완료!";
            log.info("========================================");
            log.info("✅ 뉴스 수집 완료! ({}개)", lastCollectionCount);
            log.info("========================================");
            
        } catch (Exception e) {
            log.error("❌ 뉴스 수집 실패", e);
            lastCollectionStatus = "❌ 실패: " + e.getMessage();
            addLog("❌ 오류: " + e.getMessage());
        } finally {
            isCollecting = false;
        }
    }
    
    /**
     * 중복 필터링 후 MySQL 저장
     */
    private int filterAndSaveNews(Path jsonPath) throws Exception {
        String jsonContent = Files.readString(jsonPath);
        JsonNode rootNode = objectMapper.readTree(jsonContent);
        JsonNode dataArray = rootNode.get("data");
        
        if (dataArray == null || !dataArray.isArray()) {
            return 0;
        }
        
        int originalCount = dataArray.size();
        ArrayNode filteredArray = objectMapper.createArrayNode();
        int duplicateCount = 0;
        
        for (JsonNode newsNode : dataArray) {
            String title = newsNode.get("title").asText();
            String publishedAtStr = newsNode.get("published_at").asText();
            
            try {
                LocalDateTime publishedAt = LocalDateTime.parse(publishedAtStr, DATE_FORMATTER);
                
                // 중복 체크
                boolean exists = stockNewsRepository.existsByTitleAndPublishedAt(title, publishedAt);
                
                if (exists) {
                    duplicateCount++;
                } else {
                    filteredArray.add(newsNode);
                }
            } catch (Exception e) {
                // 날짜 파싱 실패 시 포함
                filteredArray.add(newsNode);
            }
        }
        
        log.info("📊 중복 필터링: {} → {} (중복 {}개)", 
                originalCount, filteredArray.size(), duplicateCount);
        
        if (filteredArray.size() == 0) {
            return 0;
        }
        
        // 필터링된 JSON으로 저장
        ObjectNode newRoot = objectMapper.createObjectNode();
        newRoot.put("timestamp", rootNode.get("timestamp").asText());
        newRoot.put("total_news", filteredArray.size());
        newRoot.set("data", filteredArray);
        
        String newJsonContent = objectMapper.writerWithDefaultPrettyPrinter()
                .writeValueAsString(newRoot);
        Files.writeString(jsonPath, newJsonContent);
        
        // MySQL 저장
        newsCollectionService.loadNewsFromJson(jsonPath.toAbsolutePath().toString());
        
        return filteredArray.size();
    }
    
    /**
     * 로그 추가
     */
    private void addLog(String message) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        String logEntry = String.format("[%s] %s", timestamp, message);
        
        synchronized (collectionLogs) {
            collectionLogs.add(0, logEntry);
            
            // 최대 크기 유지
            while (collectionLogs.size() > MAX_LOG_SIZE) {
                collectionLogs.remove(collectionLogs.size() - 1);
            }
        }
    }
    
    // ========================================
    // Getter (Admin에서 상태 조회용)
    // ========================================
    
    public boolean isCollecting() {
        return isCollecting;
    }
    
    public String getLastCollectionStatus() {
        return lastCollectionStatus;
    }
    
    public LocalDateTime getLastCollectionTime() {
        return lastCollectionTime;
    }
    
    public int getLastCollectionCount() {
        return lastCollectionCount;
    }
    
    public List<String> getCollectionLogs() {
        synchronized (collectionLogs) {
            return new ArrayList<>(collectionLogs);
        }
    }
    
    public boolean isSchedulerEnabled() {
        return schedulerEnabled;
    }
    
    public void setSchedulerEnabled(boolean enabled) {
        this.schedulerEnabled = enabled;
        addLog(enabled ? "Scheduler enabled" : "Scheduler disabled");
    }
    
    // ========================================
    // Date-based Collection (Calendar Feature)
    // ========================================
    
    /**
     * Scan all news URLs and group by date
     * Runs news_date_scanner.py
     */
    public void scanNewsUrls() {
        if (isCollecting) {
            throw new IllegalStateException("Collection in progress");
        }
        
        isCollecting = true;
        lastCollectionStatus = "Scanning URLs...";
        addLog("[SCAN] Starting URL scan");
        
        try {
            List<String> command = new ArrayList<>();
            command.add("python");
            command.add("-u");
            command.add("python/news_date_scanner.py");
            
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            pb.environment().put("PYTHONUNBUFFERED", "1");
            
            Process process = pb.start();
            
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[Python] {}", line);
                    
                    if (line.startsWith("PROGRESS:")) {
                        String[] parts = line.split(":");
                        if (parts.length >= 2) {
                            lastCollectionStatus = "Scanning: " + parts[1];
                        }
                    }
                }
            }
            
            int exitCode = process.waitFor();
            
            if (exitCode != 0) {
                throw new RuntimeException("news_date_scanner.py failed (exit: " + exitCode + ")");
            }
            
            lastCollectionStatus = "Scan complete!";
            addLog("[SCAN] URL scan completed");
            
        } catch (Exception e) {
            log.error("URL scan failed", e);
            lastCollectionStatus = "Scan failed: " + e.getMessage();
            addLog("[ERROR] " + e.getMessage());
            throw new RuntimeException(e);
        } finally {
            isCollecting = false;
        }
    }
    
    /**
     * Get scanned news summary from JSON
     * Returns date -> {total, saved} mapping
     */
    public java.util.Map<String, java.util.Map<String, Object>> getScannedNewsSummary() {
        java.util.Map<String, java.util.Map<String, Object>> result = new java.util.LinkedHashMap<>();
        
        try {
            Path scanPath = Paths.get("python", "output", "scanned_news.json");
            
            if (!scanPath.toFile().exists()) {
                return result;
            }
            
            String jsonContent = Files.readString(scanPath);
            JsonNode rootNode = objectMapper.readTree(jsonContent);
            JsonNode newsByDate = rootNode.get("news_by_date");
            
            if (newsByDate == null) {
                return result;
            }
            
            // Iterate each date
            java.util.Iterator<String> dates = newsByDate.fieldNames();
            while (dates.hasNext()) {
                String date = dates.next();
                JsonNode newsArray = newsByDate.get(date);
                int totalCount = newsArray.size();
                
                // Count saved news in DB for this date
                int savedCount = 0;
                for (JsonNode news : newsArray) {
                    String title = news.get("title").asText();
                    String publishedAtStr = news.get("published_at").asText();
                    
                    try {
                        LocalDateTime publishedAt = LocalDateTime.parse(publishedAtStr, DATE_FORMATTER);
                        if (stockNewsRepository.existsByTitleAndPublishedAt(title, publishedAt)) {
                            savedCount++;
                        }
                    } catch (Exception e) {
                        // Skip
                    }
                }
                
                java.util.Map<String, Object> dateInfo = new java.util.HashMap<>();
                dateInfo.put("total", totalCount);
                dateInfo.put("saved", savedCount);
                dateInfo.put("unsaved", totalCount - savedCount);
                
                result.put(date, dateInfo);
            }
            
        } catch (Exception e) {
            log.error("Failed to read scanned news summary", e);
        }
        
        return result;
    }
    
    /**
     * Get scan timestamp from JSON
     */
    public String getScanTimestamp() {
        try {
            Path scanPath = Paths.get("python", "output", "scanned_news.json");
            
            if (!scanPath.toFile().exists()) {
                return null;
            }
            
            String jsonContent = Files.readString(scanPath);
            JsonNode rootNode = objectMapper.readTree(jsonContent);
            return rootNode.get("scan_timestamp").asText();
            
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Collect news for specific date
     * Runs news_collector.py --date YYYY-MM-DD
     */
    public void collectNewsByDate(String date) {
        if (isCollecting) {
            throw new IllegalStateException("Collection in progress");
        }
        
        isCollecting = true;
        lastCollectionStatus = "Collecting for " + date + "...";
        lastCollectionTime = LocalDateTime.now();
        lastCollectionCount = 0;
        
        addLog("[DATE] Collecting news for " + date);
        
        try {
            // Run news_collector.py with --date
            List<String> command = new ArrayList<>();
            command.add("python");
            command.add("-u");
            command.add("python/news_collector.py");
            command.add("--date");
            command.add(date);
            
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            pb.environment().put("PYTHONUNBUFFERED", "1");
            
            Process process = pb.start();
            
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[Python] {}", line);
                    
                    if (line.startsWith("PROGRESS:")) {
                        try {
                            String[] parts = line.split(":");
                            if (parts.length >= 2) {
                                String[] progressParts = parts[1].split("/");
                                int current = Integer.parseInt(progressParts[0]);
                                int total = Integer.parseInt(progressParts[1]);
                                String symbol = parts.length > 2 ? parts[2] : "";
                                lastCollectionStatus = String.format(
                                    "Processing %d/%d (%s)", current, total, symbol
                                );
                            }
                        } catch (Exception e) {
                            // Ignore
                        }
                    }
                }
            }
            
            int exitCode = process.waitFor();
            
            if (exitCode != 0) {
                throw new RuntimeException("news_collector.py failed (exit: " + exitCode + ")");
            }
            
            // Save to MySQL
            Path jsonPath = Paths.get("python", "output", "news_details.json");
            
            if (jsonPath.toFile().exists()) {
                int savedCount = filterAndSaveNews(jsonPath);
                lastCollectionCount = savedCount;
                addLog("[DATE] Saved " + savedCount + " news for " + date);
            }
            
            lastCollectionStatus = "Complete! (" + date + ")";
            
        } catch (Exception e) {
            log.error("Date-based collection failed", e);
            lastCollectionStatus = "Failed: " + e.getMessage();
            addLog("[ERROR] " + e.getMessage());
            throw new RuntimeException(e);
        } finally {
            isCollecting = false;
        }
    }
}
