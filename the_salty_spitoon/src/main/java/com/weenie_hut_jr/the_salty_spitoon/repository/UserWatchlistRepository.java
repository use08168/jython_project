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
     * 사용자의 그룹 미지정 워치리스트 조회 (Ungrouped)
     */
    List<UserWatchlist> findByUserIdAndGroupIsNullOrderByCreatedAtDesc(Long userId);

    /**
     * 사용자의 특정 종목 조회 (그룹 무관, 첫 번째 것)
     */
    Optional<UserWatchlist> findFirstByUserIdAndSymbol(Long userId, String symbol);

    /**
     * 사용자의 특정 종목의 모든 row 조회
     */
    List<UserWatchlist> findByUserIdAndSymbol(Long userId, String symbol);

    /**
     * 사용자의 특정 종목 + 특정 그룹 조회
     */
    Optional<UserWatchlist> findByUserIdAndSymbolAndGroupId(Long userId, String symbol, Long groupId);

    /**
     * 사용자의 특정 종목 + Ungrouped 조회
     */
    Optional<UserWatchlist> findByUserIdAndSymbolAndGroupIsNull(Long userId, String symbol);

    /**
     * 종목 존재 여부 확인 (그룹 무관)
     */
    boolean existsByUserIdAndSymbol(Long userId, String symbol);

    /**
     * 종목+그룹 존재 여부 확인
     */
    boolean existsByUserIdAndSymbolAndGroupId(Long userId, String symbol, Long groupId);

    /**
     * 사용자의 워치리스트 개수 (그룹 무관, 중복 제거)
     */
    @Query("SELECT COUNT(DISTINCT w.symbol) FROM UserWatchlist w WHERE w.userId = :userId")
    long countDistinctSymbolByUserId(@Param("userId") Long userId);

    /**
     * 사용자의 특정 그룹 워치리스트 개수
     */
    long countByUserIdAndGroupId(Long userId, Long groupId);

    /**
     * 사용자의 Ungrouped 워치리스트 개수
     */
    long countByUserIdAndGroupIsNull(Long userId);

    /**
     * 사용자의 워치리스트 심볼 목록만 조회 (중복 제거)
     */
    @Query("SELECT DISTINCT w.symbol FROM UserWatchlist w WHERE w.userId = :userId")
    List<String> findDistinctSymbolsByUserId(@Param("userId") Long userId);

    /**
     * 특정 종목이 그룹에 속해있는지 확인 (그룹이 있는 row가 있는지)
     */
    @Query("SELECT COUNT(w) > 0 FROM UserWatchlist w WHERE w.userId = :userId AND w.symbol = :symbol AND w.group IS NOT NULL")
    boolean existsInAnyGroup(@Param("userId") Long userId, @Param("symbol") String symbol);

    /**
     * 특정 종목의 그룹 ID 목록 조회
     */
    @Query("SELECT w.group.id FROM UserWatchlist w WHERE w.userId = :userId AND w.symbol = :symbol AND w.group IS NOT NULL")
    List<Long> findGroupIdsByUserIdAndSymbol(@Param("userId") Long userId, @Param("symbol") String symbol);

    /**
     * 사용자의 모든 종목 삭제 (특정 symbol)
     */
    void deleteByUserIdAndSymbol(Long userId, String symbol);
}
