package com.weenie_hut_jr.the_salty_spitoon.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class DataStatus {
    private String symbol;
    private String name; // ✅ 추가
    private LocalDateTime lastUpdate;
    private BigDecimal lastPrice;
    private Long lastVolume;
    private String status; // FRESH, STALE, OLD

    // ✅ admin.jsp가 기대하는 필드 추가
    private String mysqlLatest; // MySQL 최신 시각 (문자열)
    private String yahooLatest; // 현재 시각 (문자열)
    private Long gapMinutes; // 공백 (분)
}