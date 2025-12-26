<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>관리자 - The Salty Spitoon</title>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #131722;
            min-height: 100vh;
            color: #d1d4dc;
        }

        a {
            color: inherit;
            text-decoration: none;
        }

        /* 공통 네비게이션 */
        .navbar {
            background: #1e222d;
            border-bottom: 1px solid #2a2e39;
            padding: 0 20px;
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .navbar-container {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
            height: 60px;
        }

        .navbar-brand {
            font-size: 20px;
            font-weight: 700;
            background: linear-gradient(135deg, #2962ff 0%, #26a69a 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .navbar-menu {
            display: flex;
            gap: 8px;
        }

        .navbar-item {
            padding: 10px 16px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
            color: #787b86;
            transition: all 0.2s;
        }

        .navbar-item:hover {
            background: #2a2e39;
            color: #d1d4dc;
        }

        .navbar-item.active {
            background: #2962ff;
            color: white;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 1.8rem;
            color: #d1d4dc;
        }
        
        h1 span {
            color: #2962ff;
        }
        
        .card {
            background: #1e222d;
            border: 1px solid #2a2e39;
            border-radius: 8px;
            padding: 24px;
            margin-bottom: 20px;
        }
        
        .card-title {
            font-size: 1.1rem;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            color: #d1d4dc;
        }
        
        /* 기간 선택 버튼 */
        .days-selector {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
            flex-wrap: wrap;
        }
        
        .days-btn {
            padding: 12px 24px;
            border: 1px solid #2a2e39;
            background: #2a2e39;
            color: #787b86;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .days-btn:hover {
            background: #363a45;
            color: #d1d4dc;
            border-color: #434651;
        }
        
        .days-btn.active {
            background: #2962ff;
            color: white;
            border-color: #2962ff;
        }
        
        .days-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        /* 버튼 스타일 */
        .btn-primary {
            width: 100%;
            padding: 16px;
            background: #2962ff;
            border: none;
            border-radius: 10px;
            color: white;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .btn-primary:hover:not(:disabled) {
            transform: translateY(-2px);
            background: #1e53e5;
            box-shadow: 0 4px 12px rgba(41, 98, 255, 0.3);
        }
        
        .btn-primary:disabled {
            background: #2a2e39;
            color: #787b86;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        .btn-secondary {
            padding: 12px 20px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #d1d4dc;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .btn-secondary:hover {
            background: #363a45;
        }
        
        /* 진행률 영역 */
        .progress-section {
            display: none;
        }
        
        .progress-section.visible {
            display: block;
        }
        
        .progress-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        
        .progress-text {
            font-size: 1.1rem;
            color: #787b86;
        }
        
        .progress-percent {
            font-size: 1.5rem;
            font-weight: bold;
            color: #2962ff;
        }
        
        .progress-bar-container {
            height: 12px;
            background: #2a2e39;
            border-radius: 6px;
            overflow: hidden;
            margin-bottom: 15px;
        }
        
        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #2962ff, #26a69a);
            border-radius: 6px;
            transition: width 0.3s ease;
            width: 0%;
        }
        
        .current-symbol {
            padding: 12px 16px;
            background: rgba(41, 98, 255, 0.1);
            border-radius: 8px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .current-symbol .symbol {
            font-weight: bold;
            font-size: 1.2rem;
            color: #2962ff;
        }
        
        .current-symbol .status {
            font-size: 0.9rem;
            color: #787b86;
        }
        
        .current-symbol .status.success {
            color: #26a69a;
        }
        
        .current-symbol .status.failed {
            color: #ef5350;
        }
        
        .eta {
            text-align: center;
            color: #787b86;
            font-size: 0.9rem;
        }
        
        /* 로그 영역 */
        .log-section {
            margin-top: 20px;
        }
        
        .log-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .log-title {
            font-size: 1rem;
            color: #787b86;
        }
        
        .log-toggle {
            background: none;
            border: none;
            color: #2962ff;
            cursor: pointer;
            font-size: 0.9rem;
        }
        
        .log-container {
            max-height: 250px;
            overflow-y: auto;
            background: #2a2e39;
            border-radius: 8px;
            padding: 15px;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.85rem;
        }
        
        .log-entry {
            padding: 4px 0;
            border-bottom: 1px solid #363a45;
        }
        
        .log-entry:last-child {
            border-bottom: none;
        }
        
        .log-entry .time {
            color: #787b86;
            margin-right: 10px;
        }
        
        .log-entry .symbol {
            color: #2962ff;
            font-weight: bold;
            margin-right: 8px;
        }
        
        .log-entry.success .message {
            color: #26a69a;
        }
        
        .log-entry.failed .message {
            color: #ef5350;
        }
        
        /* 완료 결과 */
        .result-section {
            display: none;
        }
        
        .result-section.visible {
            display: block;
        }
        
        .result-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .stat-box {
            background: #2a2e39;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-value.success {
            color: #26a69a;
        }
        
        .stat-value.failed {
            color: #ef5350;
        }
        
        .stat-value.total {
            color: #2962ff;
        }
        
        .stat-label {
            font-size: 0.9rem;
            color: #787b86;
        }
        
        .failed-list {
            margin-top: 15px;
            padding: 15px;
            background: rgba(239, 83, 80, 0.1);
            border-radius: 8px;
            border: 1px solid rgba(239, 83, 80, 0.3);
        }
        
        .failed-list-title {
            color: #ef5350;
            margin-bottom: 10px;
            font-weight: 500;
        }
        
        .failed-list-items {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
        
        .failed-item {
            background: rgba(239, 83, 80, 0.2);
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.85rem;
        }
        
        /* 재무 데이터 섹션 */
        .financial-section {
            margin-top: 20px;
        }
        
        .financial-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .select-wrapper {
            flex: 1;
            min-width: 200px;
        }
        
        .select-wrapper select {
            width: 100%;
            padding: 12px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #d1d4dc;
            font-size: 0.9rem;
        }
        
        .select-wrapper select option {
            background: #1e222d;
        }
        
        /* WebSocket 상태 */
        .ws-status {
            position: fixed;
            bottom: 20px;
            right: 20px;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .ws-status.connected {
            background: rgba(38, 166, 154, 0.2);
            color: #26a69a;
        }
        
        .ws-status.disconnected {
            background: rgba(239, 83, 80, 0.2);
            color: #ef5350;
        }
        
        .ws-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: currentColor;
        }
        
        /* 네비게이션 */
        .nav-links {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .nav-links a {
            color: #2962ff;
            text-decoration: none;
            padding: 8px 16px;
            border-radius: 6px;
            transition: all 0.2s;
        }
        
        .nav-links a:hover {
            background: rgba(41, 98, 255, 0.1);
        }
    </style>
</head>
<body>
    <!-- 공통 네비게이션 -->
    <nav class="navbar">
        <div class="navbar-container">
            <a href="/stock" class="navbar-brand">The Salty Spitoon</a>
            <div class="navbar-menu">
                <a href="/stock" class="navbar-item">대시보드</a>
                <a href="/stock/chart?symbol=AAPL" class="navbar-item">차트</a>
                <a href="/news" class="navbar-item">뉴스</a>
                <a href="/admin" class="navbar-item active">관리자</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <h1>🛠️ <span>The Salty Spitoon</span> 관리자</h1>
        
        <!-- 과거 데이터 수집 카드 -->
        <div class="card">
            <div class="card-title">📊 과거 데이터 수집 (1분봉)</div>
            
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                Yahoo Finance API에서 NASDAQ 100 전체 종목의 과거 1분봉 데이터를 수집합니다.<br>
                ⚠️ API 제한으로 최대 7일까지만 수집 가능합니다.
            </p>
            
            <div class="days-selector">
                <button class="days-btn" data-days="1">1일</button>
                <button class="days-btn" data-days="2">2일</button>
                <button class="days-btn active" data-days="3">3일</button>
                <button class="days-btn" data-days="5">5일</button>
                <button class="days-btn" data-days="7">7일 (최대)</button>
            </div>
            
            <button id="startBtn" class="btn-primary">
                <span>🚀</span>
                <span>수집 시작</span>
            </button>
        </div>
        
        <!-- 진행률 카드 -->
        <div class="card progress-section" id="progressSection">
            <div class="progress-header">
                <span class="progress-text" id="progressText">0 / 100 종목</span>
                <span class="progress-percent" id="progressPercent">0%</span>
            </div>
            
            <div class="progress-bar-container">
                <div class="progress-bar" id="progressBar"></div>
            </div>
            
            <div class="current-symbol" id="currentSymbol">
                <span class="symbol">-</span>
                <span class="status">대기 중...</span>
            </div>
            
            <div class="eta" id="etaText">예상 남은 시간: 계산 중...</div>
            
            <!-- 로그 -->
            <div class="log-section">
                <div class="log-header">
                    <span class="log-title">📋 수집 로그</span>
                    <button class="log-toggle" id="clearLogBtn">지우기</button>
                </div>
                <div class="log-container" id="logContainer"></div>
            </div>
        </div>
        
        <!-- 완료 결과 카드 -->
        <div class="card result-section" id="resultSection">
            <div class="card-title">✅ 수집 완료</div>
            
            <div class="result-stats">
                <div class="stat-box">
                    <div class="stat-value success" id="resultSuccess">0</div>
                    <div class="stat-label">성공</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value failed" id="resultFailed">0</div>
                    <div class="stat-label">실패</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value total" id="resultCandles">0</div>
                    <div class="stat-label">총 캔들 수</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="resultDuration" style="color: #ffd43b;">-</div>
                    <div class="stat-label">소요 시간</div>
                </div>
            </div>
            
            <div class="failed-list" id="failedList" style="display: none;">
                <div class="failed-list-title">❌ 실패한 종목</div>
                <div class="failed-list-items" id="failedListItems"></div>
            </div>
        </div>
        
        <!-- 재무 데이터 카드 -->
        <div class="card">
            <div class="card-title">💰 재무 데이터 관리</div>
            
            <div class="financial-section">
                <div class="financial-actions" style="margin-bottom: 15px;">
                    <button class="btn-secondary" onclick="collectFinancialData()">
                        📥 재무 데이터 수집 (Python)
                    </button>
                    <button class="btn-secondary" onclick="loadLatestFinancialData()">
                        📤 최신 데이터 로드 (MySQL)
                    </button>
                </div>
                
                <div class="financial-actions">
                    <div class="select-wrapper">
                        <select id="jsonFileSelect">
                            <option value="">-- JSON 파일 선택 --</option>
                            <c:forEach var="file" items="${financialJsonFiles}">
                                <option value="${file}">${file}</option>
                            </c:forEach>
                        </select>
                    </div>
                    <button class="btn-secondary" onclick="loadSelectedFinancialData()">
                        📤 선택 파일 로드
                    </button>
                </div>
                
                <div id="financialResult" style="margin-top: 15px; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 8px; display: none; white-space: pre-wrap; font-family: monospace; font-size: 0.85rem;"></div>
            </div>
        </div>
        
        <!-- 뉴스 수집 카드 -->
        <div class="card">
            <div class="card-title">📰 뉴스 데이터 수집</div>
            
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                Yahoo Finance API에서 NASDAQ 100 종목의 뉴스를 수집하고, 기사 본문을 크롤링합니다.<br>
                ✅ MySQL 중복 체크: 이미 DB에 있는 뉴스는 크롤링 전 자동으로 스킵됩니다.
            </p>
            
            <!-- 수집 대상 선택 -->
            <div style="margin-bottom: 20px;">
                <div style="margin-bottom: 10px; color: #d1d4dc; font-weight: 500;">📊 수집 대상</div>
                <div style="display: flex; gap: 10px; margin-bottom: 15px;">
                    <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
                        <input type="radio" name="newsTarget" value="all" checked 
                               style="accent-color: #2962ff;" onchange="toggleSymbolInput()">
                        <span>전체 종목 (NASDAQ 100)</span>
                    </label>
                    <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
                        <input type="radio" name="newsTarget" value="specific" 
                               style="accent-color: #2962ff;" onchange="toggleSymbolInput()">
                        <span>특정 종목만</span>
                    </label>
                </div>
                <div id="symbolInputWrapper" style="display: none;">
                    <input type="text" id="newsSymbolsInput" 
                           placeholder="종목 코드 입력 (예: AAPL, MSFT, GOOGL)"
                           style="width: 100%; padding: 12px; background: #2a2e39; border: 1px solid #434651; border-radius: 6px; color: #d1d4dc; font-size: 0.9rem;">
                    <div style="margin-top: 8px; font-size: 0.8rem; color: #787b86;">
                        팀: 쉼표로 구분하여 여러 종목 입력 가능
                    </div>
                </div>
            </div>
            
            <!-- 종목당 뉴스 개수 선택 -->
            <div style="margin-bottom: 20px;">
                <div style="margin-bottom: 10px; color: #d1d4dc; font-weight: 500;">📝 종목당 뉴스 개수</div>
                <div class="days-selector" style="margin-bottom: 0;">
                    <button class="days-btn" data-count="1" type="button">1개</button>
                    <button class="days-btn" data-count="3" type="button">3개</button>
                    <button class="days-btn active" data-count="5" type="button">5개</button>
                    <button class="days-btn" data-count="10" type="button">10개 (최대)</button>
                </div>
                <div style="margin-top: 8px; font-size: 0.8rem; color: #787b86;">
                    팀: Yahoo API는 종목당 최대 10개의 최신 뉴스만 제공합니다.
                </div>
            </div>
            
            <div style="background: #2a2e39; border-radius: 8px; padding: 16px; margin-bottom: 20px; font-size: 0.85rem; color: #787b86;">
                <div style="margin-bottom: 8px; font-weight: 500; color: #d1d4dc;">📝 수집 과정 (4단계)</div>
                <div>1️⃣ Python API로 뉴스 링크 수집 → news_links.json</div>
                <div>2️⃣ Java가 MySQL과 비교 → 중복 제거 → JSON 덤어쓰기</div>
                <div>3️⃣ Python Selenium으로 본문 크롤링 → news_details.json</div>
                <div>4️⃣ Java가 MySQL에 저장</div>
            </div>
            
            <button id="newsCollectBtn" class="btn-primary" onclick="startNewsCollection()">
                <span>📰</span>
                <span>뉴스 수집 시작</span>
            </button>
            
            <!-- 뉴스 수집 진행률 -->
            <div id="newsProgressSection" style="margin-top: 20px; display: none;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="color: #787b86;" id="newsProgressText">준비 중...</span>
                    <span style="font-weight: bold; color: #2962ff;" id="newsProgressPercent">0%</span>
                </div>
                <div style="height: 10px; background: #2a2e39; border-radius: 5px; overflow: hidden; margin-bottom: 15px;">
                    <div id="newsProgressBar" style="height: 100%; background: linear-gradient(90deg, #2962ff, #26a69a); width: 0%; transition: width 0.3s;"></div>
                </div>
                <div id="newsStatusText" style="padding: 12px 16px; background: rgba(41, 98, 255, 0.1); border-radius: 8px; color: #d1d4dc; font-size: 0.9rem;">
                    대기 중...
                </div>
            </div>
        </div>
    </div>
    
    <!-- WebSocket 상태 표시 -->
    <div class="ws-status disconnected" id="wsStatus">
        <div class="ws-dot"></div>
        <span>연결 끊김</span>
    </div>

    <script>
        // 상태 관리
        let selectedDays = 3;
        let stompClient = null;
        let isCollecting = false;
        let startTime = null;
        let processedCount = 0;
        
        // DOM 요소
        const startBtn = document.getElementById('startBtn');
        const progressSection = document.getElementById('progressSection');
        const resultSection = document.getElementById('resultSection');
        const progressBar = document.getElementById('progressBar');
        const progressText = document.getElementById('progressText');
        const progressPercent = document.getElementById('progressPercent');
        const currentSymbol = document.getElementById('currentSymbol');
        const etaText = document.getElementById('etaText');
        const logContainer = document.getElementById('logContainer');
        const wsStatus = document.getElementById('wsStatus');
        
        // 기간 선택 버튼 이벤트
        document.querySelectorAll('.days-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                if (isCollecting) return;
                
                document.querySelectorAll('.days-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                selectedDays = parseInt(btn.dataset.days);
            });
        });
        
        // 시작 버튼 이벤트
        startBtn.addEventListener('click', startCollection);
        
        // 로그 지우기 버튼
        document.getElementById('clearLogBtn').addEventListener('click', () => {
            logContainer.innerHTML = '';
        });
        
        // WebSocket 연결
        function connectWebSocket() {
            const socket = new SockJS('${pageContext.request.contextPath}/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null; // 디버그 로그 끄기
            
            stompClient.connect({}, 
                // 연결 성공
                function(frame) {
                    console.log('WebSocket connected');
                    updateWsStatus(true);
                    
                    // 진행률 구독
                    stompClient.subscribe('/topic/admin/progress', function(message) {
                        const data = JSON.parse(message.body);
                        handleProgress(data);
                    });
                },
                // 연결 실패
                function(error) {
                    console.error('WebSocket error:', error);
                    updateWsStatus(false);
                    // 5초 후 재연결 시도
                    setTimeout(connectWebSocket, 5000);
                }
            );
        }
        
        // WebSocket 상태 업데이트
        function updateWsStatus(connected) {
            if (connected) {
                wsStatus.className = 'ws-status connected';
                wsStatus.innerHTML = '<div class="ws-dot"></div><span>연결됨</span>';
            } else {
                wsStatus.className = 'ws-status disconnected';
                wsStatus.innerHTML = '<div class="ws-dot"></div><span>연결 끊김</span>';
            }
        }
        
        // 수집 시작
        async function startCollection() {
            if (isCollecting) return;
            
            try {
                const response = await fetch('${pageContext.request.contextPath}/admin/collect-historical?days=' + selectedDays, {
                    method: 'POST'
                });
                const data = await response.json();
                
                if (data.success) {
                    isCollecting = true;
                    startTime = Date.now();
                    processedCount = 0;
                    
                    // UI 업데이트
                    startBtn.disabled = true;
                    startBtn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                    document.querySelectorAll('.days-btn').forEach(b => b.disabled = true);
                    
                    progressSection.classList.add('visible');
                    resultSection.classList.remove('visible');
                    logContainer.innerHTML = '';
                    
                } else {
                    alert(data.message);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('수집 시작에 실패했습니다.');
            }
        }
        
        // 진행률 처리
        function handleProgress(data) {
            if (data.type === 'progress') {
                const { current, total, symbol, status, message, candleCount } = data;
                processedCount = current;
                
                // 진행률 바 업데이트
                const percent = Math.round((current / total) * 100);
                progressBar.style.width = percent + '%';
                progressText.textContent = current + ' / ' + total + ' 종목';
                progressPercent.textContent = percent + '%';
                
                // 현재 심볼 업데이트
                const symbolSpan = currentSymbol.querySelector('.symbol');
                const statusSpan = currentSymbol.querySelector('.status');
                symbolSpan.textContent = symbol;
                
                if (status === 'processing') {
                    statusSpan.textContent = message;
                    statusSpan.className = 'status';
                } else if (status === 'success') {
                    statusSpan.textContent = '✅ ' + candleCount + ' candles';
                    statusSpan.className = 'status success';
                } else {
                    statusSpan.textContent = '❌ ' + message;
                    statusSpan.className = 'status failed';
                }
                
                // ETA 계산
                if (current > 0 && startTime) {
                    const elapsed = Date.now() - startTime;
                    const avgTime = elapsed / current;
                    const remaining = (total - current) * avgTime;
                    etaText.textContent = '예상 남은 시간: ' + formatTime(remaining);
                }
                
                // 로그 추가 (success/failed만)
                if (status === 'success' || status === 'failed') {
                    addLogEntry(symbol, status, status === 'success' ? 
                        candleCount + ' candles' : message);
                }
                
            } else if (data.type === 'complete') {
                handleComplete(data);
                
            } else if (data.type === 'error') {
                alert(data.message);
                resetUI();
            }
        }
        
        // 완료 처리
        function handleComplete(data) {
            isCollecting = false;
            
            // UI 리셋
            resetUI();
            
            // 결과 표시
            progressSection.classList.remove('visible');
            resultSection.classList.add('visible');
            
            document.getElementById('resultSuccess').textContent = data.successCount;
            document.getElementById('resultFailed').textContent = data.failedCount;
            document.getElementById('resultCandles').textContent = 
                data.totalCandles.toLocaleString();
            document.getElementById('resultDuration').textContent = data.duration;
            
            // 실패 목록 표시
            const failedList = document.getElementById('failedList');
            const failedItems = document.getElementById('failedListItems');
            
            if (data.failedSymbols && data.failedSymbols.length > 0) {
                failedList.style.display = 'block';
                failedItems.innerHTML = data.failedSymbols
                    .map(s => '<span class="failed-item">' + s + '</span>')
                    .join('');
            } else {
                failedList.style.display = 'none';
            }
        }
        
        // UI 리셋
        function resetUI() {
            startBtn.disabled = false;
            startBtn.innerHTML = '<span>🚀</span><span>수집 시작</span>';
            document.querySelectorAll('.days-btn').forEach(b => b.disabled = false);
        }
        
        // 로그 항목 추가
        function addLogEntry(symbol, status, message) {
            const now = new Date();
            const time = now.toLocaleTimeString('ko-KR', { 
                hour: '2-digit', 
                minute: '2-digit', 
                second: '2-digit' 
            });
            
            const entry = document.createElement('div');
            entry.className = 'log-entry ' + status;
            entry.innerHTML = 
                '<span class="time">[' + time + ']</span>' +
                '<span class="symbol">' + symbol + '</span>' +
                '<span class="message">' + message + '</span>';
            
            logContainer.appendChild(entry);
            logContainer.scrollTop = logContainer.scrollHeight;
        }
        
        // 시간 포맷팅
        function formatTime(ms) {
            const seconds = Math.floor(ms / 1000);
            const minutes = Math.floor(seconds / 60);
            const secs = seconds % 60;
            
            if (minutes > 0) {
                return minutes + '분 ' + secs + '초';
            }
            return secs + '초';
        }
        
        // ========================================
        // 재무 데이터 관련 함수
        // ========================================
        
        function collectFinancialData() {
            const resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 재무 데이터 수집 시작 중...';
            
            fetch('${pageContext.request.contextPath}/admin/collect-financial-data', {
                method: 'POST'
            })
            .then(response => response.text())
            .then(data => {
                resultDiv.textContent = data;
            })
            .catch(error => {
                resultDiv.textContent = '❌ 오류: ' + error;
            });
        }
        
        function loadLatestFinancialData() {
            const resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 최신 재무 데이터 로드 중...';
            
            fetch('${pageContext.request.contextPath}/admin/load-latest-financial-data', {
                method: 'POST'
            })
            .then(response => response.text())
            .then(data => {
                resultDiv.textContent = data;
            })
            .catch(error => {
                resultDiv.textContent = '❌ 오류: ' + error;
            });
        }
        
        function loadSelectedFinancialData() {
            const select = document.getElementById('jsonFileSelect');
            const fileName = select.value;
            
            if (!fileName) {
                alert('JSON 파일을 선택해주세요.');
                return;
            }
            
            const resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 ' + fileName + ' 로드 중...';
            
            fetch('${pageContext.request.contextPath}/admin/load-financial-data?jsonFileName=' + encodeURIComponent(fileName), {
                method: 'POST'
            })
            .then(response => response.text())
            .then(data => {
                resultDiv.textContent = data;
            })
            .catch(error => {
                resultDiv.textContent = '❌ 오류: ' + error;
            });
        }
        
        // ========================================
        // 뉴스 수집 관련 함수
        // ========================================
        
        let isNewsCollecting = false;
        let newsPollingInterval = null;
        let selectedNewsCount = 5;
        
        // 뉴스 개수 선택 버튼 이벤트
        document.querySelectorAll('.days-btn[data-count]').forEach(btn => {
            btn.addEventListener('click', () => {
                if (isNewsCollecting) return;
                
                document.querySelectorAll('.days-btn[data-count]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                selectedNewsCount = parseInt(btn.dataset.count);
            });
        });
        
        // 종목 입력창 토글
        function toggleSymbolInput() {
            const wrapper = document.getElementById('symbolInputWrapper');
            const isSpecific = document.querySelector('input[name="newsTarget"]:checked').value === 'specific';
            wrapper.style.display = isSpecific ? 'block' : 'none';
        }
        
        function startNewsCollection() {
            if (isNewsCollecting) {
                alert('이미 뉴스 수집이 진행 중입니다.');
                return;
            }
            
            // 옵션 수집
            const isAllSymbols = document.querySelector('input[name="newsTarget"]:checked').value === 'all';
            const symbolsInput = document.getElementById('newsSymbolsInput').value.trim();
            const symbols = isAllSymbols ? '' : symbolsInput;
            
            // 특정 종목 선택했는데 입력이 없으면 경고
            if (!isAllSymbols && !symbols) {
                alert('종목 코드를 입력해주세요. (예: AAPL, MSFT, GOOGL)');
                return;
            }
            
            const btn = document.getElementById('newsCollectBtn');
            const progressSection = document.getElementById('newsProgressSection');
            
            // URL 파라미터 구성
            const params = new URLSearchParams();
            params.append('count', selectedNewsCount);
            if (symbols) {
                params.append('symbols', symbols);
            }
            
            fetch('${pageContext.request.contextPath}/admin/collect-news?' + params.toString(), {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    isNewsCollecting = true;
                    btn.disabled = true;
                    btn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                    progressSection.style.display = 'block';
                    
                    // 상태 폴링 시작
                    newsPollingInterval = setInterval(pollNewsStatus, 2000);
                } else {
                    alert(data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('뉴스 수집 시작에 실패했습니다.');
            });
        }
        
        function pollNewsStatus() {
            fetch('${pageContext.request.contextPath}/admin/news-collection-status')
            .then(response => response.json())
            .then(data => {
                updateNewsProgress(data);
                
                if (!data.isCollecting) {
                    // 수집 완료
                    clearInterval(newsPollingInterval);
                    isNewsCollecting = false;
                    
                    const btn = document.getElementById('newsCollectBtn');
                    btn.disabled = false;
                    btn.innerHTML = '<span>📰</span><span>뉴스 수집 시작</span>';
                    
                    if (data.status.includes('✅')) {
                        alert('뉴스 수집이 완료되었습니다!');
                    } else if (data.status.includes('❌')) {
                        alert('뉴스 수집 중 오류가 발생했습니다: ' + data.status);
                    }
                }
            })
            .catch(error => {
                console.error('Polling error:', error);
            });
        }
        
        function updateNewsProgress(data) {
            const progressText = document.getElementById('newsProgressText');
            const progressPercent = document.getElementById('newsProgressPercent');
            const progressBar = document.getElementById('newsProgressBar');
            const statusText = document.getElementById('newsStatusText');
            
            statusText.textContent = data.status;
            
            if (data.total > 0) {
                const percent = Math.round((data.progress / data.total) * 100);
                progressText.textContent = data.progress + ' / ' + data.total + ' 기사';
                progressPercent.textContent = percent + '%';
                progressBar.style.width = percent + '%';
            } else {
                progressText.textContent = data.status;
                progressPercent.textContent = '';
            }
        }
        
        // ========================================
        // 초기화
        // ========================================
        
        // 페이지 로드 시 WebSocket 연결
        connectWebSocket();
        
        // 수집 상태 확인 (새로고침 대응)
        fetch('${pageContext.request.contextPath}/admin/historical-collection-status')
            .then(r => r.json())
            .then(data => {
                if (data.isCollecting) {
                    isCollecting = true;
                    startTime = Date.now();
                    startBtn.disabled = true;
                    startBtn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                    document.querySelectorAll('.days-btn').forEach(b => b.disabled = true);
                    progressSection.classList.add('visible');
                }
            });
        
        // 뉴스 수집 상태 확인
        fetch('${pageContext.request.contextPath}/admin/news-collection-status')
            .then(r => r.json())
            .then(data => {
                if (data.isCollecting) {
                    isNewsCollecting = true;
                    const btn = document.getElementById('newsCollectBtn');
                    btn.disabled = true;
                    btn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                    document.getElementById('newsProgressSection').style.display = 'block';
                    updateNewsProgress(data);
                    
                    // 폴링 시작
                    newsPollingInterval = setInterval(pollNewsStatus, 2000);
                }
            });
    </script>
</body>
</html>
