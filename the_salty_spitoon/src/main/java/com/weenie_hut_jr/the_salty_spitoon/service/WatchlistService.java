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
     * 종목 좋아요 추가
     */
    @Transactional
    public UserWatchlist addToWatchlist(Long userId, String symbol) {
        // 이미 존재하는지 확인
        if (watchlistRepository.existsByUserIdAndSymbol(userId, symbol)) {
            throw new RuntimeException("이미 워치리스트에 추가된 종목입니다.");
        }

        UserWatchlist watchlist = UserWatchlist.builder()
                .userId(userId)
                .symbol(symbol.toUpperCase())
                .build();

        UserWatchlist saved = watchlistRepository.save(watchlist);
        log.info("워치리스트 추가: userId={}, symbol={}", userId, symbol);
        return saved;
    }

    /**
     * 종목 좋아요 제거
     */
    @Transactional
    public void removeFromWatchlist(Long userId, String symbol) {
        UserWatchlist watchlist = watchlistRepository.findByUserIdAndSymbol(userId, symbol)
                .orElseThrow(() -> new RuntimeException("워치리스트에 없는 종목입니다."));

        watchlistRepository.delete(watchlist);
        log.info("워치리스트 제거: userId={}, symbol={}", userId, symbol);
    }

    /**
     * 종목 좋아요 토글
     */
    @Transactional
    public boolean toggleWatchlist(Long userId, String symbol) {
        Optional<UserWatchlist> existing = watchlistRepository.findByUserIdAndSymbol(userId, symbol);

        if (existing.isPresent()) {
            watchlistRepository.delete(existing.get());
            log.info("워치리스트 제거 (토글): userId={}, symbol={}", userId, symbol);
            return false;
        } else {
            UserWatchlist watchlist = UserWatchlist.builder()
                    .userId(userId)
                    .symbol(symbol.toUpperCase())
                    .build();
            watchlistRepository.save(watchlist);
            log.info("워치리스트 추가 (토글): userId={}, symbol={}", userId, symbol);
            return true;
        }
    }

    /**
     * 종목 좋아요 여부 확인
     */
    public boolean isInWatchlist(Long userId, String symbol) {
        return watchlistRepository.existsByUserIdAndSymbol(userId, symbol);
    }

    /**
     * 사용자의 전체 워치리스트 조회
     */
    public List<UserWatchlist> getWatchlist(Long userId) {
        return watchlistRepository.findByUserIdOrderByCreatedAtDesc(userId);
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
     * 사용자의 워치리스트 심볼 목록
     */
    public List<String> getWatchlistSymbols(Long userId) {
        return watchlistRepository.findSymbolsByUserId(userId);
    }

    /**
     * 종목의 그룹 변경
     */
    @Transactional
    public void updateWatchlistGroup(Long userId, String symbol, Long groupId) {
        UserWatchlist watchlist = watchlistRepository.findByUserIdAndSymbol(userId, symbol)
                .orElseThrow(() -> new RuntimeException("워치리스트에 없는 종목입니다."));

        if (groupId == null) {
            watchlist.setGroup(null);
        } else {
            WatchlistGroup group = groupRepository.findByIdAndUserId(groupId, userId)
                    .orElseThrow(() -> new RuntimeException("존재하지 않는 그룹입니다."));
            watchlist.setGroup(group);
        }

        watchlistRepository.save(watchlist);
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

        // 그룹에 속한 종목들의 그룹을 null로 변경
        List<UserWatchlist> items = watchlistRepository.findByUserIdAndGroupIdOrderByCreatedAtDesc(userId, groupId);
        for (UserWatchlist item : items) {
            item.setGroup(null);
        }
        watchlistRepository.saveAll(items);

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
}
