package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.model.Stock;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 주식 데이터 REST API 컨트롤러
 * 
 * Dashboard에서 호출하는 API 엔드포인트들을 제공
 * - /api/stocks/{symbol}/latest - 최신 가격 정보
 * - /api/stocks/{symbol}/history - 과거 데이터 (차트용)
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-28
 */
@Slf4j
@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
public class StockApiController {

    private final StockCandle1mRepository candleRepository;
    private final StockRepository stockRepository;

    /**
     * 특정 종목의 최신 가격 정보 조회
     * 
     * Dashboard에서 지수, 환율, 섹터, 워치리스트 데이터 표시에 사용
     * 
     * @param symbol 종목 심볼 (예: AAPL, ^IXIC, KRW=X)
     * @return 최신 가격 및 변동률 정보
     */
    @GetMapping("/{symbol}/latest")
    public ResponseEntity<Map<String, Object>> getLatestPrice(@PathVariable String symbol) {
        log.debug("최신 가격 조회: {}", symbol);
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            // 최신 캔들 조회
            Optional<StockCandle1m> latestOpt = candleRepository
                    .findFirstBySymbolOrderByTimestampDesc(symbol);
            
            if (latestOpt.isEmpty()) {
                log.warn("{} - 데이터 없음", symbol);
                response.put("symbol", symbol);
                response.put("closePrice", 0);
                response.put("close", 0);
                response.put("changePercent", 0);
                response.put("change_percent", 0);
                response.put("error", true);
                response.put("message", "No data available");
                return ResponseEntity.ok(response);
            }
            
            StockCandle1m latest = latestOpt.get();
            
            // 이전 캔들 조회 (전일 종가 또는 이전 캔들)
            // 1분 전 데이터 먼저 시도
            LocalDateTime prevTime = latest.getTimestamp().minusMinutes(1);
            Optional<StockCandle1m> prevOpt = candleRepository
                    .findBySymbolAndTimestamp(symbol, prevTime);
            
            // 없으면 가장 최근 이전 데이터 조회
            if (prevOpt.isEmpty()) {
                List<StockCandle1m> prevList = candleRepository
                        .findBySymbolAndTimestampBeforeOrderByTimestampDesc(symbol, latest.getTimestamp());
                if (!prevList.isEmpty()) {
                    prevOpt = Optional.of(prevList.get(0));
                }
            }
            
            BigDecimal prevClose = prevOpt.map(StockCandle1m::getClose).orElse(latest.getClose());
            
            // 변동 계산
            BigDecimal change = latest.getClose().subtract(prevClose);
            BigDecimal changePercent = BigDecimal.ZERO;
            
            if (prevClose.compareTo(BigDecimal.ZERO) != 0) {
                changePercent = change
                        .divide(prevClose, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));
            }
            
            // 종목 정보 조회 (이름, 로고)
            Optional<Stock> stockOpt = stockRepository.findById(symbol);
            String name = stockOpt.map(Stock::getName).orElse(symbol);
            String logoUrl = stockOpt.map(Stock::getLogoUrl).orElse(null);
            
            // 응답 구성
            response.put("symbol", symbol);
            response.put("name", name);
            response.put("logoUrl", logoUrl);
            response.put("logo_url", logoUrl);
            response.put("closePrice", latest.getClose());
            response.put("close", latest.getClose());
            response.put("close_price", latest.getClose());
            response.put("open", latest.getOpen());
            response.put("high", latest.getHigh());
            response.put("low", latest.getLow());
            response.put("volume", latest.getVolume());
            response.put("change", change);
            response.put("changePercent", changePercent);
            response.put("change_percent", changePercent);
            response.put("timestamp", latest.getTimestamp());
            response.put("error", false);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("{} - 가격 조회 실패: {}", symbol, e.getMessage());
            response.put("symbol", symbol);
            response.put("error", true);
            response.put("message", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    /**
     * 특정 종목의 과거 데이터 조회 (차트용)
     * 
     * @param symbol 종목 심볼
     * @param days 조회할 일수 (기본 1일)
     * @return 캔들 데이터 리스트
     */
    @GetMapping("/{symbol}/history")
    public ResponseEntity<List<Map<String, Object>>> getHistory(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "1") int days) {
        
        log.debug("과거 데이터 조회: {} ({}일)", symbol, days);
        
        try {
            LocalDateTime to = LocalDateTime.now();
            LocalDateTime from = to.minusDays(days);
            
            List<StockCandle1m> candles = candleRepository
                    .findBySymbolAndTimestampBetweenOrderByTimestampAsc(symbol, from, to);
            
            List<Map<String, Object>> result = new ArrayList<>();
            
            for (StockCandle1m candle : candles) {
                Map<String, Object> item = new HashMap<>();
                item.put("timestamp", candle.getTimestamp().toString());
                item.put("datetime", candle.getTimestamp().toString());
                item.put("open", candle.getOpen());
                item.put("high", candle.getHigh());
                item.put("low", candle.getLow());
                item.put("close", candle.getClose());
                item.put("closePrice", candle.getClose());
                item.put("volume", candle.getVolume());
                result.add(item);
            }
            
            log.info("{} - {}개 캔들 반환", symbol, result.size());
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("{} - 과거 데이터 조회 실패: {}", symbol, e.getMessage());
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * 모든 종목의 최신 가격 조회 (리스트)
     * 
     * @return 모든 종목의 최신 가격 정보
     */
    @GetMapping("/all/latest")
    public ResponseEntity<List<Map<String, Object>>> getAllLatestPrices() {
        log.debug("전체 종목 최신 가격 조회");
        
        List<Map<String, Object>> result = new ArrayList<>();
        
        try {
            List<Stock> stocks = stockRepository.findAll();
            
            for (Stock stock : stocks) {
                Optional<StockCandle1m> latestOpt = candleRepository
                        .findFirstBySymbolOrderByTimestampDesc(stock.getSymbol());
                
                if (latestOpt.isPresent()) {
                    StockCandle1m latest = latestOpt.get();
                    
                    Map<String, Object> item = new HashMap<>();
                    item.put("symbol", stock.getSymbol());
                    item.put("name", stock.getName());
                    item.put("closePrice", latest.getClose());
                    item.put("volume", latest.getVolume());
                    item.put("timestamp", latest.getTimestamp());
                    
                    result.add(item);
                }
            }
            
            log.info("전체 종목: {}개 반환", result.size());
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("전체 종목 조회 실패: {}", e.getMessage());
            return ResponseEntity.ok(Collections.emptyList());
        }
    }
}
