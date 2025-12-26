package com.weenie_hut_jr.the_salty_spitoon.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 주식 데이터 전송 객체 (DTO - Data Transfer Object)
 * 
 * 역할:
 * - StockCandle1m 엔티티를 API 응답용으로 변환
 * - 클라이언트(프론트엔드)에 전송할 차트 데이터 포맷
 * - 엔티티의 불필요한 정보(id, createdAt 등) 제외
 * 
 * 엔티티 vs DTO:
 * - StockCandle1m: JPA 엔티티, DB 테이블과 1:1 매핑
 * - StockData: DTO, API 응답 전용, 가벼운 구조
 * 
 * 사용 위치:
 * - StockService: 엔티티 → DTO 변환
 * - StockController: REST API 응답
 * - Chart.js / TradingView: 프론트엔드 차트 라이브러리
 * 
 * 변환 예시:
 * {@code
 * StockCandle1m entity = repository.findById(1L);
 * StockData dto = StockData.builder()
 *     .date(Date.from(entity.getTimestamp().atZone(ZoneId.systemDefault()).toInstant()))
 *     .open(entity.getOpen())
 *     .high(entity.getHigh())
 *     .low(entity.getLow())
 *     .close(entity.getClose())
 *     .volume(entity.getVolume())
 *     .build();
 * }
 * 
 * JSON 응답 예시:
 * {
 * "date": "2025-12-21T09:31:00.000Z",
 * "open": 273.5000,
 * "high": 273.8000,
 * "low": 273.4000,
 * "close": 273.6700,
 * "volume": 1234567
 * }
 * 
 * 왜 DTO를 사용하는가?
 * 1. 보안: 엔티티의 내부 정보(id, createdAt) 노출 방지
 * 2. 성능: 필요한 필드만 전송 (네트워크 트래픽 감소)
 * 3. 유연성: API 스펙 변경 시 엔티티 영향 없음
 * 4. 명확성: 프론트엔드와 백엔드 계약 명확화
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Data // Lombok: getter, setter, toString, equals, hashCode 자동 생성
@Builder // Lombok: 빌더 패턴 (StockData.builder().date(...).open(...).build())
@NoArgsConstructor // Lombok: 기본 생성자 (JSON 역직렬화 필요)
@AllArgsConstructor // Lombok: 모든 필드 생성자
public class StockData {

    /**
     * 캔들 날짜/시간 (Date/Time)
     * 
     * 역할:
     * - 해당 캔들의 타임스탬프
     * - 차트의 X축 데이터
     * 
     * 타입:
     * - java.util.Date (Jackson이 자동으로 ISO 8601 형식으로 변환)
     * - StockCandle1m의 LocalDateTime에서 변환됨
     * 
     * 변환 과정:
     * LocalDateTime (DB) → Date (DTO) → ISO 8601 String (JSON)
     * 
     * JSON 형식:
     * - "2025-12-21T09:31:00.000Z" (ISO 8601)
     * - JavaScript Date 객체와 호환
     * 
     * 프론트엔드 사용:
     * {@code
     * // JavaScript
     * const chartData = response.data.map(item => ({
     *     x: new Date(item.date),
     *     y: item.close
     * }));
     * }
     * 
     * 시간대:
     * - UTC 또는 시스템 기본 시간대
     * - 프론트엔드에서 로컬 시간대로 변환 필요
     */
    private Date date;

    /**
     * 시가 (Opening Price)
     * 
     * 역할:
     * - 해당 캔들의 첫 거래 가격
     * - 캔들 차트의 시작점
     * 
     * 타입:
     * - BigDecimal (정확한 금융 계산)
     * - JSON에서는 숫자로 직렬화
     * 
     * JSON 형식:
     * - 273.5000 (소수점 4자리)
     * 
     * 프론트엔드 사용:
     * - 캔들 몸통 그리기
     * - 양봉/음봉 색상 결정 (close vs open)
     */
    private BigDecimal open;

    /**
     * 고가 (Highest Price)
     * 
     * 역할:
     * - 해당 캔들의 최고 거래 가격
     * - 캔들 차트의 상단 꼬리 끝점
     * 
     * 타입:
     * - BigDecimal
     * - JSON: 273.8000
     * 
     * 프론트엔드 사용:
     * - 캔들의 위쪽 그림자(upper wick) 그리기
     * - 저항선 분석
     * 
     * 제약:
     * - high >= open, close, low
     */
    private BigDecimal high;

