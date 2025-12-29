package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.zip.GZIPInputStream;

/**
 * 뉴스 조회 및 디코딩 Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NewsService {

    private final StockNewsRepository stockNewsRepository;
    private final StockCandle1mRepository stockCandle1mRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * ========================================
     * 디코딩 로직
     * ========================================
     */

    /**
     * encoded_data를 디코딩하여 뉴스 상세 정보 반환
     *
     * @param encodedData gzip + URL-safe Base64 인코딩된 데이터
     * @return Map<String, String> - url, summary, publisher, full_content
     */
    public Map<String, String> decodeNewsDetail(String encodedData) {
        try {
            // 1. URL-safe Base64 디코딩
            byte[] compressed = Base64.getUrlDecoder().decode(encodedData);

            // 2. gzip 압축 해제
            ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
            try (GZIPInputStream gzipStream = new GZIPInputStream(new ByteArrayInputStream(compressed))) {
                byte[] buffer = new byte[1024];
                int len;
                while ((len = gzipStream.read(buffer)) > 0) {
                    byteStream.write(buffer, 0, len);
                }
            }
            String jsonStr = byteStream.toString(StandardCharsets.UTF_8);

            // 3. JSON → Map
            @SuppressWarnings("unchecked")
            Map<String, String> decodedData = objectMapper.readValue(jsonStr, Map.class);

            log.debug("✅ 디코딩 성공: {} chars", jsonStr.length());

            return decodedData;

        } catch (Exception e) {
            log.error("❌ 디코딩 실패", e);

            // 실패 시 빈 맵 반환
            Map<String, String> errorMap = new HashMap<>();
            errorMap.put("url", "");
            errorMap.put("summary", "디코딩 실패");
            errorMap.put("publisher", "");
            errorMap.put("full_content", "뉴스 내용을 불러올 수 없습니다.");

            return errorMap;
        }
    }

    /**
     * ========================================
     * 뉴스 조회 메서드
     * ========================================
     */

    /**
     * 전체 뉴스 목록 조회 (페이징)
     * 최신순 정렬
     */
    public Page<StockNews> getAllNews(Pageable pageable) {
        return stockNewsRepository.findAllByOrderByPublishedAtDesc(pageable);
    }

    /**
     * ID로 뉴스 조회
     */
    public Optional<StockNews> getNewsById(Long id) {
        return stockNewsRepository.findById(id);
    }

    /**
     * ID로 뉴스 조회 + 디코딩된 상세 정보
     */
    public Map<String, Object> getNewsDetailById(Long id) {
        Optional<StockNews> newsOpt = stockNewsRepository.findById(id);

        if (newsOpt.isEmpty()) {
            return null;
        }

        StockNews news = newsOpt.get();

        // 디코딩
        Map<String, String> decodedData = decodeNewsDetail(news.getEncodedData());

        // 결과 조합
        Map<String, Object> result = new HashMap<>();
        result.put("id", news.getId());
        result.put("symbol", news.getSymbol());
        result.put("title", news.getTitle());
        result.put("publishedAt", news.getPublishedAt());
        result.put("thumbnailUrl", news.getThumbnailUrl());
        result.put("crawledAt", news.getCrawledAt());

        // 디코딩된 데이터
        result.put("url", decodedData.get("url"));
        result.put("summary", decodedData.get("summary"));
        result.put("publisher", decodedData.get("publisher"));
        result.put("fullContent", decodedData.get("full_content"));

        return result;
    }

    /**
     * 종목별 뉴스 조회 (페이징)
     */
    public Page<StockNews> getNewsBySymbol(String symbol, Pageable pageable) {
        return stockNewsRepository.findBySymbol(symbol, pageable);
    }

    /**
     * 제목으로 검색 (페이징)
     */
    public Page<StockNews> searchNewsByTitle(String keyword, Pageable pageable) {
        return stockNewsRepository.searchByTitle(keyword, pageable);
    }

    /**
     * 전체 뉴스 개수
     */
    public long getTotalNewsCount() {
        return stockNewsRepository.count();
    }

    /**
     * 종목별 뉴스 개수
     */
    public long getNewsCountBySymbol(String symbol) {
        return stockNewsRepository.countBySymbol(symbol);
    }

    /**
     * DB에 존재하는 고유 symbol 목록 조회
     */
    public List<String> getDistinctSymbols() {
        return stockNewsRepository.findDistinctSymbols();
    }

    /**
     * 특정 날짜의 뉴스 조회
     */
    public List<StockNews> getNewsByDate(java.time.LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(23, 59, 59);
        return stockNewsRepository.findByDateRange(startOfDay, endOfDay);
    }

    /**
     * 특정 월에 뉴스가 있는 날짜 목록 조회
     */
    public List<String> getDatesWithNews(int year, int month) {
        List<java.sql.Date> dates = stockNewsRepository.findDatesWithNews(year, month);
        return dates.stream()
                .map(d -> d.toLocalDate().toString())
                .toList();
    }

    /**
     * ========================================
     * 주가 변동률 계산
     * ========================================
     */

    /**
     * 뉴스 발행 시점 전후 주가 변동률 계산
     * 
     * @param symbol 종목 심볼
     * @param publishedAt 뉴스 발행 시간
     * @return 변동률 정보 (1시간 후, 1일 후)
     */
    public Map<String, Object> calculatePriceChange(String symbol, LocalDateTime publishedAt) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 1. 뉴스 발행 직전 가격
            Optional<StockCandle1m> beforeOpt = stockCandle1mRepository.findLatestBefore(symbol, publishedAt);
            
            if (beforeOpt.isEmpty()) {
                log.warn("⚠️  뉴스 발행 직전 가격 데이터 없음: {} @ {}", symbol, publishedAt);
                result.put("available", false);
                result.put("message", "가격 데이터 없음");
                return result;
            }
            
            StockCandle1m before = beforeOpt.get();
            double beforePrice = before.getClose().doubleValue();
            
            result.put("available", true);
            result.put("beforePrice", beforePrice);
            result.put("beforeTime", before.getTimestamp());
            
            // 2. 1시간 후 가격
            LocalDateTime after1Hour = publishedAt.plusHours(1);
            Optional<StockCandle1m> after1hOpt = stockCandle1mRepository.findEarliestAfter(symbol, after1Hour);
            
            if (after1hOpt.isPresent()) {
                StockCandle1m after1h = after1hOpt.get();
                double after1hPrice = after1h.getClose().doubleValue();
                double change1h = ((after1hPrice - beforePrice) / beforePrice) * 100;
                
                result.put("after1hPrice", after1hPrice);
                result.put("after1hTime", after1h.getTimestamp());
                result.put("change1h", Math.round(change1h * 100.0) / 100.0);
            }
            
            // 3. 1일 후 가격
            LocalDateTime after1Day = publishedAt.plusDays(1);
            Optional<StockCandle1m> after1dOpt = stockCandle1mRepository.findEarliestAfter(symbol, after1Day);
            
            if (after1dOpt.isPresent()) {
                StockCandle1m after1d = after1dOpt.get();
                double after1dPrice = after1d.getClose().doubleValue();
                double change1d = ((after1dPrice - beforePrice) / beforePrice) * 100;
                
                result.put("after1dPrice", after1dPrice);
                result.put("after1dTime", after1d.getTimestamp());
                result.put("change1d", Math.round(change1d * 100.0) / 100.0);
            }
            
            log.info("✅ 주가 변동률 계산 완료: {} - 1h: {}%, 1d: {}%", 
                symbol, result.get("change1h"), result.get("change1d"));
            
        } catch (Exception e) {
            log.error("❌ 주가 변동률 계산 실패: {}", symbol, e);
            result.put("available", false);
            result.put("message", "계산 오류");
        }
        
        return result;
    }
}