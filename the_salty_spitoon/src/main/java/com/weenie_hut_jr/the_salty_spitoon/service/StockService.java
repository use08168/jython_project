package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.model.StockData;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 주식 데이터 비즈니스 로직 서비스
 * 
 * 역할:
 * - MySQL에서 주식 데이터 조회 및 가공
 * - 실시간 주가 정보 제공
 * - 과거 데이터 조회 및 타임프레임 변환
 * - 기술적 지표 계산 (이동평균선, RSI 등)
 * 
 * 아키텍처 변경사항:
 * - 기존: YahooFinanceAPI 직접 호출
 * - 현재: MySQL에서만 조회 (Python 수집 데이터 활용)
 * 
 * 데이터 흐름:
 * 1. Python (stock_collector.py) → MySQL 1분봉 저장
 * 2. StockService → MySQL 조회
 * 3. 타임프레임 집계 (1분 → 5분/1시간/1일)
 * 4. 기술지표 계산
 * 5. Controller → API 응답
 * 
 * 주요 기능:
 * 1. 실시간 데이터: getRealTimeStock()
 * 2. 과거 데이터: getHistoricalData(), getAllHistoricalData()
 * 3. 타임프레임 집계: aggregateByTimeframe()
 * 4. 기술지표: calculateMA(), calculateRSI()
 * 
 * 타임프레임 지원:
 * - 1m: 1분봉 (원본 데이터)
 * - 5m: 5분봉 (1분봉 5개 집계)
 * - 15m: 15분봉 (1분봉 15개 집계)
 * - 1h: 1시간봉 (1분봉 60개 집계)
 * - 4h: 4시간봉 (1분봉 240개 집계)
 * - 1d: 일봉 (1분봉 390개 집계)
 * 
 * 기술지표:
 * - MA (Moving Average): 이동평균선
 * - RSI (Relative Strength Index): 상대강도지수
 * - 향후 확장: MACD, 볼린저밴드, 스토캐스틱 등
 * 
 * 성능 고려사항:
 * - 1분봉 데이터: 대량 (연간 97,500개/종목)
 * - 집계 연산: CPU 집약적
 * - 캐싱 고려 가능
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j // 로깅 기능
@Service // Spring Service Bean
@RequiredArgsConstructor // final 필드 생성자 주입
public class StockService {

    // 의존성 주입
    private final StockCandle1mRepository candleRepository; // 1분봉 데이터 Repository

