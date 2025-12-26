package com.weenie_hut_jr.the_salty_spitoon.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 재무 지표 엔티티 (Financial Metrics)
 * 
 * 역할:
 * - 핵심 재무 비율 및 지표 저장
 * - 수익성, 성장성, 재무 건전성, 밸류에이션 지표
 * - ticker.info에서 추출한 동적 데이터
 * 
 * 데이터베이스:
 * - 테이블명: financial_metrics
 * - Primary Key: id (Auto Increment)
 * - Unique Key: symbol (종목당 하나)
 * 
 * 데이터 출처:
 * - yfinance ticker.info
 * 
 * 업데이트 주기:
 * - Python 스크립트 실행 시마다 업데이트
 * - 동적 데이터 (시가총액, P/E 등)
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장
 * - FinancialController: API 응답
 * - detail.jsp: 재무 지표 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "financial_metrics")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinancialMetrics {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10, unique = true)
    private String symbol;

    // 수익성 지표
    @Column(name = "profit_margins", precision = 10, scale = 6)
    private BigDecimal profitMargins;

    @Column(name = "operating_margins", precision = 10, scale = 6)
    private BigDecimal operatingMargins;

    @Column(name = "gross_margins", precision = 10, scale = 6)
    private BigDecimal grossMargins;

    @Column(name = "ebitda_margins", precision = 10, scale = 6)
    private BigDecimal ebitdaMargins;

    @Column(name = "return_on_equity", precision = 10, scale = 6)
    private BigDecimal returnOnEquity;

    @Column(name = "return_on_assets", precision = 10, scale = 6)
    private BigDecimal returnOnAssets;

    // 성장성 지표
    @Column(name = "revenue_growth", precision = 10, scale = 6)
    private BigDecimal revenueGrowth;

    @Column(name = "earnings_growth", precision = 10, scale = 6)
    private BigDecimal earningsGrowth;

    @Column(name = "earnings_quarterly_growth", precision = 10, scale = 6)
    private BigDecimal earningsQuarterlyGrowth;

    // 재무 건전성
    @Column(name = "current_ratio", precision = 10, scale = 4)
    private BigDecimal currentRatio;

    @Column(name = "quick_ratio", precision = 10, scale = 4)
    private BigDecimal quickRatio;

    @Column(name = "debt_to_equity", precision = 10, scale = 4)
    private BigDecimal debtToEquity;

    @Column(name = "total_debt", precision = 20, scale = 2)
    private BigDecimal totalDebt;

    @Column(name = "total_cash", precision = 20, scale = 2)
    private BigDecimal totalCash;

    // 밸류에이션
    @Column(name = "trailing_pe", precision = 10, scale = 4)
    private BigDecimal trailingPe;

    @Column(name = "forward_pe", precision = 10, scale = 4)
    private BigDecimal forwardPe;

    @Column(name = "peg_ratio", precision = 10, scale = 4)
    private BigDecimal pegRatio;

    @Column(name = "price_to_book", precision = 10, scale = 4)
    private BigDecimal priceToBook;

    @Column(name = "price_to_sales_trailing_12_months", precision = 10, scale = 4)
    private BigDecimal priceToSalesTrailing12Months;

    @Column(name = "enterprise_value", precision = 20, scale = 2)
    private BigDecimal enterpriseValue;

    @Column(name = "enterprise_to_revenue", precision = 10, scale = 4)
    private BigDecimal enterpriseToRevenue;

    @Column(name = "enterprise_to_ebitda", precision = 10, scale = 4)
    private BigDecimal enterpriseToEbitda;

    // EPS
    @Column(name = "trailing_eps", precision = 10, scale = 4)
    private BigDecimal trailingEps;

    @Column(name = "forward_eps", precision = 10, scale = 4)
    private BigDecimal forwardEps;

    // 배당
    @Column(name = "dividend_rate", precision = 10, scale = 4)
    private BigDecimal dividendRate;

    @Column(name = "dividend_yield", precision = 10, scale = 6)
    private BigDecimal dividendYield;

    @Column(name = "payout_ratio", precision = 10, scale = 6)
    private BigDecimal payoutRatio;

    // 시장 데이터
    @Column(name = "market_cap", precision = 20, scale = 2)
    private BigDecimal marketCap;

    @Column(name = "shares_outstanding")
    private Long sharesOutstanding;

    @Column(name = "float_shares")
    private Long floatShares;

    @Column(name = "shares_short")
    private Long sharesShort;

    @Column(name = "short_ratio", precision = 10, scale = 4)
    private BigDecimal shortRatio;

    @Column(precision = 10, scale = 4)
    private BigDecimal beta;

    // 52주 가격
    @Column(name = "fifty_two_week_high", precision = 15, scale = 4)
    private BigDecimal fiftyTwoWeekHigh;

    @Column(name = "fifty_two_week_low", precision = 15, scale = 4)
    private BigDecimal fiftyTwoWeekLow;

    @Column(name = "fifty_day_average", precision = 15, scale = 4)
    private BigDecimal fiftyDayAverage;

    @Column(name = "two_hundred_day_average", precision = 15, scale = 4)
    private BigDecimal twoHundredDayAverage;

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