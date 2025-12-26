package com.weenie_hut_jr.the_salty_spitoon.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weenie_hut_jr.the_salty_spitoon.model.StockCandle1m;
import com.weenie_hut_jr.the_salty_spitoon.repository.StockCandle1mRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.File;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 과거 주식 데이터 로드 서비스
 * 
 * 역할:
 * - 초기 데이터베이스 구축 (과거 데이터 일괄 로드)
 * - 데이터 손실 시 복구
 * - 특정 기간 데이터 재수집
 * - Python 스크립트와의 파일 기반 통신
 * 
 * 동작 원리:
 * 1. 관리자 요청 (/admin/load-historical)
 * 2. Config 파일(historical_config.json) 읽기
 * 3. MySQL에서 마지막 데이터 시각 확인
 * 4. Request JSON 생성 (symbol, hours, last_timestamp)
 * 5. Python historical_loader.py 실행
 * 6. Python → yfinance API 호출 → CSV 저장
 * 7. Result JSON 생성 (Python)
 * 8. Spring이 Result JSON 읽고 MySQL 저장
 * 9. 임시 파일 정리
 * 
 * 파일 통신 구조:
 * - Config: python/config/historical_config.json (설정)
 * - Request: python/requests/request_{timestamp}.json (요청)
 * - Result: python/results/result_{timestamp}.json (응답)
 * 
 * Config JSON 예시:
 * {
 * "symbol": "AAPL",
 * "hours": 720 // 30일 (24시간 × 30일)
 * }
 * 
 * Request JSON 예시:
 * {
 * "symbol": "AAPL",
 * "hours": 720,
 * "last_timestamp": "2025-12-21 09:30:00" // 또는 null
 * }
 * 
 * Result JSON 예시:
 * {
 * "status": "success",
 * "symbol": "AAPL",
 * "count": 2730,
 * "data": [
 * {
 * "timestamp": "2025-11-21 09:30:00",
 * "open": "270.50",
 * "high": "271.20",
 * "low": "270.30",
 * "close": "270.80",
 * "volume": 1234567
 * },
 * ...
 * ]
 * }
 * 
 * 사용 시나리오:
 * 1. 초기 설치: 과거 30일 데이터 로드
 * 2. 서비스 중단 후 재시작: 중단 기간 데이터 채우기
 * 3. 새 종목 추가: 해당 종목 과거 데이터 로드
 * 
 * FileDataCollector와의 차이:
 * - FileDataCollector: 실시간 데이터 (1분마다, 자동)
 * - HistoricalDataService: 과거 데이터 (수동 실행, 대량)
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Slf4j // 로깅 기능
@Service // Spring Service Bean
@RequiredArgsConstructor // final 필드 생성자 주입
public class HistoricalDataService {

    // 의존성 주입
    private final StockCandle1mRepository candleRepository; // MySQL 저장
    private final ObjectMapper objectMapper = new ObjectMapper(); // JSON 파싱

    /**
     * Python 기본 디렉토리 경로
     * 
     * 설정:
     * - application.properties: python.base.dir=python
     * - 기본값: "python" (설정 없으면)
     * 
     * 구조:
     * python/
     * ├── config/
     * │ └── historical_config.json
     * ├── requests/
     * │ └── request_{timestamp}.json
     * ├── results/
     * │ └── result_{timestamp}.json
     * ├── output/
     * │ └── latest_data.json
     * ├── venv/
     * ├── historical_loader.py
     * └── stock_collector.py
     */
    @Value("${python.base.dir:python}")
    private String pythonBaseDir;