    /**
     * 실시간 주식 데이터 조회 (MySQL 기반)
     * 
     * 기능:
     * - 특정 종목의 가장 최신 1분봉 데이터 조회
     * - 이전 캔들과 비교하여 등락률 계산
     * - 대시보드 및 상세 차트용 실시간 정보 제공
     * 
     * 동작 과정:
     * 1. 최신 캔들 조회 (ORDER BY timestamp DESC LIMIT 1)
     * 2. 데이터 없으면 기본값 반환 (error: true)
     * 3. 1분 전 캔들 조회 (변동 계산용)
     * 4. 등락폭 및 등락률 계산
     * 5. 결과 Map 생성 및 반환
     * 
     * 데이터 없는 경우:
     * - Python 수집 시작 전
     * - 새로 추가된 종목
     * - 주말/휴장일
     * - 에러 플래그와 함께 기본값 반환
     * 
     * 변동 계산:
     * - 등락폭: 현재 종가 - 이전 종가
     * - 등락률: (등락폭 / 이전 종가) × 100
     * 
     * 이전 종가 결정:
     * - 1분 전 캔들 있음: 그 종가 사용
     * - 없음: 현재 캔들 종가 사용 (변동 0%)
     * 
     * 반환 데이터:
     * - symbol: 종목 심볼
     * - price: 현재가 (종가)
     * - change: 등락폭 (±)
     * - changePercent: 등락률 (%)
     * - volume: 거래량
     * - dayHigh: 고가
     * - dayLow: 저가
     * - open: 시가
     * - previousClose: 전일 종가
     * - timestamp: 데이터 시각
     * - error: 에러 여부
     * 
     * 사용 위치:
     * - StockController.getRealTimeData()
     * - StockController.getDashboardData()
     * - API: /stock/api/realtime/{symbol}
     * - WebSocket 초기 데이터
     * 
     * 성능:
     * - 인덱스 활용: (symbol, timestamp DESC)
     * - LIMIT 1: 매우 빠름
     * - 총 2번 쿼리: 최신 + 이전
     * 
     * 예시:
     * Input: "AAPL"
     * Output: {
     * "symbol": "AAPL",
     * "price": 273.67,
     * "change": 1.48,
     * "changePercent": 0.54,
     * "volume": 1234567,
     * "dayHigh": 273.80,
     * "dayLow": 273.40,
     * "open": 273.50,
     * "previousClose": 272.19,
     * "timestamp": "2025-12-21T15:30:00",
     * "error": false
     * }
     * 
     * @param symbol 종목 심볼 (예: AAPL, GOOGL)
     * @return Map 실시간 주가 정보
     */
    public Map<String, Object> getRealTimeStock(String symbol) {
        log.debug("{} - 실시간 데이터 조회 (MySQL)", symbol);

        // 1. 최신 캔들 조회 (가장 최근 1분봉)
        Optional<StockCandle1m> latestCandle = candleRepository
                .findFirstBySymbolOrderByTimestampDesc(symbol);

        // 2. 데이터 없음 체크
        if (latestCandle.isEmpty()) {
            log.warn("{} - MySQL에 데이터 없음 (Python 수집 대기 중일 수 있음)", symbol);

            // 에러 대신 기본값 반환 (프론트엔드에서 처리)
            Map<String, Object> result = new HashMap<>();
            result.put("symbol", symbol);
            result.put("price", BigDecimal.ZERO);
            result.put("change", BigDecimal.ZERO);
            result.put("changePercent", BigDecimal.ZERO);
            result.put("volume", 0L);
            result.put("dayHigh", BigDecimal.ZERO);
            result.put("dayLow", BigDecimal.ZERO);
            result.put("open", BigDecimal.ZERO);
            result.put("previousClose", BigDecimal.ZERO);
            result.put("error", true); // 에러 플래그
            result.put("message", "No data available - waiting for collection");
            return result;
        }

        StockCandle1m candle = latestCandle.get();

        // 3. 이전 캔들 조회 (1분 전)
        // - 변동 계산을 위해 필요
        LocalDateTime previousTime = candle.getTimestamp().minusMinutes(1);
        Optional<StockCandle1m> previousCandle = candleRepository
                .findBySymbolAndTimestamp(symbol, previousTime);

        // 4. 이전 종가 결정
        BigDecimal previousClose = previousCandle
                .map(StockCandle1m::getClose) // 있으면 그 종가
                .orElse(candle.getClose()); // 없으면 현재 종가 (변동 0)

        // 5. 등락폭 계산 (change = 현재 - 이전)
        BigDecimal change = candle.getClose().subtract(previousClose);

        // 6. 등락률 계산 (changePercent = change / previousClose × 100)
        BigDecimal changePercent = BigDecimal.ZERO;

        if (previousClose.compareTo(BigDecimal.ZERO) != 0) {
            // 0으로 나누기 방지
            changePercent = change
                    .divide(previousClose, 4, RoundingMode.HALF_UP) // 소수점 4자리
                    .multiply(BigDecimal.valueOf(100)); // 퍼센트 변환
        }

        // 로그 출력 (간결한 정보)
        log.info("{} - 실시간: ${} ({}%)",
                symbol,
                candle.getClose(),
                changePercent.setScale(2, RoundingMode.HALF_UP));

        // 7. 결과 Map 생성
        Map<String, Object> result = new HashMap<>();
        result.put("symbol", symbol);
        result.put("price", candle.getClose()); // 현재가
        result.put("change", change); // 등락폭
        result.put("changePercent", changePercent); // 등락률
        result.put("volume", candle.getVolume()); // 거래량
        result.put("dayHigh", candle.getHigh()); // 고가
        result.put("dayLow", candle.getLow()); // 저가
        result.put("open", candle.getOpen()); // 시가
        result.put("previousClose", previousClose); // 전일 종가
        result.put("timestamp", candle.getTimestamp()); // 데이터 시각
        result.put("error", false); // 정상

        return result;
    }

