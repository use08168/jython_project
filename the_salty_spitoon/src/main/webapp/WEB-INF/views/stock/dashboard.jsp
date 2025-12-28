<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Stocks - The Salty Spitoon</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; background-color: #0f1419; color: #ffffff; min-height: 100vh; }
        a { color: inherit; text-decoration: none; }

        /* 네비게이션 */
        .navbar { background-color: #1a1f2e; border-bottom: 1px solid #252b3d; padding: 12px 32px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 100; }
        .navbar-brand { display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 700; color: #3b82f6; text-decoration: none; }
        .navbar-brand svg { width: 28px; height: 28px; }
        .navbar-menu { display: flex; align-items: center; gap: 24px; }
        .navbar-menu a { color: #9ca3af; text-decoration: none; font-size: 14px; font-weight: 500; transition: color 0.2s; }
        .navbar-menu a:hover, .navbar-menu a.active { color: #ffffff; }
        .navbar-right { display: flex; align-items: center; gap: 16px; }
        .user-avatar { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; cursor: pointer; border: 2px solid #22c55e; }

        /* 메인 컨텐츠 */
        .main-content { padding: 24px 32px; max-width: 1600px; margin: 0 auto; }

        /* 헤더 섹션 */
        .header-section { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .header-left { display: flex; flex-direction: column; gap: 8px; }
        .market-info { display: flex; align-items: center; gap: 24px; flex-wrap: wrap; }
        .market-status { display: inline-flex; align-items: center; gap: 8px; font-size: 14px; color: #9ca3af; }
        .market-status::before { content: ''; width: 8px; height: 8px; border-radius: 50%; }
        .market-status.open::before { background-color: #22c55e; }
        .market-status.closed::before { background-color: #ef4444; }
        .time-display { display: flex; gap: 16px; font-size: 13px; color: #6b7280; }
        .time-display .time-item { display: flex; align-items: center; gap: 6px; }
        .time-display .time-value { color: #9ca3af; font-family: 'SF Mono', monospace; }

        /* 환율 카드 */
        .exchange-rate-card { display: flex; align-items: center; gap: 12px; background: linear-gradient(135deg, #1a1f2e 0%, #252b3d 100%); border: 1px solid #374151; border-radius: 12px; padding: 14px 20px; }
        .exchange-icon { font-size: 24px; }
        .exchange-info { display: flex; flex-direction: column; }
        .exchange-label { font-size: 11px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; }
        .exchange-value { font-size: 20px; font-weight: 700; color: #ffffff; }
        .exchange-change { font-size: 13px; font-weight: 600; padding: 4px 10px; border-radius: 6px; margin-left: 8px; }
        .exchange-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .exchange-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }

        /* 메인 차트 섹션 */
        .chart-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; margin-bottom: 24px; }
        .chart-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .chart-title h2 { font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 12px; }
        .chart-title .badge { padding: 4px 8px; background-color: #252b3d; border-radius: 4px; font-size: 11px; color: #9ca3af; }
        .chart-info { display: flex; align-items: baseline; gap: 12px; margin-top: 8px; }
        .chart-price { font-size: 32px; font-weight: 700; }
        .chart-change { font-size: 14px; padding: 4px 8px; border-radius: 4px; }
        .chart-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .chart-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .chart-periods { display: flex; gap: 4px; background-color: #252b3d; padding: 4px; border-radius: 8px; }
        .chart-period { padding: 8px 16px; font-size: 13px; font-weight: 500; color: #9ca3af; background: none; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
        .chart-period:hover { color: #ffffff; }
        .chart-period.active { background-color: #374151; color: #ffffff; }
        #main-chart { width: 100%; height: 350px; margin-top: 16px; }

        /* 섹터 슬라이더 */
        .sector-slider-section { margin-bottom: 24px; }
        .sector-slider-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .sector-slider-header h3 { font-size: 16px; font-weight: 600; color: #d1d5db; }
        .sector-slider-nav { display: flex; gap: 8px; }
        .sector-slider-nav button { width: 32px; height: 32px; border-radius: 6px; background-color: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .sector-slider-nav button:hover { background-color: #374151; color: #ffffff; }
        .sector-slider-container { overflow-x: auto; scroll-behavior: smooth; -ms-overflow-style: none; scrollbar-width: none; }
        .sector-slider-container::-webkit-scrollbar { display: none; }
        .sector-slider { display: flex; gap: 12px; padding: 4px 0; }
        .sector-card { min-width: 180px; background-color: #1a1f2e; border-radius: 12px; padding: 16px; border: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .sector-card:hover { border-color: #3b82f6; transform: translateY(-2px); }
        .sector-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px; }
        .sector-symbol { font-size: 14px; font-weight: 600; color: #ffffff; }
        .sector-name { font-size: 11px; color: #6b7280; margin-top: 2px; }
        .sector-change { font-size: 12px; font-weight: 600; padding: 2px 6px; border-radius: 4px; }
        .sector-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .sector-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .sector-mini-chart { height: 50px; margin-top: 8px; }

        /* 컨트롤 패널 */
        .controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px 20px; background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; flex-wrap: wrap; gap: 16px; }
        .search-box { flex: 1; max-width: 400px; }
        .search-input { width: 100%; padding: 12px 16px; background: #252b3d; border: 1px solid #374151; border-radius: 8px; color: #d1d5db; font-size: 14px; }
        .search-input:focus { outline: none; border-color: #3b82f6; }
        .search-input::placeholder { color: #6b7280; }
        .controls-right { display: flex; align-items: center; gap: 16px; }
        .stock-count { font-size: 13px; color: #6b7280; }
        .stock-count span { color: #d1d5db; font-weight: 600; }
        .view-toggle { display: flex; gap: 4px; background-color: #252b3d; padding: 4px; border-radius: 8px; }
        .toggle-btn { padding: 8px 16px; background: none; border: none; border-radius: 6px; color: #9ca3af; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.2s; }
        .toggle-btn:hover { color: #ffffff; }
        .toggle-btn.active { background-color: #374151; color: #ffffff; }

        /* ========================================
           Normal View (리스트 형태)
           ======================================== */
        .stock-list { display: flex; flex-direction: column; gap: 8px; }
        .stock-list-item { display: flex; align-items: center; gap: 16px; background: #1a1f2e; border-radius: 12px; padding: 16px 20px; border: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .stock-list-item:hover { border-color: #3b82f6; background-color: #1e2433; }
        .stock-list-logo { width: 48px; height: 36px; border-radius: 8px; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; }
        .stock-list-logo img { height: 24px; width: auto; max-width: 100%; object-fit: contain; }
        .stock-list-info { flex: 0 0 140px; }
        .stock-list-symbol { font-size: 16px; font-weight: 600; color: #ffffff; }
        .stock-list-name { font-size: 12px; color: #6b7280; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .stock-list-chart { flex: 1; height: 40px; min-width: 150px; }
        .stock-list-price { flex: 0 0 100px; text-align: right; }
        .stock-list-price-value { font-size: 16px; font-weight: 600; color: #ffffff; }
        .stock-list-change { font-size: 13px; margin-top: 2px; }
        .stock-list-change.positive { color: #22c55e; }
        .stock-list-change.negative { color: #ef4444; }
        .stock-list-bookmark { flex: 0 0 40px; display: flex; justify-content: center; }
        .bookmark-btn { width: 36px; height: 36px; border-radius: 8px; background: transparent; border: 1px solid #374151; color: #6b7280; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .bookmark-btn:hover { border-color: #f59e0b; color: #f59e0b; }
        .bookmark-btn.active { background-color: rgba(245, 158, 11, 0.15); border-color: #f59e0b; color: #f59e0b; }
        .bookmark-btn svg { width: 18px; height: 18px; }

        /* ========================================
           Compact View (그리드 형태)
           ======================================== */
        .stock-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 12px; }
        .stock-card { background: #1a1f2e; border-radius: 12px; padding: 16px; cursor: pointer; transition: all 0.2s; border: 1px solid #252b3d; position: relative; }
        .stock-card:hover { border-color: #3b82f6; transform: translateY(-2px); }
        .stock-card-header { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
        .stock-card-logo { width: 80px; height: 28px; border-radius: 6px; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; }
        .stock-card-logo img { height: 18px; width: auto; max-width: 100%; object-fit: contain; }
        .stock-card-info { flex: 1; min-width: 0; }
        .stock-card-symbol { font-size: 15px; font-weight: 600; color: #3b82f6; }
        .stock-card-name { font-size: 11px; color: #6b7280; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .stock-card-badge { padding: 3px 8px; border-radius: 4px; font-size: 10px; font-weight: 600; background: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .stock-card-price { font-size: 22px; font-weight: 700; color: #22c55e; margin-bottom: 4px; }
        .stock-card-price.down { color: #ef4444; }
        .stock-card-change { display: flex; align-items: center; gap: 8px; }
        .stock-card-change-badge { padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 12px; background: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .stock-card-change-badge.down { background: rgba(239, 68, 68, 0.15); color: #ef4444; }

        /* 로딩 */
        .loading { text-align: center; padding: 60px 20px; color: #6b7280; }
        .loading-spinner { width: 40px; height: 40px; border: 3px solid #252b3d; border-top-color: #3b82f6; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* 반응형 */
        @media (max-width: 1200px) {
            .stock-list-chart { min-width: 100px; }
        }
        @media (max-width: 768px) {
            .main-content { padding: 16px; }
            .header-section { flex-direction: column; }
            .stock-list-chart { display: none; }
            .stock-grid { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }
        }
    </style>
</head>
<body>
    <!-- 네비게이션 (dashboard.jsp와 동일) -->
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/></svg>
            The Salty Spitoon
        </a>
        <div class="navbar-menu">
            <a href="/dashboard">Market</a>
            <a href="/stock" class="active">Stocks</a>
            <a href="/watchlist">Watchlist</a>
            <a href="/news">News</a>
            <a href="/admin">Admin</a>
        </div>
        <div class="navbar-right">
            <sec:authorize access="isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/logout'" title="로그아웃">
                    <sec:authentication property="principal.username" var="userEmail"/>
                    <c:out value="${userEmail.substring(0,1).toUpperCase()}"/>
                </div>
            </sec:authorize>
            <sec:authorize access="!isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/login'" title="로그인">?</div>
            </sec:authorize>
        </div>
    </nav>

    <main class="main-content">
        <!-- 헤더 섹션 -->
        <div class="header-section">
            <div class="header-left">
                <div class="market-info">
                    <div class="market-status" id="market-status"><span>Checking...</span></div>
                    <div class="time-display">
                        <div class="time-item">🇰🇷 KST <span class="time-value" id="time-kst">--:--:--</span></div>
                        <div class="time-item">🇺🇸 EST <span class="time-value" id="time-est">--:--:--</span></div>
                    </div>
                </div>
            </div>
            <div class="exchange-rate-card">
                <div class="exchange-icon">💲</div>
                <div class="exchange-info">
                    <div class="exchange-label">USD/KRW</div>
                    <div class="exchange-value" id="usd-krw-value">--</div>
                </div>
                <div class="exchange-change" id="usd-krw-change">--</div>
            </div>
        </div>

        <!-- NASDAQ Composite 차트 -->
        <div class="chart-section">
            <div class="chart-header">
                <div class="chart-title">
                    <div>
                        <h2>
                            <span id="main-chart-logo" style="display: inline-flex; align-items: center; justify-content: center; width: 48px; height: 32px; background: #fff; border-radius: 6px; margin-right: 8px; overflow: hidden;">
                                <span style="font-size: 16px;">📈</span>
                            </span>
                            NASDAQ Composite <span class="badge">^IXIC</span>
                        </h2>
                        <div class="chart-info">
                            <span class="chart-price" id="chart-price">--</span>
                            <span class="chart-change positive" id="chart-change">--</span>
                        </div>
                    </div>
                </div>
                <div class="chart-periods">
                    <button class="chart-period active" data-period="1m">1m</button>
                    <button class="chart-period" data-period="5m">5m</button>
                    <button class="chart-period" data-period="1h">1h</button>
                    <button class="chart-period" data-period="1d">1d</button>
                </div>
            </div>
            <div id="main-chart"></div>
        </div>

        <!-- 섹터 슬라이더 -->
        <div class="sector-slider-section">
            <div class="sector-slider-header">
                <h3>📊 Sector Performance</h3>
                <div class="sector-slider-nav">
                    <button onclick="scrollSectors(-1)">←</button>
                    <button onclick="scrollSectors(1)">→</button>
                </div>
            </div>
            <div class="sector-slider-container" id="sector-slider-container">
                <div class="sector-slider" id="sector-slider">
                    <!-- 동적으로 로드됨 -->
                </div>
            </div>
        </div>

        <!-- 컨트롤 패널 -->
        <div class="controls">
            <div class="search-box">
                <input type="text" class="search-input" id="searchInput" placeholder="Search by symbol or name..." oninput="filterStocks()">
            </div>
            <div class="controls-right">
                <div class="stock-count">Showing <span id="stockCount">--</span> stocks</div>
                <div class="view-toggle">
                    <button class="toggle-btn active" data-view="normal">Normal</button>
                    <button class="toggle-btn" data-view="compact">Compact</button>
                </div>
            </div>
        </div>

        <!-- 종목 리스트/그리드 -->
        <div id="stock-container">
            <div class="loading">
                <div class="loading-spinner"></div>
                <p>Loading stocks...</p>
            </div>
        </div>
    </main>

    <script>
        // ========================================
        // 전역 변수
        // ========================================
        var allStocks = [];
        var filteredStocks = [];
        var currentView = 'normal';
        var watchlistSymbols = new Set();
        var miniCharts = {};
        var mainChart = null;
        var mainAreaSeries = null;
        var stompClient = null;

        // 제외할 심볼 (지수, 환율, 섹터 ETF)
        var excludeSymbols = ['^IXIC', '^GSPC', '^DJI', '^VIX', 'KRW=X', 'XLK', 'XLF', 'XLE', 'XLV', 'XLY', 'XLI', 'XLB', 'XLRE', 'XLU', 'XLC', 'XLP'];

        // 섹터 ETF 정보
        var sectorETFs = [
            { symbol: 'XLK', name: 'Technology' },
            { symbol: 'XLF', name: 'Financials' },
            { symbol: 'XLE', name: 'Energy' },
            { symbol: 'XLV', name: 'Healthcare' },
            { symbol: 'XLY', name: 'Consumer Disc.' },
            { symbol: 'XLI', name: 'Industrials' },
            { symbol: 'XLB', name: 'Materials' },
            { symbol: 'XLRE', name: 'Real Estate' },
            { symbol: 'XLU', name: 'Utilities' },
            { symbol: 'XLC', name: 'Communication' },
            { symbol: 'XLP', name: 'Consumer Staples' }
        ];

        // ========================================
        // 초기화
        // ========================================
        document.addEventListener('DOMContentLoaded', function() {
            updateTime();
            setInterval(updateTime, 1000);
            checkMarketStatus();
            loadExchangeRate();
            initMainChart();
            loadMainChartData('1m');
            loadSectorSlider();
            loadWatchlist();
            loadStocks();
            setupViewToggle();
            setupChartPeriods();
            connectWebSocket();

            // 30초마다 데이터 갱신
            setInterval(function() {
                loadStocks();
                loadExchangeRate();
            }, 30000);
        });

        // ========================================
        // 시간 및 마켓 상태
        // ========================================
        function updateTime() {
            var now = new Date();
            var kstOptions = { timeZone: 'Asia/Seoul', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            var estOptions = { timeZone: 'America/New_York', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            document.getElementById('time-kst').textContent = now.toLocaleString('en-US', kstOptions);
            document.getElementById('time-est').textContent = now.toLocaleString('en-US', estOptions);
        }

        function checkMarketStatus() {
            var now = new Date();
            var estOptions = { timeZone: 'America/New_York', hour: 'numeric', minute: 'numeric', weekday: 'short' };
            var estTime = now.toLocaleString('en-US', estOptions);
            var hour = parseInt(now.toLocaleString('en-US', { timeZone: 'America/New_York', hour: 'numeric', hour12: false }));
            var day = now.toLocaleString('en-US', { timeZone: 'America/New_York', weekday: 'short' });

            var statusEl = document.getElementById('market-status');
            var isWeekend = (day === 'Sat' || day === 'Sun');
            var isMarketHours = (hour >= 9 && hour < 16);

            if (isWeekend || !isMarketHours) {
                statusEl.className = 'market-status closed';
                statusEl.innerHTML = '<span>Market Closed</span>';
            } else {
                statusEl.className = 'market-status open';
                statusEl.innerHTML = '<span>Market Open</span>';
            }
        }

        function loadExchangeRate() {
            fetch('/api/stocks/' + encodeURIComponent('KRW=X') + '/latest')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data && !data.error) {
                        var rate = data.closePrice || data.close || 0;
                        var change = data.changePercent || data.change_percent || 0;
                        var isPositive = change <= 0;

                        document.getElementById('usd-krw-value').textContent = '₩' + rate.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                        var changeEl = document.getElementById('usd-krw-change');
                        changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                        changeEl.className = 'exchange-change ' + (isPositive ? 'positive' : 'negative');
                    }
                })
                .catch(function(error) {
                    console.error('Exchange rate error:', error);
                });
        }

        // ========================================
        // 메인 차트 (NASDAQ Composite)
        // ========================================
        function initMainChart() {
            var container = document.getElementById('main-chart');
            mainChart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 350,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { color: '#252b3d' }, horzLines: { color: '#252b3d' } },
                crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
                rightPriceScale: { borderColor: '#252b3d' },
                timeScale: { borderColor: '#252b3d', timeVisible: true }
            });

            mainAreaSeries = mainChart.addAreaSeries({
                topColor: 'rgba(59, 130, 246, 0.4)',
                bottomColor: 'rgba(59, 130, 246, 0.0)',
                lineColor: '#3b82f6',
                lineWidth: 2
            });

            window.addEventListener('resize', function() {
                mainChart.applyOptions({ width: container.clientWidth });
            });

            // 로고 로드
            fetch('/api/stocks/' + encodeURIComponent('^IXIC') + '/latest')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && data.logoUrl) {
                        document.getElementById('main-chart-logo').innerHTML = '<img src="' + data.logoUrl + '" style="height: 20px; width: auto;">';
                    }
                    if (data) {
                        var price = data.closePrice || data.close || 0;
                        var change = data.changePercent || data.change_percent || 0;
                        document.getElementById('chart-price').textContent = price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                        var changeEl = document.getElementById('chart-change');
                        changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                        changeEl.className = 'chart-change ' + (change >= 0 ? 'positive' : 'negative');
                    }
                });
        }

        function loadMainChartData(timeframe) {
            var url = '/stock/api/chart/' + encodeURIComponent('^IXIC') + '/all?timeframe=' + timeframe;
            fetch(url)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.data && data.data.length > 0) {
                        var chartData = data.data.map(function(item) {
                            return {
                                time: new Date(item.date).getTime() / 1000,
                                value: parseFloat(item.close)
                            };
                        });
                        mainAreaSeries.setData(chartData);
                    }
                })
                .catch(function(error) {
                    console.error('Main chart error:', error);
                });
        }

        function setupChartPeriods() {
            var buttons = document.querySelectorAll('.chart-period');
            buttons.forEach(function(btn) {
                btn.addEventListener('click', function() {
                    buttons.forEach(function(b) { b.classList.remove('active'); });
                    this.classList.add('active');
                    loadMainChartData(this.getAttribute('data-period'));
                });
            });
        }

        // ========================================
        // 섹터 슬라이더
        // ========================================
        function loadSectorSlider() {
            var slider = document.getElementById('sector-slider');
            slider.innerHTML = '';

            sectorETFs.forEach(function(sector) {
                var card = document.createElement('div');
                card.className = 'sector-card';
                card.onclick = function() { location.href = '/stock/detail/' + sector.symbol; };
                card.innerHTML = 
                    '<div class="sector-card-header">' +
                        '<div>' +
                            '<div class="sector-symbol">' + sector.symbol + '</div>' +
                            '<div class="sector-name">' + sector.name + '</div>' +
                        '</div>' +
                        '<div class="sector-change positive" id="sector-change-' + sector.symbol + '">--</div>' +
                    '</div>' +
                    '<div class="sector-mini-chart" id="sector-chart-' + sector.symbol + '"></div>';
                slider.appendChild(card);

                // 데이터 로드
                loadSectorData(sector.symbol);
            });
        }

        function loadSectorData(symbol) {
            // 가격 정보
            fetch('/api/stocks/' + symbol + '/latest')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && !data.error) {
                        var change = data.changePercent || data.change_percent || 0;
                        var changeEl = document.getElementById('sector-change-' + symbol);
                        if (changeEl) {
                            changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            changeEl.className = 'sector-change ' + (change >= 0 ? 'positive' : 'negative');
                        }
                    }
                });

            // 미니 차트 (1시간 데이터)
            fetch('/api/stocks/' + symbol + '/history?days=1')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && data.length > 0) {
                        createSectorMiniChart(symbol, data.slice(-60)); // 최근 60분
                    }
                });
        }

        function createSectorMiniChart(symbol, data) {
            var container = document.getElementById('sector-chart-' + symbol);
            if (!container) return;

            var chart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 50,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { visible: false }, horzLines: { visible: false } },
                rightPriceScale: { visible: false },
                timeScale: { visible: false },
                crosshair: { mode: LightweightCharts.CrosshairMode.Hidden },
                handleScroll: false,
                handleScale: false
            });

            var firstPrice = parseFloat(data[0].close || data[0].closePrice);
            var lastPrice = parseFloat(data[data.length - 1].close || data[data.length - 1].closePrice);
            var isPositive = lastPrice >= firstPrice;

            var series = chart.addAreaSeries({
                topColor: isPositive ? 'rgba(34, 197, 94, 0.3)' : 'rgba(239, 68, 68, 0.3)',
                bottomColor: 'transparent',
                lineColor: isPositive ? '#22c55e' : '#ef4444',
                lineWidth: 1.5,
                priceLineVisible: false,
                lastValueVisible: false
            });

            var chartData = data.map(function(item) {
                return {
                    time: new Date(item.timestamp || item.datetime).getTime() / 1000,
                    value: parseFloat(item.close || item.closePrice)
                };
            });

            series.setData(chartData);
            chart.timeScale().fitContent();
        }

        function scrollSectors(direction) {
            var container = document.getElementById('sector-slider-container');
            container.scrollBy({ left: direction * 200, behavior: 'smooth' });
        }

        // ========================================
        // 워치리스트
        // ========================================
        function loadWatchlist() {
            fetch('/api/watchlist')
                .then(function(response) {
                    if (response.status === 401) return null;
                    return response.json();
                })
                .then(function(data) {
                    if (data && data.success && data.data) {
                        watchlistSymbols = new Set(data.data.map(function(s) { return s.symbol; }));
                    }
                })
                .catch(function(error) {
                    console.error('Watchlist error:', error);
                });
        }

        function toggleWatchlist(symbol, event) {
            event.stopPropagation();
            
            fetch('/api/watchlist/toggle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ symbol: symbol })
            })
            .then(function(response) {
                if (response.status === 401) {
                    location.href = '/login';
                    return null;
                }
                return response.json();
            })
            .then(function(data) {
                if (data && data.success) {
                    if (data.isInWatchlist) {
                        watchlistSymbols.add(symbol);
                    } else {
                        watchlistSymbols.delete(symbol);
                    }
                    updateBookmarkButton(symbol, data.isInWatchlist);
                }
            })
            .catch(function(error) {
                console.error('Toggle watchlist error:', error);
            });
        }

        function updateBookmarkButton(symbol, isActive) {
            var btn = document.querySelector('.bookmark-btn[data-symbol="' + symbol + '"]');
            if (btn) {
                if (isActive) {
                    btn.classList.add('active');
                    btn.querySelector('svg').setAttribute('fill', 'currentColor');
                } else {
                    btn.classList.remove('active');
                    btn.querySelector('svg').setAttribute('fill', 'none');
                }
            }
        }

        // ========================================
        // 종목 로드 및 렌더링
        // ========================================
        function loadStocks() {
            fetch('/stock/api/dashboard')
                .then(function(response) { return response.json(); })
                .then(function(stocks) {
                    // 제외할 심볼 필터링
                    allStocks = stocks.filter(function(s) {
                        return excludeSymbols.indexOf(s.symbol) === -1;
                    });
                    filteredStocks = allStocks;
                    document.getElementById('stockCount').textContent = filteredStocks.length;
                    renderStocks();
                })
                .catch(function(error) {
                    console.error('Load stocks error:', error);
                });
        }

        function filterStocks() {
            var query = document.getElementById('searchInput').value.toLowerCase();
            if (query === '') {
                filteredStocks = allStocks;
            } else {
                filteredStocks = allStocks.filter(function(stock) {
                    return stock.symbol.toLowerCase().includes(query) || 
                           stock.name.toLowerCase().includes(query);
                });
            }
            document.getElementById('stockCount').textContent = filteredStocks.length;
            renderStocks();
        }

        function renderStocks() {
            var container = document.getElementById('stock-container');
            
            if (filteredStocks.length === 0) {
                container.innerHTML = '<div class="loading"><p>No stocks found</p></div>';
                return;
            }

            if (currentView === 'normal') {
                renderListView(container);
            } else {
                renderGridView(container);
            }
        }

        function renderListView(container) {
            var html = '<div class="stock-list">';
            
            filteredStocks.forEach(function(stock) {
                var price = stock.error ? 0 : parseFloat(stock.price || 0);
                var changePercent = stock.error ? 0 : parseFloat(stock.changePercent || 0);
                var isDown = changePercent < 0;
                var isInWatchlist = watchlistSymbols.has(stock.symbol);

                var logoHtml = stock.logoUrl 
                    ? '<img src="' + stock.logoUrl + '" alt="' + stock.symbol + '" onerror="this.parentElement.innerHTML=\'📈\'">'
                    : '📈';

                html += 
                    '<div class="stock-list-item" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                        '<div class="stock-list-logo">' + logoHtml + '</div>' +
                        '<div class="stock-list-info">' +
                            '<div class="stock-list-symbol">' + stock.symbol + '</div>' +
                            '<div class="stock-list-name">' + stock.name + '</div>' +
                        '</div>' +
                        '<div class="stock-list-chart" id="mini-chart-' + stock.symbol + '"></div>' +
                        '<div class="stock-list-price">' +
                            '<div class="stock-list-price-value">$' + price.toFixed(2) + '</div>' +
                            '<div class="stock-list-change ' + (isDown ? 'negative' : 'positive') + '">' +
                                (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%' +
                            '</div>' +
                        '</div>' +
                        '<div class="stock-list-bookmark">' +
                            '<button class="bookmark-btn ' + (isInWatchlist ? 'active' : '') + '" data-symbol="' + stock.symbol + '" onclick="toggleWatchlist(\'' + stock.symbol + '\', event)">' +
                                '<svg viewBox="0 0 24 24" fill="' + (isInWatchlist ? 'currentColor' : 'none') + '" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>' +
                            '</button>' +
                        '</div>' +
                    '</div>';
            });

            html += '</div>';
            container.innerHTML = html;

            // 미니 차트 생성
            filteredStocks.forEach(function(stock) {
                loadMiniChart(stock.symbol);
            });
        }

        function renderGridView(container) {
            var html = '<div class="stock-grid">';
            
            filteredStocks.forEach(function(stock) {
                var price = stock.error ? 0 : parseFloat(stock.price || 0);
                var changePercent = stock.error ? 0 : parseFloat(stock.changePercent || 0);
                var change = stock.error ? 0 : parseFloat(stock.change || 0);
                var isDown = changePercent < 0;

                var logoHtml = stock.logoUrl 
                    ? '<img src="' + stock.logoUrl + '" alt="' + stock.symbol + '" onerror="this.parentElement.innerHTML=\'📈\'">'
                    : '📈';

                html += 
                    '<div class="stock-card" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                        '<div class="stock-card-header">' +
                            '<div class="stock-card-logo">' + logoHtml + '</div>' +
                            '<div class="stock-card-info">' +
                                '<div class="stock-card-symbol">' + stock.symbol + '</div>' +
                                '<div class="stock-card-name">' + stock.name + '</div>' +
                            '</div>' +
                            '<div class="stock-card-badge">Live</div>' +
                        '</div>' +
                        '<div class="stock-card-price ' + (isDown ? 'down' : '') + '">$' + price.toFixed(2) + '</div>' +
                        '<div class="stock-card-change">' +
                            '<span class="stock-card-change-badge ' + (isDown ? 'down' : '') + '">' +
                                (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%' +
                            '</span>' +
                            '<span style="color: #6b7280; font-size: 12px;">' +
                                (change >= 0 ? '+' : '') + change.toFixed(2) +
                            '</span>' +
                        '</div>' +
                    '</div>';
            });

            html += '</div>';
            container.innerHTML = html;
        }

        function loadMiniChart(symbol) {
            var container = document.getElementById('mini-chart-' + symbol);
            if (!container) return;

            fetch('/api/stocks/' + symbol + '/history?days=1')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && data.length > 0) {
                        createMiniChart(symbol, container, data.slice(-60));
                    }
                })
                .catch(function(error) {
                    console.error('Mini chart error for ' + symbol);
                });
        }

        function createMiniChart(symbol, container, data) {
            var chart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 40,
                layout: { background: { type: 'solid', color: 'transparent' } },
                grid: { vertLines: { visible: false }, horzLines: { visible: false } },
                rightPriceScale: { visible: false },
                timeScale: { visible: false },
                crosshair: { mode: LightweightCharts.CrosshairMode.Hidden },
                handleScroll: false,
                handleScale: false
            });

            var firstPrice = parseFloat(data[0].close || data[0].closePrice);
            var lastPrice = parseFloat(data[data.length - 1].close || data[data.length - 1].closePrice);
            var isPositive = lastPrice >= firstPrice;

            var series = chart.addAreaSeries({
                topColor: isPositive ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)',
                bottomColor: 'transparent',
                lineColor: isPositive ? '#22c55e' : '#ef4444',
                lineWidth: 1.5,
                priceLineVisible: false,
                lastValueVisible: false
            });

            var chartData = data.map(function(item) {
                return {
                    time: new Date(item.timestamp || item.datetime).getTime() / 1000,
                    value: parseFloat(item.close || item.closePrice)
                };
            });

            series.setData(chartData);
            chart.timeScale().fitContent();
            miniCharts[symbol] = { chart: chart, series: series };
        }

        // ========================================
        // View 토글
        // ========================================
        function setupViewToggle() {
            var buttons = document.querySelectorAll('.view-toggle .toggle-btn');
            buttons.forEach(function(btn) {
                btn.addEventListener('click', function() {
                    buttons.forEach(function(b) { b.classList.remove('active'); });
                    this.classList.add('active');
                    currentView = this.getAttribute('data-view');
                    renderStocks();
                });
            });
        }

        // ========================================
        // WebSocket
        // ========================================
        function connectWebSocket() {
            var socket = new SockJS('/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null;

            stompClient.connect({}, function(frame) {
                console.log('WebSocket connected');
                
                // NASDAQ Composite 구독
                stompClient.subscribe('/topic/stock/^IXIC', function(msg) {
                    var candle = JSON.parse(msg.body);
                    if (mainAreaSeries) {
                        mainAreaSeries.update({
                            time: new Date(candle.timestamp).getTime() / 1000,
                            value: parseFloat(candle.close)
                        });
                    }
                    document.getElementById('chart-price').textContent = parseFloat(candle.close).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                });

            }, function(error) {
                console.error('WebSocket error:', error);
                setTimeout(connectWebSocket, 5000);
            });
        }
    </script>
</body>
</html>
