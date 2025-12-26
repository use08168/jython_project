package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.model.*;
import com.weenie_hut_jr.the_salty_spitoon.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * 재무 데이터 서비스
 * 
 * 역할:
 * - Python에서 생성한 재무 데이터 JSON 읽기
 * - 6개 테이블에 데이터 저장
 * - 중복 체크 및 업데이트
 * - 대량 데이터 일괄 처리
 * 
 * 동작 흐름:
 * 1. Python load_nasdaq100_financial.py 실행
 * 2. JSON 파일 생성 (python/results/financial_data_{timestamp}.json)
 * 3. 이 서비스가 JSON 파일 읽기
 * 4. 각 종목별 데이터 파싱
 * 5. 6개 테이블에 저장 (중복 체크)
 * 
 * JSON 구조:
 * {
 * "timestamp": "2025-12-21 14:30:00",
 * "total": 101,
 * "success": 95,
 * "failed": 6,
 * "data": [
 * {
 * "symbol": "AAPL",
 * "name": "Apple Inc.",
 * "success": true,
 * "income_statement": { "quarterly": [...], "yearly": [...] },
 * "balance_sheet": { "quarterly": [...], "yearly": [...] },
 * "cashflow": { "quarterly": [...], "yearly": [...] },
 * "metrics": {...},
 * "dividends": [...],
 * "company_info": {...}
 * },
 * ...
 * ]
 * }
 * 
 * 사용 위치:
 * - 수동 실행: 관리자가 JSON 파일 경로 지정
 * - 자동 실행: 최신 JSON 파일 자동 탐색
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FinancialDataService {

    // Repository 의존성 주입
    private final FinancialIncomeStatementRepository incomeStatementRepository;
    private final FinancialBalanceSheetRepository balanceSheetRepository;
    private final FinancialCashflowRepository cashflowRepository;
    private final FinancialMetricsRepository metricsRepository;
    private final FinancialDividendRepository dividendRepository;
    private final CompanyInfoRepository companyInfoRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    /**
     * JSON 파일에서 재무 데이터 로드 및 저장
     * 
     * @param jsonFilePath JSON 파일 경로
     * @return 처리 결과 메시지
     */
    @Transactional
    public String loadFinancialDataFromJson(String jsonFilePath) {
        log.info("========================================");
        log.info("Financial Data Load Started");
        log.info("========================================");
        log.info("📄 Reading JSON: {}", jsonFilePath);

        try {
            // JSON 파일 읽기
            File jsonFile = new File(jsonFilePath);
            if (!jsonFile.exists()) {
                throw new RuntimeException("JSON file not found: " + jsonFilePath);
            }

            JsonNode root = objectMapper.readTree(jsonFile);
            JsonNode dataArray = root.get("data");

            if (dataArray == null || !dataArray.isArray()) {
                throw new RuntimeException("Invalid JSON structure: 'data' array not found");
            }

            // 통계 변수
            int totalSymbols = dataArray.size();
            int successCount = 0;
            int failedCount = 0;
            int incomeCount = 0;
            int balanceCount = 0;
            int cashflowCount = 0;
            int metricsCount = 0;
            int dividendCount = 0;
            int companyInfoCount = 0;

            // 각 종목 데이터 처리
            for (JsonNode symbolData : dataArray) {
                String symbol = symbolData.get("symbol").asText();
                boolean success = symbolData.get("success").asBoolean();

                if (!success) {
                    log.warn("❌ Skipping {} (collection failed)", symbol);
                    failedCount++;
                    continue;
                }

                log.info("\n[Processing] {}", symbol);

                try {
                    // 1. 재무제표 저장
                    int income = saveIncomeStatements(symbol, symbolData.get("income_statement"));
                    incomeCount += income;
                    log.info("  ✅ Income Statements: {}", income);

                    // 2. 대차대조표 저장
                    int balance = saveBalanceSheets(symbol, symbolData.get("balance_sheet"));
                    balanceCount += balance;
                    log.info("  ✅ Balance Sheets: {}", balance);

                    // 3. 현금흐름표 저장
                    int cashflow = saveCashflows(symbol, symbolData.get("cashflow"));
                    cashflowCount += cashflow;
                    log.info("  ✅ Cashflows: {}", cashflow);

                    // 4. 재무 지표 저장
                    boolean metrics = saveMetrics(symbol, symbolData.get("metrics"));
                    if (metrics)
                        metricsCount++;
                    log.info("  ✅ Metrics: {}", metrics ? "saved" : "skipped");

                    // 5. 배당금 저장
                    int dividend = saveDividends(symbol, symbolData.get("dividends"));
                    dividendCount += dividend;
                    log.info("  ✅ Dividends: {}", dividend);

                    // 6. 기업 정보 저장
                    boolean companyInfo = saveCompanyInfo(symbol, symbolData.get("company_info"));
                    if (companyInfo)
                        companyInfoCount++;
                    log.info("  ✅ Company Info: {}", companyInfo ? "saved" : "skipped");

                    successCount++;

                } catch (Exception e) {
                    log.error("❌ Failed to process {}: {}", symbol, e.getMessage());
                    failedCount++;
                }
            }

            // 최종 결과
            log.info("\n========================================");
            log.info("Financial Data Load Completed");
            log.info("========================================");
            log.info("Total Symbols: {}", totalSymbols);
            log.info("Success: {} | Failed: {}", successCount, failedCount);
            log.info("----------------------------------------");
            log.info("Income Statements: {}", incomeCount);
            log.info("Balance Sheets: {}", balanceCount);
            log.info("Cashflows: {}", cashflowCount);
            log.info("Metrics: {}", metricsCount);
            log.info("Dividends: {}", dividendCount);
            log.info("Company Info: {}", companyInfoCount);
            log.info("========================================");

            return String.format("✅ Processed %d symbols (Success: %d, Failed: %d)",
                    totalSymbols, successCount, failedCount);

        } catch (Exception e) {
            log.error("❌ Financial data load failed", e);
            throw new RuntimeException("Failed to load financial data: " + e.getMessage(), e);
        }
    }

    /**
     * 재무제표 저장 (Income Statement)
     */
    private int saveIncomeStatements(String symbol, JsonNode data) {
        if (data == null)
            return 0;

        int count = 0;

        // 분기별
        JsonNode quarterly = data.get("quarterly");
        if (quarterly != null && quarterly.isArray()) {
            for (JsonNode item : quarterly) {
                if (saveIncomeStatement(symbol, item, FinancialIncomeStatement.PeriodType.quarterly)) {
                    count++;
                }
            }
        }

        // 연간
        JsonNode yearly = data.get("yearly");
        if (yearly != null && yearly.isArray()) {
            for (JsonNode item : yearly) {
                if (saveIncomeStatement(symbol, item, FinancialIncomeStatement.PeriodType.yearly)) {
                    count++;
                }
            }
        }

        return count;
    }

    /**
     * 개별 재무제표 저장
     */
    private boolean saveIncomeStatement(String symbol, JsonNode data, FinancialIncomeStatement.PeriodType periodType) {
        try {
            String fiscalDateStr = data.get("fiscal_date").asText();
            LocalDate fiscalDate = LocalDate.parse(fiscalDateStr, DATE_FORMATTER);

            // 중복 체크
            Optional<FinancialIncomeStatement> existing = incomeStatementRepository
                    .findBySymbolAndFiscalDateAndPeriodType(symbol, fiscalDate, periodType);

            FinancialIncomeStatement entity = existing.orElse(
                    FinancialIncomeStatement.builder()
                            .symbol(symbol)
                            .fiscalDate(fiscalDate)
                            .periodType(periodType)
                            .build());

            // 데이터 매핑
            entity.setTotalRevenue(getBigDecimal(data, "total_revenue"));
            entity.setCostOfRevenue(getBigDecimal(data, "cost_of_revenue"));
            entity.setGrossProfit(getBigDecimal(data, "gross_profit"));
            entity.setResearchAndDevelopment(getBigDecimal(data, "research_and_development"));
            entity.setSellingGeneralAndAdministration(getBigDecimal(data, "selling_general_and_administration"));
            entity.setOperatingExpense(getBigDecimal(data, "operating_expense"));
            entity.setOperatingIncome(getBigDecimal(data, "operating_income"));
            entity.setEbitda(getBigDecimal(data, "ebitda"));
            entity.setEbit(getBigDecimal(data, "ebit"));
            entity.setInterestExpense(getBigDecimal(data, "interest_expense"));
            entity.setInterestIncome(getBigDecimal(data, "interest_income"));
            entity.setOtherIncomeExpense(getBigDecimal(data, "other_income_expense"));
            entity.setPretaxIncome(getBigDecimal(data, "pretax_income"));
            entity.setTaxProvision(getBigDecimal(data, "tax_provision"));
            entity.setNetIncome(getBigDecimal(data, "net_income"));
            entity.setNetIncomeCommonStockholders(getBigDecimal(data, "net_income_common_stockholders"));
            entity.setBasicEps(getBigDecimal(data, "basic_eps"));
            entity.setDilutedEps(getBigDecimal(data, "diluted_eps"));
            entity.setBasicAverageShares(getLong(data, "basic_average_shares"));
            entity.setDilutedAverageShares(getLong(data, "diluted_average_shares"));

            incomeStatementRepository.save(entity);
            return true;

        } catch (Exception e) {
            log.warn("Failed to save income statement: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 대차대조표 저장 (Balance Sheet)
     */
    private int saveBalanceSheets(String symbol, JsonNode data) {
        if (data == null)
            return 0;

        int count = 0;

        // 분기별
        JsonNode quarterly = data.get("quarterly");
        if (quarterly != null && quarterly.isArray()) {
            for (JsonNode item : quarterly) {
                if (saveBalanceSheet(symbol, item, FinancialIncomeStatement.PeriodType.quarterly)) {
                    count++;
                }
            }
        }

        // 연간
        JsonNode yearly = data.get("yearly");
        if (yearly != null && yearly.isArray()) {
            for (JsonNode item : yearly) {
                if (saveBalanceSheet(symbol, item, FinancialIncomeStatement.PeriodType.yearly)) {
                    count++;
                }
            }
        }

        return count;
    }

    /**
     * 개별 대차대조표 저장
     */
    private boolean saveBalanceSheet(String symbol, JsonNode data, FinancialIncomeStatement.PeriodType periodType) {
        try {
            String fiscalDateStr = data.get("fiscal_date").asText();
            LocalDate fiscalDate = LocalDate.parse(fiscalDateStr, DATE_FORMATTER);

            // 중복 체크
            Optional<FinancialBalanceSheet> existing = balanceSheetRepository
                    .findBySymbolAndFiscalDateAndPeriodType(symbol, fiscalDate, periodType);

            FinancialBalanceSheet entity = existing.orElse(
                    FinancialBalanceSheet.builder()
                            .symbol(symbol)
                            .fiscalDate(fiscalDate)
                            .periodType(periodType)
                            .build());

            // 자산
            entity.setTotalAssets(getBigDecimal(data, "total_assets"));
            entity.setCurrentAssets(getBigDecimal(data, "current_assets"));
            entity.setCashAndCashEquivalents(getBigDecimal(data, "cash_and_cash_equivalents"));
            entity.setCashCashEquivalentsAndShortTermInvestments(
                    getBigDecimal(data, "cash_cash_equivalents_and_short_term_investments"));
            entity.setReceivables(getBigDecimal(data, "receivables"));
            entity.setInventory(getBigDecimal(data, "inventory"));
            entity.setOtherCurrentAssets(getBigDecimal(data, "other_current_assets"));
            entity.setNetPpe(getBigDecimal(data, "net_ppe"));
            entity.setGrossPpe(getBigDecimal(data, "gross_ppe"));
            entity.setGoodwill(getBigDecimal(data, "goodwill"));
            entity.setIntangibleAssets(getBigDecimal(data, "intangible_assets"));
            entity.setInvestmentsAndAdvances(getBigDecimal(data, "investments_and_advances"));
            entity.setOtherNonCurrentAssets(getBigDecimal(data, "other_non_current_assets"));

            // 부채
            entity.setTotalLiabilitiesNetMinorityInterest(
                    getBigDecimal(data, "total_liabilities_net_minority_interest"));
            entity.setCurrentLiabilities(getBigDecimal(data, "current_liabilities"));
            entity.setPayablesAndAccruedExpenses(getBigDecimal(data, "payables_and_accrued_expenses"));
            entity.setCurrentDebt(getBigDecimal(data, "current_debt"));
            entity.setOtherCurrentLiabilities(getBigDecimal(data, "other_current_liabilities"));
            entity.setLongTermDebt(getBigDecimal(data, "long_term_debt"));
            entity.setOtherNonCurrentLiabilities(getBigDecimal(data, "other_non_current_liabilities"));
            entity.setTotalDebt(getBigDecimal(data, "total_debt"));

            // 자본
            entity.setStockholdersEquity(getBigDecimal(data, "stockholders_equity"));
            entity.setCommonStock(getBigDecimal(data, "common_stock"));
            entity.setRetainedEarnings(getBigDecimal(data, "retained_earnings"));
            entity.setTreasuryStock(getBigDecimal(data, "treasury_stock"));
            entity.setCapitalStock(getBigDecimal(data, "capital_stock"));

            balanceSheetRepository.save(entity);
            return true;

        } catch (Exception e) {
            log.warn("Failed to save balance sheet: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 현금흐름표 저장 (Cash Flow)
     */
    private int saveCashflows(String symbol, JsonNode data) {
        if (data == null)
            return 0;

        int count = 0;

        // 분기별
        JsonNode quarterly = data.get("quarterly");
        if (quarterly != null && quarterly.isArray()) {
            for (JsonNode item : quarterly) {
                if (saveCashflow(symbol, item, FinancialIncomeStatement.PeriodType.quarterly)) {
                    count++;
                }
            }
        }

        // 연간
        JsonNode yearly = data.get("yearly");
        if (yearly != null && yearly.isArray()) {
            for (JsonNode item : yearly) {
                if (saveCashflow(symbol, item, FinancialIncomeStatement.PeriodType.yearly)) {
                    count++;
                }
            }
        }

        return count;
    }

    /**
     * 개별 현금흐름표 저장
     */
    private boolean saveCashflow(String symbol, JsonNode data, FinancialIncomeStatement.PeriodType periodType) {
        try {
            String fiscalDateStr = data.get("fiscal_date").asText();
            LocalDate fiscalDate = LocalDate.parse(fiscalDateStr, DATE_FORMATTER);

            // 중복 체크
            Optional<FinancialCashflow> existing = cashflowRepository.findBySymbolAndFiscalDateAndPeriodType(symbol,
                    fiscalDate, periodType);

            FinancialCashflow entity = existing.orElse(
                    FinancialCashflow.builder()
                            .symbol(symbol)
                            .fiscalDate(fiscalDate)
                            .periodType(periodType)
                            .build());

            // 영업활동
            entity.setOperatingCashFlow(getBigDecimal(data, "operating_cash_flow"));
            entity.setCashFlowFromContinuingOperatingActivities(
                    getBigDecimal(data, "cash_flow_from_continuing_operating_activities"));
            entity.setNetIncomeFromContinuingOperations(getBigDecimal(data, "net_income_from_continuing_operations"));
            entity.setDepreciationAndAmortization(getBigDecimal(data, "depreciation_and_amortization"));
            entity.setDeferredIncomeTax(getBigDecimal(data, "deferred_income_tax"));
            entity.setStockBasedCompensation(getBigDecimal(data, "stock_based_compensation"));
            entity.setChangeInWorkingCapital(getBigDecimal(data, "change_in_working_capital"));
            entity.setChangeInReceivables(getBigDecimal(data, "change_in_receivables"));
            entity.setChangeInInventory(getBigDecimal(data, "change_in_inventory"));
            entity.setChangeInPayables(getBigDecimal(data, "change_in_payables"));

            // 투자활동
            entity.setInvestingCashFlow(getBigDecimal(data, "investing_cash_flow"));
            entity.setCapitalExpenditure(getBigDecimal(data, "capital_expenditure"));
            entity.setNetPpePurchaseAndSale(getBigDecimal(data, "net_ppe_purchase_and_sale"));
            entity.setNetInvestmentPurchaseAndSale(getBigDecimal(data, "net_investment_purchase_and_sale"));
            entity.setNetBusinessPurchaseAndSale(getBigDecimal(data, "net_business_purchase_and_sale"));

            // 재무활동
            entity.setFinancingCashFlow(getBigDecimal(data, "financing_cash_flow"));
            entity.setCashDividendsPaid(getBigDecimal(data, "cash_dividends_paid"));
            entity.setCommonStockIssuance(getBigDecimal(data, "common_stock_issuance"));
            entity.setCommonStockPayments(getBigDecimal(data, "common_stock_payments"));
            entity.setNetCommonStockIssuance(getBigDecimal(data, "net_common_stock_issuance"));
            entity.setLongTermDebtIssuance(getBigDecimal(data, "long_term_debt_issuance"));
            entity.setLongTermDebtPayments(getBigDecimal(data, "long_term_debt_payments"));
            entity.setNetLongTermDebtIssuance(getBigDecimal(data, "net_long_term_debt_issuance"));

            // 잉여현금흐름
            entity.setFreeCashFlow(getBigDecimal(data, "free_cash_flow"));

            // 현금 변동
            entity.setEndCashPosition(getBigDecimal(data, "end_cash_position"));
            entity.setBeginningCashPosition(getBigDecimal(data, "beginning_cash_position"));
            entity.setChangesInCash(getBigDecimal(data, "changes_in_cash"));
            entity.setEffectOfExchangeRateChanges(getBigDecimal(data, "effect_of_exchange_rate_changes"));

            cashflowRepository.save(entity);
            return true;

        } catch (Exception e) {
            log.warn("Failed to save cashflow: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 재무 지표 저장 (Metrics)
     */
    private boolean saveMetrics(String symbol, JsonNode data) {
        if (data == null)
            return false;

        try {
            // 중복 체크 (종목당 하나)
            Optional<FinancialMetrics> existing = metricsRepository.findBySymbol(symbol);

            FinancialMetrics entity = existing.orElse(
                    FinancialMetrics.builder()
                            .symbol(symbol)
                            .build());

            // 수익성
            entity.setProfitMargins(getBigDecimal(data, "profit_margins"));
            entity.setOperatingMargins(getBigDecimal(data, "operating_margins"));
            entity.setGrossMargins(getBigDecimal(data, "gross_margins"));
            entity.setEbitdaMargins(getBigDecimal(data, "ebitda_margins"));
            entity.setReturnOnEquity(getBigDecimal(data, "return_on_equity"));
            entity.setReturnOnAssets(getBigDecimal(data, "return_on_assets"));

            // 성장성
            entity.setRevenueGrowth(getBigDecimal(data, "revenue_growth"));
            entity.setEarningsGrowth(getBigDecimal(data, "earnings_growth"));
            entity.setEarningsQuarterlyGrowth(getBigDecimal(data, "earnings_quarterly_growth"));

            // 재무 건전성
            entity.setCurrentRatio(getBigDecimal(data, "current_ratio"));
            entity.setQuickRatio(getBigDecimal(data, "quick_ratio"));
            entity.setDebtToEquity(getBigDecimal(data, "debt_to_equity"));
            entity.setTotalDebt(getBigDecimal(data, "total_debt"));
            entity.setTotalCash(getBigDecimal(data, "total_cash"));

            // 밸류에이션
            entity.setTrailingPe(getBigDecimal(data, "trailing_pe"));
            entity.setForwardPe(getBigDecimal(data, "forward_pe"));
            entity.setPegRatio(getBigDecimal(data, "peg_ratio"));
            entity.setPriceToBook(getBigDecimal(data, "price_to_book"));
            entity.setPriceToSalesTrailing12Months(getBigDecimal(data, "price_to_sales_trailing_12_months"));
            entity.setEnterpriseValue(getBigDecimal(data, "enterprise_value"));
            entity.setEnterpriseToRevenue(getBigDecimal(data, "enterprise_to_revenue"));
            entity.setEnterpriseToEbitda(getBigDecimal(data, "enterprise_to_ebitda"));

            // EPS
            entity.setTrailingEps(getBigDecimal(data, "trailing_eps"));
            entity.setForwardEps(getBigDecimal(data, "forward_eps"));

            // 배당
            entity.setDividendRate(getBigDecimal(data, "dividend_rate"));
            entity.setDividendYield(getBigDecimal(data, "dividend_yield"));
            entity.setPayoutRatio(getBigDecimal(data, "payout_ratio"));

            // 시장
            entity.setMarketCap(getBigDecimal(data, "market_cap"));
            entity.setSharesOutstanding(getLong(data, "shares_outstanding"));
            entity.setFloatShares(getLong(data, "float_shares"));
            entity.setSharesShort(getLong(data, "shares_short"));
            entity.setShortRatio(getBigDecimal(data, "short_ratio"));
            entity.setBeta(getBigDecimal(data, "beta"));

            // 52주
            entity.setFiftyTwoWeekHigh(getBigDecimal(data, "fifty_two_week_high"));
            entity.setFiftyTwoWeekLow(getBigDecimal(data, "fifty_two_week_low"));
            entity.setFiftyDayAverage(getBigDecimal(data, "fifty_day_average"));
            entity.setTwoHundredDayAverage(getBigDecimal(data, "two_hundred_day_average"));

            metricsRepository.save(entity);
            return true;

        } catch (Exception e) {
            log.warn("Failed to save metrics: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 배당금 저장 (Dividends)
     */
    private int saveDividends(String symbol, JsonNode data) {
        if (data == null || !data.isArray())
            return 0;

        int count = 0;

        for (JsonNode item : data) {
            try {
                String paymentDateStr = item.get("payment_date").asText();
                LocalDate paymentDate = LocalDate.parse(paymentDateStr, DATE_FORMATTER);
                BigDecimal amount = getBigDecimal(item, "dividend_amount");

                if (amount == null)
                    continue;

                // 중복 체크
                Optional<FinancialDividend> existing = dividendRepository.findBySymbolAndPaymentDate(symbol,
                        paymentDate);

                FinancialDividend entity = existing.orElse(
                        FinancialDividend.builder()
                                .symbol(symbol)
                                .paymentDate(paymentDate)
                                .build());

                entity.setDividendAmount(amount);

                dividendRepository.save(entity);
                count++;

            } catch (Exception e) {
                log.warn("Failed to save dividend: {}", e.getMessage());
            }
        }

        return count;
    }

    /**
     * 기업 정보 저장 (Company Info)
     */
    private boolean saveCompanyInfo(String symbol, JsonNode data) {
        if (data == null)
            return false;

        try {
            // 중복 체크 (종목당 하나)
            Optional<CompanyInfo> existing = companyInfoRepository.findBySymbol(symbol);

            CompanyInfo entity = existing.orElse(
                    CompanyInfo.builder()
                            .symbol(symbol)
                            .build());

            // 기본 정보
            entity.setLongName(getString(data, "long_name"));
            entity.setShortName(getString(data, "short_name"));

            // 분류
            entity.setSector(getString(data, "sector"));
            entity.setIndustry(getString(data, "industry"));
            entity.setIndustryKey(getString(data, "industry_key"));
            entity.setSectorKey(getString(data, "sector_key"));

            // 위치
            entity.setCountry(getString(data, "country"));
            entity.setCity(getString(data, "city"));
            entity.setState(getString(data, "state"));
            entity.setAddress(getString(data, "address"));
            entity.setZipCode(getString(data, "zip_code"));

            // 연락처
            entity.setWebsite(getString(data, "website"));
            entity.setPhone(getString(data, "phone"));

            // 조직
            entity.setFullTimeEmployees(getInteger(data, "full_time_employees"));

            // 사업 설명
            entity.setLongBusinessSummary(getString(data, "long_business_summary"));

            // 시장 정보
            entity.setMarketCap(getBigDecimal(data, "market_cap"));
            entity.setEnterpriseValue(getBigDecimal(data, "enterprise_value"));

            companyInfoRepository.save(entity);
            return true;

        } catch (Exception e) {
            log.warn("Failed to save company info: {}", e.getMessage());
            return false;
        }
    }

    // ========================================
    // 헬퍼 메서드
    // ========================================

    private BigDecimal getBigDecimal(JsonNode node, String fieldName) {
        JsonNode field = node.get(fieldName);
        if (field == null || field.isNull())
            return null;
        try {
            return new BigDecimal(field.asText());
        } catch (Exception e) {
            return null;
        }
    }

    private Long getLong(JsonNode node, String fieldName) {
        JsonNode field = node.get(fieldName);
        if (field == null || field.isNull())
            return null;
        try {
            return field.asLong();
        } catch (Exception e) {
            return null;
        }
    }

    private String getString(JsonNode node, String fieldName) {
        JsonNode field = node.get(fieldName);
        if (field == null || field.isNull())
            return null;
        return field.asText();
    }

    private Integer getInteger(JsonNode node, String fieldName) {
        JsonNode field = node.get(fieldName);
        if (field == null || field.isNull())
            return null;
        try {
            return field.asInt();
        } catch (Exception e) {
            return null;
        }
    }
}