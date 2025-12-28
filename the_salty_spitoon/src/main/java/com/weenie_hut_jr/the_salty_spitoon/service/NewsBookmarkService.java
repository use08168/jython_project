package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.entity.UserNewsBookmark;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import com.weenie_hut_jr.the_salty_spitoon.repository.UserNewsBookmarkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 뉴스 북마크 서비스
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NewsBookmarkService {

    private final UserNewsBookmarkRepository bookmarkRepository;
    private final StockNewsRepository newsRepository;

    /**
     * 뉴스 북마크 추가
     */
    @Transactional
    public UserNewsBookmark addBookmark(Long userId, Long newsId) {
        // 이미 존재하는지 확인
        if (bookmarkRepository.existsByUserIdAndNewsId(userId, newsId)) {
            throw new RuntimeException("이미 북마크된 뉴스입니다.");
        }

        StockNews news = newsRepository.findById(newsId)
                .orElseThrow(() -> new RuntimeException("존재하지 않는 뉴스입니다."));

        UserNewsBookmark bookmark = UserNewsBookmark.builder()
                .userId(userId)
                .news(news)
                .build();

        UserNewsBookmark saved = bookmarkRepository.save(bookmark);
        log.info("뉴스 북마크 추가: userId={}, newsId={}", userId, newsId);
        return saved;
    }

    /**
     * 뉴스 북마크 제거
     */
    @Transactional
    public void removeBookmark(Long userId, Long newsId) {
        UserNewsBookmark bookmark = bookmarkRepository.findByUserIdAndNewsId(userId, newsId)
                .orElseThrow(() -> new RuntimeException("북마크되지 않은 뉴스입니다."));

        bookmarkRepository.delete(bookmark);
        log.info("뉴스 북마크 제거: userId={}, newsId={}", userId, newsId);
    }

    /**
     * 뉴스 북마크 토글
     */
    @Transactional
    public boolean toggleBookmark(Long userId, Long newsId) {
        Optional<UserNewsBookmark> existing = bookmarkRepository.findByUserIdAndNewsId(userId, newsId);

        if (existing.isPresent()) {
            bookmarkRepository.delete(existing.get());
            log.info("뉴스 북마크 제거 (토글): userId={}, newsId={}", userId, newsId);
            return false;
        } else {
            StockNews news = newsRepository.findById(newsId)
                    .orElseThrow(() -> new RuntimeException("존재하지 않는 뉴스입니다."));

            UserNewsBookmark bookmark = UserNewsBookmark.builder()
                    .userId(userId)
                    .news(news)
                    .build();
            bookmarkRepository.save(bookmark);
            log.info("뉴스 북마크 추가 (토글): userId={}, newsId={}", userId, newsId);
            return true;
        }
    }

    /**
     * 뉴스 북마크 여부 확인
     */
    public boolean isBookmarked(Long userId, Long newsId) {
        return bookmarkRepository.existsByUserIdAndNewsId(userId, newsId);
    }

    /**
     * 사용자의 북마크 목록 조회 (페이지네이션)
     */
    public Page<UserNewsBookmark> getBookmarks(Long userId, Pageable pageable) {
        return bookmarkRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }

    /**
     * 사용자의 모든 북마크 조회
     */
    public List<UserNewsBookmark> getAllBookmarks(Long userId) {
        return bookmarkRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /**
     * 사용자의 북마크된 뉴스 ID 목록
     */
    public List<Long> getBookmarkedNewsIds(Long userId) {
        return bookmarkRepository.findNewsIdsByUserId(userId);
    }

    /**
     * 사용자의 북마크 개수
     */
    public long getBookmarkCount(Long userId) {
        return bookmarkRepository.countByUserId(userId);
    }
}
