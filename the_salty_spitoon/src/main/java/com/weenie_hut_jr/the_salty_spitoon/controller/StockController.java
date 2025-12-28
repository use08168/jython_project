package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.model.Stock;
import com.weenie_hut_jr.the_salty_spitoon.model.StockData;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockRepository;
import com.weenie_hut_jr.the_salty_spitoon.service.StockService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;

/**
 * 주식 데이터 컨트롤러
 * 
 * 역할:
 * - NASDAQ 100 종목의 실시간 주가 및 차트 데이터 제공
 * - 대시보드 및 상세 차트 페이지 렌더링
 * - RESTful API를 통한 실시간 데이터 스트리밍
 * 
 * 주요 기능:
 * 1. 대시보드: NASDAQ 100 전체 종목 실시간 모니터링
 * 2. 상세 차트: 개별 종목의 과거 데이터 시각화
 * 3. 기술지표: 이동평균선(MA), RSI 등 자동 계산
 * 
 * 페이지 라우팅:
 * - GET /stock : 대시보드 (NASDAQ 100 전체 종목)
 * - GET /stock/detail/{symbol} : 종목 상세 차트 페이지
 * 
 * API 엔드포인트:
 * - GET /stock/api/dashboard : 대시보드용 전체 종목 실시간 데이터
 * - GET /stock/api/realtime/{symbol}: 특정 종목 실시간 데이터
 * - GET /stock/api/chart/{symbol} : 차트 데이터 (일수 제한 있음, 레거시)
 * - GET /stock/api/chart/{symbol}/all: 전체 차트 데이터 (무제한)
 * 
 * 데이터 흐름:
 * 1. Python → MySQL: stock_collector.py가 1분마다 데이터 수집
 * 2. MySQL → Spring: Repository를 통해 데이터 조회
 * 3. Spring → Client: REST API 또는 JSP로 데이터 전달
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j // 로깅 기능 활성화
@Controller // Spring MVC Controller
@RequestMapping("/stock") // 기본 경로: /stock
@RequiredArgsConstructor // final 필드 생성자 주입
public class StockController {

    // 의존성 주입
    private final StockService stockService; // 주식 비즈니스 로직 처리
    private final StockRepository stockRepository; // 종목 정보 DB 조회

    /**
     * 대시보드 페이지 렌더링 (NASDAQ 100 종목 목록)
     * 
     * 기능:
     * - 활성화된 NASDAQ 100 종목 전체 조회
     * - JSP로 종목 리스트 전달
     * - 각 종목의 실시간 데이터는 프론트엔드에서 AJAX로 요청
     * 
     * 동작:
     * 1. stocks 테이블에서 is_active = true인 종목 조회
     * 2. 종목 개수 확인 (최대 100개)
     * 3. Model에 데이터 바인딩
     * 4. stock/dashboard.jsp 렌더링
     * 
     * URL: GET /stock
     * View: stock/dashboard.jsp
     * 
     * Model Attributes:
     * - stocks: List<Stock> - 활성 종목 리스트
     * - totalStocks: int - 총 종목 개수
     * 
     * @param model Spring MVC Model 객체
     * @return JSP 뷰 이름 또는 에러 페이지
     */
    @GetMapping("")
    public String showDashboard(Model model) {
        log.info("대시보드 페이지 요청");

        try {
            // 활성 종목 목록 조회 (is_active = true)
            List<Stock> activeStocks = stockRepository.findByIsActiveTrue();

            // null 체크 (안전성)
            if (activeStocks == null) {
                activeStocks = new ArrayList<>();
                log.warn("findByIsActiveTrue returned null");
            }

            log.info("활성 종목 {}개 조회 (NASDAQ 100)", activeStocks.size());

            // JSP로 데이터 전달
            model.addAttribute("stocks", activeStocks);
            model.addAttribute("totalStocks", activeStocks.size());

            return "stock/dashboard"; // stock/dashboard.jsp

        } catch (Exception e) {
            log.error("대시보드 페이지 로드 실패", e);
            model.addAttribute("error", "대시보드를 불러올 수 없습니다: " + e.getMessage());
            return "error/500"; // 500 에러 페이지
        }
    }

    /**
     * 종목 상세 차트 페이지 렌더링
     * 
     * 기능:
     * - 특정 종목의 차트 페이지 제공
     * - 종목 존재 여부 및 활성 상태 검증
     * - 차트 데이터는 프론트엔드에서 /api/chart/{symbol}/all로 요청
     * 
     * 동작:
     * 1. URL 경로에서 심볼 추출 (예: /stock/detail/AAPL)
     * 2. stocks 테이블에서 종목 존재 확인
     * 3. is_active 상태 체크
     * 4. 종목 정보를 JSP로 전달
     * 
     * URL: GET /stock/detail/{symbol}
     * View: stock/detail.jsp
     * 
     * 경로 변수:
     * 
     * @param symbol 종목 심볼 (예: AAPL, GOOGL, TSLA)
     * 
     *               Model Attributes:
     *               - stock: Stock 객체 (전체 정보)
     *               - symbol: String (종목 코드)
     *               - name: String (회사명)
     * 
     *               에러 처리:
     *               - 404: 종목이 DB에 없음
     *               - inactive: 비활성화된 종목
     * 
     * @param symbol 종목 심볼 (대소문자 구분 없음)
     * @param model  Spring MVC Model
     * @return JSP 뷰 이름 또는 에러 페이지
     */
    @GetMapping("/detail/{symbol}")
    public String showDetailChart(@PathVariable String symbol, Model model) {
        log.info("종목 상세 페이지 요청: {}", symbol);

        // 1. stocks 테이블에서 종목 존재 확인
        Optional<Stock> stockOpt = stockRepository.findById(symbol.toUpperCase());

        if (stockOpt.isEmpty()) {
            log.warn("존재하지 않는 종목: {}", symbol);
            model.addAttribute("error", "종목을 찾을 수 없습니다: " + symbol);
            return "error/404"; // 404 에러 페이지
        }

        Stock stock = stockOpt.get();

        // 2. 비활성 종목 체크 (is_active = false)
        if (!stock.getIsActive()) {
            log.warn("비활성 종목 접근: {}", symbol);
            model.addAttribute("message", "현재 이 종목은 서비스되지 않습니다.");
            return "error/inactive"; // 비활성 종목 안내 페이지
        }

        // 3. JSP에 종목 정보 전달
        model.addAttribute("stock", stock);
        model.addAttribute("symbol", stock.getSymbol());
        model.addAttribute("name", stock.getName());

        log.info("종목 상세 페이지 로드: {} ({})", stock.getSymbol(), stock.getName());

        return "stock/detail"; // stock/detail.jsp
    }

    /**
     * 대시보드용 실시간 데이터 API (NASDAQ 100 전체 종목)
     * 
     * 기능:
     * - NASDAQ 100 모든 종목의 실시간 주가 정보 반환
     * - 대시보드 페이지의 AJAX 요청에 응답
     * - 각 종목의 현재가, 등락폭, 등락률 제공
     * 
     * 동작:
     * 1. is_active = true인 모든 종목 조회
     * 2. 각 종목의 실시간 데이터를 StockService에서 가져옴
     * 3. 에러 발생 시에도 기본 정보는 제공 (fallback)
     * 4. 성공/실패 카운트 로깅
     * 
     * URL: GET /stock/api/dashboard
     * Method: GET
     * Response Type: JSON Array
     * 
     * 응답 예시:
     * [
     * {
     * "symbol": "AAPL",
     * "name": "Apple Inc.",
     * "price": 273.67,
     * "change": 1.48,
     * "changePercent": 0.54,
     * "error": false
     * },
     * {
     * "symbol": "GOOGL",
     * "name": "Alphabet Inc Class A",
     * "price": 182.35,
     * "change": -0.82,
     * "changePercent": -0.45,
     * "error": false
     * }
     * ]
     * 
     * 에러 처리:
     * - 개별 종목 조회 실패 시 error: true로 표시
     * - 전체 API는 실패하지 않고 가능한 데이터 반환
     * 
     * @return List<Map> 전체 종목의 실시간 데이터 배열
     */
    @GetMapping("/api/dashboard")
    @ResponseBody // JSON 응답
    public List<Map<String, Object>> getDashboardData() {
        log.info("대시보드 API 요청 (NASDAQ 100)");

        // 활성 종목 조회
        List<Stock> activeStocks = stockRepository.findByIsActiveTrue();
        List<Map<String, Object>> result = new ArrayList<>();

        // 통계 변수
        int successCount = 0;
        int errorCount = 0;

        // 각 종목의 실시간 데이터 조회
        for (Stock stock : activeStocks) {
            try {
                // StockService를 통해 실시간 데이터 조회
                Map<String, Object> stockData = stockService.getRealTimeStock(stock.getSymbol());
                stockData.put("name", stock.getName()); // 회사명 추가
                stockData.put("logoUrl", stock.getLogoUrl()); // 로고 URL 추가
                result.add(stockData);

                // 성공/실패 카운트
                if (!stockData.containsKey("error") || !(Boolean) stockData.get("error")) {
                    successCount++;
                } else {
                    errorCount++;
                }

            } catch (Exception e) {
                log.error("{} - 실시간 데이터 조회 실패", stock.getSymbol(), e);
                errorCount++;

                // 실패해도 기본 정보는 제공 (fallback)
                Map<String, Object> fallback = new HashMap<>();
                fallback.put("symbol", stock.getSymbol());
                fallback.put("name", stock.getName());
                fallback.put("price", BigDecimal.ZERO);
                fallback.put("change", BigDecimal.ZERO);
                fallback.put("changePercent", BigDecimal.ZERO);
                fallback.put("error", true);
                fallback.put("message", "Data unavailable");
                result.add(fallback);
            }
        }

        log.info("대시보드 데이터 응답: 총 {}개 (성공: {}, 에러: {})",
                result.size(), successCount, errorCount);

        return result;
    }

    /**
     * 실시간 주식 데이터 조회 API (단일 종목)
     * 
     * 기능:
     * - 특정 종목의 현재 주가 정보 제공
     * - WebSocket 업데이트 외 추가 조회가 필요한 경우 사용
     * 
     * 동작:
     * 1. 종목 심볼을 대문자로 변환
     * 2. StockService.getRealTimeStock() 호출
     * 3. stock_candle_1m 테이블에서 최신 데이터 반환
     * 
     * URL: GET /stock/api/realtime/{symbol}
     * Method: GET
     * Response Type: JSON Object
     * 
     * 경로 변수:
     * 
     * @param symbol 종목 심볼 (예: aapl, GOOGL, tsla)
     * 
     *               응답 예시 (성공):
     *               {
     *               "symbol": "AAPL",
     *               "price": 273.67,
     *               "change": 1.48,
     *               "changePercent": 0.54,
     *               "volume": 45123000,
     *               "timestamp": "2025-12-21T15:30:00"
     *               }
     * 
     *               응답 예시 (실패):
     *               {
     *               "error": true,
     *               "message": "No data available",
     *               "symbol": "AAPL",
     *               "price": 0,
     *               "change": 0,
     *               "changePercent": 0
     *               }
     * 
     * @param symbol 조회할 종목 심볼
     * @return Map 실시간 주가 데이터
     */
    @GetMapping("/api/realtime/{symbol}")
    @ResponseBody // JSON 응답
    public Map<String, Object> getRealTimeData(@PathVariable String symbol) {
        log.info("실시간 데이터 요청: {}", symbol);

        try {
            // 대문자 변환 후 조회
            return stockService.getRealTimeStock(symbol.toUpperCase());

        } catch (Exception e) {
            log.error("실시간 데이터 조회 실패: {}", symbol, e);

            // 에러 응답 구성
            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", e.getMessage());
            error.put("symbol", symbol);
            error.put("price", BigDecimal.ZERO);
            error.put("change", BigDecimal.ZERO);
            error.put("changePercent", BigDecimal.ZERO);
            return error;
        }
    }

    /**
     * 차트 데이터 + 기술지표 조회 API (레거시)
     * 
     * ⚠️ 주의: 이 API는 레거시 지원용입니다.
     * 신규 개발 시에는 /api/chart/{symbol}/all 사용을 권장합니다.
     * 
     * 기능:
     * - 지정된 기간(days)의 과거 데이터 조회
     * - 이동평균선, RSI 등 기술지표 계산
     * 
     * 동작:
     * 1. days 파라미터로 조회 기간 제한
     * 2. stock_candle_1m 테이블에서 데이터 조회
     * 3. 요청된 기술지표 계산
     * 
     * URL: GET /stock/api/chart/{symbol}
     * Method: GET
     * Response Type: JSON Object
     * 
     * 경로 변수:
     * 
     * @param symbol     종목 심볼
     * 
     *                   쿼리 파라미터:
     * @param timeframe  타임프레임 (기본값: 1m)
     * @param days       조회 일수 (기본값: 7)
     * @param indicators 기술지표 (예: MA5,MA20,RSI)
     * 
     *                   응답 예시:
     *                   {
     *                   "symbol": "AAPL",
     *                   "timeframe": "1m",
     *                   "data": [
     *                   { "timestamp": "2025-12-21T09:30:00", "open": 273.00,
     *                   "high": 273.50, ... },
     *                   ...
     *                   ],
     *                   "indicators": {
     *                   "MA5": [null, null, null, null, 273.20, 273.35, ...],
     *                   "MA20": [null, ..., 272.80, 272.90, ...],
     *                   "RSI": [null, ..., 55.3, 56.1, ...]
     *                   }
     *                   }
     * 
     *                   제한사항:
     *                   - days 파라미터로 데이터 양 제한
     *                   - 장기 분석에는 부적합
     * 
     * @return Map 차트 데이터와 기술지표
     */
    @GetMapping("/api/chart/{symbol}")
    @ResponseBody
    public Map<String, Object> getChartData(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "1m") String timeframe,
            @RequestParam(defaultValue = "7") int days,
            @RequestParam(required = false) String indicators) {

        log.info("차트 데이터 요청 (레거시): {} (타임프레임: {}, 일수: {}, 지표: {})",
                symbol, timeframe, days, indicators);

        try {
            // 1. 과거 데이터 조회 (days 제한)
            List<StockData> historicalData = stockService.getHistoricalData(
                    symbol.toUpperCase(), timeframe, days);

            Map<String, Object> response = new HashMap<>();
            response.put("symbol", symbol.toUpperCase());
            response.put("timeframe", timeframe);
            response.put("data", historicalData);

            // 2. 기술지표 계산
            if (indicators != null && !indicators.isEmpty()) {
                String[] indicatorList = indicators.split(",");
                Map<String, Object> technicalIndicators = new HashMap<>();

                for (String indicator : indicatorList) {
                    switch (indicator.trim().toUpperCase()) {
                        case "MA5":
                            // 5일 이동평균선 계산
                            technicalIndicators.put("MA5", stockService.calculateMA(historicalData, 5));
                            break;
                        case "MA20":
                            // 20일 이동평균선 계산
                            technicalIndicators.put("MA20", stockService.calculateMA(historicalData, 20));
                            break;
                        case "MA50":
                            // 50일 이동평균선 계산
                            technicalIndicators.put("MA50", stockService.calculateMA(historicalData, 50));
                            break;
                        case "MA200":
                            // 200일 이동평균선 계산
                            technicalIndicators.put("MA200", stockService.calculateMA(historicalData, 200));
                            break;
                        case "RSI":
                            // RSI(14) 계산
                            technicalIndicators.put("RSI", stockService.calculateRSI(historicalData, 14));
                            break;
                    }
                }

                response.put("indicators", technicalIndicators);
            }

            log.info("차트 데이터 응답: {} ({}개)", symbol, historicalData.size());
            return response;

        } catch (Exception e) {
            log.error("차트 데이터 조회 실패: {}", symbol, e);

            // 에러 응답
            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", e.getMessage());
            error.put("data", Collections.emptyList());
            return error;
        }
    }

    /**
     * 전체 차트 데이터 조회 API (무제한)
     * 
     * ✅ 권장: 신규 개발 시 이 API 사용
     * 
     * 기능:
     * - MySQL에 저장된 모든 과거 데이터 반환
     * - 데이터가 쌓일수록 자동으로 더 많은 데이터 제공
     * - NASDAQ 100 모든 종목 지원
     * - 기술지표 자동 계산
     * 
     * 동작:
     * 1. stock_candle_1m 테이블에서 전체 데이터 조회 (days 제한 없음)
     * 2. timestamp 오름차순 정렬
     * 3. 요청된 기술지표 계산
     * 4. 데이터 개수 및 지표 개수 로깅
     * 
     * URL: GET /stock/api/chart/{symbol}/all
     * Method: GET
     * Response Type: JSON Object
     * 
     * 경로 변수:
     * 
     * @param symbol     종목 심볼 (예: AAPL, GOOGL, META, TSLA, ...)
     * 
     *                   쿼리 파라미터:
     * @param timeframe  타임프레임 (기본값: 1m)
     *                   - 1m: 1분봉
     *                   - 5m: 5분봉
     *                   - 15m: 15분봉
     *                   - 1h: 1시간봉
     *                   - 4h: 4시간봉
     *                   - 1d: 일봉
     * 
     * @param indicators 기술지표 (쉼표로 구분)
     *                   - MA5, MA20, MA50, MA200: 이동평균선
     *                   - RSI: 상대강도지수 (14일 기준)
     *                   예: "MA5,MA20,RSI"
     * 
     *                   응답 예시 (성공):
     *                   {
     *                   "success": true,
     *                   "symbol": "AAPL",
     *                   "timeframe": "1m",
     *                   "data": [
     *                   {
     *                   "timestamp": "2025-12-21T09:30:00",
     *                   "open": 273.00,
     *                   "high": 273.50,
     *                   "low": 272.80,
     *                   "close": 273.20,
     *                   "volume": 1234567
     *                   },
     *                   ...
     *                   ],
     *                   "indicators": {
     *                   "MA5": [null, null, null, null, 273.20, 273.35, ...],
     *                   "MA20": [null, ..., 272.80, 272.90, ...],
     *                   "RSI": [null, ..., 55.3, 56.1, ...]
     *                   }
     *                   }
     * 
     *                   응답 예시 (데이터 없음):
     *                   {
     *                   "success": false,
     *                   "message": "No data available for AAPL",
     *                   "data": [],
     *                   "indicators": {}
     *                   }
     * 
     *                   응답 예시 (에러):
     *                   {
     *                   "success": false,
     *                   "error": "Database connection failed",
     *                   "data": [],
     *                   "indicators": {}
     *                   }
     * 
     *                   확장성:
     *                   - 데이터 수집이 계속되면 자동으로 더 많은 데이터 제공
     *                   - 프론트엔드에서 줌/팬 기능 구현 가능
     *                   - 장기 추세 분석 가능
     * 
     *                   성능:
     *                   - 인덱스: (symbol, timestamp) 복합 인덱스 사용
     *                   - 대용량 데이터 처리 가능
     *                   - 필요 시 페이징 추가 가능
     * 
     * @return Map 전체 차트 데이터와 기술지표
     */
    @GetMapping("/api/chart/{symbol}/all")
    @ResponseBody
    public Map<String, Object> getAllChartData(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "1m") String timeframe,
            @RequestParam(required = false) String indicators) {

        log.info("전체 차트 데이터 요청: symbol={}, timeframe={}, indicators={}",
                symbol, timeframe, indicators);

        Map<String, Object> response = new HashMap<>();

        try {
            // 전체 데이터 조회 (days 제한 없음)
            List<StockData> data = stockService.getAllHistoricalData(symbol.toUpperCase(), timeframe);

            log.info("전체 차트 데이터 조회 완료: {}개", data.size());

            // 데이터 없음 체크
            if (data.isEmpty()) {
                log.warn("데이터 없음: symbol={}", symbol);
                response.put("success", false);
                response.put("message", "No data available for " + symbol);
                response.put("data", Collections.emptyList());
                response.put("indicators", Collections.emptyMap());
                return response;
            }

            response.put("data", data);

            // 기술지표 계산
            Map<String, List<BigDecimal>> indicatorData = new HashMap<>();

            if (indicators != null && !indicators.isEmpty()) {
                String[] indicatorList = indicators.split(",");

                for (String indicator : indicatorList) {
                    indicator = indicator.trim();

                    try {
                        if (indicator.startsWith("MA")) {
                            // 이동평균선 계산 (MA5, MA20, MA50, MA200)
                            int period = Integer.parseInt(indicator.substring(2));
                            indicatorData.put(indicator, stockService.calculateMA(data, period));
                            log.debug("{}:{} 계산 완료", symbol, indicator);

                        } else if (indicator.equalsIgnoreCase("RSI")) {
                            // RSI 계산 (14일 기준)
                            indicatorData.put("RSI", stockService.calculateRSI(data, 14));
                            log.debug("{}:RSI 계산 완료", symbol);
                        }

                    } catch (Exception e) {
                        log.warn("지표 계산 실패: {}, 에러: {}", indicator, e.getMessage());
                    }
                }
            }

            response.put("indicators", indicatorData);
            response.put("success", true);
            response.put("symbol", symbol.toUpperCase());
            response.put("timeframe", timeframe);

            log.info("응답 준비 완료: 데이터 {}개, 지표 {}개",
                    data.size(), indicatorData.size());

        } catch (Exception e) {
            log.error("전체 차트 데이터 조회 실패: symbol={}", symbol, e);

            // 에러 응답
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("data", Collections.emptyList());
            response.put("indicators", Collections.emptyMap());
        }

        return response;
    }
}