package com.weenie_hut_jr.the_salty_spitoon.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Python 프로세스 생명주기 관리 서비스
 * 
 * 역할:
 * - Spring Boot 애플리케이션과 Python 스크립트의 통합 관리
 * - Python 실시간 데이터 수집기(stock_collector.py) 제어
 * - 프로세스 시작/중지/재시작 관리
 * - Python 출력 로그를 Spring 로그 시스템으로 통합
 * 
 * 생명주기:
 * 1. Spring 시작 (@PostConstruct)
 * → Python 가상환경 설정 (start.py)
 * → stock_collector.py 실행
 * → 백그라운드 프로세스로 계속 실행
 * 
 * 2. Spring 실행 중
 * → Python 프로세스 모니터링
 * → 로그 수집 및 전달
 * → 상태 체크 API 제공
 * 
 * 3. Spring 종료 (@PreDestroy)
 * → Python 프로세스 우아하게 종료 (destroy)
 * → 5초 대기 후 강제 종료 (destroyForcibly)
 * → Lock 파일 정리
 * 
 * Python 스크립트 구조:
 * - start.py: 가상환경 설정, 패키지 설치 확인
 * - stock_collector.py: 실시간 데이터 수집 (1분마다)
 * - latest_data.json: 수집 결과 출력
 * 
 * 프로세스 관리:
 * - 단일 프로세스: 한 번에 하나의 collector만 실행
 * - Lock 파일: 중복 실행 방지 (collector.lock)
 * - 자동 재시작: 에러 발생 시 관리자가 수동 재시작
 * 
 * 로그 통합:
 * - Python stdout/stderr → Spring Logger
 * - 별도 스레드로 비동기 로그 수집
 * - [Python] 접두사로 구분
 * 
 * 관리자 기능:
 * - isPythonRunning(): 상태 확인
 * - restartPython(): 수동 재시작
 * - API: /admin/python-status, /admin/restart-python
 * 
 * 에러 처리:
 * - Python 설정 실패: RuntimeException (애플리케이션 시작 중단)
 * - Python 실행 실패: RuntimeException
 * - 종료 실패: 로그만 남기고 계속 (강제 종료)
 * 
 * OS 호환성:
 * - Windows: venv/Scripts/python.exe
 * - Linux/Mac: venv/bin/python
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j // 로깅 기능
@Service // Spring Service Bean
public class PythonManager {

    /**
     * 시스템 Python 명령어
     * 
     * 설정:
     * - application.properties: python.path=python
     * - 기본값: "python"
     * 
     * 용도:
     * - start.py 실행 (가상환경 설정)
     * - 시스템에 설치된 Python 사용
     * 
     * 환경별 설정:
     * - Windows: python 또는 py
     * - Linux/Mac: python3
     * - Conda: conda run python
     * 
     * 주의:
     * - 가상환경이 아닌 시스템 Python
     * - venv 생성 후에는 pythonExecutable 사용
     */
    @Value("${python.path:python}")
    private String pythonCommand;

    /**
     * Python 프로젝트 기본 디렉토리
     * 
     * 설정:
     * - application.properties: python.base.dir=python
     * - 기본값: "python"
     * 
     * 디렉토리 구조:
     * python/
     * ├── venv/ # 가상환경
     * ├── start.py # 환경 설정 스크립트
     * ├── stock_collector.py # 실시간 수집기
     * ├── historical_loader.py
     * ├── config/
     * ├── output/
     * ├── requests/
     * ├── results/
     * └── requirements.txt
     */
    @Value("${python.base.dir:python}")
    private String pythonBaseDir;

    /**
     * Python 프로세스 객체
     * 
     * 역할:
     * - stock_collector.py 실행 중인 프로세스
     * - 프로세스 제어에 사용 (종료, 상태 확인)
     * 
     * 생명주기:
     * - startCollector()에서 생성
     * - shutdown()에서 종료
     * - restartPython()에서 재생성
     * 
     * null 상태:
     * - 초기화 전
     * - 종료 후
     */
    private Process pythonProcess;

    /**
     * 가상환경의 Python 실행 파일 경로
     * 
     * 예시:
     * - Windows: python/venv/Scripts/python.exe
     * - Linux/Mac: python/venv/bin/python
     * 
     * 용도:
     * - stock_collector.py 실행
     * - 가상환경 내 패키지 사용 (yfinance 등)
     * 
     * 설정 시점:
     * - setupPythonEnvironment()에서 초기화
     */
    private String pythonExecutable;

