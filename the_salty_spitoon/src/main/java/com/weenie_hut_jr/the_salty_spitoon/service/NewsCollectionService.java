package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockNewsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * 뉴스 수집 Service
 * - JSON 파일 읽기
 * - MySQL 저장
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NewsCollectionService {

    private final StockNewsRepository stockNewsRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * news_details.json 파일을 읽어서 MySQL에 저장
     */
    @Transactional
    public void loadNewsFromJson(String jsonFilePath) {
        log.info("========================================");
        log.info("뉴스 데이터 로딩 시작");
        log.info("========================================");
        log.info("파일 경로: {}", jsonFilePath);

        try {
            // 1. JSON 파일 읽기
            File jsonFile = new File(jsonFilePath);
            if (!jsonFile.exists()) {
                log.error("❌ 파일이 존재하지 않습니다: {}", jsonFilePath);
                throw new IllegalArgumentException("파일을 찾을 수 없습니다: " + jsonFilePath);
            }

            JsonNode rootNode = objectMapper.readTree(jsonFile);
            String timestamp = rootNode.get("timestamp").asText();
            int totalNews = rootNode.get("total_news").asInt();
            JsonNode dataArray = rootNode.get("data");

            log.info("파일 생성 시간: {}", timestamp);
            log.info("총 뉴스 개수: {}", totalNews);

            // 2. 뉴스 데이터 파싱 및 저장
            int successCount = 0;
            int skipCount = 0;
            int errorCount = 0;

            List<StockNews> newsToSave = new ArrayList<>();

            for (JsonNode newsNode : dataArray) {
                try {
                    String symbol = newsNode.get("symbol").asText();
                    String title = newsNode.get("title").asText();
                    String publishedAtStr = newsNode.get("published_at").asText();
                    String thumbnailUrl = newsNode.has("thumbnail_url") && !newsNode.get("thumbnail_url").isNull()
                            ? newsNode.get("thumbnail_url").asText()
                            : null;
                    String encodedData = newsNode.has("encoded_data") && !newsNode.get("encoded_data").isNull()
                            ? newsNode.get("encoded_data").asText()
                            : null;

                    // encoded_data가 없으면 스킵
                    if (encodedData == null || encodedData.isEmpty()) {
                        log.warn("⚠️  encoded_data 없음 - 스킵: {}", title);
                        skipCount++;
                        continue;
                    }

                    // 날짜 파싱
                    LocalDateTime publishedAt = LocalDateTime.parse(publishedAtStr, DATE_FORMATTER);

                    // 중복 체크
                    if (stockNewsRepository.existsByTitleAndPublishedAt(title, publishedAt)) {
                        log.debug("중복 뉴스 스킵: {}", title);
                        skipCount++;
                        continue;
                    }

                    // Entity 생성
                    StockNews stockNews = StockNews.builder()
                            .symbol(symbol)
                            .title(title)
                            .publishedAt(publishedAt)
                            .thumbnailUrl(thumbnailUrl)
                            .encodedData(encodedData)
                            .build();

                    newsToSave.add(stockNews);
                    successCount++;

                } catch (Exception e) {
                    log.error("❌ 뉴스 처리 중 오류: {}", e.getMessage());
                    errorCount++;
                }
            }

            // 3. 일괄 저장
            if (!newsToSave.isEmpty()) {
                stockNewsRepository.saveAll(newsToSave);
                log.info("✅ {}개 뉴스 저장 완료", newsToSave.size());
            }

            // 4. 결과 출력
            log.info("========================================");
            log.info("뉴스 로딩 완료");
            log.info("========================================");
            log.info("✅ 성공: {}", successCount);
            log.info("⚠️  스킵: {}", skipCount);
            log.info("❌ 에러: {}", errorCount);
            log.info("========================================");

        } catch (Exception e) {
            log.error("❌ 뉴스 로딩 실패", e);
            throw new RuntimeException("뉴스 로딩 중 오류 발생", e);
        }
    }

    /**
     * 전체 뉴스 개수 조회
     */
    public long getTotalNewsCount() {
        return stockNewsRepository.count();
    }

    /**
     * 종목별 뉴스 개수 조회
     */
    public long getNewsCountBySymbol(String symbol) {
        return stockNewsRepository.countBySymbol(symbol);
    }
}