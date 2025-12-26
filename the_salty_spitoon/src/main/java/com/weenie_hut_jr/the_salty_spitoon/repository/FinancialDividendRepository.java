package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.FinancialDividend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * 배당금 리포지토리
 * 
 * 역할:
 * - financial_dividends 테이블 CRUD
 * - 배당 이력 조회
 * - 중복 체크 및 업데이트
 * 
 * 주요 메서드:
 * - findBySymbolOrderByPaymentDateDesc: 최신순 배당 조회
 * - findBySymbolAndPaymentDate: 중복 체크
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장 및 조회
 * - FinancialController: API 응답
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Repository
public interface FinancialDividendRepository extends JpaRepository<FinancialDividend, Long> {

    /**
     * 종목별 배당 이력 조회 (최신순)
     * 
     * @param symbol 종목 심볼
     * @return 배당 리스트
     */
    List<FinancialDividend> findBySymbolOrderByPaymentDateDesc(String symbol);

    /**
     * 중복 체크용 (symbol + payment_date)
     * 
     * @param symbol      종목 심볼
     * @param paymentDate 배당 지급일
     * @return Optional<FinancialDividend>
     */
    Optional<FinancialDividend> findBySymbolAndPaymentDate(String symbol, LocalDate paymentDate);

    /**
     * 종목 삭제
     * 
     * @param symbol 종목 심볼
     */
    void deleteBySymbol(String symbol);
}