package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.entity.WatchlistGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 워치리스트 그룹 Repository
 */
@Repository
public interface WatchlistGroupRepository extends JpaRepository<WatchlistGroup, Long> {

    /**
     * 사용자의 모든 그룹 조회
     */
    List<WatchlistGroup> findByUserIdOrderByCreatedAtAsc(Long userId);

    /**
     * 사용자의 특정 그룹 조회
     */
    Optional<WatchlistGroup> findByIdAndUserId(Long id, Long userId);

    /**
     * 사용자의 그룹 이름으로 조회
     */
    Optional<WatchlistGroup> findByUserIdAndName(Long userId, String name);

    /**
     * 사용자의 그룹 개수
     */
    long countByUserId(Long userId);
}