    /**
     * 타임스탬프 포맷터
     * 
     * 형식: "yyyy-MM-dd HH:mm:ss"
     * 예시: "2025-12-21 15:30:00"
     * 
     * 용도:
     * - Python과 Java 간 시각 데이터 통일
     * - JSON 문자열 ↔ LocalDateTime 변환
     */
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 과거 데이터 로드 메인 프로세스
     * 
     * 전체 흐름:
     * 1. historical_config.json 읽기 (symbol, hours)
     * 2. MySQL에서 마지막 데이터 시각 조회
     * 3. Request JSON 생성 및 저장
     * 4. Python historical_loader.py 실행 (동기)
     * 5. Result JSON 읽기
     * 6. 상태 확인 (success/error)
     * 7. 데이터 MySQL 저장
     * 8. 임시 파일 정리
     * 9. 결과 반환
     * 
     * 실행 방법:
     * - 관리자 API: POST /admin/load-historical
     * - 수동 호출: historicalDataService.loadHistoricalData()
     * 
     * 실행 시간:
     * - Python API 호출: ~30초 (yfinance)
     * - DB 저장: ~10초 (2730개 데이터)
     * - 총: ~40-60초
     * 
     * 데이터 양:
     * - 1시간: 60개 (1분봉)
     * - 24시간: 390개 (장 시간 6.5시간)
     * - 30일: ~11,700개
     * 
     * 중복 처리:
     * - last_timestamp 이후 데이터만 요청
     * - DB 저장 시 중복 체크
     * - 중복 데이터는 스킵
     * 
     * 에러 처리:
     * - Config 파일 없음: RuntimeException
     * - Python 실행 실패: RuntimeException
     * - Result 파일 없음: RuntimeException
     * - Python 에러: 에러 메시지와 함께 예외
     * 
     * 로그 구조:
     * ========================================
     * Historical Data Load Started
     * ========================================
     * 📋 Config loaded: symbol=AAPL, hours=720
     * 📅 Last data in DB: 2025-11-21 09:30:00
     * 📤 Request created: request_1703145000000.json
     * 🐍 Executing Python loader...
     * ✅ Python loader completed
     * 💾 Saved: 2730, Skipped: 0 (duplicates)
     * ========================================
     * Historical Data Load Completed
     * Symbol: AAPL
     * Saved: 2730 candles
     * ========================================
     * 
     * @return String 처리 결과 메시지
     * @throws Exception Config 파일 오류, Python 실행 오류 등
     */
    public String loadHistoricalData() throws Exception {
        // 시작 로그
        log.info("========================================");
        log.info("Historical Data Load Started");
        log.info("========================================");

        // 1. Config 파일 읽기
        File configFile = new File(pythonBaseDir + "/config/historical_config.json");
        if (!configFile.exists()) {
            throw new RuntimeException("Config file not found: " + configFile.getAbsolutePath());
        }

        JsonNode config = objectMapper.readTree(configFile);
        String symbol = config.get("symbol").asText(); // 종목 심볼
        int hours = config.get("hours").asInt(); // 조회 시간 (시간 단위)

        log.info("📋 Config loaded: symbol={}, hours={}", symbol, hours);

        // 2. MySQL에서 마지막 데이터 시각 확인
        // - 기존 데이터가 있으면: 그 이후부터 로드 (중복 방지)
        // - 없으면: 처음부터 전체 로드
        Optional<LocalDateTime> lastTimestamp = candleRepository
                .findLastTimestampBySymbol(symbol);

        String lastTimestampStr = null;
        if (lastTimestamp.isPresent()) {
            lastTimestampStr = lastTimestamp.get().format(FORMATTER);
            log.info("📅 Last data in DB: {}", lastTimestampStr);
        } else {
            log.info("📅 No existing data for {}", symbol);
        }

        // 3. Request JSON 생성
        // - 고유 ID: 현재 시각의 밀리초 타임스탬프
        // - 파일명: request_{timestamp}.json
        String requestId = String.valueOf(System.currentTimeMillis());
        File requestFile = createRequestFile(requestId, symbol, hours, lastTimestampStr);

        // 4. Python 실행 (동기 - 완료될 때까지 대기)
        executePythonLoader(requestFile);

        // 5. Result JSON 읽기
        File resultFile = new File(pythonBaseDir + "/results/result_" + requestId + ".json");
        if (!resultFile.exists()) {
            throw new RuntimeException("Result file not created: " + resultFile.getName());
        }

        JsonNode result = objectMapper.readTree(resultFile);

        // 6. 결과 상태 확인
        String status = result.get("status").asText();

        if ("error".equals(status)) {
            String error = result.get("error").asText();
            log.error("❌ Python returned error: {}", error);
            throw new RuntimeException("Historical load failed: " + error);
        }

        // 7. 데이터 MySQL 저장
        int savedCount = saveHistoricalData(result);

        // 완료 로그
        log.info("========================================");
        log.info("Historical Data Load Completed");
        log.info("  Symbol: {}", symbol);
        log.info("  Saved: {} candles", savedCount);
        log.info("========================================");

        // 8. 임시 파일 정리
        cleanupFiles(requestFile, resultFile);

        return String.format("✅ Historical data loaded: %s (%d candles)", symbol, savedCount);
    }

