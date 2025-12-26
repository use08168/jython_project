package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 1분봉 캔들 데이터 Repository
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-25
 */
@Repository
public interface StockCandle1mRepository extends JpaRepository<StockCandle1m, Long> {

        /**
         * 심볼과 타임스탬프로 조회 (UPSERT용)
         */
        Optional<StockCandle1m> findBySymbolAndTimestamp(String symbol, LocalDateTime timestamp);

        /**
         * 심볼과 기간으로 조회 (차트용)
         */
        List<StockCandle1m> findBySymbolAndTimestampBetweenOrderByTimestampAsc(
                        String symbol,
                        LocalDateTime start,
                        LocalDateTime end);

        /**
         * 심볼로 최신 데이터 조회 (실시간 가격용)
         */
        Optional<StockCandle1m> findTopBySymbolOrderByTimestampDesc(String symbol);

        /**
         * 심볼로 최신 데이터 조회 (별칭)
         * StockService에서 사용
         */
        Optional<StockCandle1m> findFirstBySymbolOrderByTimestampDesc(String symbol);

        /**
         * 심볼의 모든 데이터 조회 (시간순)
         * StockService에서 사용
         */
        List<StockCandle1m> findBySymbolOrderByTimestampAsc(String symbol);

        /**
         * 심볼의 마지막 타임스탬프 조회
         * HistoricalDataService에서 사용
         */
        @Query("SELECT MAX(c.timestamp) FROM StockCandle1m c WHERE c.symbol = :symbol")
        Optional<LocalDateTime> findLastTimestampBySymbol(@Param("symbol") String symbol);
}