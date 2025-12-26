package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.CompanyInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 기업 정보 리포지토리
 * 
 * 역할:
 * - company_info 테이블 CRUD
 * - 종목별 기업 정보 조회
 * - 섹터/산업별 기업 조회
 * 
 * 특징:
 * - 종목당 하나의 레코드만 존재 (UNIQUE KEY: symbol)
 * - 업데이트 시 기존 레코드 덮어쓰기
 * 
 * 주요 메서드:
 * - findBySymbol: 종목별 조회
 * - findBySector: 섹터별 조회
 * - findByIndustry: 산업별 조회
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장 및 조회
 * - FinancialController: API 응답
 * - detail.jsp: 기업 정보 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Repository
public interface CompanyInfoRepository extends JpaRepository<CompanyInfo, Long> {

    /**
     * 종목별 기업 정보 조회
     * 
     * @param symbol 종목 심볼
     * @return Optional<CompanyInfo>
     */
    Optional<CompanyInfo> findBySymbol(String symbol);

    /**
     * 섹터별 기업 조회
     * 
     * @param sector 섹터명
     * @return 기업 정보 리스트
     */
    List<CompanyInfo> findBySector(String sector);

    /**
     * 산업별 기업 조회
     * 
     * @param industry 산업명
     * @return 기업 정보 리스트
     */
    List<CompanyInfo> findByIndustry(String industry);

    /**
     * 종목 삭제
     * 
     * @param symbol 종목 심볼
     */
    void deleteBySymbol(String symbol);
}