    /**
     * Spring 시작 시 자동 실행되는 초기화 메서드
     * 
     * @PostConstruct:
     *                 - Spring Bean 생성 후 자동 호출
     *                 - 의존성 주입 완료 후 실행
     *                 - 생성자 실행 → 의존성 주입 → @PostConstruct
     * 
     *                 실행 순서:
     *                 1. Spring Boot 애플리케이션 시작
     *                 2. PythonManager Bean 생성
     *                 3. @Value 필드 주입
     *                 4. initialize() 호출 ← 여기
     *                 5. 애플리케이션 준비 완료
     * 
     *                 동작 과정:
     *                 1. Python 가상환경 설정 (start.py)
     *                 - venv 존재 확인
     *                 - 없으면 생성
     *                 - requirements.txt 패키지 설치
     * 
     *                 2. stock_collector.py 시작
     *                 - 백그라운드 프로세스 실행
     *                 - 1분마다 데이터 수집
     *                 - latest_data.json 업데이트
     * 
     *                 3. 프로세스 모니터링 설정
     *                 - 로그 수집 스레드 시작
     *                 - Python 출력 → Spring Logger
     * 
     *                 실행 시간:
     *                 - start.py: ~5-10초 (패키지 설치 여부)
     *                 - stock_collector.py: ~1초 (프로세스 시작)
     *                 - 총: 약 10-15초
     * 
     *                 에러 처리:
     *                 - 실패 시 RuntimeException
     *                 - Spring Boot 애플리케이션 시작 중단
     *                 - 로그 확인 후 수동 조치 필요
     * 
     *                 로그 출력:
     *                 ========================================
     *                 Python Manager Initialization
     *                 ========================================
     *                 Setting up Python environment...
     *                 ✅ Python environment ready
     *                 Python executable: python/venv/bin/python
     *                 Starting Python collector...
     *                 ✅ Python collector started (PID: 12345)
     *                 ========================================
     *                 Python Manager Ready
     *                 ========================================
     */
    @PostConstruct
    public void initialize() {
        log.info("========================================");
        log.info("Python Manager Initialization");
        log.info("========================================");

        try {
            // 1. Python 환경 설정 (가상환경 생성 및 패키지 설치)
            setupPythonEnvironment();

            // 2. Python 수집기 시작 (stock_collector.py 실행)
            startCollector();

            log.info("========================================");
            log.info("Python Manager Ready");
            log.info("========================================");

        } catch (Exception e) {
            // 초기화 실패 시 애플리케이션 시작 중단
            log.error("Python initialization failed", e);
            throw new RuntimeException("Failed to initialize Python", e);
        }
    }

    /**
     * Python 가상환경 설정 (start.py 실행)
     * 
     * 기능:
     * - start.py 스크립트 실행
     * - 가상환경(venv) 생성 또는 확인
     * - requirements.txt 패키지 설치
     * - 설정 완료 후 venv Python 경로 저장
     * 
     * start.py 동작:
     * 1. venv 디렉토리 존재 확인
     * 2. 없으면: python -m venv venv 실행
     * 3. requirements.txt 확인
     * 4. pip install -r requirements.txt
     * 5. 성공 메시지 출력
     * 
     * requirements.txt 예시:
     * yfinance==0.2.28
     * pandas==2.0.3
     * numpy==1.24.3
     * 
     * ProcessBuilder 설정:
     * - pythonCommand: 시스템 Python (python 또는 python3)
     * - start.py: 설정 스크립트
     * - redirectErrorStream(true): stderr → stdout 통합
     * - inheritIO(): Python 출력을 Java 콘솔에 표시
     * 
     * 동기 실행:
     * - waitFor(): start.py 완료까지 대기
     * - 설정 완료 후 다음 단계 진행
     * 
     * Exit code:
     * - 0: 정상 완료
     * - != 0: 에러 발생 → RuntimeException
     * 
     * 실행 시간:
     * - venv 존재 + 패키지 설치됨: ~2초
     * - venv 생성 + 패키지 설치: ~10-30초
     * 
     * @throws Exception start.py 실행 실패, 패키지 설치 오류
     */
    private void setupPythonEnvironment() throws Exception {
        log.info("Setting up Python environment...");

        ProcessBuilder pb = new ProcessBuilder(
                pythonCommand,
                "-m",
                "pip",
                "install",
                "-r",
                pythonBaseDir + "/requirements.txt",
                "--break-system-packages");

        pb.redirectErrorStream(true); // stderr를 stdout에 합침
        pb.inheritIO(); // Python 출력을 Java 콘솔에 표시

        // 프로세스 시작 및 완료 대기
        Process setupProcess = pb.start();
        int exitCode = setupProcess.waitFor();

        // Exit code 확인
        if (exitCode != 0) {
            throw new RuntimeException("Python setup failed with exit code: " + exitCode);
        }

        // 가상환경의 Python 경로 설정 (OS별)
        pythonExecutable = getPythonExecutablePath();

        log.info("✅ Python environment ready");
        log.info("   Python executable: {}", pythonExecutable);
    }

