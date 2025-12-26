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
 * 현금흐름표 엔티티 (Cash Flow Statement)
 * 
 * 역할:
 * - 현금흐름 데이터 저장
 * - 영업/투자/재무 활동 현금흐름 추적
 * - 잉여현금흐름 분석
 * 
 * 데이터베이스:
 * - 테이블명: financial_cashflow
 * - Primary Key: id (Auto Increment)
 * - Unique Key: (symbol, fiscal_date, period_type)
 * 
 * 데이터 출처:
 * - yfinance ticker.cashflow (연간)
 * - yfinance ticker.quarterly_cashflow (분기)
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "financial_cashflow")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinancialCashflow {

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

    // 영업활동 현금흐름
    @Column(name = "operating_cash_flow", precision = 20, scale = 2)
    private BigDecimal operatingCashFlow;

    @Column(name = "cash_flow_from_continuing_operating_activities", precision = 20, scale = 2)
    private BigDecimal cashFlowFromContinuingOperatingActivities;

    @Column(name = "net_income_from_continuing_operations", precision = 20, scale = 2)
    private BigDecimal netIncomeFromContinuingOperations;

    @Column(name = "depreciation_and_amortization", precision = 20, scale = 2)
    private BigDecimal depreciationAndAmortization;

    @Column(name = "deferred_income_tax", precision = 20, scale = 2)
    private BigDecimal deferredIncomeTax;

    @Column(name = "stock_based_compensation", precision = 20, scale = 2)
    private BigDecimal stockBasedCompensation;

    @Column(name = "change_in_working_capital", precision = 20, scale = 2)
    private BigDecimal changeInWorkingCapital;

    @Column(name = "change_in_receivables", precision = 20, scale = 2)
    private BigDecimal changeInReceivables;

    @Column(name = "change_in_inventory", precision = 20, scale = 2)
    private BigDecimal changeInInventory;

    @Column(name = "change_in_payables", precision = 20, scale = 2)
    private BigDecimal changeInPayables;

    // 투자활동 현금흐름
    @Column(name = "investing_cash_flow", precision = 20, scale = 2)
    private BigDecimal investingCashFlow;

    @Column(name = "capital_expenditure", precision = 20, scale = 2)
    private BigDecimal capitalExpenditure;

    @Column(name = "net_ppe_purchase_and_sale", precision = 20, scale = 2)
    private BigDecimal netPpePurchaseAndSale;

    @Column(name = "net_investment_purchase_and_sale", precision = 20, scale = 2)
    private BigDecimal netInvestmentPurchaseAndSale;

    @Column(name = "net_business_purchase_and_sale", precision = 20, scale = 2)
    private BigDecimal netBusinessPurchaseAndSale;

    // 재무활동 현금흐름
    @Column(name = "financing_cash_flow", precision = 20, scale = 2)
    private BigDecimal financingCashFlow;

    @Column(name = "cash_dividends_paid", precision = 20, scale = 2)
    private BigDecimal cashDividendsPaid;

    @Column(name = "common_stock_issuance", precision = 20, scale = 2)
    private BigDecimal commonStockIssuance;

    @Column(name = "common_stock_payments", precision = 20, scale = 2)
    private BigDecimal commonStockPayments;

    @Column(name = "net_common_stock_issuance", precision = 20, scale = 2)
    private BigDecimal netCommonStockIssuance;

    @Column(name = "long_term_debt_issuance", precision = 20, scale = 2)
    private BigDecimal longTermDebtIssuance;

    @Column(name = "long_term_debt_payments", precision = 20, scale = 2)
    private BigDecimal longTermDebtPayments;

    @Column(name = "net_long_term_debt_issuance", precision = 20, scale = 2)
    private BigDecimal netLongTermDebtIssuance;

    // 잉여현금흐름
    @Column(name = "free_cash_flow", precision = 20, scale = 2)
    private BigDecimal freeCashFlow;

    // 현금 변동
    @Column(name = "end_cash_position", precision = 20, scale = 2)
    private BigDecimal endCashPosition;

    @Column(name = "beginning_cash_position", precision = 20, scale = 2)
    private BigDecimal beginningCashPosition;

    @Column(name = "changes_in_cash", precision = 20, scale = 2)
    private BigDecimal changesInCash;

    @Column(name = "effect_of_exchange_rate_changes", precision = 20, scale = 2)
    private BigDecimal effectOfExchangeRateChanges;

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