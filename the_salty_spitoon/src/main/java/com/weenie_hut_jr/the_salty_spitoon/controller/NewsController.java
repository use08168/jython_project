package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

/**
 * 뉴스 페이지 Controller
 */
@Slf4j
@Controller
@RequestMapping("/news")
@RequiredArgsConstructor
public class NewsController {

    private final NewsService newsService;

    /**
     * 뉴스 목록 페이지
     * 
     * URL: http://localhost:8080/news
     * URL: http://localhost:8080/news?page=0&size=20
     * URL: http://localhost:8080/news?symbol=AAPL
     */
    @GetMapping
    public String newsList(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String symbol,
            Model model) {

        log.info("뉴스 목록 페이지 요청 - page: {}, size: {}, symbol: {}", page, size, symbol);

        Pageable pageable = PageRequest.of(page, size);
        Page<StockNews> newsPage;

        // 종목별 필터링
        if (symbol != null && !symbol.isEmpty()) {
            newsPage = newsService.getNewsBySymbol(symbol, pageable);
            model.addAttribute("selectedSymbol", symbol);
            log.info("종목별 뉴스 조회: {} - {}개", symbol, newsPage.getTotalElements());
        } else {
            newsPage = newsService.getAllNews(pageable);
            log.info("전체 뉴스 조회: {}개", newsPage.getTotalElements());
        }

        // 모델에 데이터 추가
        model.addAttribute("newsPage", newsPage);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", newsPage.getTotalPages());
        model.addAttribute("totalNews", newsPage.getTotalElements());

        // 주요 종목 리스트 (필터용)
        String[] symbols = { "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX" };
        model.addAttribute("symbols", symbols);

        return "news";
    }

    /**
     * 뉴스 상세 페이지
     * 
     * URL: http://localhost:8080/news/detail/1
     */
    @GetMapping("/detail/{id}")
    public String newsDetail(@PathVariable Long id, Model model) {
        log.info("뉴스 상세 페이지 요청 - ID: {}", id);

        try {
            // 뉴스 조회 + 디코딩
            Map<String, Object> newsDetail = newsService.getNewsDetailById(id);

            if (newsDetail == null) {
                log.warn("⚠️  뉴스를 찾을 수 없음 - ID: {}", id);
                model.addAttribute("error", "뉴스를 찾을 수 없습니다.");
                return "error/404";
            }

            // 모델에 데이터 추가
            model.addAttribute("news", newsDetail);

            log.info("✅ 뉴스 상세 조회 성공 - 제목: {}", newsDetail.get("title"));

            return "newsDetail";

        } catch (Exception e) {
            log.error("❌ 뉴스 상세 조회 실패 - ID: {}", id, e);
            model.addAttribute("error", "뉴스를 불러오는 중 오류가 발생했습니다.");
            return "error/500";
        }
    }

    /**
     * 제목 검색
     * 
     * URL: http://localhost:8080/news/search?keyword=AI
     */
    @GetMapping("/search")
    public String searchNews(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Model model) {

        log.info("뉴스 검색 - 키워드: {}, page: {}", keyword, page);

        Pageable pageable = PageRequest.of(page, size);
        Page<StockNews> newsPage = newsService.searchNewsByTitle(keyword, pageable);

        model.addAttribute("newsPage", newsPage);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", newsPage.getTotalPages());
        model.addAttribute("totalNews", newsPage.getTotalElements());
        model.addAttribute("keyword", keyword);

        log.info("검색 결과: {}개", newsPage.getTotalElements());

        return "news";
    }
}