    /**
     * Request JSON 파일 생성
     * 
     * 기능:
     * - Python에게 전달할 요청 데이터 생성
     * - JSON 파일로 저장
     * 
     * JSON 구조:
     * {
     * "symbol": "AAPL", // 조회할 종목
     * "hours": 720, // 과거 몇 시간
     * "last_timestamp": "2025-12-21 09:30:00" // 마지막 데이터 시각 (없으면 null)
     * }
     * 
     * last_timestamp 활용:
     * - null: 처음부터 hours만큼 로드
     * - 값 있음: 해당 시각 이후부터 현재까지 로드
     * 
     * 파일 경로:
     * - python/requests/request_{requestId}.json
     * - requestId: 밀리초 타임스탬프 (고유성 보장)
     * 
     * 디렉토리 생성:
     * - mkdirs(): requests 폴더 없으면 자동 생성
     * 
     * Pretty Print:
     * - writerWithDefaultPrettyPrinter(): 가독성 좋은 JSON
     * 
     * @param requestId     요청 고유 ID (타임스탬프)
     * @param symbol        종목 심볼
     * @param hours         조회 시간 (시간 단위)
     * @param lastTimestamp 마지막 데이터 시각 (없으면 null)
     * @return File 생성된 Request JSON 파일
     * @throws Exception JSON 쓰기 실패
     */
    private File createRequestFile(String requestId, String symbol, int hours, String lastTimestamp) throws Exception {
        // 요청 데이터 구성
        Map<String, Object> request = new HashMap<>();
        request.put("symbol", symbol);
        request.put("hours", hours);
        request.put("last_timestamp", lastTimestamp); // null 가능

        // 파일 경로 지정
        File requestFile = new File(pythonBaseDir + "/requests/request_" + requestId + ".json");

        // 디렉토리 생성 (없으면)
        requestFile.getParentFile().mkdirs();

        // JSON 파일 저장 (Pretty Print)
        objectMapper.writerWithDefaultPrettyPrinter()
                .writeValue(requestFile, request);

        log.info("📤 Request created: {}", requestFile.getName());

        return requestFile;
    }

    /**
     * Python historical_loader.py 실행
     * 
     * 기능:
     * - Python 스크립트를 별도 프로세스로 실행
     * - Request JSON을 인자로 전달
     * - 실행 완료까지 대기 (동기)
     * 
     * 실행 명령:
     * python/venv/bin/python python/historical_loader.py
     * python/requests/request_XXX.json
     * 
     * ProcessBuilder:
     * - Java에서 외부 프로세스 실행
     * - redirectErrorStream(true): stderr → stdout 통합
     * - inheritIO(): Python 출력을 Java 콘솔에 표시
     * 
     * Python 스크립트 동작:
     * 1. Request JSON 읽기
     * 2. yfinance API 호출 (과거 데이터)
     * 3. 1분봉 데이터 다운로드
     * 4. Result JSON 생성
     * 
     * 실행 시간:
     * - yfinance API: 20-40초 (네트워크 속도)
     * - JSON 처리: 1-2초
     * - 총: 약 30-60초
     * 
     * 에러 처리:
     * - Exit code 0: 정상 종료
     * - Exit code != 0: 에러 발생 → RuntimeException
     * 
     * OS 호환성:
     * - Windows: python/venv/Scripts/python.exe
     * - Linux/Mac: python/venv/bin/python
     * 
     * venv (가상환경):
     * - yfinance, pandas 등 패키지 설치됨
     * - 시스템 Python과 격리
     * 
     * @param requestFile Request JSON 파일
     * @throws Exception Python 실행 실패, 타임아웃 등
     */
    private void executePythonLoader(File requestFile) throws Exception {
        log.info("🐍 Executing Python loader...");

        // Python 실행 파일 경로 (OS별 분기)
        String pythonExe = getPythonExecutable();

        // ProcessBuilder 설정
        ProcessBuilder pb = new ProcessBuilder(
                pythonExe, // Python 실행 파일
                pythonBaseDir + "/historical_loader.py", // 스크립트 경로
                requestFile.getAbsolutePath()); // Request JSON 경로

        pb.redirectErrorStream(true); // stderr를 stdout에 합침
        pb.inheritIO(); // Python 출력을 Java 콘솔에 표시

        // 프로세스 시작
        Process process = pb.start();

        // 완료 대기 (블로킹)
        int exitCode = process.waitFor();

        // Exit code 확인
        if (exitCode != 0) {
            throw new RuntimeException("Python loader failed with exit code: " + exitCode);
        }

        log.info("✅ Python loader completed");
    }

