package com.weenie_hut_jr.the_salty_spitoon.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollectionResult {
    private Boolean success;
    private String message;
    private Integer totalSymbols;
    private Integer successCount;
    private Integer failureCount;
    private Integer totalCandles;
    private String startTime;
    private String endTime;
    private List<SymbolResult> symbolResults;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SymbolResult {
        private String symbol;
        private Boolean success;
        private Integer candlesCollected;
        private String message;
    }
}