    /**
     * 과거 데이터 조회 (차트용, 기간 제한 있음)
     * 
     * 기능:
     * - 지정된 일수(days)만큼의 과거 데이터 조회
     * - 타임프레임에 따라 1분봉 집계
     * - 차트 렌더링용 데이터 제공
     * 
     * 동작 과정:
     * 1. 조회 기간 계산 (현재 - days일)
     * 2. MySQL에서 1분봉 데이터 조회
     * 3. 1분봉이면 변환 후 반환
     * 4. 다른 타임프레임이면 집계 후 반환
     * 
     * 타임프레임 처리:
     * - 1m: 원본 1분봉 그대로 반환
     * - 5m, 15m, 1h, 4h, 1d: aggregateByTimeframe() 호출
     * 
     * 데이터 양 예상:
     * - 1일 (1m): ~390개 (6.5시간 × 60분)
     * - 7일 (1m): ~2,730개
     * - 30일 (1m): ~11,700개
     * - 7일 (5m): ~546개
     * - 7일 (1h): ~46개
     * 
     * 사용 위치:
     * - StockController.getChartData()
     * - API: /stock/api/chart/{symbol}?days=7
     * 
     * 제한사항:
     * - days 파라미터로 데이터 양 제한
     * - 대량 데이터 방지
     * 
     * 대안:
     * - getAllHistoricalData(): 전체 데이터 (제한 없음)
     * 
     * 예시:
     * Input: ("AAPL", "1m", 7)
     * Output: List<StockData> (약 2730개)
     * 
     * Input: ("AAPL", "1h", 7)
     * Output: List<StockData> (약 46개, 1분봉 집계)
     * 
     * @param symbol    종목 심볼
     * @param timeframe 타임프레임 (1m, 5m, 15m, 1h, 4h, 1d)
     * @param days      조회 일수
     * @return List<StockData> 차트 데이터
     */
    public List<StockData> getHistoricalData(String symbol, String timeframe, int days) {
        log.info("{} - 과거 데이터 조회 (타임프레임: {}, 일수: {})", symbol, timeframe, days);

        // 1. 조회 기간 계산
        LocalDateTime to = LocalDateTime.now(); // 현재 시각
        LocalDateTime from = to.minusDays(days); // days일 전

        log.debug("{} - 조회 기간: {} ~ {}", symbol, from, to);

        // 2. MySQL에서 1분봉 조회 (기간 필터)
        List<StockCandle1m> oneMinData = candleRepository
                .findBySymbolAndTimestampBetweenOrderByTimestampAsc(symbol, from, to);

        log.info("{} - MySQL 조회 결과: {}개", symbol, oneMinData.size());

        // 3. 데이터 없음 체크
        if (oneMinData.isEmpty()) {
            log.warn("{} - 조회된 데이터 없음! (historical_loader.py 실행 필요)", symbol);
            return Collections.emptyList();
        }

        // 4. 1분봉이면 변환 후 바로 반환
        if ("1m".equals(timeframe)) {
            List<StockData> result = convertToStockData(oneMinData);
            log.info("{} - 1분봉 반환: {}개", symbol, result.size());
            return result;
        }

        // 5. 타임프레임 집계 (5m, 1h, 1d 등)
        List<StockData> aggregated = aggregateByTimeframe(oneMinData, timeframe);
        log.info("{} - {}봉 집계 완료: {}개", symbol, timeframe, aggregated.size());

        return aggregated;
    }

