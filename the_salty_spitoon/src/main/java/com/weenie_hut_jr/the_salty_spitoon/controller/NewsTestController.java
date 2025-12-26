package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.service.NewsCollectionService;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 뉴스 데이터 로딩 테스트 Controller
 */
@Slf4j
@RestController
@RequestMapping("/api/news/test")
@RequiredArgsConstructor
public class NewsTestController {

    private final NewsCollectionService newsCollectionService;
    private final NewsService newsService;

    /**
     * JSON 파일에서 뉴스 로딩
     * 
     * URL: http://localhost:8080/api/news/test/load
     */
    @GetMapping("/load")
    public ResponseEntity<Map<String, Object>> loadNewsFromJson() {
        log.info("========================================");
        log.info("뉴스 로딩 API 호출");
        log.info("========================================");

        Map<String, Object> response = new HashMap<>();

        try {
            // JSON 파일 경로
            String jsonFilePath = "python/output/news_details.json";

            // 로딩 전 개수
            long beforeCount = newsCollectionService.getTotalNewsCount();
            log.info("로딩 전 뉴스 개수: {}", beforeCount);

            // JSON 로딩
            newsCollectionService.loadNewsFromJson(jsonFilePath);

            // 로딩 후 개수
            long afterCount = newsCollectionService.getTotalNewsCount();
            log.info("로딩 후 뉴스 개수: {}", afterCount);

            // 응답 데이터
            response.put("success", true);
            response.put("message", "뉴스 로딩 완료");
            response.put("beforeCount", beforeCount);
            response.put("afterCount", afterCount);
            response.put("loadedCount", afterCount - beforeCount);

            log.info("========================================");
            log.info("✅ 뉴스 로딩 성공");
            log.info("========================================");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 뉴스 로딩 실패", e);

            response.put("success", false);
            response.put("message", "뉴스 로딩 실패: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());

            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 현재 저장된 뉴스 통계
     * 
     * URL: http://localhost:8080/api/news/test/stats
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getNewsStats() {
        Map<String, Object> response = new HashMap<>();

        try {
            long totalCount = newsCollectionService.getTotalNewsCount();

            // 주요 종목별 개수
            Map<String, Long> symbolCounts = new HashMap<>();
            String[] symbols = { "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META" };

            for (String symbol : symbols) {
                long count = newsCollectionService.getNewsCountBySymbol(symbol);
                if (count > 0) {
                    symbolCounts.put(symbol, count);
                }
            }

            response.put("success", true);
            response.put("totalNews", totalCount);
            response.put("symbolCounts", symbolCounts);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 통계 조회 실패", e);

            response.put("success", false);
            response.put("message", "통계 조회 실패: " + e.getMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 디코딩 테스트
     * 
     * URL: http://localhost:8080/api/news/test/decode/{id}
     */
    @GetMapping("/decode/{id}")
    public ResponseEntity<Map<String, Object>> testDecode(@PathVariable Long id) {
        log.info("========================================");
        log.info("디코딩 테스트: ID = {}", id);
        log.info("========================================");

        try {
            Map<String, Object> newsDetail = newsService.getNewsDetailById(id);

            if (newsDetail == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "뉴스를 찾을 수 없습니다. ID: " + id);

                log.warn("⚠️  뉴스를 찾을 수 없음: ID = {}", id);

                return ResponseEntity.notFound().build();
            }

            log.info("✅ 디코딩 성공");
            log.info("제목: {}", newsDetail.get("title"));
            log.info("출처: {}", newsDetail.get("publisher"));
            log.info("본문 길이: {} chars", ((String) newsDetail.get("fullContent")).length());
            log.info("========================================");

            // 응답에 success 플래그 추가
            newsDetail.put("success", true);

            return ResponseEntity.ok(newsDetail);

        } catch (Exception e) {
            log.error("❌ 디코딩 실패", e);

            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "디코딩 실패: " + e.getMessage());
            error.put("error", e.getClass().getSimpleName());

            return ResponseEntity.internalServerError().body(error);
        }
    }

    /**
     * 테스트용 - 모든 뉴스 삭제
     * 
     * URL: http://localhost:8080/api/news/test/clear
     */
    @GetMapping("/clear")
    public ResponseEntity<Map<String, Object>> clearAllNews() {
        log.warn("========================================");
        log.warn("⚠️  모든 뉴스 삭제 요청");
        log.warn("========================================");

        Map<String, Object> response = new HashMap<>();

        try {
            long beforeCount = newsCollectionService.getTotalNewsCount();

            // 모든 뉴스 삭제 (테스트용)
            // stockNewsRepository.deleteAll();

            response.put("success", true);
            response.put("message", "삭제 기능은 주석 처리되어 있습니다. 필요시 코드에서 주석 해제하세요.");
            response.put("beforeCount", beforeCount);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 삭제 실패", e);

            response.put("success", false);
            response.put("message", "삭제 실패: " + e.getMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }
}