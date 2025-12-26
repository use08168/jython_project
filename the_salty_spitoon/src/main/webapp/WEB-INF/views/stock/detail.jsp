<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${symbol} - ${name}</title>
    
    <!-- 
        ========================================
        외부 라이브러리 (CDN)
        ========================================
    -->
    
    <!-- Bootstrap 3.3.7 (탭 UI용) -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    
    <!-- 
        TradingView Lightweight Charts v4.1.0
        - 역할: 금융 차트 렌더링 엔진
        - 기능: 캔들스틱, 라인 차트, 기술지표
    -->
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    
    <!-- 
        SockJS & STOMP (WebSocket)
        - 역할: 실시간 양방향 통신
        - 용도: 1분마다 새 캔들 수신
    -->
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    
    <style>
        /* 
            ========================================
            전역 리셋
            ========================================
        */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        /* 
            ========================================
            Body: 다크 테마
            ========================================
        */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #131722;
            color: #d1d4dc;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        /* 
            ========================================
            헤더: 종목 정보 + 뒤로가기
            ========================================
        */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 20px;
            background: #1e222d;
            border-radius: 8px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        /* 뒤로가기 버튼 */
        .back-button {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            background: #2a2e39;
            color: #d1d4dc;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
            text-decoration: none;
        }
        
        .back-button:hover {
            background: #363a45;
        }
        
        /* 종목 정보 영역 */
        .stock-info {
            display: flex;
            align-items: baseline;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        /* 종목 심볼 */
        .symbol {
            font-size: 24px;
            font-weight: bold;
            color: #2962ff;
        }
        
        /* 회사명 */
        .company-name {
            font-size: 14px;
            color: #787b86;
        }
        
        /* 현재가 */
        .price {
            font-size: 32px;
            font-weight: bold;
            color: #26a69a;
        }
        
        .price.down {
            color: #ef5350;
        }
        
        /* 등락률 */
        .change {
            font-size: 18px;
            color: #26a69a;
        }
        
        .change.down {
            color: #ef5350;
        }
        
        /* WebSocket 연결 상태 */
        .connection-status {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: #787b86;
        }
        
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #ef5350;
        }
        
        .status-dot.connected {
            background: #26a69a;
        }
        
        /* 
            ========================================
            컨트롤 패널
            ========================================
        */
        .controls {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            padding: 15px;
            background: #1e222d;
            border-radius: 8px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 8px 16px;
            background: #2a2e39;
            color: #d1d4dc;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn:hover {
            background: #363a45;
        }
        
        .btn.active {
            background: #2962ff;
            color: white;
        }
        
        .btn-group {
            display: flex;
            gap: 5px;
        }
        
        .divider {
            width: 1px;
            background: #434651;
        }
        
        /* 
            ========================================
            차트 영역
            ========================================
        */
        .chart-container {
            background: #1e222d;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
        }
        
        #chart {
            height: 600px;
        }
        
        /* 
            ========================================
            로딩 스피너
            ========================================
        */
        .loading {
            text-align: center;
            padding: 40px;
            color: #787b86;
        }
        
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #2a2e39;
            border-top-color: #2962ff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 16px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        /* 
            ========================================
            재무 정보 섹션 (신규)
            ========================================
        */
        .financial-section {
            background: #1e222d;
            border-radius: 8px;
            padding: 20px;
            margin-top: 30px;
        }
        
        .financial-section h2 {
            color: #d1d4dc;
            margin-bottom: 20px;
            font-size: 20px;
        }
        
        /* Bootstrap 탭 다크 테마 오버라이드 */
        .nav-tabs {
            border-bottom: 2px solid #2a2e39;
        }
        
        .nav-tabs > li > a {
            color: #787b86;
            background: transparent;
            border: none;
            border-radius: 0;
            padding: 12px 20px;
            transition: all 0.3s;
        }
        
        .nav-tabs > li > a:hover {
            background: #2a2e39;
            border: none;
            color: #d1d4dc;
        }
        
        .nav-tabs > li.active > a,
        .nav-tabs > li.active > a:hover,
        .nav-tabs > li.active > a:focus {
            color: #2962ff;
            background: transparent;
            border: none;
            border-bottom: 2px solid #2962ff;
        }
        
        .tab-content {
            padding: 20px 0;
        }
        
        /* 기간 선택 버튼 */
        .period-selector {
            margin-bottom: 15px;
        }
        
        .period-selector .btn {
            margin-right: 5px;
        }
        
        /* 재무 테이블 */
        .financial-table {
            width: 100%;
            background: #1e222d;
            color: #d1d4dc;
            border-collapse: collapse;
            margin-top: 15px;
        }
        
        .financial-table th {
            background: #2a2e39;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            border-bottom: 2px solid #434651;
        }
        
        .financial-table td {
            padding: 10px 12px;
            border-bottom: 1px solid #2a2e39;
        }
        
        .financial-table tr:hover {
            background: #2a2e39;
        }
        
        /* 숫자 포맷 */
        .number {
            text-align: right;
            font-family: 'Courier New', monospace;
        }
        
        .positive {
            color: #26a69a;
        }
        
        .negative {
            color: #ef5350;
        }
        
        /* 정보 카드 */
        .info-card {
            background: #2a2e39;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 15px;
        }
        
        .info-card h4 {
            color: #2962ff;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #1e222d;
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-label {
            color: #787b86;
        }
        
        .info-value {
            color: #d1d4dc;
            font-weight: 500;
        }
        
        /* 에러 메시지 */
        .error-message {
            text-align: center;
            padding: 40px;
            color: #ef5350;
        }
        
        .no-data {
            text-align: center;
            padding: 40px;
            color: #787b86;
        }
    </style>
</head>
<body>
    <!-- 공통 네비게이션 -->
    <nav class="navbar" style="background: #1e222d; border-bottom: 1px solid #2a2e39; padding: 0 20px; position: sticky; top: 0; z-index: 1000;">
        <div style="max-width: 1400px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; height: 60px;">
            <a href="/stock" style="font-size: 20px; font-weight: 700; background: linear-gradient(135deg, #2962ff 0%, #26a69a 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; text-decoration: none;">The Salty Spitoon</a>
            <div style="display: flex; gap: 8px;">
                <a href="/stock" style="padding: 10px 16px; border-radius: 6px; font-size: 14px; font-weight: 500; color: #787b86; text-decoration: none;">대시보드</a>
                <a href="/stock/chart?symbol=AAPL" style="padding: 10px 16px; border-radius: 6px; font-size: 14px; font-weight: 500; color: #787b86; text-decoration: none;">차트</a>
                <a href="/news" style="padding: 10px 16px; border-radius: 6px; font-size: 14px; font-weight: 500; color: #787b86; text-decoration: none;">뉴스</a>
                <a href="/admin" style="padding: 10px 16px; border-radius: 6px; font-size: 14px; font-weight: 500; color: #787b86; text-decoration: none;">관리자</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <!-- 
            ========================================
            헤더: 종목 정보 및 네비게이션
            ========================================
        -->
        <div class="header">
            <!-- 뒤로가기 버튼 -->
            <a href="/stock" class="back-button">
                ← 대시보드로
            </a>
            
            <!-- 종목 정보 -->
            <div class="stock-info">
                <div>
                    <span class="symbol">${symbol}</span>
                    <span class="company-name">${name}</span>
                </div>
                <span class="price" id="currentPrice">--</span>
                <span class="change" id="priceChange">--</span>
            </div>
            
            <!-- WebSocket 연결 상태 -->
            <div class="connection-status">
                <span class="status-dot" id="statusDot"></span>
                <span id="statusText">Connecting...</span>
            </div>
        </div>
        
        <!-- 
            ========================================
            컨트롤 패널: 타임프레임 및 기술지표
            ========================================
        -->
        <div class="controls">
            <!-- 타임프레임 선택 -->
            <div class="btn-group">
                <button class="btn active" onclick="changeTimeframe('1m', this)">1m</button>
                <button class="btn" onclick="changeTimeframe('5m', this)">5m</button>
                <button class="btn" onclick="changeTimeframe('1h', this)">1h</button>
                <button class="btn" onclick="changeTimeframe('1d', this)">1d</button>
            </div>
            
            <!-- 구분선 -->
            <div class="divider"></div>
            
            <!-- 기술지표 토글 -->
            <button class="btn active" onclick="toggleIndicator('MA5', this)">MA5</button>
            <button class="btn active" onclick="toggleIndicator('MA20', this)">MA20</button>
            <button class="btn" onclick="toggleIndicator('MA50', this)">MA50</button>
            <button class="btn" onclick="toggleIndicator('MA200', this)">MA200</button>
            <button class="btn" onclick="toggleIndicator('RSI', this)">RSI</button>
            
            <span style="margin-left: auto; color: #787b86; font-size: 12px;">
                Real-time updates every minute
            </span>
        </div>
        
        <!-- 
            ========================================
            차트 영역
            ========================================
        -->
        <div class="chart-container">
            <div id="chart">
                <div class="loading">
                    <div class="loading-spinner"></div>
                    <p>Loading chart...</p>
                </div>
            </div>
        </div>
        
        <!-- 
            ========================================
            재무 정보 섹션 (신규)
            ========================================
        -->
        <div class="financial-section">
            <h2>📊 Financial Information</h2>
            
            <!-- 탭 네비게이션 -->
            <ul class="nav nav-tabs" role="tablist">
                <li role="presentation" class="active">
                    <a href="#income-statement" data-toggle="tab" onclick="loadIncomeStatement()">
                        재무제표
                    </a>
                </li>
                <li role="presentation">
                    <a href="#balance-sheet" data-toggle="tab" onclick="loadBalanceSheet()">
                        대차대조표
                    </a>
                </li>
                <li role="presentation">
                    <a href="#cashflow" data-toggle="tab" onclick="loadCashflow()">
                        현금흐름표
                    </a>
                </li>
                <li role="presentation">
                    <a href="#metrics" data-toggle="tab" onclick="loadMetrics()">
                        재무지표
                    </a>
                </li>
                <li role="presentation">
                    <a href="#dividends" data-toggle="tab" onclick="loadDividends()">
                        배당
                    </a>
                </li>
                <li role="presentation">
                    <a href="#company-info" data-toggle="tab" onclick="loadCompanyInfo()">
                        기업정보
                    </a>
                </li>
            </ul>
            
            <!-- 탭 컨텐츠 -->
            <div class="tab-content">
                <!-- 재무제표 -->
                <div role="tabpanel" class="tab-pane active" id="income-statement">
                    <div class="period-selector">
                        <button class="btn active" onclick="loadIncomeStatement('quarterly', this)">분기</button>
                        <button class="btn" onclick="loadIncomeStatement('yearly', this)">연간</button>
                    </div>
                    <div id="income-statement-content">
                        <div class="loading">
                            <div class="loading-spinner"></div>
                            <p>Loading...</p>
                        </div>
                    </div>
                </div>
                
                <!-- 대차대조표 -->
                <div role="tabpanel" class="tab-pane" id="balance-sheet">
                    <div class="period-selector">
                        <button class="btn active" onclick="loadBalanceSheet('quarterly', this)">분기</button>
                        <button class="btn" onclick="loadBalanceSheet('yearly', this)">연간</button>
                    </div>
                    <div id="balance-sheet-content"></div>
                </div>
                
                <!-- 현금흐름표 -->
                <div role="tabpanel" class="tab-pane" id="cashflow">
                    <div class="period-selector">
                        <button class="btn active" onclick="loadCashflow('quarterly', this)">분기</button>
                        <button class="btn" onclick="loadCashflow('yearly', this)">연간</button>
                    </div>
                    <div id="cashflow-content"></div>
                </div>
                
                <!-- 재무지표 -->
                <div role="tabpanel" class="tab-pane" id="metrics">
                    <div id="metrics-content"></div>
                </div>
                
                <!-- 배당 -->
                <div role="tabpanel" class="tab-pane" id="dividends">
                    <div id="dividends-content"></div>
                </div>
                
                <!-- 기업정보 -->
                <div role="tabpanel" class="tab-pane" id="company-info">
                    <div id="company-info-content"></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        /* 
            ========================================
            전역 변수
            ========================================
        */
        
        const SYMBOL = '${symbol}';
        
        // 차트 관련 (기존)
        let chart;
        let candlestickSeries;
        let indicatorSeries = {};
        let currentTimeframe = '1m';
        let activeIndicators = new Set(['MA5', 'MA20']);
        
        // WebSocket (기존)
        let stompClient = null;
        let currentSubscription = null;

        /* 
            ========================================
            기존 차트 관련 함수들 (유지)
            ========================================
        */
        
        function initChart() {
            const chartOptions = {
                layout: {
                    background: { color: '#1e222d' },
                    textColor: '#d1d4dc',
                },
                grid: {
                    vertLines: { color: '#2b2b43' },
                    horzLines: { color: '#2b2b43' },
                },
                width: document.getElementById('chart').offsetWidth,
                height: 600,
                timeScale: {
                    timeVisible: true,
                    secondsVisible: false,
                }
            };
            
            chart = LightweightCharts.createChart(
                document.getElementById('chart'), 
                chartOptions
            );
            
            candlestickSeries = chart.addCandlestickSeries({
                upColor: '#26a69a',
                downColor: '#ef5350',
                borderVisible: false,
                wickUpColor: '#26a69a',
                wickDownColor: '#ef5350',
            });
            
            window.addEventListener('resize', function() {
                chart.applyOptions({
                    width: document.getElementById('chart').offsetWidth
                });
            });
        }

        function connectWebSocket() {
            console.log('WebSocket connecting...');
            
            const socket = new SockJS('/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null;
            
            stompClient.connect({}, 
                function(frame) {
                    console.log('WebSocket connected');
                    updateConnectionStatus(true);
                    subscribeToSymbol(SYMBOL);
                }, 
                function(error) {
                    console.error('WebSocket connection failed:', error);
                    updateConnectionStatus(false);
                    setTimeout(connectWebSocket, 5000);
                }
            );
        }

        function subscribeToSymbol(symbol) {
            if (currentSubscription) {
                currentSubscription.unsubscribe();
            }
            
            console.log('Subscribing to:', symbol);
            
            currentSubscription = stompClient.subscribe(
                '/topic/stock/' + symbol, 
                function(message) {
                    const candle = JSON.parse(message.body);
                    console.log('New candle received:', candle);
                    updateChartWithNewCandle(candle);
                }
            );
        }

        function updateChartWithNewCandle(candle) {
            if (currentTimeframe !== '1m') {
                loadChartData();
                return;
            }
            
            const candleData = {
                time: new Date(candle.timestamp).getTime() / 1000,
                open: parseFloat(candle.open),
                high: parseFloat(candle.high),
                low: parseFloat(candle.low),
                close: parseFloat(candle.close)
            };
            
            candlestickSeries.update(candleData);
            updateRealTimePrice();
        }

        function updateConnectionStatus(connected) {
            const dot = document.getElementById('statusDot');
            const text = document.getElementById('statusText');
            
            if (connected) {
                dot.classList.add('connected');
                text.textContent = 'Live';
            } else {
                dot.classList.remove('connected');
                text.textContent = 'Disconnected';
            }
        }

        async function loadChartData() {
            try {
                const chartDiv = document.getElementById('chart');
                const loadingDiv = chartDiv.querySelector('.loading');
                if (loadingDiv) {
                    loadingDiv.remove();
                }
                
                if (!currentTimeframe) {
                    currentTimeframe = '1m';
                }
                
                const indicators = Array.from(activeIndicators).join(',') || 'MA5,MA20';
                const url = '/stock/api/chart/' + SYMBOL + '/all' +
                        '?timeframe=' + currentTimeframe + 
                        '&indicators=' + indicators;
                
                console.log('API Request:', url);
                
                const response = await fetch(url);
                
                if (!response.ok) {
                    throw new Error('HTTP ' + response.status + ': ' + response.statusText);
                }
                
                const data = await response.json();
                
                if (data.error) {
                    console.error('Chart data error:', data.error);
                    alert('Chart load failed: ' + data.error);
                    return;
                }
                
                console.log('Chart data loaded:', data.data ? data.data.length : 0, 'candles');
                
                if (!data.data || data.data.length === 0) {
                    console.warn('No chart data');
                    alert('No chart data available. Please wait for data collection.');
                    return;
                }
                
                const candleData = data.data.map(function(item) {
                    return {
                        time: new Date(item.date).getTime() / 1000,
                        open: parseFloat(item.open),
                        high: parseFloat(item.high),
                        low: parseFloat(item.low),
                        close: parseFloat(item.close)
                    };
                });
                
                candlestickSeries.setData(candleData);
                
                if (data.indicators) {
                    updateIndicators(data.data, data.indicators);
                }
                
                updateRealTimePrice();
                
            } catch (error) {
                console.error('Chart load failed:', error);
                alert('Failed to load chart: ' + error.message);
            }
        }

        function updateIndicators(rawData, indicators) {
            Object.values(indicatorSeries).forEach(function(series) {
                chart.removeSeries(series);
            });
            indicatorSeries = {};
            
            const colors = {
                MA5: '#2962ff',
                MA20: '#ff6d00',
                MA50: '#ab47bc',
                MA200: '#66bb6a',
                RSI: '#f44336'
            };
            
            Object.keys(indicators).forEach(function(key) {
                const lineData = [];
                const indicatorValues = indicators[key];
                
                rawData.forEach(function(item, index) {
                    if (indicatorValues[index] != null) {
                        lineData.push({
                            time: new Date(item.date).getTime() / 1000,
                            value: parseFloat(indicatorValues[index])
                        });
                    }
                });
                
                if (lineData.length > 0) {
                    indicatorSeries[key] = chart.addLineSeries({
                        color: colors[key] || '#ffffff',
                        lineWidth: 2
                    });
                    indicatorSeries[key].setData(lineData);
                }
            });
        }

        async function updateRealTimePrice() {
            try {
                const response = await fetch('/stock/api/realtime/' + SYMBOL);
                const data = await response.json();
                
                if (data.error) return;
                
                const price = parseFloat(data.price);
                document.getElementById('currentPrice').textContent = '$' + price.toFixed(2);
                
                const changePercent = parseFloat(data.changePercent);
                const changeElement = document.getElementById('priceChange');
                changeElement.textContent = (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%';
                
                const priceElement = document.getElementById('currentPrice');
                if (changePercent >= 0) {
                    priceElement.classList.remove('down');
                    changeElement.classList.remove('down');
                } else {
                    priceElement.classList.add('down');
                    changeElement.classList.add('down');
                }
                
            } catch (error) {
                console.error('Real-time price update failed:', error);
            }
        }

        function changeTimeframe(timeframe, button) {
            document.querySelectorAll('.btn-group .btn').forEach(function(btn) {
                btn.classList.remove('active');
            });
            button.classList.add('active');
            
            currentTimeframe = timeframe;
            loadChartData();
        }

        function toggleIndicator(indicator, button) {
            if (activeIndicators.has(indicator)) {
                activeIndicators.delete(indicator);
                button.classList.remove('active');
            } else {
                activeIndicators.add(indicator);
                button.classList.add('active');
            }
            
            loadChartData();
        }

        /* 
            ========================================
            재무 정보 로드 함수들 (신규)
            ========================================
        */

        /**
         * 재무제표 로드
         */
        async function loadIncomeStatement(period, button) {
            period = period || 'quarterly';
            
            // 버튼 활성화 상태 변경
            if (button) {
                const container = button.parentElement;
                container.querySelectorAll('.btn').forEach(function(btn) {
                    btn.classList.remove('active');
                });
                button.classList.add('active');
            }
            
            const contentDiv = document.getElementById('income-statement-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/income-statement?period=' + period);
                const data = await response.json();
                
                if (!data.success || !data.data || data.data.length === 0) {
                    contentDiv.innerHTML = '<div class="no-data">재무제표 데이터가 없습니다.</div>';
                    return;
                }
                
                // 테이블 생성
                let html = '<table class="financial-table">';
                html += '<thead><tr>';
                html += '<th>항목</th>';
                
                // 날짜 헤더 (최대 4개)
                const displayData = data.data.slice(0, 4);
                displayData.forEach(function(item) {
                    html += '<th class="number">' + item.fiscalDate + '</th>';
                });
                html += '</tr></thead><tbody>';
                
                // 데이터 행
                const rows = [
                    { label: '총 매출', key: 'totalRevenue' },
                    { label: '매출원가', key: 'costOfRevenue' },
                    { label: '매출총이익', key: 'grossProfit' },
                    { label: '연구개발비', key: 'researchAndDevelopment' },
                    { label: '판매관리비', key: 'sellingGeneralAndAdministration' },
                    { label: '영업이익', key: 'operatingIncome' },
                    { label: 'EBITDA', key: 'ebitda' },
                    { label: '순이익', key: 'netIncome' },
                    { label: 'EPS (기본)', key: 'basicEps' },
                    { label: 'EPS (희석)', key: 'dilutedEps' }
                ];
                
                rows.forEach(function(row) {
                    html += '<tr>';
                    html += '<td>' + row.label + '</td>';
                    
                    displayData.forEach(function(item) {
                        const value = item[row.key];
                        if (value == null) {
                            html += '<td class="number">-</td>';
                        } else if (row.key.includes('Eps')) {
                            html += '<td class="number">$' + parseFloat(value).toFixed(2) + '</td>';
                        } else {
                            html += '<td class="number">$' + formatNumber(value) + '</td>';
                        }
                    });
                    
                    html += '</tr>';
                });
                
                html += '</tbody></table>';
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load income statement:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /**
         * 대차대조표 로드
         */
        async function loadBalanceSheet(period, button) {
            period = period || 'quarterly';
            
            if (button) {
                const container = button.parentElement;
                container.querySelectorAll('.btn').forEach(function(btn) {
                    btn.classList.remove('active');
                });
                button.classList.add('active');
            }
            
            const contentDiv = document.getElementById('balance-sheet-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/balance-sheet?period=' + period);
                const data = await response.json();
                
                if (!data.success || !data.data || data.data.length === 0) {
                    contentDiv.innerHTML = '<div class="no-data">대차대조표 데이터가 없습니다.</div>';
                    return;
                }
                
                let html = '<table class="financial-table">';
                html += '<thead><tr><th>항목</th>';
                
                const displayData = data.data.slice(0, 4);
                displayData.forEach(function(item) {
                    html += '<th class="number">' + item.fiscalDate + '</th>';
                });
                html += '</tr></thead><tbody>';
                
                const rows = [
                    { label: '총 자산', key: 'totalAssets' },
                    { label: '유동 자산', key: 'currentAssets' },
                    { label: '현금 및 현금성 자산', key: 'cashAndCashEquivalents' },
                    { label: '매출채권', key: 'receivables' },
                    { label: '재고자산', key: 'inventory' },
                    { label: '총 부채', key: 'totalLiabilitiesNetMinorityInterest' },
                    { label: '유동 부채', key: 'currentLiabilities' },
                    { label: '장기 부채', key: 'longTermDebt' },
                    { label: '자본총계', key: 'stockholdersEquity' },
                    { label: '이익잉여금', key: 'retainedEarnings' }
                ];
                
                rows.forEach(function(row) {
                    html += '<tr><td>' + row.label + '</td>';
                    displayData.forEach(function(item) {
                        const value = item[row.key];
                        html += '<td class="number">' + (value != null ? '$' + formatNumber(value) : '-') + '</td>';
                    });
                    html += '</tr>';
                });
                
                html += '</tbody></table>';
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load balance sheet:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /**
         * 현금흐름표 로드
         */
        async function loadCashflow(period, button) {
            period = period || 'quarterly';
            
            if (button) {
                const container = button.parentElement;
                container.querySelectorAll('.btn').forEach(function(btn) {
                    btn.classList.remove('active');
                });
                button.classList.add('active');
            }
            
            const contentDiv = document.getElementById('cashflow-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/cashflow?period=' + period);
                const data = await response.json();
                
                if (!data.success || !data.data || data.data.length === 0) {
                    contentDiv.innerHTML = '<div class="no-data">현금흐름표 데이터가 없습니다.</div>';
                    return;
                }
                
                let html = '<table class="financial-table">';
                html += '<thead><tr><th>항목</th>';
                
                const displayData = data.data.slice(0, 4);
                displayData.forEach(function(item) {
                    html += '<th class="number">' + item.fiscalDate + '</th>';
                });
                html += '</tr></thead><tbody>';
                
                const rows = [
                    { label: '영업활동 현금흐름', key: 'operatingCashFlow' },
                    { label: '투자활동 현금흐름', key: 'investingCashFlow' },
                    { label: '재무활동 현금흐름', key: 'financingCashFlow' },
                    { label: '잉여현금흐름', key: 'freeCashFlow' },
                    { label: '자본적 지출', key: 'capitalExpenditure' },
                    { label: '배당금 지급', key: 'cashDividendsPaid' },
                    { label: '기말 현금', key: 'endCashPosition' }
                ];
                
                rows.forEach(function(row) {
                    html += '<tr><td>' + row.label + '</td>';
                    displayData.forEach(function(item) {
                        const value = item[row.key];
                        html += '<td class="number">' + (value != null ? '$' + formatNumber(value) : '-') + '</td>';
                    });
                    html += '</tr>';
                });
                
                html += '</tbody></table>';
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load cashflow:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /**
         * 재무지표 로드
         */
        async function loadMetrics() {
            const contentDiv = document.getElementById('metrics-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/metrics');
                const data = await response.json();
                
                if (!data.success || !data.data) {
                    contentDiv.innerHTML = '<div class="no-data">재무지표 데이터가 없습니다.</div>';
                    return;
                }
                
                const metrics = data.data;
                
                let html = '';
                
                // 수익성 지표
                html += '<div class="info-card">';
                html += '<h4>수익성 지표</h4>';
                html += createInfoRow('순이익률', formatPercent(metrics.profitMargins));
                html += createInfoRow('영업이익률', formatPercent(metrics.operatingMargins));
                html += createInfoRow('매출총이익률', formatPercent(metrics.grossMargins));
                html += createInfoRow('ROE', formatPercent(metrics.returnOnEquity));
                html += createInfoRow('ROA', formatPercent(metrics.returnOnAssets));
                html += '</div>';
                
                // 밸류에이션
                html += '<div class="info-card">';
                html += '<h4>밸류에이션</h4>';
                html += createInfoRow('P/E Ratio (후행)', formatNumber(metrics.trailingPe, 2));
                html += createInfoRow('P/E Ratio (선행)', formatNumber(metrics.forwardPe, 2));
                html += createInfoRow('PEG Ratio', formatNumber(metrics.pegRatio, 2));
                html += createInfoRow('P/B Ratio', formatNumber(metrics.priceToBook, 2));
                html += createInfoRow('시가총액', '$' + formatNumber(metrics.marketCap));
                html += '</div>';
                
                // 배당
                html += '<div class="info-card">';
                html += '<h4>배당</h4>';
                html += createInfoRow('배당수익률', formatPercent(metrics.dividendYield));
                html += createInfoRow('배당성향', formatPercent(metrics.payoutRatio));
                html += createInfoRow('연간 배당금', '$' + formatNumber(metrics.dividendRate, 2));
                html += '</div>';
                
                // 재무 건전성
                html += '<div class="info-card">';
                html += '<h4>재무 건전성</h4>';
                html += createInfoRow('유동비율', formatNumber(metrics.currentRatio, 2));
                html += createInfoRow('당좌비율', formatNumber(metrics.quickRatio, 2));
                html += createInfoRow('부채비율', formatNumber(metrics.debtToEquity, 2));
                html += createInfoRow('베타', formatNumber(metrics.beta, 2));
                html += '</div>';
                
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load metrics:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /**
         * 배당 정보 로드
         */
        async function loadDividends() {
            const contentDiv = document.getElementById('dividends-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/dividends');
                const data = await response.json();
                
                if (!data.success || !data.data || data.data.length === 0) {
                    contentDiv.innerHTML = '<div class="no-data">배당 데이터가 없습니다.</div>';
                    return;
                }
                
                let html = '<table class="financial-table">';
                html += '<thead><tr>';
                html += '<th>지급일</th>';
                html += '<th class="number">주당 배당금</th>';
                html += '</tr></thead><tbody>';
                
                data.data.forEach(function(dividend) {
                    html += '<tr>';
                    html += '<td>' + dividend.paymentDate + '</td>';
                    html += '<td class="number">$' + parseFloat(dividend.dividendAmount).toFixed(4) + '</td>';
                    html += '</tr>';
                });
                
                html += '</tbody></table>';
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load dividends:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /**
         * 기업 정보 로드
         */
        async function loadCompanyInfo() {
            const contentDiv = document.getElementById('company-info-content');
            contentDiv.innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading...</p></div>';
            
            try {
                const response = await fetch('/stock/api/financial/' + SYMBOL + '/info');
                const data = await response.json();
                
                if (!data.success || !data.data) {
                    contentDiv.innerHTML = '<div class="no-data">기업 정보 데이터가 없습니다.</div>';
                    return;
                }
                
                const info = data.data;
                
                let html = '';
                
                // 기본 정보
                html += '<div class="info-card">';
                html += '<h4>기본 정보</h4>';
                html += createInfoRow('정식 회사명', info.longName || '-');
                html += createInfoRow('섹터', info.sector || '-');
                html += createInfoRow('산업', info.industry || '-');
                html += createInfoRow('국가', info.country || '-');
                html += createInfoRow('도시', info.city || '-');
                html += '</div>';
                
                // 연락처
                html += '<div class="info-card">';
                html += '<h4>연락처</h4>';
                html += createInfoRow('웹사이트', info.website ? '<a href="' + info.website + '" target="_blank" style="color: #2962ff;">' + info.website + '</a>' : '-');
                html += createInfoRow('전화번호', info.phone || '-');
                html += createInfoRow('주소', info.address || '-');
                html += '</div>';
                
                // 조직
                html += '<div class="info-card">';
                html += '<h4>조직 정보</h4>';
                html += createInfoRow('정규직 직원 수', info.fullTimeEmployees ? formatNumber(info.fullTimeEmployees) + '명' : '-');
                html += createInfoRow('시가총액', info.marketCap ? '$' + formatNumber(info.marketCap) : '-');
                html += createInfoRow('기업가치', info.enterpriseValue ? '$' + formatNumber(info.enterpriseValue) : '-');
                html += '</div>';
                
                // 사업 설명
                if (info.longBusinessSummary) {
                    html += '<div class="info-card">';
                    html += '<h4>사업 개요</h4>';
                    html += '<p style="color: #d1d4dc; line-height: 1.6;">' + info.longBusinessSummary + '</p>';
                    html += '</div>';
                }
                
                contentDiv.innerHTML = html;
                
            } catch (error) {
                console.error('Failed to load company info:', error);
                contentDiv.innerHTML = '<div class="error-message">데이터 로드 실패: ' + error.message + '</div>';
            }
        }

        /* 
            ========================================
            유틸리티 함수들
            ========================================
        */

        /**
         * 숫자 포맷팅 (천 단위 콤마)
         */
        function formatNumber(num, decimals) {
            if (num == null || isNaN(num)) return '-';
            
            decimals = decimals || 0;
            
            // 억 단위 변환
            if (Math.abs(num) >= 1000000000) {
                return (num / 1000000000).toFixed(2) + 'B';
            } else if (Math.abs(num) >= 1000000) {
                return (num / 1000000).toFixed(2) + 'M';
            } else if (Math.abs(num) >= 1000) {
                return (num / 1000).toFixed(2) + 'K';
            }
            
            return parseFloat(num).toFixed(decimals);
        }

        /**
         * 퍼센트 포맷팅
         */
        function formatPercent(num) {
            if (num == null || isNaN(num)) return '-';
            return (parseFloat(num) * 100).toFixed(2) + '%';
        }

        /**
         * 정보 행 생성
         */
        function createInfoRow(label, value) {
            return '<div class="info-row">' +
                   '<span class="info-label">' + label + '</span>' +
                   '<span class="info-value">' + (value || '-') + '</span>' +
                   '</div>';
        }

        /* 
            ========================================
            페이지 로드 초기화
            ========================================
        */
        window.onload = function() {
            console.log('Page loaded:', SYMBOL);
            
            // 차트 초기화
            initChart();
            
            setTimeout(function() {
                console.log('Loading chart with timeframe:', currentTimeframe);
                loadChartData();
            }, 100);
            
            // WebSocket 연결
            connectWebSocket();
            
            // 1분마다 가격 업데이트
            setInterval(updateRealTimePrice, 60000);
            
            // 재무제표 로드 (기본 탭)
            setTimeout(function() {
                loadIncomeStatement('quarterly');
            }, 500);
        };
    </script>
</body>
</html>