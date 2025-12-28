package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.entity.User;
import com.weenie_hut_jr.the_salty_spitoon.entity.UserNewsBookmark;
import com.weenie_hut_jr.the_salty_spitoon.repository.UserRepository;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsBookmarkService;
import com.weenie_hut_jr.the_salty_spitoon.service.NewsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
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
    private final NewsBookmarkService bookmarkService;
    private final UserRepository userRepository;

    /**
     * 사용자 ID 조회 헬퍼
     */
    private Long getUserId(UserDetails userDetails) {
        if (userDetails == null) {
            return null;
        }
        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElse(null);
        return user != null ? user.getId() : null;
    }

    // ========================================
    // 페이지
    // ========================================

    /**
     * 뉴스 목록 페이지
     */
    @GetMapping
    public String newsList(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String symbol,
            @AuthenticationPrincipal UserDetails userDetails,
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

        // DB에서 실제 존재하는 symbol 목록 조회
        List<String> symbols = newsService.getDistinctSymbols();
        model.addAttribute("symbols", symbols);

        // 북마크된 뉴스 ID 목록
        Long userId = getUserId(userDetails);
        if (userId != null) {
            List<Long> bookmarkedIds = bookmarkService.getBookmarkedNewsIds(userId);
            model.addAttribute("bookmarkedIds", bookmarkedIds);
        }

        return "news";
    }

    /**
     * 뉴스 상세 페이지
     */
    @GetMapping("/detail/{id}")
    public String newsDetail(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails,
            Model model) {

        log.info("뉴스 상세 페이지 요청 - ID: {}", id);

        try {
            // 뉴스 조회 + 디코딩
            Map<String, Object> newsDetail = newsService.getNewsDetailById(id);

            if (newsDetail == null) {
                log.warn("뉴스를 찾을 수 없음 - ID: {}", id);
                model.addAttribute("error", "뉴스를 찾을 수 없습니다.");
                return "error/404";
            }

            // 모델에 데이터 추가
            model.addAttribute("news", newsDetail);

            // 주가 변동률 계산
            String symbol = (String) newsDetail.get("symbol");
            java.time.LocalDateTime publishedAt = (java.time.LocalDateTime) newsDetail.get("publishedAt");
            Map<String, Object> priceChange = newsService.calculatePriceChange(symbol, publishedAt);
            model.addAttribute("priceChange", priceChange);

            // 북마크 여부
            Long userId = getUserId(userDetails);
            if (userId != null) {
                boolean isBookmarked = bookmarkService.isBookmarked(userId, id);
                model.addAttribute("isBookmarked", isBookmarked);
            }

            log.info("뉴스 상세 조회 성공 - 제목: {}", newsDetail.get("title"));

            return "newsDetail";

        } catch (Exception e) {
            log.error("뉴스 상세 조회 실패 - ID: {}", id, e);
            model.addAttribute("error", "뉴스를 불러오는 중 오류가 발생했습니다.");
            return "error/500";
        }
    }

    /**
     * 저장된 뉴스 페이지
     */
    @GetMapping("/saved")
    public String savedNews(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserDetails userDetails,
            Model model) {

        Long userId = getUserId(userDetails);
        if (userId == null) {
            return "redirect:/login";
        }

        log.info("저장된 뉴스 페이지 요청 - userId: {}", userId);

        Pageable pageable = PageRequest.of(page, size);
        Page<UserNewsBookmark> bookmarks = bookmarkService.getBookmarks(userId, pageable);

        model.addAttribute("bookmarks", bookmarks);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", bookmarks.getTotalPages());
        model.addAttribute("totalBookmarks", bookmarks.getTotalElements());

        return "newsSaved";
    }

    /**
     * 제목 검색
     */
    @GetMapping("/search")
    public String searchNews(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserDetails userDetails,
            Model model) {

        log.info("뉴스 검색 - 키워드: {}, page: {}", keyword, page);

        Pageable pageable = PageRequest.of(page, size);
        Page<StockNews> newsPage = newsService.searchNewsByTitle(keyword, pageable);

        model.addAttribute("newsPage", newsPage);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", newsPage.getTotalPages());
        model.addAttribute("totalNews", newsPage.getTotalElements());
        model.addAttribute("keyword", keyword);

        // 북마크된 뉴스 ID 목록
        Long userId = getUserId(userDetails);
        if (userId != null) {
            List<Long> bookmarkedIds = bookmarkService.getBookmarkedNewsIds(userId);
            model.addAttribute("bookmarkedIds", bookmarkedIds);
        }

        log.info("검색 결과: {}개", newsPage.getTotalElements());

        return "news";
    }

    // ========================================
    // 북마크 API
    // ========================================

    /**
     * 뉴스 북마크 토글
     */
    @PostMapping("/api/bookmark/toggle")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> toggleBookmark(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, Long> request) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            Long newsId = request.get("newsId");
            if (newsId == null) {
                response.put("success", false);
                response.put("message", "뉴스 ID가 필요합니다.");
                return ResponseEntity.badRequest().body(response);
            }

            boolean isBookmarked = bookmarkService.toggleBookmark(userId, newsId);

            response.put("success", true);
            response.put("isBookmarked", isBookmarked);
            response.put("message", isBookmarked ? "북마크에 추가되었습니다." : "북마크에서 제거되었습니다.");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("북마크 토글 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 북마크 여부 확인
     */
    @GetMapping("/api/bookmark/check/{newsId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> checkBookmark(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long newsId) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("isBookmarked", false);
                return ResponseEntity.ok(response);
            }

            boolean isBookmarked = bookmarkService.isBookmarked(userId, newsId);
            response.put("isBookmarked", isBookmarked);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("북마크 확인 실패", e);
            response.put("isBookmarked", false);
            return ResponseEntity.ok(response);
        }
    }
}
