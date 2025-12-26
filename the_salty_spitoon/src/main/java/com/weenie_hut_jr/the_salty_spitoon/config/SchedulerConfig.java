package com.weenie_hut_jr.the_salty_spitoon.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Spring Scheduler 활성화 설정
 * 
 * 역할:
 * - @Scheduled 어노테이션 활성화
 * - StockDataCollector의 주기적 실행 지원
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Configuration
@EnableScheduling
public class SchedulerConfig {
    // @EnableScheduling 어노테이션만으로 설정 완료
}