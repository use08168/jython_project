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
 * 재무제표 엔티티 (Income Statement)
 * 
 * 역할:
 * - 손익계산서 데이터 저장
 * - 분기별/연간 재무 성과 추적
 * - 매출, 이익, 비용 등 핵심 재무 지표
 * 
 * 데이터베이스:
 * - 테이블명: financial_income_statement
 * - Primary Key: id (Auto Increment)
 * - Unique Key: (symbol, fiscal_date, period_type)
 * 
 * 데이터 출처:
 * - yfinance ticker.financials (연간)
 * - yfinance ticker.quarterly_financials (분기)
 * 
 * 업데이트 주기:
 * - 분기별: 연 4회
 * - 연간: 연 1회
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장
 * - FinancialController: API 응답
 * - detail.jsp: 재무 정보 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "financial_income_statement")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinancialIncomeStatement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String symbol;

    @Column(name = "fiscal_date", nullable = false)
    private LocalDate fiscalDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", nullable = false)
    private PeriodType periodType;

    // 매출 관련
    @Column(name = "total_revenue", precision = 20, scale = 2)
    private BigDecimal totalRevenue;

    @Column(name = "cost_of_revenue", precision = 20, scale = 2)
    private BigDecimal costOfRevenue;

    @Column(name = "gross_profit", precision = 20, scale = 2)
    private BigDecimal grossProfit;

    // 비용
    @Column(name = "research_and_development", precision = 20, scale = 2)
    private BigDecimal researchAndDevelopment;

    @Column(name = "selling_general_and_administration", precision = 20, scale = 2)
    private BigDecimal sellingGeneralAndAdministration;

    @Column(name = "operating_expense", precision = 20, scale = 2)
    private BigDecimal operatingExpense;

    // 영업 관련
    @Column(name = "operating_income", precision = 20, scale = 2)
    private BigDecimal operatingIncome;

    @Column(precision = 20, scale = 2)
    private BigDecimal ebitda;

    @Column(precision = 20, scale = 2)
    private BigDecimal ebit;

    // 기타 손익
    @Column(name = "interest_expense", precision = 20, scale = 2)
    private BigDecimal interestExpense;

    @Column(name = "interest_income", precision = 20, scale = 2)
    private BigDecimal interestIncome;

    @Column(name = "other_income_expense", precision = 20, scale = 2)
    private BigDecimal otherIncomeExpense;

    // 세전/세후 이익
    @Column(name = "pretax_income", precision = 20, scale = 2)
    private BigDecimal pretaxIncome;

    @Column(name = "tax_provision", precision = 20, scale = 2)
    private BigDecimal taxProvision;

    @Column(name = "net_income", precision = 20, scale = 2)
    private BigDecimal netIncome;

    @Column(name = "net_income_common_stockholders", precision = 20, scale = 2)
    private BigDecimal netIncomeCommonStockholders;

    // EPS
    @Column(name = "basic_eps", precision = 10, scale = 4)
    private BigDecimal basicEps;

    @Column(name = "diluted_eps", precision = 10, scale = 4)
    private BigDecimal dilutedEps;

    @Column(name = "basic_average_shares")
    private Long basicAverageShares;

    @Column(name = "diluted_average_shares")
    private Long dilutedAverageShares;

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

    /**
     * 기간 타입 (분기/연간)
     */
    public enum PeriodType {
        quarterly, // 분기별
        yearly // 연간
    }
}