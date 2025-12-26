package com.weenie_hut_jr.the_salty_spitoon.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 1분봉 캔들 데이터
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-25
 */
@Entity
@Table(name = "stock_candle_1m", indexes = {
        @Index(name = "idx_symbol_timestamp", columnList = "symbol,timestamp", unique = true)
})
@Data // ← Getter, Setter, toString, equals, hashCode 자동 생성
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockCandle1m {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String symbol;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal open;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal high;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal low;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal close;

    @Column(nullable = false)
    private Long volume;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
