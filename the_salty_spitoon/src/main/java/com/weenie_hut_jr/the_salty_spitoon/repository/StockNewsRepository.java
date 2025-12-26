package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.entity.StockNews;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 주식 뉴스 Repository
 */
@Repository
public interface StockNewsRepository extends JpaRepository<StockNews, Long> {

    /**
     * 종목별 뉴스 조회 (페이징)
     */
    Page<StockNews> findBySymbol(String symbol, Pageable pageable);

    /**
     * 종목별 뉴스 조회 (발행일 내림차순)
     */
    List<StockNews> findBySymbolOrderByPublishedAtDesc(String symbol);

    /**
     * 최근 뉴스 조회 (페이징)
     */
    Page<StockNews> findAllByOrderByPublishedAtDesc(Pageable pageable);

    /**
     * 특정 기간 뉴스 조회
     */
    @Query("SELECT n FROM StockNews n WHERE n.publishedAt BETWEEN :startDate AND :endDate ORDER BY n.publishedAt DESC")
    List<StockNews> findByDateRange(@Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    /**
     * 종목 + 기간 뉴스 조회
     */
    @Query("SELECT n FROM StockNews n WHERE n.symbol = :symbol AND n.publishedAt BETWEEN :startDate AND :endDate ORDER BY n.publishedAt DESC")
    List<StockNews> findBySymbolAndDateRange(@Param("symbol") String symbol,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    /**
     * 제목으로 검색 (LIKE)
     */
    @Query("SELECT n FROM StockNews n WHERE n.title LIKE %:keyword% ORDER BY n.publishedAt DESC")
    Page<StockNews> searchByTitle(@Param("keyword") String keyword, Pageable pageable);

    /**
     * 종목별 뉴스 개수
     */
    long countBySymbol(String symbol);

    /**
     * 제목 + 발행일로 중복 체크
     */
    boolean existsByTitleAndPublishedAt(String title, LocalDateTime publishedAt);

    /**
     * 특정 날짜 이후 뉴스 삭제 (관리용)
     */
    void deleteByPublishedAtBefore(LocalDateTime date);
}