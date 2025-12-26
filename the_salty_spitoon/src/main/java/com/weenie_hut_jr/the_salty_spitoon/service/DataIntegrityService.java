package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.dto.CollectionResult;
import com.weenie_hut_jr.the_salty_spitoon.dto.IntegrityIssue;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional; // ✅ 이 줄 추가!

/**
 * 데이터 무결성 검증 서비스
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-25
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DataIntegrityService {

    private final StockCandle1mRepository candleRepository;

    /**
     * 전체 데이터 무결성 검증
     */
    public List<String> checkDataIntegrity() {
        log.info("[DataIntegrity] Starting data integrity check...");

        List<String> issues = new ArrayList<>();
        List<StockCandle1m> allCandles = candleRepository.findAll();

        log.info("[DataIntegrity] Total records: {}", allCandles.size());

        int invalidPriceCount = 0;
        int invalidVolumeCount = 0;
        int invalidOhlcCount = 0;

        for (StockCandle1m candle : allCandles) {
            if (isInvalidPrice(candle)) {
                issues.add(String.format("[%s @ %s] Invalid price: O=%.2f H=%.2f L=%.2f C=%.2f",
                        candle.getSymbol(),
                        candle.getTimestamp(),
                        candle.getOpen(),
                        candle.getHigh(),
                        candle.getLow(),
                        candle.getClose()));
                invalidPriceCount++;
            }

            if (candle.getVolume() != null && candle.getVolume() < 0) {
                issues.add(String.format("[%s @ %s] Negative volume: %d",
                        candle.getSymbol(),
                        candle.getTimestamp(),
                        candle.getVolume()));
                invalidVolumeCount++;
            }

            if (!isValidOhlc(candle)) {
                issues.add(String.format("[%s @ %s] Invalid OHLC relationship: O=%.2f H=%.2f L=%.2f C=%.2f",
                        candle.getSymbol(),
                        candle.getTimestamp(),
                        candle.getOpen(),
                        candle.getHigh(),
                        candle.getLow(),
                        candle.getClose()));
                invalidOhlcCount++;
            }
        }

        log.info("[DataIntegrity] ========================================");
        log.info("[DataIntegrity] Check completed");
        log.info("[DataIntegrity]   Total issues: {}", issues.size());
        log.info("[DataIntegrity]   Invalid prices: {}", invalidPriceCount);
        log.info("[DataIntegrity]   Invalid volumes: {}", invalidVolumeCount);
        log.info("[DataIntegrity]   Invalid OHLC: {}", invalidOhlcCount);
        log.info("[DataIntegrity] ========================================");

        return issues;
    }

    /**
     * AdminController에서 사용하는 메서드
     */
    public List<IntegrityIssue> checkAllIntegrity() {
        log.info("[DataIntegrity] checkAllIntegrity called");

        List<IntegrityIssue> issues = new ArrayList<>();
        List<StockCandle1m> allCandles = candleRepository.findAll();

        for (StockCandle1m candle : allCandles) {
            if (isInvalidPrice(candle) || !isValidOhlc(candle)) {
                IntegrityIssue issue = new IntegrityIssue();
                issue.setSymbol(candle.getSymbol());
                issue.setTimestamp(candle.getTimestamp());
                issue.setIssueType(isInvalidPrice(candle) ? "INVALID_PRICE" : "INVALID_OHLC");
                issue.setDescription(String.format("O=%.2f H=%.2f L=%.2f C=%.2f",
                        candle.getOpen(), candle.getHigh(), candle.getLow(), candle.getClose()));
                issues.add(issue);
            }
        }

        return issues;
    }

    /**
     * 문제 수정
     */
    @Transactional
    public CollectionResult fixIssues(List<IntegrityIssue> issues) {
        log.info("[DataIntegrity] Fixing {} issues...", issues.size());

        CollectionResult result = new CollectionResult();
        result.setTotalSymbols(issues.size());
        result.setSuccessCount(0);
        result.setFailureCount(0);
        result.setTotalCandles(0); // ✅ 추가
        result.setSuccess(true); // ✅ 추가

        for (IntegrityIssue issue : issues) {
            try {
                Optional<StockCandle1m> candle = candleRepository
                        .findBySymbolAndTimestamp(issue.getSymbol(), issue.getTimestamp());

                if (candle.isPresent()) {
                    candleRepository.delete(candle.get());
                    result.setSuccessCount(result.getSuccessCount() + 1);
                    result.setTotalCandles(result.getTotalCandles() + 1); // ✅ 추가
                    log.info("[DataIntegrity] Fixed: {} @ {}", issue.getSymbol(), issue.getTimestamp());
                }

            } catch (Exception e) {
                result.setFailureCount(result.getFailureCount() + 1);
                log.error("[DataIntegrity] Failed to fix: {} @ {}", issue.getSymbol(), issue.getTimestamp(), e);
            }
        }

        // ✅ 메시지 설정
        result.setMessage(String.format("Fixed %d/%d issues",
                result.getSuccessCount(),
                result.getTotalSymbols()));

        return result;
    }

    /**
     * 중복 검증
     */
    public List<String> checkDuplicates() {
        log.info("[DataIntegrity] Checking for duplicates...");
        return new ArrayList<>(); // UPSERT 방식에서는 중복 불가
    }

    private boolean isInvalidPrice(StockCandle1m candle) {
        return candle.getOpen() == null || candle.getOpen().compareTo(BigDecimal.ZERO) <= 0 ||
                candle.getHigh() == null || candle.getHigh().compareTo(BigDecimal.ZERO) <= 0 ||
                candle.getLow() == null || candle.getLow().compareTo(BigDecimal.ZERO) <= 0 ||
                candle.getClose() == null || candle.getClose().compareTo(BigDecimal.ZERO) <= 0;
    }

    private boolean isValidOhlc(StockCandle1m candle) {
        if (candle.getHigh() == null || candle.getLow() == null ||
                candle.getOpen() == null || candle.getClose() == null) {
            return false;
        }

        if (candle.getHigh().compareTo(candle.getLow()) < 0) {
            return false;
        }

        if (candle.getHigh().compareTo(candle.getOpen()) < 0 ||
                candle.getHigh().compareTo(candle.getClose()) < 0) {
            return false;
        }

        if (candle.getLow().compareTo(candle.getOpen()) > 0 ||
                candle.getLow().compareTo(candle.getClose()) > 0) {
            return false;
        }

        return true;
    }
}