    /**
     * 타임프레임별 집계 (1분봉 → N분/N시간/일봉)
     * 
     * 기능:
     * - 1분봉 데이터를 지정된 타임프레임으로 집계
     * - OHLCV (Open, High, Low, Close, Volume) 계산
     * 
     * 집계 원리:
     * - Open: 그룹 내 첫 번째 캔들의 시가
     * - High: 그룹 내 모든 캔들의 최고가
     * - Low: 그룹 내 모든 캔들의 최저가
     * - Close: 그룹 내 마지막 캔들의 종가
     * - Volume: 그룹 내 모든 거래량의 합
     * 
     * 그룹핑 전략:
     * 1. calculateGroupKey()로 시간대별 그룹 키 생성
     * 2. TreeMap으로 시간순 정렬 자동 보장
     * 3. 각 그룹별 OHLCV 집계
     * 
     * 예시 (5분봉):
     * Input (1분봉):
     * 09:30 - O:100, H:102, L:99, C:101, V:1000
     * 09:31 - O:101, H:103, L:100, C:102, V:1500
     * 09:32 - O:102, H:104, L:101, C:103, V:2000
     * 09:33 - O:103, H:105, L:102, C:104, V:1800
     * 09:34 - O:104, H:106, L:103, C:105, V:2200
     * 
     * Output (5분봉):
     * 09:30 - O:100, H:106, L:99, C:105, V:8500
     * (그룹 키: 09:30, 5개 캔들 집계)
     * 
     * 시간 정규화:
     * - 5분봉: 09:30, 09:35, 09:40, ...
     * - 1시간봉: 09:00, 10:00, 11:00, ...
     * - 일봉: 00:00 (날짜)
     * 
     * 성능:
     * - TreeMap 정렬: O(n log n)
     * - 스트림 연산: O(n)
     * - 전체: O(n log n)
     * 
     * 데이터 변환:
     * - 2730개 (7일 1분봉) → 546개 (7일 5분봉)
     * - 압축률: 약 1/5
     * 
     * @param oneMinData 1분봉 원본 데이터
     * @param timeframe  목표 타임프레임
     * @return List<StockData> 집계된 데이터
     */
    private List<StockData> aggregateByTimeframe(List<StockCandle1m> oneMinData, String timeframe) {
        // 1. 타임프레임 → 분 단위 변환
        int intervalMinutes = getIntervalMinutes(timeframe);
        log.debug("집계 간격: {}분", intervalMinutes);

        // 2. 시간대별 그룹핑 (TreeMap으로 자동 정렬)
        Map<LocalDateTime, List<StockCandle1m>> grouped = new TreeMap<>();

        for (StockCandle1m candle : oneMinData) {
            // 그룹 키 계산 (시간 정규화)
            LocalDateTime groupKey = calculateGroupKey(candle.getTimestamp(), intervalMinutes);
            grouped.computeIfAbsent(groupKey, k -> new ArrayList<>()).add(candle);
        }

        log.debug("그룹핑 완료: {}개 그룹", grouped.size());

        // 3. 각 그룹별 OHLCV 집계
        List<StockData> result = new ArrayList<>();

        for (Map.Entry<LocalDateTime, List<StockCandle1m>> entry : grouped.entrySet()) {
            LocalDateTime time = entry.getKey(); // 그룹 시간
            List<StockCandle1m> candles = entry.getValue(); // 그룹 내 캔들들

            // 빈 그룹 스킵
            if (candles.isEmpty()) {
                continue;
            }

            // 시간순 정렬 (안전성)
            candles.sort(Comparator.comparing(StockCandle1m::getTimestamp));

            // OHLCV 계산

            // Open: 첫 번째 캔들의 시가
            BigDecimal open = candles.get(0).getOpen();

            // Close: 마지막 캔들의 종가
            BigDecimal close = candles.get(candles.size() - 1).getClose();

            // High: 모든 캔들의 최고가
            BigDecimal high = candles.stream()
                    .map(StockCandle1m::getHigh)
                    .max(BigDecimal::compareTo)
                    .orElse(BigDecimal.ZERO);

            // Low: 모든 캔들의 최저가
            BigDecimal low = candles.stream()
                    .map(StockCandle1m::getLow)
                    .min(BigDecimal::compareTo)
                    .orElse(BigDecimal.ZERO);

            // Volume: 모든 거래량의 합
            Long volume = candles.stream()
                    .mapToLong(StockCandle1m::getVolume)
                    .sum();

            // StockData 빌드
            result.add(StockData.builder()
                    .date(Date.from(time.atZone(ZoneId.systemDefault()).toInstant()))
                    .open(open)
                    .high(high)
                    .low(low)
                    .close(close)
                    .volume(volume)
                    .build());
        }

        log.debug("집계 결과: {}개 → {}개", oneMinData.size(), result.size());

        return result;
    }

