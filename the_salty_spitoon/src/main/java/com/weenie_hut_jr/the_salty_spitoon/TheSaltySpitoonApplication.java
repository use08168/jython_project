package com.weenie_hut_jr.the_salty_spitoon;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * The Salty Spitoon - 실시간 주식 차트 애플리케이션
 * Spring Boot 메인 애플리케이션 클래스
 * 
 * ========================================
 * 프로젝트 개요
 * ========================================
 * 
 * 프로젝트명: The Salty Spitoon
 * 목적: NASDAQ 100 종목 실시간 주가 차트 서비스
 * 기술 스택:
 * - Backend: Spring Boot 3.x, MyBatis, JPA
 * - Database: MySQL 8.0
 * - Python: 데이터 수집 (yfinance, pandas)
 * - Frontend: JSP, JavaScript, WebSocket
 * - 실시간 통신: STOMP over WebSocket
 * 
 * ========================================
 * 주요 기능
 * ========================================
 * 
 * 1. 실시간 데이터 수집
 * - Python (stock_collector.py) → 1분마다 NASDAQ 100 데이터 수집
 * - JSON 파일 기반 통신 (latest_data.json)
 * - FileDataCollector → MySQL 저장
 * 
 * 2. WebSocket 실시간 스트리밍
 * - STOMP 프로토콜
 * - Topic: /topic/stock/{symbol}
 * - 모든 구독자에게 실시간 데이터 브로드캐스트
 * 
 * 3. 차트 시각화
 * - 1분/5분/15분/1시간/4시간/일봉 타임프레임 지원
 * - 기술지표: MA(5,20,50,200), RSI(14)
 * - 대시보드: NASDAQ 100 전체 종목 모니터링
 * 
 * 4. 과거 데이터 로드
 * - historical_loader.py 실행
 * - yfinance API 활용
 * - 초기 데이터베이스 구축
 * 
 * ========================================
 * 아키텍처
 * ========================================
 * 
 * [데이터 수집 계층]
 * Python (stock_collector.py)
 * → latest_data.json
 * → FileDataCollector (@Scheduled 5초)
 * → MySQL (stock_candle_1m)
 * 
 * [데이터 제공 계층]
 * Client (JavaScript)
 * → REST API (/stock/api/*)
 * → StockController
 * → StockService
 * → StockCandle1mRepository
 * → MySQL
 * 
 * [실시간 통신 계층]
 * FileDataCollector
 * → WebSocket (SimpMessagingTemplate)
 * → /topic/stock/{symbol}
 * → Subscribed Clients
 * 
 * ========================================
 * Spring Boot 설정
 * ========================================
 * 
 * @SpringBootApplication:
 *                         - 자동 설정 활성화 (@EnableAutoConfiguration)
 *                         - 컴포넌트 스캔 (@ComponentScan)
 *                         - 설정 클래스 등록 (@Configuration)
 *                         - 이 패키지 하위의 모든 @Component, @Service, @Controller 자동
 *                         스캔
 * 
 * @EnableScheduling:
 *                    - Spring Scheduler 활성화
 *                    - @Scheduled 어노테이션 사용 가능
 *                    - 용도:
 *                    1. FileDataCollector: 5초마다 JSON 파일 체크
 *                    2. 향후: 헬스 체크, 데이터 정리 등
 *                    - 스케줄러 설정: SchedulerConfig.java
 * 
 * @EnableAsync:
 *               - 비동기 처리 활성화
 *               - @Async 어노테이션 사용 가능
 *               - 용도:
 *               1. 이메일 발송 (비차단)
 *               2. 대용량 데이터 처리
 *               3. 장시간 작업 (historical data load)
 *               - 기본: SimpleAsyncTaskExecutor 사용
 *               - 커스텀 설정 가능 (ThreadPoolTaskExecutor)
 * 
 *               ========================================
 *               애플리케이션 시작 순서
 *               ========================================
 * 
 *               1. main() 메서드 실행
 *               2. SpringApplication.run() 호출
 *               3. Spring Context 초기화
 *               4. Bean 생성 및 의존성 주입
 *               5. @PostConstruct 메서드 실행
 *               → PythonManager.initialize()
 *               - Python 가상환경 설정 (start.py)
 *               - stock_collector.py 실행
 *               6. @Scheduled 메서드 시작
 *               → FileDataCollector.checkForUpdates()
 *               7. 내장 Tomcat 서버 시작 (포트: 8080)
 *               8. 애플리케이션 준비 완료
 * 
 *               ========================================
 *               종료 순서
 *               ========================================
 * 
 *               1. Ctrl+C 또는 종료 신호 수신
 *               2. Graceful Shutdown 시작
 *               3. @PreDestroy 메서드 실행
 *               → PythonManager.shutdown()
 *               - Python 프로세스 정상 종료 (5초 대기)
 *               - 강제 종료 (필요 시)
 *               - Lock 파일 정리
 *               4. WebSocket 연결 종료
 *               5. 데이터베이스 연결 해제
 *               6. Spring Context 종료
 *               7. JVM 종료
 * 
 *               ========================================
 *               환경 설정
 *               ========================================
 * 
 *               application.properties:
 *               - server.port: 서버 포트 (기본 8080)
 *               - spring.datasource.*: MySQL 연결 정보
 *               - python.path: Python 실행 경로
 *               - python.base.dir: Python 프로젝트 디렉토리
 * 
 *               필수 디렉토리 구조:
 *               project-root/
 *               ├── src/main/java/ # Java 소스
 *               ├── src/main/webapp/ # JSP 뷰
 *               ├── python/ # Python 스크립트
 *               │ ├── venv/ # 가상환경
 *               │ ├── start.py # 환경 설정
 *               │ ├── stock_collector.py # 실시간 수집
 *               │ ├── historical_loader.py # 과거 데이터 로드
 *               │ ├── config/ # 설정 파일
 *               │ ├── output/ # 출력 데이터
 *               │ ├── requests/ # 요청 파일
 *               │ └── results/ # 결과 파일
 *               └── build.gradle # Gradle 빌드 설정
 * 
 *               ========================================
 *               주요 의존성
 *               ========================================
 * 
 *               - Spring Boot Web: REST API, MVC
 *               - Spring Boot WebSocket: 실시간 통신
 *               - Spring Boot Data JPA: ORM
 *               - MyBatis Spring Boot Starter: SQL 매핑
 *               - MySQL Connector: 데이터베이스 드라이버
 *               - Lombok: 보일러플레이트 코드 제거
 *               - Jackson: JSON 직렬화/역직렬화
 * 
 *               Python 의존성:
 *               - yfinance: 주식 데이터 API
 *               - pandas: 데이터 처리
 *               - numpy: 수치 계산
 * 
 *               ========================================
 *               실행 방법
 *               ========================================
 * 
 *               개발 환경:
 *               1. MySQL 서버 시작
 *               2. 데이터베이스 생성: CREATE DATABASE stock_db;
 *               3. Python 가상환경 설정: cd python && python -m venv venv
 *               4. 패키지 설치: pip install -r requirements.txt
 *               5. Spring Boot 실행: ./gradlew bootRun
 *               또는 IDE에서 TheSaltySpitoonApplication 실행
 *               6. 브라우저: http://localhost:8080/stock
 * 
 *               프로덕션 배포:
 *               1. JAR 빌드: ./gradlew build
 *               2. 실행: java -jar
 *               build/libs/the-salty-spitoon-0.0.1-SNAPSHOT.jar
 *               3. 환경변수 설정: DB 정보, Python 경로 등
 * 
 *               ========================================
 *               트러블슈팅
 *               ========================================
 * 
 *               Python 시작 실패:
 *               - venv가 없거나 손상됨 → python/start.py 재실행
 *               - 패키지 미설치 → pip install -r requirements.txt
 *               - 경로 문제 → application.properties의 python.base.dir 확인
 * 
 *               데이터 수집 안 됨:
 *               - Python 프로세스 상태 확인: GET /admin/python-status
 *               - 로그 확인: [Python] 접두사 로그
 *               - 재시작: POST /admin/restart-python
 * 
 *               WebSocket 연결 실패:
 *               - CORS 설정 확인: WebSocketConfig.setAllowedOriginPatterns
 *               - SockJS 폴백 확인
 *               - 브라우저 콘솔 에러 체크
 * 
 *               차트 데이터 없음:
 *               - MySQL 데이터 확인: SELECT COUNT(*) FROM stock_candle_1m
 *               - 과거 데이터 로드: POST /admin/load-historical
 *               - Python 수집 확인: python/output/latest_data.json 파일
 * 
 *               ========================================
 *               모니터링 및 관리
 *               ========================================
 * 
 *               관리자 API:
 *               - GET /admin/python-status : Python 상태 확인
 *               - POST /admin/restart-python : Python 재시작
 *               - POST /admin/load-historical : 과거 데이터 로드
 * 
 *               로그 확인:
 *               - Application 로그: Spring Boot 로그
 *               - Python 로그: [Python] 접두사
 *               - 수집 통계: "📊 Data processed: N saved, M skipped"
 *               - 실시간 데이터: "✅ AAPL - Saved: $273.67 @ 15:30"
 * 
 *               데이터베이스 모니터링:
 *               - 테이블 크기: SELECT COUNT(*) FROM stock_candle_1m
 *               - 최신 데이터: SELECT MAX(timestamp) FROM stock_candle_1m
 *               - 종목별 통계: SELECT symbol, COUNT(*) FROM stock_candle_1m GROUP BY
 *               symbol
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 * @version 1.0.0
 */
@SpringBootApplication // Spring Boot 자동 설정 + 컴포넌트 스캔 + 설정 클래스
@EnableScheduling // 스케줄러 활성화 (@Scheduled 사용 가능)
@EnableAsync // 비동기 처리 활성화 (@Async 사용 가능)
public class TheSaltySpitoonApplication {

	/**
	 * 애플리케이션 진입점 (Entry Point)
	 * 
	 * 기능:
	 * - Spring Boot 애플리케이션 시작
	 * - Spring Context 초기화
	 * - 내장 Tomcat 서버 구동
	 * 
	 * 실행 과정:
	 * 1. SpringApplication 객체 생성
	 * 2. 설정 로드 (application.properties)
	 * 3. Bean 생성 및 의존성 주입
	 * 4. @PostConstruct 메서드 실행 (PythonManager 초기화)
	 * 5. 내장 Tomcat 시작
	 * 6. 포트 바인딩 (기본 8080)
	 * 7. 애플리케이션 준비 완료 로그 출력
	 * 
	 * 시작 로그 예시:
	 * 
	 * . ____ _ __ _ _
	 * /\\ / ___'_ __ _ _(_)_ __ __ _ \ \ \ \
	 * ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
	 * \\/ ___)| |_)| | | | | || (_| | ) ) ) )
	 * ' |____| .__|_| |_|_| |_\__, | / / / /
	 * =========|_|==============|___/=/_/_/_/
	 * :: Spring Boot :: (v3.2.0)
	 * 
	 * ========================================
	 * Python Manager Initialization
	 * ========================================
	 * Setting up Python environment...
	 * ✅ Python environment ready
	 * Python executable: python/venv/bin/python
	 * Starting Python collector...
	 * ✅ Python collector started (PID: 12345)
	 * ========================================
	 * Python Manager Ready
	 * ========================================
	 * 
	 * Started TheSaltySpitoonApplication in 15.234 seconds (JVM running for 16.5)
	 * 
	 * 접속 URL:
	 * - 대시보드: http://localhost:8080/stock
	 * - 상세 차트: http://localhost:8080/stock/detail/AAPL
	 * - 관리자: http://localhost:8080/admin/*
	 * 
	 * 종료:
	 * - Ctrl+C 또는 IDE 정지 버튼
	 * - Graceful Shutdown 진행
	 * - Python 프로세스 자동 종료
	 * 
	 * JVM 옵션 (선택):
	 * - 메모리: -Xms512m -Xmx2g
	 * - GC: -XX:+UseG1GC
	 * - 프로파일: -Dspring.profiles.active=prod
	 * 
	 * 환경변수 (선택):
	 * - SPRING_PROFILES_ACTIVE=prod
	 * - SPRING_DATASOURCE_URL=jdbc:mysql://...
	 * - PYTHON_PATH=python3
	 * 
	 * @param args 커맨드라인 인자 (일반적으로 사용 안 함)
	 *             예: --server.port=9090 --spring.profiles.active=dev
	 */
	public static void main(String[] args) {
		// Spring Boot 애플리케이션 실행
		// - TheSaltySpitoonApplication.class: 메인 설정 클래스
		// - args: 커맨드라인 인자 전달
		SpringApplication.run(TheSaltySpitoonApplication.class, args);
	}

	// ========================================
	// 향후 확장 (TODO)
	// ========================================

	/**
	 * TODO: 커스텀 AsyncConfigurer 설정
	 * 
	 * @Configuration
	 *                public class AsyncConfig implements AsyncConfigurer {
	 * @Override
	 *           public Executor getAsyncExecutor() {
	 *           ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
	 *           executor.setCorePoolSize(5);
	 *           executor.setMaxPoolSize(10);
	 *           executor.setQueueCapacity(100);
	 *           executor.setThreadNamePrefix("async-");
	 *           executor.initialize();
	 *           return executor;
	 *           }
	 *           }
	 */

	/**
	 * TODO: 커스텀 Banner 설정
	 * 
	 * public static void main(String[] args) {
	 * SpringApplication app = new
	 * SpringApplication(TheSaltySpitoonApplication.class);
	 * app.setBannerMode(Banner.Mode.OFF);
	 * // 또는 커스텀 배너: src/main/resources/banner.txt
	 * app.run(args);
	 * }
	 */

	/**
	 * TODO: ApplicationRunner로 초기 데이터 로드
	 * 
	 * @Bean
	 *       public ApplicationRunner init(StockRepository stockRepository) {
	 *       return args -> {
	 *       log.info("Initializing default stocks...");
	 *       // NASDAQ 100 종목 초기화
	 *       };
	 *       }
	 */
}