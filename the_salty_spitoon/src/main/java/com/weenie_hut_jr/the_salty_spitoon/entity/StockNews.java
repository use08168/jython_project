package com.weenie_hut_jr.the_salty_spitoon.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 주식 뉴스 Entity
 */
@Entity
@Table(name = "stock_news", indexes = {
        @Index(name = "idx_symbol", columnList = "symbol"),
        @Index(name = "idx_published_at", columnList = "published_at"),
        @Index(name = "idx_symbol_published", columnList = "symbol, published_at")
}, uniqueConstraints = {
        @UniqueConstraint(name = "uk_title_date", columnNames = { "title", "published_at" })
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockNews {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 종목 심볼 (예: AAPL, GOOGL)
     */
    @Column(nullable = false, length = 10)
    private String symbol;

    /**
     * 뉴스 제목
     */
    @Column(nullable = false, length = 500)
    private String title;

    /**
     * 뉴스 발행 시간
     */
    @Column(name = "published_at", nullable = false)
    private LocalDateTime publishedAt;

    /**
     * 썸네일 이미지 URL
     */
    @Column(name = "thumbnail_url", length = 1000)
    private String thumbnailUrl;

    /**
     * 인코딩된 뉴스 상세 데이터 (gzip + Base64)
     * - url
     * - summary
     * - publisher
     * - full_content
     */
    @Lob
    @Column(name = "encoded_data", nullable = false, columnDefinition = "MEDIUMTEXT")
    private String encodedData;

    /**
     * 크롤링 시간
     */
    @Column(name = "crawled_at")
    private LocalDateTime crawledAt;

    /**
     * 생성 시간 자동 설정
     */
    @PrePersist
    protected void onCreate() {
        if (crawledAt == null) {
            crawledAt = LocalDateTime.now();
        }
    }
}