    /**
     * 그룹 키 계산 (시간대별 그룹핑)
     * 
     * 기능:
     * - 개별 캔들의 timestamp를 그룹 키로 정규화
     * - 타임프레임에 따라 다른 정규화 규칙 적용
     * 
     * 정규화 규칙:
     * 
     * 1. 일봉 (1440분 이상):
     * - 00:00:00으로 정규화
     * - 예: 2025-12-21 09:31:00 → 2025-12-21 00:00:00
     * 
     * 2. 시간봉 (60분 이상):
     * - 시간 단위로 반올림
     * - 예: 09:31 (1h) → 09:00
     * - 예: 09:31 (4h) → 08:00 (4시간 단위)
     * 
     * 3. 분봉 (60분 미만):
     * - 분 단위로 반올림
     * - 예: 09:32 (5m) → 09:30
     * - 예: 09:47 (15m) → 09:45
     * 
     * 계산 예시 (5분봉):
     * - 09:30 → 09:30 (30 / 5 * 5 = 30)
     * - 09:31 → 09:30 (31 / 5 * 5 = 30)
     * - 09:34 → 09:30 (34 / 5 * 5 = 30)
     * - 09:35 → 09:35 (35 / 5 * 5 = 35)
     * 
     * 계산 예시 (4시간봉):
     * - 09:00 → 08:00 (9 / 4 * 4 = 8)
     * - 11:00 → 08:00 (11 / 4 * 4 = 8)
     * - 12:00 → 12:00 (12 / 4 * 4 = 12)
     * 
     * truncatedTo(ChronoUnit.HOURS):
     * - 분, 초, 나노초를 0으로 설정
     * - 예: 09:31:45.123 → 09:00:00.000
     * 
     * @param time            원본 timestamp
     * @param intervalMinutes 집계 간격 (분 단위)
     * @return LocalDateTime 정규화된 그룹 키
     */
    private LocalDateTime calculateGroupKey(LocalDateTime time, int intervalMinutes) {
        if (intervalMinutes >= 1440) {
            // 일봉 (1d 이상)
            // 날짜만 남기고 시각은 00:00
            return time.toLocalDate().atTime(0, 0);

        } else if (intervalMinutes >= 60) {
            // 시간봉 (1h, 4h)
            int hour = time.getHour();
            // 시간 단위 반올림
            int roundedHour = (hour / (intervalMinutes / 60)) * (intervalMinutes / 60);
            return time.toLocalDate().atTime(roundedHour, 0);

        } else {
            // 분봉 (5m, 15m)
            int minute = time.getMinute();
            // 분 단위 반올림
            int roundedMinute = (minute / intervalMinutes) * intervalMinutes;
            // 시간은 그대로, 분만 정규화
            return time.truncatedTo(ChronoUnit.HOURS).plusMinutes(roundedMinute);
        }
    }

    /**
     * 타임프레임 문자열을 분 단위로 변환
     * 
     * 기능:
     * - 타임프레임 약자 → 분 단위 숫자 변환
     * - aggregateByTimeframe()에서 사용
     * 
     * 지원 타임프레임:
     * - 1m: 1분
     * - 5m: 5분
     * - 15m: 15분
     * - 1h: 60분 (1시간)
     * - 4h: 240분 (4시간)
     * - 1d: 1440분 (24시간, 1일)
     * 
     * Switch Expression:
     * - Java 14+ 문법
     * - yield로 값 반환
     * 
     * 기본값:
     * - 알 수 없는 타임프레임: 1분 (1m)
     * - 경고 로그 출력
     * 
     * 확장성:
     * - 새 타임프레임 추가 용이
     * - 예: "30m" → 30, "1w" → 10080
     * 
     * @param timeframe 타임프레임 문자열
     * @return int 분 단위 간격
     */
    private int getIntervalMinutes(String timeframe) {
        return switch (timeframe) {
            case "1m" -> 1;
            case "5m" -> 5;
            case "15m" -> 15;
            case "1h" -> 60;
            case "4h" -> 240;
            case "1d" -> 1440;
            default -> {
                log.warn("알 수 없는 타임프레임: {} (기본값 1분 사용)", timeframe);
                yield 1; // 기본값
            }
        };
    }

