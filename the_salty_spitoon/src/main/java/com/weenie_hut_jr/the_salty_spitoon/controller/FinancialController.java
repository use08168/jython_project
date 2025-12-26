package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.model.*;
import com.weenie_hut_jr.the_salty_spitoon.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 재무 데이터 API 컨트롤러
 * 
 * 역할:
 * - NASDAQ 100 종목의 재무 데이터 제공
 * - 6개 분리된 API 엔드포인트
 * - detail.jsp에서 AJAX로 호출
 * 
 * API 엔드포인트:
 * - GET /stock/api/financial/{symbol}/income-statement?period=quarterly
 * - GET /stock/api/financial/{symbol}/balance-sheet?period=yearly
 * - GET /stock/api/financial/{symbol}/cashflow?period=quarterly
 * - GET /stock/api/financial/{symbol}/metrics
 * - GET /stock/api/financial/{symbol}/dividends
 * - GET /stock/api/financial/{symbol}/info
 * 
 * 응답 형식:
 * - JSON
 * - 에러 시에도 success: false와 함께 JSON 반환
 * 
 * 사용 위치:
 * - detail.jsp: 재무 정보 섹션
 * - 탭 전환 시 필요한 데이터만 로드
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j
@RestController
@RequestMapping("/stock/api/financial")
@RequiredArgsConstructor
public class FinancialController {

    // Repository 의존성 주입
    private final FinancialIncomeStatementRepository incomeStatementRepository;
    private final FinancialBalanceSheetRepository balanceSheetRepository;
    private final FinancialCashflowRepository cashflowRepository;
    private final FinancialMetricsRepository metricsRepository;
    private final FinancialDividendRepository dividendRepository;
    private final CompanyInfoRepository companyInfoRepository;

