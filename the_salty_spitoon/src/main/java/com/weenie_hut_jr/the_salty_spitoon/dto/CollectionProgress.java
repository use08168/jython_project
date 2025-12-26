package com.weenie_hut_jr.the_salty_spitoon.dto;

import java.util.List;
import java.util.ArrayList;

/**
 * 과거 데이터 수집 진행률 DTO
 * WebSocket을 통해 클라이언트에게 전송
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-26
 */
public class CollectionProgress {
    
    private String type;           // "progress" 또는 "complete"
    private int current;           // 현재 진행 수
    private int total;             // 전체 종목 수
    private String symbol;         // 현재 처리 중인 종목
    private String status;         // "success", "failed", "processing"
    private String message;        // 상세 메시지
    private int candleCount;       // 수집된 캔들 수
    
    // 완료 시 통계
    private int successCount;
    private int failedCount;
    private int totalCandles;
    private List<String> failedSymbols;
    private String duration;
    
    public CollectionProgress() {
        this.failedSymbols = new ArrayList<>();
    }
    
    // 진행 중 상태 생성
    public static CollectionProgress progress(int current, int total, String symbol, 
                                               String status, String message, int candleCount) {
        CollectionProgress p = new CollectionProgress();
        p.type = "progress";
        p.current = current;
        p.total = total;
        p.symbol = symbol;
        p.status = status;
        p.message = message;
        p.candleCount = candleCount;
        return p;
    }
    
    // 완료 상태 생성
    public static CollectionProgress complete(int successCount, int failedCount, 
                                               int totalCandles, List<String> failedSymbols, 
                                               String duration) {
        CollectionProgress p = new CollectionProgress();
        p.type = "complete";
        p.successCount = successCount;
        p.failedCount = failedCount;
        p.totalCandles = totalCandles;
        p.failedSymbols = failedSymbols != null ? failedSymbols : new ArrayList<>();
        p.duration = duration;
        return p;
    }
    
    // 에러 상태 생성
    public static CollectionProgress error(String message) {
        CollectionProgress p = new CollectionProgress();
        p.type = "error";
        p.status = "error";
        p.message = message;
        return p;
    }

    // Getters and Setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    
    public int getCurrent() { return current; }
    public void setCurrent(int current) { this.current = current; }
    
    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }
    
    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    
    public int getCandleCount() { return candleCount; }
    public void setCandleCount(int candleCount) { this.candleCount = candleCount; }
    
    public int getSuccessCount() { return successCount; }
    public void setSuccessCount(int successCount) { this.successCount = successCount; }
    
    public int getFailedCount() { return failedCount; }
    public void setFailedCount(int failedCount) { this.failedCount = failedCount; }
    
    public int getTotalCandles() { return totalCandles; }
    public void setTotalCandles(int totalCandles) { this.totalCandles = totalCandles; }
    
    public List<String> getFailedSymbols() { return failedSymbols; }
    public void setFailedSymbols(List<String> failedSymbols) { this.failedSymbols = failedSymbols; }
    
    public String getDuration() { return duration; }
    public void setDuration(String duration) { this.duration = duration; }
}