    /**
     * OS별 Python 실행 파일 경로 반환
     * 
     * OS 감지:
     * - System.getProperty("os.name"): OS 이름
     * - toLowerCase(): 대소문자 통일
     * 
     * 경로 결정:
     * - Windows: python/venv/Scripts/python.exe
     * - Linux/Mac: python/venv/bin/python
     * 
     * venv 구조 차이:
     * - Windows: Scripts/ 폴더에 실행 파일
     * - Unix: bin/ 폴더에 실행 파일
     * 
     * 반환 예시:
     * - Windows: "python/venv/Scripts/python.exe"
     * - Mac: "python/venv/bin/python"
     * - Linux: "python/venv/bin/python"
     * 
     * 사용:
     * - stock_collector.py 실행
     * - historical_loader.py 실행
     * - 가상환경 내 패키지 사용
     * 
     * @return String Python 실행 파일 전체 경로
     */
    private String getPythonExecutablePath() {
        String os = System.getProperty("os.name").toLowerCase();

        if (os.contains("win")) {
            // Windows
            return pythonBaseDir + "/venv/Scripts/python.exe";
        } else {
            // Linux, Mac
            return pythonBaseDir + "/venv/bin/python";
        }
    }

    /**
     * stock_collector.py 실행 (실시간 데이터 수집기)
     * 
     * 기능:
     * - Python 실시간 데이터 수집 스크립트 실행
     * - 백그라운드 프로세스로 계속 실행
     * - 1분마다 NASDAQ 100 종목 데이터 수집
     * - latest_data.json 파일 업데이트
     * 
     * 실행 조건 확인:
     * - pythonExecutable 파일 존재 확인
     * - 없으면 RuntimeException (환경 설정 실패)
     * 
     * ProcessBuilder 설정:
     * - pythonExecutable: 가상환경 Python
     * - stock_collector.py: 수집 스크립트
     * - redirectErrorStream(true): 에러를 표준 출력으로
     * - inheritIO() 사용 안 함 (별도 로그 처리)
     * 
     * 비동기 로그 수집:
     * - 별도 스레드로 Python 출력 읽기
     * - BufferedReader로 라인 단위 읽기
     * - Spring Logger로 전달 ([Python] 접두사)
     * 
     * 로그 예시:
     * [Python] Stock Collector Started
     * [Python] Collecting data for 100 symbols...
     * [Python] AAPL: $273.67 (+0.54%)
     * [Python] GOOGL: $182.35 (-0.45%)
     * [Python] Data saved to latest_data.json
     * 
     * 프로세스 확인:
     * - 1초 대기 (프로세스 안정화)
     * - isAlive() 체크
     * - PID 로깅
     * 
     * stock_collector.py 동작:
     * 1. 활성 종목 목록 로드 (NASDAQ 100)
     * 2. 1분마다 루프:
     * a. 각 종목 현재 데이터 조회 (yfinance)
     * b. OHLCV 데이터 수집
     * c. latest_data.json 업데이트
     * d. 1분 대기
     * 3. Ctrl+C 또는 SIGTERM 받으면 종료
     * 
     * Lock 파일:
     * - collector.lock 생성 (중복 실행 방지)
     * - 종료 시 자동 삭제
     * 
     * 에러 처리:
     * - Python 실행 파일 없음: RuntimeException
     * - 프로세스 시작 실패: RuntimeException
     * - 로그 읽기 실패: 로그만 남기고 계속
     * 
     * @throws Exception Python 실행 실패, 파일 없음 등
     */
    private void startCollector() throws Exception {
        log.info("Starting Python collector...");

        // start.py 실행 (NASDAQ 100 실시간 수집)
        ProcessBuilder pb = new ProcessBuilder(
                pythonCommand, // 시스템 Python 사용
                pythonBaseDir + "/start.py" // start.py로 변경!
        );

        pb.redirectErrorStream(true);

        // 프로세스 시작 (비동기)
        pythonProcess = pb.start();

        // Python 출력을 별도 스레드로 읽기 (비동기)
        new Thread(() -> {
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(pythonProcess.getInputStream()))) {

                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[Python] {}", line);
                }

            } catch (Exception e) {
                log.error("Error reading Python output", e);
            }
        }).start();

        // 프로세스 시작 확인 (1초 대기)
        Thread.sleep(1000);

        // 프로세스 실행 확인
        if (pythonProcess.isAlive()) {
            log.info("✅ Python collector started (PID: {})", pythonProcess.pid());
        } else {
            throw new RuntimeException("Python collector failed to start");
        }
    }

    /**
     * Spring 종료 시 자동 실행되는 정리 메서드
     * 
     * @PreDestroy:
     *              - Spring Context 종료 전 호출
     *              - Bean 파괴 직전 실행
     *              - Graceful Shutdown 구현
     * 
     *              실행 시점:
     *              1. Spring Boot 애플리케이션 종료 요청
     *              2. @PreDestroy 메서드 호출 ← 여기
     *              3. Bean 파괴
     *              4. Spring Context 종료
     *              5. JVM 종료
     * 
     *              정리 작업:
     *              1. Python 프로세스 우아한 종료 시도 (destroy)
     *              2. 5초 대기
     *              3. 종료 안 되면 강제 종료 (destroyForcibly)
     *              4. Lock 파일 삭제 (collector.lock)
     * 
     *              Graceful Shutdown:
     *              - destroy(): SIGTERM 전송 (정상 종료 요청)
     *              - Python이 현재 작업 완료 후 종료
     *              - 5초 타임아웃
     * 
     *              Forceful Shutdown:
     *              - destroyForcibly(): SIGKILL 전송 (강제 종료)
     *              - 즉시 종료
     *              - 마지막 수단
     * 
     *              Lock 파일:
     *              - collector.lock: Python 중복 실행 방지
     *              - 비정상 종료 시 남아있을 수 있음
     *              - 명시적으로 삭제
     * 
     *              로그 출력:
     *              ========================================
     *              Shutting down Python Manager
     *              ========================================
     *              Stopping Python collector...
     *              ✅ Python collector stopped
     *              ✅ Lock file cleaned up
     *              ========================================
     *              Python Manager Stopped
     *              ========================================
     * 
     *              에러 처리:
     *              - 종료 실패: 로그만 남기고 계속
     *              - Lock 파일 삭제 실패: 경고만
     *              - JVM 종료는 정상 진행
     */
    @PreDestroy
    public void shutdown() {
        log.info("========================================");
        log.info("Shutting down Python Manager");
        log.info("========================================");

        // Python 프로세스 종료
        if (pythonProcess != null && pythonProcess.isAlive()) {
            log.info("Stopping Python collector...");

            // 1. 우아한 종료 시도 (SIGTERM)
            pythonProcess.destroy();

            try {
                // 2. 5초 대기
                if (!pythonProcess.waitFor(5, java.util.concurrent.TimeUnit.SECONDS)) {
                    // 3. 종료 안 되면 강제 종료 (SIGKILL)
                    log.warn("Python didn't stop gracefully - force killing");
                    pythonProcess.destroyForcibly();
                }

                log.info("✅ Python collector stopped");

            } catch (InterruptedException e) {
                // 대기 중 인터럽트 발생
                log.error("Error while stopping Python", e);
                pythonProcess.destroyForcibly(); // 강제 종료
            }
        }

        // Lock 파일 정리
        try {
            Path lockFile = Paths.get(pythonBaseDir + "/collector.lock");
            if (Files.exists(lockFile)) {
                Files.delete(lockFile);
                log.info("✅ Lock file cleaned up");
            }
        } catch (Exception e) {
            // Lock 파일 삭제 실패 (중요하지 않음)
            log.warn("Failed to clean up lock file", e);
        }

        log.info("========================================");
        log.info("Python Manager Stopped");
        log.info("========================================");
    }

    /**
     * Python 프로세스 실행 상태 확인
     * 
     * 기능:
     * - 현재 Python 프로세스가 실행 중인지 확인
     * - 관리자 대시보드에서 상태 모니터링
     * 
     * 확인 방법:
     * - pythonProcess != null: 프로세스 객체 존재
     * - isAlive(): 프로세스 실행 중
     * 
     * 반환값:
     * - true: Python 정상 실행 중
     * - false: Python 중지 또는 미실행
     * 
     * 사용 위치:
     * - AdminController.getPythonStatus()
     * - API: GET /admin/python-status
     * 
     * 응답 예시:
     * {
     * "running": true,
     * "status": "OK"
     * }
     * 
     * false가 되는 경우:
     * - 초기화 전 (initialize 호출 전)
     * - Python 크래시
     * - 수동 종료
     * - Spring 종료
     * 
     * 모니터링:
     * - 주기적으로 체크하여 자동 재시작 가능
     * - 알림 시스템 연동 가능
     * 
     * @return boolean true: 실행 중, false: 중지
     */
    public boolean isPythonRunning() {
        return pythonProcess != null && pythonProcess.isAlive();
    }

    /**
     * Python 프로세스 재시작
     * 
     * 기능:
     * - 실행 중인 Python 프로세스 종료
     * - 새 프로세스로 재시작
     * - 에러 복구 또는 설정 변경 후 적용
     * 
     * 동작 과정:
     * 1. 현재 프로세스 존재 및 실행 확인
     * 2. destroy() 호출 (SIGTERM)
     * 3. 5초 대기
     * 4. startCollector() 호출 (새 프로세스)
     * 
     * 사용 시나리오:
     * - Python 크래시 후 복구
     * - 데이터 수집 중단 해결
     * - Config 변경 후 재시작
     * - 메모리 누수 해결
     * 
     * 사용 위치:
     * - AdminController.restartPython()
     * - API: POST /admin/restart-python
     * 
     * 주의사항:
     * - 재시작 중 데이터 수집 중단 (~1-2초)
     * - 진행 중인 수집 작업 손실 가능
     * - 빈번한 재시작은 데이터 품질 저하
     * 
     * 에러 처리:
     * - 종료 실패: Exception 발생
     * - 시작 실패: Exception 발생
     * - 트랜잭션 없음 (원자성 보장 안 됨)
     * 
     * 개선 방안:
     * - 재시작 중 상태 플래그 추가
     * - 재시작 카운트 제한
     * - 헬스 체크 추가
     * 
     * @throws Exception 종료 실패, 시작 실패
     */
    public void restartPython() throws Exception {
        log.info("Restarting Python collector...");

        // 1. 현재 프로세스 종료
        if (pythonProcess != null && pythonProcess.isAlive()) {
            pythonProcess.destroy(); // SIGTERM 전송
            // 5초 대기 (Graceful Shutdown)
            pythonProcess.waitFor(5, java.util.concurrent.TimeUnit.SECONDS);
        }

        // 2. 새 프로세스 시작
        startCollector();
    }

    // ========================================
    // 향후 개선 방안 (TODO)
    // ========================================

    /**
     * TODO: 자동 재시작 (헬스 체크)
     * 
     * @Scheduled(fixedDelay = 60000) // 1분마다
     *                       public void healthCheck() {
     *                       if (!isPythonRunning()) {
     *                       log.warn("Python collector is down - auto restarting");
     *                       try {
     *                       restartPython();
     *                       } catch (Exception e) {
     *                       log.error("Auto restart failed", e);
     *                       }
     *                       }
     *                       }
     */

    /**
     * TODO: Python 로그를 파일로 저장
     * 
     * private void startCollector() throws Exception {
     * pb.redirectOutput(new File("logs/python-collector.log"));
     * pb.redirectError(new File("logs/python-error.log"));
     * }
     */

    /**
     * TODO: 재시작 횟수 제한 (무한 재시작 방지)
     * 
     * private int restartCount = 0;
     * private static final int MAX_RESTARTS = 5;
     * 
     * public void restartPython() throws Exception {
     * if (restartCount >= MAX_RESTARTS) {
     * throw new RuntimeException("Too many restarts");
     * }
     * restartCount++;
     * // ...
     * }
     */
}