    /**
     * 재무제표 조회 (Income Statement)
     * 
     * URL: GET /stock/api/financial/{symbol}/income-statement
     * 
     * 쿼리 파라미터:
     * - period: quarterly (기본값) 또는 yearly
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "period": "quarterly",
     * "data": [
     * {
     * "fiscalDate": "2024-09-30",
     * "totalRevenue": 94930000000,
     * "grossProfit": 44543000000,
     * "operatingIncome": 29590000000,
     * "netIncome": 14736000000,
     * ...
     * },
     * ...
     * ]
     * }
     * 
     * @param symbol 종목 심볼
     * @param period 기간 타입 (quarterly/yearly)
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/income-statement")
    public ResponseEntity<Map<String, Object>> getIncomeStatement(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "quarterly") String period) {

        log.info("Income statement requested: symbol={}, period={}", symbol, period);

        Map<String, Object> response = new HashMap<>();

        try {
            FinancialIncomeStatement.PeriodType periodType = FinancialIncomeStatement.PeriodType.valueOf(period);

            List<FinancialIncomeStatement> data = incomeStatementRepository
                    .findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            symbol.toUpperCase(), periodType);

            response.put("success", true);
            response.put("symbol", symbol.toUpperCase());
            response.put("period", period);
            response.put("count", data.size());
            response.put("data", data);

            log.info("Income statement found: {} records", data.size());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.error("Invalid period type: {}", period);
            response.put("success", false);
            response.put("error", "Invalid period type: " + period);
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Failed to get income statement: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 대차대조표 조회 (Balance Sheet)
     * 
     * URL: GET /stock/api/financial/{symbol}/balance-sheet
     * 
     * 쿼리 파라미터:
     * - period: quarterly (기본값) 또는 yearly
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "period": "yearly",
     * "data": [
     * {
     * "fiscalDate": "2024-09-30",
     * "totalAssets": 364980000000,
     * "totalLiabilitiesNetMinorityInterest": 308030000000,
     * "stockholdersEquity": 56950000000,
     * ...
     * },
     * ...
     * ]
     * }
     * 
     * @param symbol 종목 심볼
     * @param period 기간 타입 (quarterly/yearly)
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/balance-sheet")
    public ResponseEntity<Map<String, Object>> getBalanceSheet(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "quarterly") String period) {

        log.info("Balance sheet requested: symbol={}, period={}", symbol, period);

        Map<String, Object> response = new HashMap<>();

        try {
            FinancialIncomeStatement.PeriodType periodType = FinancialIncomeStatement.PeriodType.valueOf(period);

            List<FinancialBalanceSheet> data = balanceSheetRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                    symbol.toUpperCase(), periodType);

            response.put("success", true);
            response.put("symbol", symbol.toUpperCase());
            response.put("period", period);
            response.put("count", data.size());
            response.put("data", data);

            log.info("Balance sheet found: {} records", data.size());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.error("Invalid period type: {}", period);
            response.put("success", false);
            response.put("error", "Invalid period type: " + period);
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Failed to get balance sheet: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 현금흐름표 조회 (Cash Flow Statement)
     * 
     * URL: GET /stock/api/financial/{symbol}/cashflow
     * 
     * 쿼리 파라미터:
     * - period: quarterly (기본값) 또는 yearly
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "period": "quarterly",
     * "data": [
     * {
     * "fiscalDate": "2024-09-30",
     * "operatingCashFlow": 31200000000,
     * "investingCashFlow": -1460000000,
     * "financingCashFlow": -30590000000,
     * "freeCashFlow": 26740000000,
     * ...
     * },
     * ...
     * ]
     * }
     * 
     * @param symbol 종목 심볼
     * @param period 기간 타입 (quarterly/yearly)
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/cashflow")
    public ResponseEntity<Map<String, Object>> getCashflow(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "quarterly") String period) {

        log.info("Cashflow requested: symbol={}, period={}", symbol, period);

        Map<String, Object> response = new HashMap<>();

        try {
            FinancialIncomeStatement.PeriodType periodType = FinancialIncomeStatement.PeriodType.valueOf(period);

            List<FinancialCashflow> data = cashflowRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                    symbol.toUpperCase(), periodType);

            response.put("success", true);
            response.put("symbol", symbol.toUpperCase());
            response.put("period", period);
            response.put("count", data.size());
            response.put("data", data);

            log.info("Cashflow found: {} records", data.size());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.error("Invalid period type: {}", period);
            response.put("success", false);
            response.put("error", "Invalid period type: " + period);
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Failed to get cashflow: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 재무 지표 조회 (Financial Metrics)
     * 
     * URL: GET /stock/api/financial/{symbol}/metrics
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "data": {
     * "profitMargins": 0.254,
     * "operatingMargins": 0.312,
     * "returnOnEquity": 0.471,
     * "returnOnAssets": 0.153,
     * "trailingPe": 35.2,
     * "forwardPe": 28.5,
     * "pegRatio": 2.1,
     * "priceToBook": 48.3,
     * "dividendYield": 0.0044,
     * "marketCap": 3450000000000,
     * ...
     * }
     * }
     * 
     * @param symbol 종목 심볼
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/metrics")
    public ResponseEntity<Map<String, Object>> getMetrics(@PathVariable String symbol) {

        log.info("Metrics requested: symbol={}", symbol);

        Map<String, Object> response = new HashMap<>();

        try {
            Optional<FinancialMetrics> metricsOpt = metricsRepository.findBySymbol(symbol.toUpperCase());

            if (metricsOpt.isPresent()) {
                response.put("success", true);
                response.put("symbol", symbol.toUpperCase());
                response.put("data", metricsOpt.get());

                log.info("Metrics found for {}", symbol);

            } else {
                response.put("success", false);
                response.put("symbol", symbol.toUpperCase());
                response.put("message", "No metrics data available");

                log.warn("No metrics found for {}", symbol);
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get metrics: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 배당금 조회 (Dividends)
     * 
     * URL: GET /stock/api/financial/{symbol}/dividends
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "count": 20,
     * "data": [
     * {
     * "paymentDate": "2024-11-14",
     * "dividendAmount": 0.25
     * },
     * {
     * "paymentDate": "2024-08-15",
     * "dividendAmount": 0.25
     * },
     * ...
     * ]
     * }
     * 
     * @param symbol 종목 심볼
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/dividends")
    public ResponseEntity<Map<String, Object>> getDividends(@PathVariable String symbol) {

        log.info("Dividends requested: symbol={}", symbol);

        Map<String, Object> response = new HashMap<>();

        try {
            List<FinancialDividend> data = dividendRepository.findBySymbolOrderByPaymentDateDesc(symbol.toUpperCase());

            response.put("success", true);
            response.put("symbol", symbol.toUpperCase());
            response.put("count", data.size());
            response.put("data", data);

            log.info("Dividends found: {} records", data.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get dividends: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 기업 정보 조회 (Company Info)
     * 
     * URL: GET /stock/api/financial/{symbol}/info
     * 
     * 응답 예시:
     * {
     * "success": true,
     * "symbol": "AAPL",
     * "data": {
     * "longName": "Apple Inc.",
     * "sector": "Technology",
     * "industry": "Consumer Electronics",
     * "country": "United States",
     * "city": "Cupertino",
     * "website": "https://www.apple.com",
     * "fullTimeEmployees": 161000,
     * "longBusinessSummary": "Apple Inc. designs, manufactures...",
     * "marketCap": 3450000000000,
     * ...
     * }
     * }
     * 
     * @param symbol 종목 심볼
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/info")
    public ResponseEntity<Map<String, Object>> getCompanyInfo(@PathVariable String symbol) {

        log.info("Company info requested: symbol={}", symbol);

        Map<String, Object> response = new HashMap<>();

        try {
            Optional<CompanyInfo> infoOpt = companyInfoRepository.findBySymbol(symbol.toUpperCase());

            if (infoOpt.isPresent()) {
                response.put("success", true);
                response.put("symbol", symbol.toUpperCase());
                response.put("data", infoOpt.get());

                log.info("Company info found for {}", symbol);

            } else {
                response.put("success", false);
                response.put("symbol", symbol.toUpperCase());
                response.put("message", "No company info available");

                log.warn("No company info found for {}", symbol);
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get company info: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * 전체 재무 데이터 조회 (선택적)
     * 
     * URL: GET /stock/api/financial/{symbol}/all
     * 
     * 모든 재무 데이터를 한 번에 반환
     * - 초기 로딩 시 사용 가능
     * - 데이터 크기가 크므로 필요 시에만 사용
     * 
     * @param symbol 종목 심볼
     * @return ResponseEntity<Map>
     */
    @GetMapping("/{symbol}/all")
    public ResponseEntity<Map<String, Object>> getAllFinancialData(@PathVariable String symbol) {

        log.info("All financial data requested: symbol={}", symbol);

        Map<String, Object> response = new HashMap<>();

        try {
            String upperSymbol = symbol.toUpperCase();

            // 모든 데이터 조회
            Map<String, Object> allData = new HashMap<>();

            // 재무제표
            allData.put("incomeStatement", Map.of(
                    "quarterly", incomeStatementRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.quarterly),
                    "yearly", incomeStatementRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.yearly)));

            // 대차대조표
            allData.put("balanceSheet", Map.of(
                    "quarterly", balanceSheetRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.quarterly),
                    "yearly", balanceSheetRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.yearly)));

            // 현금흐름표
            allData.put("cashflow", Map.of(
                    "quarterly", cashflowRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.quarterly),
                    "yearly", cashflowRepository.findBySymbolAndPeriodTypeOrderByFiscalDateDesc(
                            upperSymbol, FinancialIncomeStatement.PeriodType.yearly)));

            // 재무 지표
            metricsRepository.findBySymbol(upperSymbol).ifPresent(m -> allData.put("metrics", m));

            // 배당금
            allData.put("dividends", dividendRepository.findBySymbolOrderByPaymentDateDesc(upperSymbol));

            // 기업 정보
            companyInfoRepository.findBySymbol(upperSymbol).ifPresent(c -> allData.put("companyInfo", c));

            response.put("success", true);
            response.put("symbol", upperSymbol);
            response.put("data", allData);

            log.info("All financial data retrieved for {}", symbol);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get all financial data: {}", e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}