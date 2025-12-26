package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.Stock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 종목 마스터 리포지토리
 * 
 * 역할:
 * - stocks 테이블 CRUD 작업
 * - NASDAQ 100 종목 정보 관리
 * - 활성 종목 필터링 및 검색 기능
 * 
 * 기술 스택:
 * - Spring Data JPA
 * - JpaRepository<Stock, String>
 * - Stock: 엔티티 타입
 * - String: Primary Key 타입 (symbol)
 * 
 * Primary Key:
 * - 일반적으로 Long을 사용하지만, 이 리포지토리는 String 사용
 * - symbol(종목 심볼)이 PK이므로 String 타입
 * - 예: "AAPL", "GOOGL", "TSLA"
 * 
 * 자동 제공 메서드 (JpaRepository 상속):
 * - save(stock): INSERT 또는 UPDATE
 * - findById(symbol): 종목 심볼로 조회
 * 예: stockRepository.findById("AAPL")
 * - findAll(): 전체 종목 조회 (NASDAQ 100)
 * - delete(stock): 종목 삭제
 * - count(): 종목 개수
 * - existsById(symbol): 종목 존재 여부
 * 
 * 데이터 특성:
 * - 소량 데이터 (최대 100개 종목)
 * - 거의 변경되지 않음 (정적 데이터)
 * - 인메모리 캐싱 적용 가능
 * 
 * 사용 위치:
 * - StockController: 대시보드 종목 리스트
 * - StockService: 종목 유효성 검증
 * - AdminController: 종목 관리
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Repository // Spring Bean으로 등록
public interface StockRepository extends JpaRepository<Stock, String> {
    // JpaRepository<엔티티 타입, Primary Key 타입>
    // - Stock: 종목 엔티티
    // - String: symbol 필드의 타입 (PK)

    /**
     * 활성 상태인 종목 목록 조회
     * 
     * 기능:
     * - is_active = true인 종목만 필터링
     * - 대시보드에 표시할 종목 리스트 제공
     * - NASDAQ 100 중 서비스 중인 종목만 반환
     * 
     * 생성되는 SQL:
     * SELECT * FROM stocks
     * WHERE is_active = true
     * 
     * 메서드 이름 규칙:
     * - findBy: SELECT
     * - IsActive: WHERE is_active = ?
     * - True: = true
     * 
     * 사용 예시:
     * {@code
     * List<Stock> activeStocks = stockRepository.findByIsActiveTrue();
     * // 활성 종목만 조회 (예: 95개)
     * 
     * model.addAttribute("stocks", activeStocks);
     * // JSP로 전달하여 대시보드 렌더링
     * }
     * 
     * 사용 위치:
     * - StockController.showDashboard(): 대시보드 페이지
     * - StockController.getDashboardData(): 대시보드 API
     * - 메인 페이지: 활성 종목만 표시
     * 
     * 데이터 양:
     * - 일반적으로 90-100개
     * - 성능 이슈 없음 (소량 데이터)
     * 
     * 비활성 종목 사유:
     * - 상장폐지
     * - 일시적 서비스 중단
     * - 데이터 품질 문제
     * - A/B 테스트 제외
     * 
     * 반환값:
     * - List<Stock>: 활성 종목 리스트
     * - 빈 리스트: 활성 종목 없음 (정상 동작)
     * 
     * 정렬:
     * - 기본 정렬 없음 (삽입 순서)
     * - 필요 시 메서드명에 OrderBy 추가 가능
     * 예: findByIsActiveTrueOrderBySymbolAsc()
     * 
     * 캐싱 고려:
     * - 데이터 변경 빈도 낮음
     * - @Cacheable 적용 가능
     * {@code
     * @Cacheable("activeStocks")
     * List<Stock> findByIsActiveTrue();
     * }
     * 
     * @return List<Stock> 활성 상태인 종목 리스트
     */
    List<Stock> findByIsActiveTrue();

