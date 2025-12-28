package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.entity.UserNewsBookmark;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 사용자 뉴스 북마크 Repository
 */
@Repository
public interface UserNewsBookmarkRepository extends JpaRepository<UserNewsBookmark, Long> {

    /**
     * 사용자의 모든 북마크 조회 (페이지네이션)
     */
    Page<UserNewsBookmark> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    /**
     * 사용자의 모든 북마크 조회
     */
    List<UserNewsBookmark> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * 사용자의 특정 뉴스 북마크 조회
     */
    Optional<UserNewsBookmark> findByUserIdAndNewsId(Long userId, Long newsId);

    /**
     * 북마크 존재 여부 확인
     */
    boolean existsByUserIdAndNewsId(Long userId, Long newsId);

    /**
     * 사용자의 북마크 개수
     */
    long countByUserId(Long userId);

    /**
     * 사용자의 북마크된 뉴스 ID 목록
     */
    @Query("SELECT b.news.id FROM UserNewsBookmark b WHERE b.userId = :userId")
    List<Long> findNewsIdsByUserId(@Param("userId") Long userId);
}
