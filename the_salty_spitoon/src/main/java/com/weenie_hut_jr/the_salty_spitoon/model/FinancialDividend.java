package com.weenie_hut_jr.the_salty_spitoon.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 배당금 엔티티 (Financial Dividend)
 * 
 * 역할:
 * - 배당금 지급 이력 저장
 * - 과거 배당 데이터 추적
 * - 배당 분석 기반 데이터
 * 
 * 데이터베이스:
 * - 테이블명: financial_dividends
 * - Primary Key: id (Auto Increment)
 * - Unique Key: (symbol, payment_date)
 * 
 * 데이터 출처:
 * - yfinance ticker.dividends
 * 
 * 데이터 범위:
 * - 최근 5년 배당 이력
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장
 * - FinancialController: API 응답
 * - detail.jsp: 배당 정보 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "financial_dividends")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinancialDividend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String symbol;

    @Column(name = "payment_date", nullable = false)
    private LocalDate paymentDate;

    @Column(name = "dividend_amount", nullable = false, precision = 10, scale = 4)
    private BigDecimal dividendAmount;

    // 메타데이터
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}