    /**
     * OS별 Python 실행 파일 경로 반환
     * 
     * OS 감지:
     * - System.getProperty("os.name"): OS 이름 조회
     * - toLowerCase(): 대소문자 통일
     * 
     * 경로 결정:
     * - Windows: python/venv/Scripts/python.exe
     * - Linux/Mac: python/venv/bin/python
     * 
     * venv 구조:
     * - Windows: Scripts/ 폴더
     * - Linux/Mac: bin/ 폴더
     * 
     * 사용 이유:
     * - 가상환경(venv)의 Python 사용
     * - 필요한 패키지(yfinance, pandas) 설치됨
     * - 시스템 Python과 독립적
     * 
     * @return String Python 실행 파일 전체 경로
     */
    private String getPythonExecutable() {
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
     * Result JSON 데이터를 MySQL에 저장
     * 
     * 기능:
     * - Python이 생성한 Result JSON 파싱
     * - 각 캔들 데이터를 StockCandle1m 엔티티로 변환
     * - MySQL에 저장 (중복 체크)
     * 
     * Result JSON 구조:
     * {
     * "status": "success",
     * "symbol": "AAPL",
     * "count": 2730,
     * "data": [
     * {
     * "timestamp": "2025-11-21 09:30:00",
     * "open": "270.50",
     * ...
     * },
     * ...
     * ]
     * }
     * 
     * 처리 과정:
     * 1. "data" 배열 추출
     * 2. 각 캔들 데이터 순회
     * 3. timestamp 파싱
     * 4. 중복 체크 (findBySymbolAndTimestamp)
     * 5. 중복이면 스킵, 아니면 저장
     * 6. 통계 집계 (saved, skipped)
     * 
     * 중복 처리 이유:
     * - 동일한 Config로 여러 번 실행 가능
     * - 실행 중 중단 후 재시작
     * - last_timestamp 계산 오차
     * 
     * 배치 처리:
     * - 현재: 개별 save() 호출
     * - 개선: saveAll() 배치 처리 가능
     * 
     * 에러 처리:
     * - 개별 캔들 저장 실패 시 로그만 남기고 계속
     * - 전체 프로세스는 중단 안 됨
     * 
     * 성능:
     * - 2730개 데이터: ~10초
     * - 단일 트랜잭션 고려 가능
     * 
     * @param result Python Result JSON
     * @return int 실제 저장된 캔들 개수
     */
    private int saveHistoricalData(JsonNode result) {
        // "data" 배열 추출
        JsonNode dataArray = result.get("data");

        // 데이터 없음 체크
        if (dataArray == null || !dataArray.isArray()) {
            log.warn("No data to save");
            return 0;
        }

        // 통계 변수
        int savedCount = 0; // 저장 성공
        int skippedCount = 0; // 중복으로 스킵

        // 각 캔들 데이터 순회
        for (JsonNode candleNode : dataArray) {
            try {
                // timestamp 파싱: "2025-11-21 09:30:00" → LocalDateTime
                LocalDateTime timestamp = LocalDateTime.parse(
                        candleNode.get("timestamp").asText(),
                        FORMATTER);

                // 중복 체크
                String symbol = result.get("symbol").asText();
                if (candleRepository.findBySymbolAndTimestamp(symbol, timestamp).isPresent()) {
                    skippedCount++;
                    continue; // 중복, 다음 캔들로
                }

                // StockCandle1m 엔티티 생성
                StockCandle1m candle = StockCandle1m.builder()
                        .symbol(symbol)
                        .timestamp(timestamp)
                        .open(new BigDecimal(candleNode.get("open").asText()))
                        .high(new BigDecimal(candleNode.get("high").asText()))
                        .low(new BigDecimal(candleNode.get("low").asText()))
                        .close(new BigDecimal(candleNode.get("close").asText()))
                        .volume(candleNode.get("volume").asLong())
                        .build();

                // MySQL 저장
                candleRepository.save(candle);
                savedCount++;

            } catch (Exception e) {
                // 개별 캔들 저장 실패 (로그만, 계속 진행)
                log.error("Failed to save candle: {}", e.getMessage());
            }
        }

        // 저장 통계 로그
        log.info("💾 Saved: {}, Skipped: {} (duplicates)", savedCount, skippedCount);

        return savedCount;
    }

    /**
     * 임시 파일 정리
     * 
     * 기능:
     * - Request JSON, Result JSON 삭제
     * - 디스크 공간 확보
     * 
     * 정리 대상:
     * - python/requests/request_{requestId}.json
     * - python/results/result_{requestId}.json
     * 
     * 정리 시점:
     * - 데이터 저장 완료 후
     * - 정상/에러 모두 정리
     * 
     * 에러 처리:
     * - 파일 삭제 실패 시 경고 로그만
     * - 전체 프로세스에 영향 없음
     * 
     * 보관 옵션:
     * - 디버깅: 파일 보관 필요 시 주석 처리
     * - 감사: 별도 아카이브 폴더로 이동
     * 
     * 가변 인자:
     * - File... files: 여러 파일 한 번에 정리
     * 
     * @param files 삭제할 파일들
     */
    private void cleanupFiles(File... files) {
        for (File file : files) {
            try {
                if (file.exists()) {
                    Files.delete(file.toPath());
                    log.debug("🗑️  Cleaned up: {}", file.getName());
                }
            } catch (Exception e) {
                // 삭제 실패 시 경고만 (치명적 아님)
                log.warn("Failed to delete {}: {}", file.getName(), e.getMessage());
            }
        }
    }

    // ========================================
    // 향후 개선 방안 (TODO)
    // ========================================

    /**
     * TODO: 배치 저장으로 성능 개선
     * 
     * @Transactional
     *                private int saveHistoricalDataBatch(JsonNode result) {
     *                List<StockCandle1m> candles = new ArrayList<>();
     *                // ... 엔티티 생성 ...
     *                candleRepository.saveAll(candles); // 배치 INSERT
     *                return candles.size();
     *                }
     */

    /**
     * TODO: 비동기 처리 (사용자 대기 시간 단축)
     * 
     * @Async
     *        public CompletableFuture<String> loadHistoricalDataAsync() {
     *        // 백그라운드 실행, 즉시 응답
     *        return CompletableFuture.completedFuture(loadHistoricalData());
     *        }
     */

    /**
     * TODO: 진행률 모니터링 (WebSocket으로 실시간 전송)
     * 
     * private void updateProgress(int current, int total) {
     * messagingTemplate.convertAndSend("/topic/admin/progress", {
     * "current": current,
     * "total": total,
     * "percent": (current * 100 / total)
     * });
     * }
     */

    /**
     * TODO: 여러 종목 동시 로드
     * 
     * public Map<String, Integer> loadMultipleSymbols(List<String> symbols) {
     * // 병렬 처리 또는 순차 처리
     * }
     */
}