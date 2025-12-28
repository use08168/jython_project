package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * 뉴스 데이터 REST API 컨트롤러
 * 
 * Dashboard에서 호출하는 API 엔드포인트들을 제공
 * - /api/news/latest - 최신 뉴스 목록
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-28
 */
@Slf4j
@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
public class NewsApiController {

    private final NewsService newsService;

    /**
     * 최신 뉴스 조회
     * 
     * Dashboard Market Recap 섹션에서 사용
     * 
     * @param limit 가져올 뉴스 개수 (기본 4)
     * @param symbol 종목 심볼 (선택, 지정시 해당 종목 뉴스만)
     * @return 최신 뉴스 리스트
     */
    @GetMapping("/latest")
    public ResponseEntity<List<Map<String, Object>>> getLatestNews(
            @RequestParam(defaultValue = "4") int limit,
            @RequestParam(required = false) String symbol) {
        
        log.debug("최신 뉴스 조회: {}개, symbol: {}", limit, symbol);
        
        try {
            List<StockNews> newsList;
            
            if (symbol != null && !symbol.isEmpty()) {
                // 특정 종목 뉴스
                newsList = newsService.getNewsBySymbol(symbol, PageRequest.of(0, limit)).getContent();
            } else {
                // 전체 뉴스
                newsList = newsService.getAllNews(PageRequest.of(0, limit)).getContent();
            }
            
            List<Map<String, Object>> result = new ArrayList<>();
            
            for (StockNews news : newsList) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", news.getId());
                item.put("title", news.getTitle());
                item.put("symbol", news.getSymbol());
                item.put("publishedAt", news.getPublishedAt());
                item.put("published_at", news.getPublishedAt());
                result.add(item);
            }
            
            log.info("최신 뉴스: {}개 반환", result.size());
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("최신 뉴스 조회 실패: {}", e.getMessage());
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * 종목별 뉴스 조회
     * 
     * @param symbol 종목 심볼
     * @param limit 가져올 뉴스 개수
     * @return 해당 종목의 최신 뉴스 리스트
     */
    @GetMapping("/symbol/{symbol}")
    public ResponseEntity<List<Map<String, Object>>> getNewsBySymbol(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "10") int limit) {
        
        log.debug("{}의 뉴스 조회: {}개", symbol, limit);
        
        try {
            List<StockNews> newsList = newsService.getNewsBySymbol(symbol, PageRequest.of(0, limit)).getContent();
            
            List<Map<String, Object>> result = new ArrayList<>();
            
            for (StockNews news : newsList) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", news.getId());
                item.put("title", news.getTitle());
                item.put("symbol", news.getSymbol());
                item.put("publishedAt", news.getPublishedAt());
                result.add(item);
            }
            
            log.info("{} 뉴스: {}개 반환", symbol, result.size());
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("{} 뉴스 조회 실패: {}", symbol, e.getMessage());
            return ResponseEntity.ok(Collections.emptyList());
        }
    }
}
