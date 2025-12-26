package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.FinancialBalanceSheet;
import com.weenie_hut_jr.the_salty_spitoon.model.FinancialIncomeStatement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * 대차대조표 리포지토리
 * 
 * 역할:
 * - financial_balance_sheet 테이블 CRUD
 * - 분기/연간 대차대조표 조회
 * - 중복 체크 및 업데이트
 * 
 * 주요 메서드:
 * - findBySymbolAndPeriodType: 종목 + 기간 타입별 조회
 * - findBySymbolAndFiscalDateAndPeriodType: 중복 체크
 * - findBySymbolOrderByFiscalDateDesc: 최신순 정렬
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장 및 조회
 * - FinancialController: API 응답
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Repository
public interface FinancialBalanceSheetRepository extends JpaRepository<FinancialBalanceSheet, Long> {

    /**
     * 종목 + 기간 타입별 조회 (최신순)
     * 
     * @param symbol     종목 심볼
     * @param periodType 기간 타입 (quarterly/yearly)
     * @return 대차대조표 리스트
     */
    List<FinancialBalanceSheet> findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
            String symbol,
            FinancialIncomeStatement.PeriodType periodType);

    /**
     * 중복 체크용 (symbol + fiscal_date + period_type)
     * 
     * @param symbol     종목 심볼
     * @param fiscalDate 회계 마감일
     * @param periodType 기간 타입
     * @return Optional<FinancialBalanceSheet>
     */
    Optional<FinancialBalanceSheet> findBySymbolAndFiscalDateAndPeriodType(
            String symbol,
            LocalDate fiscalDate,
            FinancialIncomeStatement.PeriodType periodType);

    /**
     * 종목별 전체 조회 (최신순)
     * 
     * @param symbol 종목 심볼
     * @return 대차대조표 리스트
     */
    List<FinancialBalanceSheet> findBySymbolOrderByFiscalDateDesc(String symbol);

    /**
     * 종목 삭제
     * 
     * @param symbol 종목 심볼
     */
    void deleteBySymbol(String symbol);
}