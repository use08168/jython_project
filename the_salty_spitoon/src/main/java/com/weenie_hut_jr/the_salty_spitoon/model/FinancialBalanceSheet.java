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
 * 대차대조표 엔티티 (Balance Sheet)
 * 
 * 역할:
 * - 재무상태표 데이터 저장
 * - 자산, 부채, 자본 현황 추적
 * - 재무 건전성 분석 기반 데이터
 * 
 * 데이터베이스:
 * - 테이블명: financial_balance_sheet
 * - Primary Key: id (Auto Increment)
 * - Unique Key: (symbol, fiscal_date, period_type)
 * 
 * 데이터 출처:
 * - yfinance ticker.balance_sheet (연간)
 * - yfinance ticker.quarterly_balance_sheet (분기)
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "financial_balance_sheet")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinancialBalanceSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String symbol;

    @Column(name = "fiscal_date", nullable = false)
    private LocalDate fiscalDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", nullable = false)
    private FinancialIncomeStatement.PeriodType periodType;

    // 자산 (Assets)
    @Column(name = "total_assets", precision = 20, scale = 2)
    private BigDecimal totalAssets;

    @Column(name = "current_assets", precision = 20, scale = 2)
    private BigDecimal currentAssets;

    @Column(name = "cash_and_cash_equivalents", precision = 20, scale = 2)
    private BigDecimal cashAndCashEquivalents;

    @Column(name = "cash_cash_equivalents_and_short_term_investments", precision = 20, scale = 2)
    private BigDecimal cashCashEquivalentsAndShortTermInvestments;

    @Column(precision = 20, scale = 2)
    private BigDecimal receivables;

    @Column(precision = 20, scale = 2)
    private BigDecimal inventory;

    @Column(name = "other_current_assets", precision = 20, scale = 2)
    private BigDecimal otherCurrentAssets;

    // 비유동 자산
    @Column(name = "net_ppe", precision = 20, scale = 2)
    private BigDecimal netPpe;

    @Column(name = "gross_ppe", precision = 20, scale = 2)
    private BigDecimal grossPpe;

    @Column(precision = 20, scale = 2)
    private BigDecimal goodwill;

    @Column(name = "intangible_assets", precision = 20, scale = 2)
    private BigDecimal intangibleAssets;

    @Column(name = "investments_and_advances", precision = 20, scale = 2)
    private BigDecimal investmentsAndAdvances;

    @Column(name = "other_non_current_assets", precision = 20, scale = 2)
    private BigDecimal otherNonCurrentAssets;

    // 부채 (Liabilities)
    @Column(name = "total_liabilities_net_minority_interest", precision = 20, scale = 2)
    private BigDecimal totalLiabilitiesNetMinorityInterest;

    @Column(name = "current_liabilities", precision = 20, scale = 2)
    private BigDecimal currentLiabilities;

    @Column(name = "payables_and_accrued_expenses", precision = 20, scale = 2)
    private BigDecimal payablesAndAccruedExpenses;

    @Column(name = "current_debt", precision = 20, scale = 2)
    private BigDecimal currentDebt;

    @Column(name = "other_current_liabilities", precision = 20, scale = 2)
    private BigDecimal otherCurrentLiabilities;

    // 비유동 부채
    @Column(name = "long_term_debt", precision = 20, scale = 2)
    private BigDecimal longTermDebt;

    @Column(name = "other_non_current_liabilities", precision = 20, scale = 2)
    private BigDecimal otherNonCurrentLiabilities;

    @Column(name = "total_debt", precision = 20, scale = 2)
    private BigDecimal totalDebt;

    // 자본 (Equity)
    @Column(name = "stockholders_equity", precision = 20, scale = 2)
    private BigDecimal stockholdersEquity;

    @Column(name = "common_stock", precision = 20, scale = 2)
    private BigDecimal commonStock;

    @Column(name = "retained_earnings", precision = 20, scale = 2)
    private BigDecimal retainedEarnings;

    @Column(name = "treasury_stock", precision = 20, scale = 2)
    private BigDecimal treasuryStock;

    @Column(name = "capital_stock", precision = 20, scale = 2)
    private BigDecimal capitalStock;

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