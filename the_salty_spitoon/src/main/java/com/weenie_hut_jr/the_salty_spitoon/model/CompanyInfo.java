package com.weenie_hut_jr.the_salty_spitoon.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 기업 정보 엔티티 (Company Info)
 * 
 * 역할:
 * - 기업 기본 정보 저장
 * - 회사명, 섹터, 산업, 위치, 연락처
 * - 사업 설명 및 조직 정보
 * 
 * 데이터베이스:
 * - 테이블명: company_info
 * - Primary Key: id (Auto Increment)
 * - Unique Key: symbol (종목당 하나)
 * 
 * 데이터 출처:
 * - yfinance ticker.info
 * 
 * 데이터 특성:
 * - 정적 정보: 회사명, 섹터, 산업, 위치 (거의 변경 없음)
 * - 동적 정보: 시가총액, 기업가치 (자주 변경)
 * 
 * 사용 위치:
 * - FinancialDataService: 데이터 저장
 * - FinancialController: API 응답
 * - detail.jsp: 기업 정보 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity
@Table(name = "company_info")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompanyInfo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10, unique = true)
    private String symbol;

    // 기본 정보
    @Column(name = "long_name", length = 200)
    private String longName;

    @Column(name = "short_name", length = 100)
    private String shortName;

    // 분류
    @Column(length = 100)
    private String sector;

    @Column(length = 100)
    private String industry;

    @Column(name = "industry_key", length = 100)
    private String industryKey;

    @Column(name = "sector_key", length = 100)
    private String sectorKey;

    // 위치
    @Column(length = 100)
    private String country;

    @Column(length = 100)
    private String city;

    @Column(length = 100)
    private String state;

    @Column(length = 500)
    private String address;

    @Column(name = "zip_code", length = 20)
    private String zipCode;

    // 연락처
    @Column(length = 200)
    private String website;

    @Column(length = 50)
    private String phone;

    // 조직
    @Column(name = "full_time_employees")
    private Integer fullTimeEmployees;

    // 사업 설명
    @Column(name = "long_business_summary", columnDefinition = "TEXT")
    private String longBusinessSummary;

    // 시장 정보 (동적)
    @Column(name = "market_cap", precision = 20, scale = 2)
    private BigDecimal marketCap;

    @Column(name = "enterprise_value", precision = 20, scale = 2)
    private BigDecimal enterpriseValue;

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