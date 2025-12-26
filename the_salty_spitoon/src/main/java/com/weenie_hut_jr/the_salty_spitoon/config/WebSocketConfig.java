package com.weenie_hut_jr.the_salty_spitoon.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * WebSocket 설정 클래스
 * 
 * 역할:
 * - WebSocket 연결 엔드포인트 설정
 * - 메시지 브로커 설정
 * - STOMP 프로토콜 활성화
 * 
 * 사용:
 * - 실시간 주식 데이터 전송
 * - 서버 → 클라이언트 단방향 통신
 * 
 * 통신 흐름:
 * 1. 클라이언트: /ws 엔드포인트로 연결
 * 2. 클라이언트: /topic/stock/{symbol} 구독
 * 3. 서버: 1분마다 새 데이터를 /topic/stock/{symbol}로 전송
 * 4. 클라이언트: 구독 중인 모든 클라이언트가 데이터 수신
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /**
     * 메시지 브로커 설정
     * 
     * @param config 메시지 브로커 레지스트리
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // 메시지 브로커 활성화
        // "/topic"으로 시작하는 메시지는 브로커가 처리
        config.enableSimpleBroker("/topic");

        // 클라이언트에서 서버로 메시지 전송 시 prefix
        // (현재는 서버→클라이언트만 사용하므로 실제로는 미사용)
        config.setApplicationDestinationPrefixes("/app");
    }

    /**
     * WebSocket 연결 엔드포인트 등록
     * 
     * @param registry STOMP 엔드포인트 레지스트리
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // "/ws" 엔드포인트로 WebSocket 연결
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*") // CORS 설정 (개발 환경)
                .withSockJS(); // SockJS 폴백 활성화 (WebSocket 미지원 브라우저 대응)
    }
}