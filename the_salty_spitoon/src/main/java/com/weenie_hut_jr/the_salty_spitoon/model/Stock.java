package com.weenie_hut_jr.the_salty_spitoon.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 종목 마스터 엔티티 (Stock Master Entity)
 * 
 * 역할:
 * - NASDAQ 100 종목의 기본 정보 저장
 * - 종목 메타데이터 관리 (심볼, 이름, 거래소)
 * - 활성/비활성 상태 관리
 * 
 * 데이터베이스:
 * - 테이블명: stocks
 * - Primary Key: symbol (종목 심볼)
 * - 인덱스: symbol (기본키)
 * 
 * 관계:
 * - StockCandle1m: 1:N (한 종목은 여러 개의 캔들 데이터를 가짐)
 * - 실제로는 FK 제약조건 없이 느슨한 연결 (성능 고려)
 * 
 * 데이터 예시:
 * - symbol: "AAPL"
 * - name: "Apple Inc."
 * - exchange: "NASDAQ"
 * - isActive: true
 * 
 * 데이터 출처:
 * - Python: load_nasdaq100.py에서 초기 데이터 로드
 * - 수동: 관리자가 직접 추가/수정 가능
 * 
 * 사용 위치:
 * - StockController: 종목 목록 조회
 * - StockService: 종목 유효성 검증
 * - Dashboard: 전체 종목 표시
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Entity // JPA 엔티티 클래스
@Table(name = "stocks") // MySQL 테이블명: stocks
@Data // Lombok: getter, setter, toString, equals, hashCode 자동 생성
@Builder // Lombok: 빌더 패턴 지원 (Stock.builder().symbol("AAPL").name("Apple Inc.").build())
@NoArgsConstructor // Lombok: 기본 생성자 (JPA 필수)
@AllArgsConstructor // Lombok: 모든 필드를 받는 생성자
public class Stock {

    /**
     * 종목 심볼 (Primary Key)
     * 
     * 특징:
     * - 티커 심볼 (예: AAPL, GOOGL, TSLA, META)
     * - 대문자로 통일
     * - 최대 10자 (일반적으로 1-5자)
     * 
     * 제약조건:
     * - Primary Key
     * - NOT NULL
     * - UNIQUE (자동 적용)
     * 
     * 예시:
     * - "AAPL" : Apple Inc.
     * - "GOOGL" : Alphabet Inc. Class A
     * - "TSLA" : Tesla, Inc.
     * - "META" : Meta Platforms, Inc.
     * - "NVDA" : NVIDIA Corporation
     */
    @Id // Primary Key
    @Column(length = 10) // VARCHAR(10)
    private String symbol;

    /**
     * 회사명 (Company Name)
     * 
     * 특징:
     * - 정식 회사명 (예: "Apple Inc.", "Tesla, Inc.")
     * - 최대 200자
     * - 대시보드 및 차트에 표시
     * 
     * 제약조건:
     * - NOT NULL
     * 
     * 예시:
     * - "Apple Inc."
     * - "Microsoft Corporation"
     * - "Alphabet Inc Class A"
     * - "Meta Platforms, Inc."
     * 
     * 사용 위치:
     * - 대시보드 종목 리스트
     * - 차트 타이틀
     * - 검색 기능
     */
    @Column(nullable = false, length = 200) // VARCHAR(200) NOT NULL
    private String name;

    /**
     * 거래소명 (Exchange)
     * 
     * 특징:
     * - 종목이 상장된 거래소 이름
     * - NASDAQ 100은 대부분 "NASDAQ"
     * - 최대 20자
     * 
     * 가능한 값:
     * - "NASDAQ" : 나스닥
     * - "NYSE" : 뉴욕증권거래소
     * - null : 미지정
     * 
     * 사용:
     * - 거래소별 필터링
     * - 메타데이터
     */
    @Column(length = 20) // VARCHAR(20), nullable
    private String exchange;

    /**
     * 로고 이미지 URL (Logo URL)
     * 
     * 특징:
     * - 회사 로고 이미지 URL
     * - Wikipedia, Clearbit 등에서 제공하는 로고
     * - 최대 500자
     * 
     * 예시:
     * - "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/500px-Apple_logo_black.svg.png"
     * 
     * 사용 위치:
     * - 대시보드 종목 리스트
     * - 종목 상세 페이지
     * - 뉴스 페이지
     * 
     * 데이터 출처:
     * - nasdaq100_tickers.csv의 logo_url 컬럼
     * - Admin 페이지 CSV 동기화 기능
     */
    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    /**
     * 활성 상태 (Active Status)
     * 
     * 역할:
     * - 현재 서비스 중인 종목인지 여부
     * - false인 종목은 대시보드에 표시 안 됨
     * - 데이터 수집은 계속될 수 있음
     * 
     * 값:
     * - true : 활성 (대시보드 표시, 차트 접근 가능)
     * - false : 비활성 (숨김 처리)
     * - null : 기본값 (true로 처리)
     * 
     * 사용 시나리오:
     * - 종목 상장폐지 시 비활성화
     * - 일시적 서비스 중단
     * - A/B 테스트용 종목 제외
     * 
     * 쿼리 예시:
     * - stockRepository.findByIsActiveTrue()
     */
    @Column(name = "is_active") // DB 컬럼명: is_active (snake_case)
    private Boolean isActive;

    /**
     * 마지막 업데이트 시각
     * 
     * 역할:
     * - 종목 정보가 마지막으로 수정된 시각
     * - 데이터 수집과는 무관 (메타데이터 수정 시각)
     * 
     * 업데이트 시점:
     * - 회사명 변경
     * - 활성 상태 변경
     * - 거래소 정보 수정
     * 
     * 형식:
     * - LocalDateTime (예: 2025-12-21T15:30:00)
     * - MySQL DATETIME 타입으로 저장
     * 
     * 사용:
     * - 감사(Audit) 로그
     * - 데이터 정합성 체크
     */
    @Column(name = "last_updated") // DB 컬럼명: last_updated
    private LocalDateTime lastUpdated;

    /**
     * 생성 시각
     * 
     * 역할:
     * - 종목이 DB에 처음 추가된 시각
     * - 불변 값 (수정되지 않음)
     * 
     * 설정 시점:
     * - Python: load_nasdaq100.py 실행 시 자동 설정
     * - 수동: INSERT 쿼리 실행 시
     * 
     * 형식:
     * - LocalDateTime
     * - MySQL DATETIME 타입
     * 
     * 사용:
     * - 종목 추가 이력 추적
     * - 데이터 분석 (종목별 서비스 기간)
     */
    @Column(name = "created_at") // DB 컬럼명: created_at
    private LocalDateTime createdAt;

    // ========================================
    // 비즈니스 로직 (향후 추가 가능)
    // ========================================

    /**
     * TODO: 종목 활성화 메서드
     * 
     * public void activate() {
     * this.isActive = true;
     * this.lastUpdated = LocalDateTime.now();
     * }
     */

    /**
     * TODO: 종목 비활성화 메서드
     * 
     * public void deactivate() {
     * this.isActive = false;
     * this.lastUpdated = LocalDateTime.now();
     * }
     */

    /**
     * TODO: 종목 정보 업데이트 메서드
     * 
     * public void updateInfo(String name, String exchange) {
     * this.name = name;
     * this.exchange = exchange;
     * this.lastUpdated = LocalDateTime.now();
     * }
     */
}