package com.weenie_hut_jr.the_salty_spitoon.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * 사용자 워치리스트 (좋아요한 종목) Entity
 * 
 * 한 종목이 여러 그룹에 속할 수 있음
 * - 좋아요만 누르면: group_id = NULL (Ungrouped)
 * - 그룹에 추가하면: 해당 group_id로 row 추가
 */
@Entity
@Table(name = "user_watchlist", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "symbol", "group_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserWatchlist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, length = 10)
    private String symbol;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id")
    private WatchlistGroup group;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
