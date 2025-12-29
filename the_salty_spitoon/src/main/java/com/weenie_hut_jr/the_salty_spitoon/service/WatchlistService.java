package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.entity.UserWatchlist;
import com.weenie_hut_jr.the_salty_spitoon.entity.WatchlistGroup;
import com.weenie_hut_jr.the_salty_spitoon.repository.UserWatchlistRepository;
import com.weenie_hut_jr.the_salty_spitoon.repository.WatchlistGroupRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 워치리스트 서비스
 * 
 * 그룹 로직:
 * - 좋아요만 누르면: Ungrouped (group_id = NULL)
 * - 그룹에 추가하면: 해당 그룹에 row 추가, Ungrouped row 삭제
 * - 모든 그룹에서 제거하면: Ungrouped row 추가
 * - All: 모든 종목 (DISTINCT symbol)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WatchlistService {

    private final UserWatchlistRepository watchlistRepository;
    private final WatchlistGroupRepository groupRepository;

    // ========================================
    // 워치리스트 (종목 좋아요)
    // ========================================

    /**
     * 종목 좋아요 토글 (Ungrouped로 추가/완전 삭제)
     */
    @Transactional
    public boolean toggleWatchlist(Long userId, String symbol) {
        symbol = symbol.toUpperCase();
        
        // 이미 워치리스트에 있는지 확인 (그룹 무관)
        boolean exists = watchlistRepository.existsByUserIdAndSymbol(userId, symbol);

        if (exists) {
            // 모든 row 삭제 (All에서 완전히 제거)
            watchlistRepository.deleteByUserIdAndSymbol(userId, symbol);
            log.info("워치리스트 완전 제거: userId={}, symbol={}", userId, symbol);
            return false;
        } else {
            // Ungrouped로 추가
            UserWatchlist watchlist = UserWatchlist.builder()
                    .userId(userId)
                    .symbol(symbol)
                    .group(null)
                    .build();
            watchlistRepository.save(watchlist);
            log.info("워치리스트 추가 (Ungrouped): userId={}, symbol={}", userId, symbol);
            return true;
        }
    }

    /**
     * 종목을 그룹에 추가
     */
    @Transactional
    public void addToGroup(Long userId, String symbol, Long groupId) {
        symbol = symbol.toUpperCase();
        
        // 그룹 존재 확인
        WatchlistGroup group = groupRepository.findByIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("존재하지 않는 그룹입니다."));

        // 이미 해당 그룹에 있는지 확인
        if (watchlistRepository.existsByUserIdAndSymbolAndGroupId(userId, symbol, groupId)) {
            log.info("이미 그룹에 존재: userId={}, symbol={}, groupId={}", userId, symbol, groupId);
            return;
        }

        // 워치리스트에 없으면 먼저 추가
        if (!watchlistRepository.existsByUserIdAndSymbol(userId, symbol)) {
            throw new RuntimeException("먼저 종목을 좋아요 해주세요.");
        }

        // Ungrouped row 삭제 (있으면)
        watchlistRepository.findByUserIdAndSymbolAndGroupIsNull(userId, symbol)
                .ifPresent(watchlistRepository::delete);

        // 그룹에 추가
        UserWatchlist watchlist = UserWatchlist.builder()
                .userId(userId)
                .symbol(symbol)
                .group(group)
                .build();
        watchlistRepository.save(watchlist);
        
        log.info("그룹에 추가: userId={}, symbol={}, groupId={}", userId, symbol, groupId);
    }

    /**
     * 종목을 그룹에서 제거
     */
    @Transactional
    public void removeFromGroup(Long userId, String symbol, Long groupId) {
        symbol = symbol.toUpperCase();
        
        // 해당 그룹에서 삭제
        UserWatchlist watchlist = watchlistRepository.findByUserIdAndSymbolAndGroupId(userId, symbol, groupId)
                .orElseThrow(() -> new RuntimeException("그룹에 없는 종목입니다."));
        watchlistRepository.delete(watchlist);

        // 더 이상 어떤 그룹에도 속하지 않으면 Ungrouped로 추가
        if (!watchlistRepository.existsInAnyGroup(userId, symbol)) {
            UserWatchlist ungrouped = UserWatchlist.builder()
                    .userId(userId)
                    .symbol(symbol)
                    .group(null)
                    .build();
            watchlistRepository.save(ungrouped);
            log.info("그룹에서 제거 → Ungrouped로 이동: userId={}, symbol={}", userId, symbol);
        } else {
            log.info("그룹에서 제거: userId={}, symbol={}, groupId={}", userId, symbol, groupId);
        }
    }

    /**
     * 종목이 특정 그룹에 속해있는지 확인
     */
    public boolean isInGroup(Long userId, String symbol, Long groupId) {
        return watchlistRepository.existsByUserIdAndSymbolAndGroupId(userId, symbol, groupId);
    }

    /**
     * 종목의 그룹 ID 목록 조회
     */
    public List<Long> getGroupIds(Long userId, String symbol) {
        return watchlistRepository.findGroupIdsByUserIdAndSymbol(userId, symbol.toUpperCase());
    }

    /**
     * 종목 좋아요 여부 확인
     */
    public boolean isInWatchlist(Long userId, String symbol) {
        return watchlistRepository.existsByUserIdAndSymbol(userId, symbol.toUpperCase());
    }

    /**
     * 사용자의 전체 워치리스트 조회 (All - 중복 제거)
     */
    public List<UserWatchlist> getWatchlist(Long userId) {
        return watchlistRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /**
     * 사용자의 전체 워치리스트 조회 (All - 중복 제거된 심볼 목록)
     */
    public List<String> getDistinctSymbols(Long userId) {
        return watchlistRepository.findDistinctSymbolsByUserId(userId);
    }

    /**
     * 사용자의 그룹별 워치리스트 조회
     */
    public List<UserWatchlist> getWatchlistByGroup(Long userId, Long groupId) {
        if (groupId == null) {
            return watchlistRepository.findByUserIdAndGroupIsNullOrderByCreatedAtDesc(userId);
        }
        return watchlistRepository.findByUserIdAndGroupIdOrderByCreatedAtDesc(userId, groupId);
    }

    /**
     * 사용자의 워치리스트 심볼 목록 (중복 제거)
     */
    public List<String> getWatchlistSymbols(Long userId) {
        return watchlistRepository.findDistinctSymbolsByUserId(userId);
    }

    /**
     * 종목의 그룹 변경 (레거시 - 단일 그룹 이동용)
     */
    @Transactional
    public void updateWatchlistGroup(Long userId, String symbol, Long groupId) {
        symbol = symbol.toUpperCase();
        
        // 기존 모든 그룹 연결 삭제
        List<UserWatchlist> existing = watchlistRepository.findByUserIdAndSymbol(userId, symbol);
        watchlistRepository.deleteAll(existing);

        if (groupId == null) {
            // Ungrouped로 이동
            UserWatchlist ungrouped = UserWatchlist.builder()
                    .userId(userId)
                    .symbol(symbol)
                    .group(null)
                    .build();
            watchlistRepository.save(ungrouped);
        } else {
            // 특정 그룹으로 이동
            WatchlistGroup group = groupRepository.findByIdAndUserId(groupId, userId)
                    .orElseThrow(() -> new RuntimeException("존재하지 않는 그룹입니다."));
            UserWatchlist watchlist = UserWatchlist.builder()
                    .userId(userId)
                    .symbol(symbol)
                    .group(group)
                    .build();
            watchlistRepository.save(watchlist);
        }

        log.info("워치리스트 그룹 변경: userId={}, symbol={}, groupId={}", userId, symbol, groupId);
    }

    // ========================================
    // 그룹 관리
    // ========================================

    /**
     * 그룹 생성
     */
    @Transactional
    public WatchlistGroup createGroup(Long userId, String name, String color) {
        // 중복 이름 확인
        if (groupRepository.findByUserIdAndName(userId, name).isPresent()) {
            throw new RuntimeException("이미 존재하는 그룹 이름입니다.");
        }

        WatchlistGroup group = WatchlistGroup.builder()
                .userId(userId)
                .name(name)
                .color(color != null ? color : "#3b82f6")
                .build();

        WatchlistGroup saved = groupRepository.save(group);
        log.info("그룹 생성: userId={}, name={}", userId, name);
        return saved;
    }

    /**
     * 그룹 수정
     */
    @Transactional
    public WatchlistGroup updateGroup(Long userId, Long groupId, String name, String color) {
        WatchlistGroup group = groupRepository.findByIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("존재하지 않는 그룹입니다."));

        // 이름 변경 시 중복 확인
        if (name != null && !name.equals(group.getName())) {
            if (groupRepository.findByUserIdAndName(userId, name).isPresent()) {
                throw new RuntimeException("이미 존재하는 그룹 이름입니다.");
            }
            group.setName(name);
        }

        if (color != null) {
            group.setColor(color);
        }

        WatchlistGroup saved = groupRepository.save(group);
        log.info("그룹 수정: userId={}, groupId={}", userId, groupId);
        return saved;
    }

    /**
     * 그룹 삭제
     */
    @Transactional
    public void deleteGroup(Long userId, Long groupId) {
        WatchlistGroup group = groupRepository.findByIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("존재하지 않는 그룹입니다."));

        // 그룹에 속한 종목들 처리
        List<UserWatchlist> items = watchlistRepository.findByUserIdAndGroupIdOrderByCreatedAtDesc(userId, groupId);
        for (UserWatchlist item : items) {
            String symbol = item.getSymbol();
            watchlistRepository.delete(item);
            
            // 다른 그룹에도 속하지 않으면 Ungrouped로
            if (!watchlistRepository.existsInAnyGroup(userId, symbol)) {
                // 이미 Ungrouped가 없다면 추가
                if (!watchlistRepository.findByUserIdAndSymbolAndGroupIsNull(userId, symbol).isPresent()) {
                    UserWatchlist ungrouped = UserWatchlist.builder()
                            .userId(userId)
                            .symbol(symbol)
                            .group(null)
                            .build();
                    watchlistRepository.save(ungrouped);
                }
            }
        }

        groupRepository.delete(group);
        log.info("그룹 삭제: userId={}, groupId={}", userId, groupId);
    }

    /**
     * 사용자의 모든 그룹 조회
     */
    public List<WatchlistGroup> getGroups(Long userId) {
        return groupRepository.findByUserIdOrderByCreatedAtAsc(userId);
    }

    /**
     * 특정 그룹 조회
     */
    public Optional<WatchlistGroup> getGroup(Long userId, Long groupId) {
        return groupRepository.findByIdAndUserId(groupId, userId);
    }

    /**
     * All 카운트 (중복 제거된 종목 수)
     */
    public long countAll(Long userId) {
        return watchlistRepository.countDistinctSymbolByUserId(userId);
    }

    /**
     * Ungrouped 카운트
     */
    public long countUngrouped(Long userId) {
        return watchlistRepository.countByUserIdAndGroupIsNull(userId);
    }

    /**
     * 그룹별 카운트
     */
    public long countByGroup(Long userId, Long groupId) {
        return watchlistRepository.countByUserIdAndGroupId(userId, groupId);
    }
}
