package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.entity.UserWatchlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 사용자 워치리스트 Repository
 */
@Repository
public interface UserWatchlistRepository extends JpaRepository<UserWatchlist, Long> {

    /**
     * 사용자의 모든 워치리스트 조회
     */
    List<UserWatchlist> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * 사용자의 특정 그룹 워치리스트 조회
     */
    List<UserWatchlist> findByUserIdAndGroupIdOrderByCreatedAtDesc(Long userId, Long groupId);

    /**
     * 사용자의 그룹 미지정 워치리스트 조회
     */
    List<UserWatchlist> findByUserIdAndGroupIsNullOrderByCreatedAtDesc(Long userId);

    /**
     * 사용자의 특정 종목 조회
     */
    Optional<UserWatchlist> findByUserIdAndSymbol(Long userId, String symbol);

    /**
     * 종목 존재 여부 확인
     */
    boolean existsByUserIdAndSymbol(Long userId, String symbol);

    /**
     * 사용자의 워치리스트 개수
     */
    long countByUserId(Long userId);

    /**
     * 사용자의 특정 그룹 워치리스트 개수
     */
    long countByUserIdAndGroupId(Long userId, Long groupId);

    /**
     * 사용자의 워치리스트 심볼 목록만 조회
     */
    @Query("SELECT w.symbol FROM UserWatchlist w WHERE w.userId = :userId")
    List<String> findSymbolsByUserId(@Param("userId") Long userId);
}
