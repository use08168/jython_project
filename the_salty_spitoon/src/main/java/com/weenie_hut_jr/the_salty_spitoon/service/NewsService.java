package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
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
import java.util.Base64;
import java.util.HashMap;
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
}