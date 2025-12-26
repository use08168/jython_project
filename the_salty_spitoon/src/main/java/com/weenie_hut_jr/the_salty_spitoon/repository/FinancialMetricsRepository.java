package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.FinancialMetrics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 재무 지표 리포지토리
 * 
 * 역할:
 * - financial_metrics 테이블 CRUD
 * - 종목별 재무 지표 조회
 * - 지표 업데이트 (종목당 하나)
 * 
 * 특징:
 * - 종목당 하나의 레코드만 존재 (UNIQUE KEY: symbol)
 * - 업데이트 시 기존 레코드 덮어쓰기
 * 
 * 주요 메서드:
 * - findBySymbol: 종목별 조회
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장 및 조회
 * - FinancialController: API 응답
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Repository
public interface FinancialMetricsRepository extends JpaRepository<FinancialMetrics, Long> {

    /**
     * 종목별 재무 지표 조회
     * 
     * @param symbol 종목 심볼
     * @return Optional<FinancialMetrics>
     */
    Optional<FinancialMetrics> findBySymbol(String symbol);

    /**
     * 종목 삭제
     * 
     * @param symbol 종목 심볼
     */
    void deleteBySymbol(String symbol);
}