    /**
     * 저가 (Lowest Price)
     * 
     * 역할:
     * - 해당 캔들의 최저 거래 가격
     * - 캔들 차트의 하단 꼬리 끝점
     * 
     * 타입:
     * - BigDecimal
     * - JSON: 273.4000
     * 
     * 프론트엔드 사용:
     * - 캔들의 아래쪽 그림자(lower wick) 그리기
     * - 지지선 분석
     * 
     * 제약:
     * - low <= open, close, high
     */
    private BigDecimal low;

    /**
     * 종가 (Closing Price)
     * 
     * 역할:
     * - 해당 캔들의 마지막 거래 가격
     * - 가장 중요한 가격 데이터
     * 
     * 타입:
     * - BigDecimal
     * - JSON: 273.6700
     * 
     * 프론트엔드 사용:
     * - 캔들 몸통의 끝점
     * - 이동평균선 계산 (MA5, MA20)
     * - 라인 차트의 기본 값
     * 
     * 양봉/음봉 결정:
     * - close > open: 양봉 (상승, 보통 빨간색)
     * - close < open: 음봉 (하락, 보통 파란색)
     * - close == open: 도지 (보합, 회색)
     */
    private BigDecimal close;

    /**
     * 거래량 (Trading Volume)
     * 
     * 역할:
     * - 해당 캔들 기간 동안 거래된 총 주식 수
     * - 시장 활동성 지표
     * 
     * 타입:
     * - Long (큰 숫자 대응)
     * - JSON: 1234567
     * 
     * 프론트엔드 사용:
     * - Volume 막대 차트 (차트 하단)
     * - 거래량 이동평균 계산
     * - 가격 움직임의 신뢰도 평가
     * 
     * Chart.js 예시:
     * {@code
     * {
     *   type: 'bar',
     *   data: {
     *     labels: dates,
     *     datasets: [{
     *       label: 'Volume',
     *       data: volumes,
     *       backgroundColor: 'rgba(75, 192, 192, 0.2)'
     * }]
     * }
     * }
     * }
     * 
     * 의미:
     * - 높은 거래량: 강한 추세, 높은 관심
     * - 낮은 거래량: 약한 추세, 낮은 유동성
     */
    private Long volume;

    // ========================================
    // 제외된 필드 (엔티티에는 있지만 DTO에는 없음)
    // ========================================

    /**
     * 제외: id (Long)
     * - 이유: 프론트엔드에서 불필요, 내부 DB 식별자 노출 방지
     */

    /**
     * 제외: symbol (String)
     * - 이유: API 요청 경로에 이미 포함 (/api/chart/{symbol})
     * - 필요 시 컨트롤러에서 응답 래퍼에 추가 가능
     */

    /**
     * 제외: createdAt (LocalDateTime)
     * - 이유: 데이터 삽입 시각은 차트에 불필요
     * - 감사 로그용이므로 API 응답에서 제외
     */

    // ========================================
    // 유틸리티 메서드 (향후 추가 가능)
    // ========================================

    /**
     * TODO: StockCandle1m 엔티티에서 DTO로 변환하는 정적 팩토리 메서드
     * 
     * public static StockData from(StockCandle1m entity) {
     * return StockData.builder()
     * .date(Date.from(entity.getTimestamp()
     * .atZone(ZoneId.systemDefault()).toInstant()))
     * .open(entity.getOpen())
     * .high(entity.getHigh())
     * .low(entity.getLow())
     * .close(entity.getClose())
     * .volume(entity.getVolume())
     * .build();
     * }
     */

    /**
     * TODO: 변동률 계산 메서드
     * 
     * public BigDecimal getChangePercent() {
     * if (open.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
     * return close.subtract(open)
     * .divide(open, 4, RoundingMode.HALF_UP)
     * .multiply(BigDecimal.valueOf(100));
     * }
     */

    /**
     * TODO: 캔들 타입 반환
     * 
     * public String getCandleType() {
     * int comparison = close.compareTo(open);
     * if (comparison > 0) return "BULLISH";
     * if (comparison < 0) return "BEARISH";
     * return "DOJI";
     * }
     */
}