    /**
     * StockCandle1m 엔티티를 StockData DTO로 변환
     * 
     * 기능:
     * - JPA 엔티티 → API 응답용 DTO 변환
     * - 불필요한 필드 제거 (id, symbol, createdAt)
     * - LocalDateTime → Date 변환
     * 
     * 변환 항목:
     * - timestamp → date (LocalDateTime → Date)
     * - OHLCV 그대로 복사
     * 
     * Stream API 사용:
     * - map(): 각 엔티티를 DTO로 변환
     * - collect(): List로 수집
     * 
     * 함수형 프로그래밍:
     * - 불변성 유지
     * - 사이드 이펙트 없음
     * - 테스트 용이
     * 
     * 성능:
     * - 단순 복사 연산: O(n)
     * - 2730개 변환: ~1ms
     * 
     * @param candles StockCandle1m 리스트
     * @return List<StockData> DTO 리스트
     */
    private List<StockData> convertToStockData(List<StockCandle1m> candles) {
        return candles.stream()
                .map(candle -> StockData.builder()
                        // LocalDateTime → Date 변환
                        .date(Date.from(candle.getTimestamp()
                                .atZone(ZoneId.systemDefault())
                                .toInstant()))
                        .open(candle.getOpen())
                        .high(candle.getHigh())
                        .low(candle.getLow())
                        .close(candle.getClose())
                        .volume(candle.getVolume())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * 이동평균선 (MA - Moving Average) 계산
     * 
     * 기능:
     * - 지정된 기간(period)의 종가 평균 계산
     * - 추세 분석 및 지지/저항선 파악
     * 
     * 계산 방법 (SMA - Simple Moving Average):
     * - MA(n) = (Close[0] + Close[1] + ... + Close[n-1]) / n
     * 
     * 예시 (MA5):
     * - 데이터: [100, 102, 101, 103, 105, 104, 106]
     * - MA5 계산:
     * [0~3]: null (데이터 부족)
     * [4]: (100+102+101+103+105) / 5 = 102.2
     * [5]: (102+101+103+105+104) / 5 = 103.0
     * [6]: (101+103+105+104+106) / 5 = 103.8
     * 
     * null 처리:
     * - 초기 (period-1)개는 null
     * - 데이터 부족으로 계산 불가
     * - 차트에서 선 시작 지점 결정
     * 
     * 지원 기간:
     * - MA5: 5일 이동평균 (단기)
     * - MA20: 20일 이동평균 (중기)
     * - MA50: 50일 이동평균 (장기)
     * - MA200: 200일 이동평균 (초장기)
     * 
     * 활용:
     * - 골든크로스: MA5 > MA20 (매수 신호)
     * - 데드크로스: MA5 < MA20 (매도 신호)
     * - 지지선/저항선
     * 
     * 성능:
     * - O(n × period)
     * - 2730개 × 20 = 54,600 연산
     * - ~1-2ms
     * 
     * 개선 방안:
     * - EMA (Exponential MA): 가중 평균
     * - 슬라이딩 윈도우: 중복 계산 제거
     * 
     * @param data   주가 데이터 (StockData 리스트)
     * @param period 이동평균 기간 (일수)
     * @return List<BigDecimal> 이동평균선 값들 (null 포함)
     */
    public List<BigDecimal> calculateMA(List<StockData> data, int period) {
        List<BigDecimal> ma = new ArrayList<>();

        // 각 데이터 포인트에 대해 MA 계산
        for (int i = 0; i < data.size(); i++) {
            // 데이터 부족 체크
            if (i < period - 1) {
                ma.add(null); // 계산 불가
                continue;
            }

            // period개의 종가 합산
            BigDecimal sum = BigDecimal.ZERO;
            for (int j = 0; j < period; j++) {
                sum = sum.add(data.get(i - j).getClose());
            }

            // 평균 계산 (소수점 2자리)
            BigDecimal average = sum.divide(
                    BigDecimal.valueOf(period),
                    2, // 소수점 2자리
                    RoundingMode.HALF_UP); // 반올림

            ma.add(average);
        }

        return ma;
    }

    /**
     * RSI (Relative Strength Index) 계산
     * 
     * 기능:
     * - 상대강도지수 계산 (0~100 범위)
     * - 과매수/과매도 판단 지표
     * 
     * 계산 방법:
     * 1. 가격 변동 계산 (현재 종가 - 이전 종가)
     * 2. 상승분(gains)과 하락분(losses) 분리
     * 3. 평균 상승분, 평균 하락분 계산
     * 4. RS = 평균 상승분 / 평균 하락분
     * 5. RSI = 100 - (100 / (1 + RS))
     * 
     * 예시 (RSI 14):
     * - 데이터: 가격 변동 [+2, -1, +3, -2, +1, ...]
     * - Gains: [2, 0, 3, 0, 1, ...]
     * - Losses: [0, 1, 0, 2, 0, ...]
     * - Avg Gain (14일): 1.5
     * - Avg Loss (14일): 0.8
     * - RS: 1.5 / 0.8 = 1.875
     * - RSI: 100 - (100 / (1 + 1.875)) = 65.22
     * 
     * 해석:
     * - RSI > 70: 과매수 (Overbought) - 매도 고려
     * - RSI < 30: 과매도 (Oversold) - 매수 고려
     * - RSI 50: 중립
     * 
     * 특수 케이스:
     * - 평균 하락분 = 0: RSI = 100 (모두 상승)
     * - 평균 상승분 = 0: RSI = 0 (모두 하락)
     * 
     * null 처리:
     * - 초기 (period)개는 null
     * - 변동 계산을 위해 period+1개 데이터 필요
     * 
     * 표준 기간:
     * - RSI(14): 14일 기준 (가장 일반적)
     * - RSI(7): 단기
     * - RSI(21): 장기
     * 
     * 활용:
     * - 다이버전스: 가격과 RSI 방향 불일치 (반전 신호)
     * - 범위 돌파: RSI가 50 돌파 (추세 전환)
     * 
     * 성능:
     * - O(n × period)
     * - 2730개 × 14 = 38,220 연산
     * - ~1-2ms
     * 
     * @param data   주가 데이터
     * @param period RSI 계산 기간 (일반적으로 14)
     * @return List<BigDecimal> RSI 값들 (0~100, null 포함)
     */
    public List<BigDecimal> calculateRSI(List<StockData> data, int period) {
        List<BigDecimal> rsi = new ArrayList<>();

        // 데이터 부족 체크
        if (data.size() < period + 1) {
            log.warn("RSI 계산 불가: 데이터 부족 (필요: {}개, 실제: {}개)", period + 1, data.size());
            return rsi;
        }

        // 1. 가격 변동 계산
        List<BigDecimal> gains = new ArrayList<>(); // 상승분
        List<BigDecimal> losses = new ArrayList<>(); // 하락분

        for (int i = 1; i < data.size(); i++) {
            // 변동 = 현재 종가 - 이전 종가
            BigDecimal change = data.get(i).getClose()
                    .subtract(data.get(i - 1).getClose());

            // 상승분: max(change, 0)
            gains.add(change.max(BigDecimal.ZERO));

            // 하락분: abs(min(change, 0))
            losses.add(change.min(BigDecimal.ZERO).abs());
        }

        // 2. RSI 계산
        for (int i = 0; i < gains.size(); i++) {
            // 데이터 부족 체크
            if (i < period - 1) {
                rsi.add(null);
                continue;
            }

            // 평균 상승분 계산
            BigDecimal avgGain = BigDecimal.ZERO;
            BigDecimal avgLoss = BigDecimal.ZERO;

            for (int j = 0; j < period; j++) {
                avgGain = avgGain.add(gains.get(i - j));
                avgLoss = avgLoss.add(losses.get(i - j));
            }

            avgGain = avgGain.divide(
                    BigDecimal.valueOf(period),
                    4, // 소수점 4자리
                    RoundingMode.HALF_UP);

            avgLoss = avgLoss.divide(
                    BigDecimal.valueOf(period),
                    4,
                    RoundingMode.HALF_UP);

            // RSI 계산
            if (avgLoss.compareTo(BigDecimal.ZERO) == 0) {
                // 모두 상승: RSI = 100
                rsi.add(BigDecimal.valueOf(100));
            } else {
                // RS = 평균 상승 / 평균 하락
                BigDecimal rs = avgGain.divide(avgLoss, 4, RoundingMode.HALF_UP);

                // RSI = 100 - (100 / (1 + RS))
                BigDecimal rsiValue = BigDecimal.valueOf(100).subtract(
                        BigDecimal.valueOf(100).divide(
                                BigDecimal.ONE.add(rs),
                                2, // 소수점 2자리
                                RoundingMode.HALF_UP));

                rsi.add(rsiValue);
            }
        }

        return rsi;
    }

    /**
     * 전체 과거 데이터 조회 (days 제한 없음)
     * 
     * 기능:
     * - MySQL에 저장된 모든 1분봉 데이터 조회
     * - 데이터 누적에 따라 자동으로 증가
     * - 장기 추세 분석 및 백테스팅용
     * 
     * getHistoricalData()와의 차이:
     * - getHistoricalData(): days 제한 있음 (성능 보호)
     * - getAllHistoricalData(): 전체 조회 (무제한)
     * 
     * 동작 과정:
     * 1. findBySymbolOrderByTimestampAsc() 호출
     * 2. 전체 데이터 조회 (WHERE symbol = ?)
     * 3. 데이터 범위 로깅 (첫 시각 ~ 마지막 시각)
     * 4. 타임프레임 집계 (필요 시)
     * 5. 반환
     * 
     * 데이터 양 예상:
     * - 1개월 수집: ~11,700개
     * - 3개월 수집: ~35,100개
     * - 1년 수집: ~97,500개
     * 
     * 성능 고려사항:
     * - ⚠️ 대량 데이터 조회: 메모리 사용량 증가
     * - ⚠️ 집계 연산: CPU 집약적
     * - ⚠️ JSON 직렬화: 네트워크 부담
     * 
     * 권장 사항:
     * - 프론트엔드에서 줌/팬 기능 구현
     * - 일부 데이터만 렌더링
     * - WebWorker로 백그라운드 처리
     * 
     * 최적화 방안:
     * 1. 페이징: Pageable 파라미터 추가
     * 2. 캐싱: @Cacheable 적용
     * 3. 압축: gzip 응답
     * 4. 스트리밍: Server-Sent Events
     * 
     * 사용 위치:
     * - StockController.getAllChartData()
     * - API: /stock/api/chart/{symbol}/all
     * - 백테스팅 시스템
     * - 데이터 분석 툴
     * 
     * 로그 출력:
     * AAPL - 전체 데이터 조회 시작 (타임프레임: 1m)
     * AAPL - MySQL 조회 결과: 35100개 (전체)
     * AAPL - 데이터 범위: 2025-09-21T09:30:00 ~ 2025-12-21T16:00:00
     * AAPL - 1분봉 반환: 35100개
     * 
     * @param symbol    종목 심볼
     * @param timeframe 타임프레임 (1m, 5m, 1h, 1d 등)
     * @return List<StockData> 전체 차트 데이터
     */
    public List<StockData> getAllHistoricalData(String symbol, String timeframe) {
        log.info("{} - 전체 데이터 조회 시작 (타임프레임: {})", symbol, timeframe);

        // 1. MySQL에서 전체 데이터 조회 (days 제한 없음)
        List<StockCandle1m> oneMinData = candleRepository
                .findBySymbolOrderByTimestampAsc(symbol);

        log.info("{} - MySQL 조회 결과: {}개 (전체)", symbol, oneMinData.size());

        // 2. 데이터 없음 체크
        if (oneMinData.isEmpty()) {
            log.warn("{} - 조회된 데이터 없음! (historical_loader.py 실행 필요)", symbol);
            return Collections.emptyList();
        }

        // 3. 데이터 범위 로그 (디버깅 및 모니터링)
        LocalDateTime firstTime = oneMinData.get(0).getTimestamp();
        LocalDateTime lastTime = oneMinData.get(oneMinData.size() - 1).getTimestamp();
        log.info("{} - 데이터 범위: {} ~ {}", symbol, firstTime, lastTime);

        // 4. 1분봉이면 변환 후 바로 반환
        if ("1m".equals(timeframe)) {
            List<StockData> result = convertToStockData(oneMinData);
            log.info("{} - 1분봉 반환: {}개", symbol, result.size());
            return result;
        }

        // 5. 타임프레임 집계 (5m, 1h, 1d 등)
        List<StockData> aggregated = aggregateByTimeframe(oneMinData, timeframe);
        log.info("{} - {}봉 집계 완료: {}개 (원본: {}개)",
                symbol, timeframe, aggregated.size(), oneMinData.size());

        return aggregated;
    }

    // ========================================
    // 향후 추가 가능한 기술지표 (TODO)
    // ========================================

    /**
     * TODO: MACD (Moving Average Convergence Divergence)
     * 
     * public Map<String, List<BigDecimal>> calculateMACD(List<StockData> data) {
     * // EMA(12) - EMA(26)
     * // Signal Line: EMA(9) of MACD
     * // Histogram: MACD - Signal
     * }
     */

    /**
     * TODO: 볼린저 밴드 (Bollinger Bands)
     * 
     * public Map<String, List<BigDecimal>> calculateBollingerBands(
     * List<StockData> data, int period, double stdDev) {
     * // Upper Band: MA + (stdDev × σ)
     * // Middle Band: MA
     * // Lower Band: MA - (stdDev × σ)
     * }
     */

    /**
     * TODO: 스토캐스틱 (Stochastic Oscillator)
     * 
     * public Map<String, List<BigDecimal>> calculateStochastic(
     * List<StockData> data, int period) {
     * // %K = (Close - Low) / (High - Low) × 100
     * // %D = MA(%K, 3)
     * }
     */

    /**
     * TODO: ATR (Average True Range) - 변동성 지표
     * 
     * public List<BigDecimal> calculateATR(List<StockData> data, int period) {
     * // TR = max(High-Low, |High-PrevClose|, |Low-PrevClose|)
     * // ATR = MA(TR, period)
     * }
     */
}