    /**
     * 회사명으로 종목 검색 (부분 일치)
     * 
     * 기능:
     * - 회사명에 특정 문자열이 포함된 종목 검색
     * - 대소문자 구분 (MySQL 기본 설정 따름)
     * - 검색 기능 구현에 사용
     * 
     * 생성되는 SQL:
     * SELECT * FROM stocks
     * WHERE name LIKE CONCAT('%', ?, '%')
     * 
     * 메서드 이름 규칙:
     * - findBy: SELECT
     * - Name: WHERE name
     * - Containing: LIKE '%?%'
     * 
     * 사용 예시:
     * {@code
     * // "Apple"이 포함된 종목 검색
     * List<Stock> results = stockRepository.findByNameContaining("Apple");
     * // 결과: [Stock(symbol="AAPL", name="Apple Inc.")]
     * 
     * // "tech"가 포함된 종목 검색
     * List<Stock> techStocks = stockRepository.findByNameContaining("tech");
     * // 결과: [Stock(symbol="NFLX", name="Netflix, Inc."), ...]
     * 
     * // 대소문자 주의 (MySQL collation 설정에 따름)
     * List<Stock> upper = stockRepository.findByNameContaining("APPLE");
     * List<Stock> lower = stockRepository.findByNameContaining("apple");
     * // 결과는 DB 설정에 따라 다를 수 있음
     * }
     * 
     * 사용 위치:
     * - 검색 기능: 사용자가 종목명 입력 시
     * - 자동완성: 타이핑하면서 실시간 검색
     * - 필터링: 특정 업종/카테고리 종목 찾기
     * 
     * 검색 패턴:
     * - "Apple" → "Apple Inc." ✓
     * - "Inc" → "Apple Inc.", "Microsoft Corporation" ✗, "Tesla, Inc." ✓
     * - "tech" → "Biotech" ✓ (의도하지 않은 매칭 가능)
     * 
     * 성능:
     * - LIKE '%...%'는 인덱스 사용 불가 (Full Table Scan)
     * - 소량 데이터(100개)라 문제없음
     * - 대량 데이터 시 Full-Text Search 고려
     * 
     * 대소문자 처리:
     * - MySQL의 collation 설정 따름
     * - utf8mb4_general_ci: 대소문자 구분 안 함
     * - utf8mb4_bin: 대소문자 구분
     * 
     * 개선 방안:
     * 1. 대소문자 무시:
     * {@code
     * List<Stock> findByNameContainingIgnoreCase(String name);
     * }
     * 
     * 2. 심볼도 함께 검색:
     * {@code
     * @Query("SELECT s FROM Stock s WHERE s.name LIKE %:keyword% OR s.symbol LIKE
     * %:keyword%")
     * List<Stock> searchByKeyword(@Param("keyword") String keyword);
     * }
     * 
     * 3. Full-Text Search (대량 데이터 시):
     * {@code
     * @Query(value = "SELECT * FROM stocks WHERE MATCH(name) AGAINST (?1)",
     * nativeQuery = true)
     * List<Stock> fullTextSearch(String keyword);
     * }
     * 
     * 반환값:
     * - List<Stock>: 검색 결과
     * - 빈 리스트: 매칭되는 종목 없음
     * 
     * 주의사항:
     * - 빈 문자열 전달 시 전체 종목 반환
     * - null 전달 시 예외 발생 가능 (검증 필요)
     * 
     * @param name 검색할 회사명 (부분 문자열)
     * @return List<Stock> 회사명에 해당 문자열이 포함된 종목 리스트
     */
    List<Stock> findByNameContaining(String name);

    // ========================================
    // 향후 추가 가능한 메서드 (TODO)
    // ========================================

    /**
     * TODO: 활성 종목 심볼만 조회 (메모리 최적화)
     * 
     * @Query("SELECT s.symbol FROM Stock s WHERE s.isActive = true")
     * List<String> findActiveSymbols();
     * 
     * 사용: Python 데이터 수집 시 활성 종목 리스트 전달
     */

    /**
     * TODO: 거래소별 종목 조회
     * 
     * List<Stock> findByExchange(String exchange);
     * 
     * 예: findByExchange("NASDAQ")
     */

    /**
     * TODO: 심볼 또는 이름으로 검색 (OR 조건)
     * 
     * @Query("SELECT s FROM Stock s WHERE s.symbol LIKE %:keyword% OR s.name LIKE
     * %:keyword%")
     * List<Stock> searchByKeyword(@Param("keyword") String keyword);
     */

    /**
     * TODO: 활성 종목 + 정렬
     * 
     * List<Stock> findByIsActiveTrueOrderBySymbolAsc();
     * List<Stock> findByIsActiveTrueOrderByNameAsc();
     */

    /**
     * TODO: 최근 업데이트된 종목 조회
     * 
     * List<Stock> findTop10ByOrderByLastUpdatedDesc();
     */

    /**
     * TODO: 종목 일괄 비활성화 (배치 작업)
     * 
     * @Modifying
     *            @Query("UPDATE Stock s SET s.isActive = false WHERE s.symbol IN
     *            :symbols")
     *            int deactivateStocks(@Param("symbols") List<String> symbols);
     */
}