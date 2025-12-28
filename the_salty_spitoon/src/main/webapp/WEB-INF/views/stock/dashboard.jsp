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
        .navbar-search { flex: 0 1 360px; position: relative; }
        .navbar-search input { width: 100%; padding: 10px 16px 10px 40px; font-size: 14px; background-color: #252b3d; border: 1px solid #374151; border-radius: 8px; color: #ffffff; transition: all 0.2s; }
        .navbar-search input:focus { outline: none; border-color: #3b82f6; }
        .navbar-search input::placeholder { color: #6b7280; }
        .navbar-search svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: #6b7280; }
        .navbar-menu { display: flex; align-items: center; gap: 24px; }
        .navbar-menu a { color: #9ca3af; text-decoration: none; font-size: 14px; font-weight: 500; transition: color 0.2s; }
        .navbar-menu a:hover, .navbar-menu a.active { color: #ffffff; }
        .navbar-right { display: flex; align-items: center; gap: 16px; }
        .user-avatar { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; cursor: pointer; border: 2px solid #22c55e; }

        /* 메인 컨텐츠 */
        .main-content { padding: 24px 32px; max-width: 1600px; margin: 0 auto; }

        /* 헤더 섹션 */
        .header-section { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .header-left { display: flex; flex-direction: column; gap: 8px; }
        .market-info { display: flex; align-items: center; gap: 24px; flex-wrap: wrap; }
        .market-status { display: inline-flex; align-items: center; gap: 8px; font-size: 24px; color: #9ca3af; }
        .market-status::before { content: ''; width: 8px; height: 8px; border-radius: 50%; }
        .market-status.open::before { background-color: #22c55e; }
        .market-status.closed::before { background-color: #ef4444; }
        .time-display { display: flex; gap: 16px; font-size: 20px; color: #6b7280; }
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
        .sector-mini-chart { height: 50px; margin-top: 8px; width: 100%; }
        .sector-mini-chart canvas { width: 100%; height: 100%; }

        /* 컨트롤 패널 */
        .controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px 20px; background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; flex-wrap: wrap; gap: 16px; }
        .sort-options { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .sort-label { font-size: 13px; color: #6b7280; margin-right: 4px; }
        .sort-btn { padding: 8px 14px; background: #252b3d; border: 1px solid #374151; border-radius: 6px; color: #9ca3af; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.2s; display: flex; align-items: center; gap: 6px; }
        .sort-btn:hover { background: #374151; color: #ffffff; }
        .sort-btn.active { background: #3b82f6; border-color: #3b82f6; color: #ffffff; }
        .sort-btn svg { width: 14px; height: 14px; }
        .controls-right { display: flex; align-items: center; gap: 16px; }
        .stock-count { font-size: 13px; color: #6b7280; }
        .stock-count span { color: #d1d5db; font-weight: 600; }
        .view-toggle { display: flex; gap: 4px; background-color: #252b3d; padding: 4px; border-radius: 8px; }
        .toggle-btn { padding: 8px 16px; background: none; border: none; border-radius: 6px; color: #9ca3af; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.2s; }
        .toggle-btn:hover { color: #ffffff; }
        .toggle-btn.active { background-color: #374151; color: #ffffff; }

        /* Normal View (리스트) */
        .stock-list { display: flex; flex-direction: column; gap: 8px; }
        .stock-list-item { display: flex; align-items: center; gap: 16px; background: #1a1f2e; border-radius: 12px; padding: 8px 24px; border: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .stock-list-item:hover { border-color: #3b82f6; background-color: #1e2433; }
        .stock-list-logo { width: 150px; height: 50px; border-radius: 8px; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; padding: 8px;}
        .stock-list-logo img { height: 40px; width: auto; max-width: 100%; object-fit: contain; }
        .stock-list-info { flex: 1; min-width: 100px; }
        .stock-list-symbol { font-size: 16px; font-weight: 600; color: #ffffff; }
        .stock-list-name { font-size: 12px; color: #6b7280; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .stock-list-right { display: flex; align-items: center; gap: 20px; margin-left: auto; }
        .stock-list-chart { width: 150px; height: 50px; flex-shrink: 0; margin-right: 120px;}
        .stock-list-chart canvas { width: 200%; height: 100%; }
        .stock-list-price { width: 100px; text-align: right; flex-shrink: 0; }
        .stock-list-price-value { font-size: 16px; font-weight: 600; color: #ffffff; }
        .stock-list-change { font-size: 13px; margin-top: 2px; }
        .stock-list-change.positive { color: #22c55e; }
        .stock-list-change.negative { color: #ef4444; }
        .stock-list-bookmark { flex-shrink: 0; }
        .bookmark-btn { width: 36px; height: 36px; border-radius: 8px; background: transparent; border: 1px solid #374151; color: #6b7280; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .bookmark-btn:hover { border-color: #f59e0b; color: #f59e0b; }
        .bookmark-btn.active { background-color: rgba(245, 158, 11, 0.15); border-color: #f59e0b; color: #f59e0b; }
        .bookmark-btn svg { width: 18px; height: 18px; }

        /* 더 보기 버튼 */
        .load-more-section { text-align: center; margin-top: 24px; }
        .load-more-btn { padding: 14px 48px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); border: none; border-radius: 10px; color: #ffffff; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
        .load-more-btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .load-more-btn:disabled { background: #374151; cursor: not-allowed; transform: none; box-shadow: none; }
        .load-more-info { font-size: 13px; color: #6b7280; margin-top: 12px; }

        /* Compact View (그리드) */
        .stock-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 12px; }
        .stock-card { background: #1a1f2e; border-radius: 12px; padding: 16px; cursor: pointer; transition: all 0.2s; border: 1px solid #252b3d; }
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
        @media (max-width: 768px) {
            .main-content { padding: 16px; }
            .header-section { flex-direction: column; }
            .stock-list-chart { display: none; }
            .stock-grid { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }
            .sort-options { width: 100%; }
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/></svg>
            The Salty Spitoon
        </a>
        <div class="navbar-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
            <input type="text" id="searchInput" placeholder="Search tickers, news..." oninput="filterStocks()">
        </div>
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

        <div class="chart-section">
            <div class="chart-header">
                <div class="chart-title">
                    <div>
                        <h2>NASDAQ Composite <span class="badge">^IXIC</span></h2>
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

        <div class="sector-slider-section">
            <div class="sector-slider-header">
                <h3>📊 Sector Performance</h3>
                <div class="sector-slider-nav">
                    <button onclick="scrollSectors(-1)">←</button>
                    <button onclick="scrollSectors(1)">→</button>
                </div>
            </div>
            <div class="sector-slider-container" id="sector-slider-container">
                <div class="sector-slider" id="sector-slider"></div>
            </div>
        </div>

        <div class="controls">
            <div class="sort-options">
                <span class="sort-label">Sort by:</span>
                <button class="sort-btn active" data-sort="alpha" onclick="sortStocks('alpha')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h12M3 18h6"/></svg>
                    A-Z
                </button>
                <button class="sort-btn" data-sort="alpha-desc" onclick="sortStocks('alpha-desc')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h6M3 12h12M3 18h18"/></svg>
                    Z-A
                </button>
                <button class="sort-btn" data-sort="bookmarked" onclick="sortStocks('bookmarked')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    Bookmarked
                </button>
                <button class="sort-btn" data-sort="price-high" onclick="sortStocks('price-high')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12l7-7 7 7"/></svg>
                    Price ↑
                </button>
                <button class="sort-btn" data-sort="price-low" onclick="sortStocks('price-low')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12l7 7 7-7"/></svg>
                    Price ↓
                </button>
            </div>
            <div class="controls-right">
                <div class="stock-count">Showing <span id="stockCount">--</span> stocks</div>
                <div class="view-toggle">
                    <button class="toggle-btn active" data-view="normal">Normal</button>
                    <button class="toggle-btn" data-view="compact">Compact</button>
                </div>
            </div>
        </div>

        <div id="stock-container">
            <div class="loading">
                <div class="loading-spinner"></div>
                <p>Loading stocks...</p>
            </div>
        </div>

        <div class="load-more-section" id="load-more-section" style="display: none;">
            <button class="load-more-btn" id="load-more-btn" onclick="loadMore()">Load More</button>
            <div class="load-more-info" id="load-more-info"></div>
        </div>
    </main>

    <script>
        var allStocks = [];
        var filteredStocks = [];
        var displayedStocks = [];
        var currentView = 'normal';
        var currentSort = 'alpha';
        var watchlistSymbols = new Set();
        var chartDataCache = {};
        var mainChart = null;
        var mainAreaSeries = null;
        var stompClient = null;

        var itemsPerPage = 10;
        var currentPage = 0;

        var excludeSymbols = ['^IXIC', '^GSPC', '^DJI', '^VIX', 'KRW=X', 'XLK', 'XLF', 'XLE', 'XLV', 'XLY', 'XLI', 'XLB', 'XLRE', 'XLU', 'XLC', 'XLP'];

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
            setInterval(function() { loadExchangeRate(); }, 30000);
        });

        function updateTime() {
            var now = new Date();
            document.getElementById('time-kst').textContent = now.toLocaleString('en-US', { timeZone: 'Asia/Seoul', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
            document.getElementById('time-est').textContent = now.toLocaleString('en-US', { timeZone: 'America/New_York', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
        }

        function checkMarketStatus() {
            var now = new Date();
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
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && !data.error) {
                        var rate = data.closePrice || data.close || 0;
                        var change = data.changePercent || data.change_percent || 0;
                        document.getElementById('usd-krw-value').textContent = '₩' + rate.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                        var changeEl = document.getElementById('usd-krw-change');
                        changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                        changeEl.className = 'exchange-change ' + (change <= 0 ? 'positive' : 'negative');
                    }
                });
        }

        function initMainChart() {
            var container = document.getElementById('main-chart');
            mainChart = LightweightCharts.createChart(container, {
                width: container.clientWidth, height: 350,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { color: '#252b3d' }, horzLines: { color: '#252b3d' } },
                rightPriceScale: { borderColor: '#252b3d' },
                timeScale: { borderColor: '#252b3d', timeVisible: true }
            });
            mainAreaSeries = mainChart.addAreaSeries({
                topColor: 'rgba(59, 130, 246, 0.4)', bottomColor: 'rgba(59, 130, 246, 0.0)',
                lineColor: '#3b82f6', lineWidth: 2
            });
            window.addEventListener('resize', function() { mainChart.applyOptions({ width: container.clientWidth }); });
            
            fetch('/api/stocks/' + encodeURIComponent('^IXIC') + '/latest')
                .then(function(r) { return r.json(); })
                .then(function(data) {
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
            fetch('/stock/api/chart/' + encodeURIComponent('^IXIC') + '/all?timeframe=' + timeframe)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.data && data.data.length > 0) {
                        var chartData = data.data.map(function(item) {
                            return { time: new Date(item.date).getTime() / 1000, value: parseFloat(item.close) };
                        });
                        mainAreaSeries.setData(chartData);
                    }
                });
        }

        function setupChartPeriods() {
            document.querySelectorAll('.chart-period').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('.chart-period').forEach(function(b) { b.classList.remove('active'); });
                    this.classList.add('active');
                    loadMainChartData(this.getAttribute('data-period'));
                });
            });
        }

        // ========================================
        // Canvas Sparkline 그리기
        // ========================================
        function drawSparkline(canvas, data, isPositive) {
            if (!canvas || !data || data.length < 2) return;

            var ctx = canvas.getContext('2d');
            var width = canvas.width;
            var height = canvas.height;
            var padding = 4;

            // 가격 배열 추출
            var prices = data.map(function(d) { return parseFloat(d.close || d.closePrice || 0); });
            var min = Math.min.apply(null, prices);
            var max = Math.max.apply(null, prices);
            var range = max - min || 1;

            // 색상 설정
            var lineColor = isPositive ? '#22c55e' : '#ef4444';
            var fillColor = isPositive ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)';

            // 캔버스 초기화
            ctx.clearRect(0, 0, width, height);

            // 좌표 계산
            var points = prices.map(function(price, i) {
                var x = padding + (i / (prices.length - 1)) * (width - padding * 2);
                var y = padding + (1 - (price - min) / range) * (height - padding * 2);
                return { x: x, y: y };
            });

            // 영역 채우기 (그라데이션)
            var gradient = ctx.createLinearGradient(0, 0, 0, height);
            gradient.addColorStop(0, fillColor);
            gradient.addColorStop(1, 'transparent');

            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (var i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.lineTo(points[points.length - 1].x, height - padding);
            ctx.lineTo(points[0].x, height - padding);
            ctx.closePath();
            ctx.fillStyle = gradient;
            ctx.fill();

            // 라인 그리기
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (var i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.strokeStyle = lineColor;
            ctx.lineWidth = 2;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.stroke();
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
                card.innerHTML = '<div class="sector-card-header"><div><div class="sector-symbol">' + sector.symbol + '</div><div class="sector-name">' + sector.name + '</div></div><div class="sector-change positive" id="sector-change-' + sector.symbol + '">--</div></div><div class="sector-mini-chart"><canvas id="sector-canvas-' + sector.symbol + '" width="148" height="50"></canvas></div>';
                slider.appendChild(card);
            });
            
            sectorETFs.forEach(function(sector) {
                loadSectorData(sector.symbol);
            });
        }

        function loadSectorData(symbol) {
            fetch('/api/stocks/' + symbol + '/latest')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && !data.error) {
                        var change = data.changePercent || data.change_percent || 0;
                        var el = document.getElementById('sector-change-' + symbol);
                        if (el) {
                            el.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            el.className = 'sector-change ' + (change >= 0 ? 'positive' : 'negative');
                        }
                    }
                });

            // 1시간봉 API 사용
            fetch('/stock/api/chart/' + symbol + '/all?timeframe=1h')
                .then(function(r) { return r.json(); })
                .then(function(response) {
                    if (response.data && response.data.length > 1) {
                        var canvas = document.getElementById('sector-canvas-' + symbol);
                        var prices = response.data.slice(-24); // 최근 24시간
                        var first = parseFloat(prices[0].close);
                        var last = parseFloat(prices[prices.length - 1].close);
                        drawSparkline(canvas, prices, last >= first);
                    }
                });
        }

        function scrollSectors(dir) {
            document.getElementById('sector-slider-container').scrollBy({ left: dir * 200, behavior: 'smooth' });
        }

        // ========================================
        // 워치리스트
        // ========================================
        function loadWatchlist() {
            fetch('/api/watchlist')
                .then(function(r) { return r.status === 401 ? null : r.json(); })
                .then(function(data) {
                    if (data && data.success && data.data) {
                        watchlistSymbols = new Set(data.data.map(function(s) { return s.symbol; }));
                    }
                });
        }

        function toggleWatchlist(symbol, event) {
            event.stopPropagation();
            fetch('/api/watchlist/toggle', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ symbol: symbol }) })
                .then(function(r) { return r.status === 401 ? (location.href = '/login', null) : r.json(); })
                .then(function(data) {
                    if (data && data.success) {
                        data.isInWatchlist ? watchlistSymbols.add(symbol) : watchlistSymbols.delete(symbol);
                        var btn = document.querySelector('.bookmark-btn[data-symbol="' + symbol + '"]');
                        if (btn) {
                            btn.classList.toggle('active', data.isInWatchlist);
                            btn.querySelector('svg').setAttribute('fill', data.isInWatchlist ? 'currentColor' : 'none');
                        }
                    }
                });
        }

        // ========================================
        // 종목 로드 및 정렬
        // ========================================
        function loadStocks() {
            fetch('/stock/api/dashboard')
                .then(function(r) { return r.json(); })
                .then(function(stocks) {
                    allStocks = stocks.filter(function(s) { return excludeSymbols.indexOf(s.symbol) === -1; });
                    filteredStocks = allStocks.slice();
                    applySorting();
                    currentPage = 0;
                    displayedStocks = [];
                    document.getElementById('stockCount').textContent = filteredStocks.length;
                    loadMore();
                });
        }

        function filterStocks() {
            var q = document.getElementById('searchInput').value.toLowerCase();
            filteredStocks = q === '' ? allStocks.slice() : allStocks.filter(function(s) { return s.symbol.toLowerCase().includes(q) || s.name.toLowerCase().includes(q); });
            applySorting();
            currentPage = 0;
            displayedStocks = [];
            document.getElementById('stockCount').textContent = filteredStocks.length;
            loadMore();
        }

        function sortStocks(sortType) {
            currentSort = sortType;
            document.querySelectorAll('.sort-btn').forEach(function(btn) {
                btn.classList.remove('active');
                if (btn.getAttribute('data-sort') === sortType) {
                    btn.classList.add('active');
                }
            });
            applySorting();
            currentPage = 0;
            displayedStocks = [];
            loadMore();
        }

        function applySorting() {
            switch (currentSort) {
                case 'alpha':
                    filteredStocks.sort(function(a, b) { return a.symbol.localeCompare(b.symbol); });
                    break;
                case 'alpha-desc':
                    filteredStocks.sort(function(a, b) { return b.symbol.localeCompare(a.symbol); });
                    break;
                case 'bookmarked':
                    filteredStocks.sort(function(a, b) {
                        var aBookmarked = watchlistSymbols.has(a.symbol) ? 1 : 0;
                        var bBookmarked = watchlistSymbols.has(b.symbol) ? 1 : 0;
                        if (bBookmarked !== aBookmarked) return bBookmarked - aBookmarked;
                        return a.symbol.localeCompare(b.symbol);
                    });
                    break;
                case 'price-high':
                    filteredStocks.sort(function(a, b) { return parseFloat(b.price || 0) - parseFloat(a.price || 0); });
                    break;
                case 'price-low':
                    filteredStocks.sort(function(a, b) { return parseFloat(a.price || 0) - parseFloat(b.price || 0); });
                    break;
            }
        }

        // ========================================
        // 페이지네이션 및 더 보기
        // ========================================
        function loadMore() {
            var start = currentPage * itemsPerPage;
            var end = Math.min(start + itemsPerPage, filteredStocks.length);
            var newStocks = filteredStocks.slice(start, end);

            if (newStocks.length === 0 && currentPage === 0) {
                document.getElementById('stock-container').innerHTML = '<div class="loading"><p>No stocks found</p></div>';
                document.getElementById('load-more-section').style.display = 'none';
                return;
            }

            displayedStocks = displayedStocks.concat(newStocks);
            currentPage++;

            renderStocks();
            updateLoadMoreButton();

            // 미니 차트 로드 (Normal 뷰일 때만)
            if (currentView === 'normal') {
                setTimeout(function() {
                    newStocks.forEach(function(stock) {
                        loadMiniChart(stock.symbol);
                    });
                }, 100);
            }
        }

        function updateLoadMoreButton() {
            var section = document.getElementById('load-more-section');
            var btn = document.getElementById('load-more-btn');
            var info = document.getElementById('load-more-info');

            var remaining = filteredStocks.length - displayedStocks.length;

            if (remaining > 0) {
                section.style.display = 'block';
                btn.disabled = false;
                btn.textContent = 'Load More (' + Math.min(remaining, itemsPerPage) + ')';
                info.textContent = 'Showing ' + displayedStocks.length + ' of ' + filteredStocks.length + ' stocks';
            } else {
                if (displayedStocks.length > itemsPerPage) {
                    section.style.display = 'block';
                    btn.disabled = true;
                    btn.textContent = 'All Loaded';
                    info.textContent = 'Showing all ' + filteredStocks.length + ' stocks';
                } else {
                    section.style.display = 'none';
                }
            }
        }

        // ========================================
        // 렌더링
        // ========================================
        function renderStocks() {
            var container = document.getElementById('stock-container');
            if (displayedStocks.length === 0) {
                container.innerHTML = '<div class="loading"><p>No stocks found</p></div>';
                return;
            }
            currentView === 'normal' ? renderListView(container) : renderGridView(container);
        }

        function renderListView(container) {
            var html = '<div class="stock-list">';
            displayedStocks.forEach(function(stock) {
                var price = stock.error ? 0 : parseFloat(stock.price || 0);
                var changePercent = stock.error ? 0 : parseFloat(stock.changePercent || 0);
                var isDown = changePercent < 0;
                var isInWatchlist = watchlistSymbols.has(stock.symbol);
                var logoHtml = stock.logoUrl ? '<img src="' + stock.logoUrl + '" onerror="this.parentElement.innerHTML=\'📈\'">' : '📈';

                html += '<div class="stock-list-item" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                    '<div class="stock-list-logo">' + logoHtml + '</div>' +
                    '<div class="stock-list-info"><div class="stock-list-symbol">' + stock.symbol + '</div><div class="stock-list-name">' + stock.name + '</div></div>' +
                    '<div class="stock-list-right">' +
                        '<div class="stock-list-chart"><canvas id="chart-canvas-' + stock.symbol + '" width="240" height="80"></canvas></div>' +
                        '<div class="stock-list-price"><div class="stock-list-price-value">$' + price.toFixed(2) + '</div><div class="stock-list-change ' + (isDown ? 'negative' : 'positive') + '">' + (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%</div></div>' +
                        '<div class="stock-list-bookmark"><button class="bookmark-btn ' + (isInWatchlist ? 'active' : '') + '" data-symbol="' + stock.symbol + '" onclick="toggleWatchlist(\'' + stock.symbol + '\', event)"><svg viewBox="0 0 24 24" fill="' + (isInWatchlist ? 'currentColor' : 'none') + '" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button></div>' +
                    '</div></div>';
            });
            html += '</div>';
            container.innerHTML = html;
        }

        function renderGridView(container) {
            var html = '<div class="stock-grid">';
            displayedStocks.forEach(function(stock) {
                var price = stock.error ? 0 : parseFloat(stock.price || 0);
                var changePercent = stock.error ? 0 : parseFloat(stock.changePercent || 0);
                var change = stock.error ? 0 : parseFloat(stock.change || 0);
                var isDown = changePercent < 0;
                var logoHtml = stock.logoUrl ? '<img src="' + stock.logoUrl + '" onerror="this.parentElement.innerHTML=\'📈\'">' : '📈';

                html += '<div class="stock-card" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                    '<div class="stock-card-header"><div class="stock-card-logo">' + logoHtml + '</div><div class="stock-card-info"><div class="stock-card-symbol">' + stock.symbol + '</div><div class="stock-card-name">' + stock.name + '</div></div><div class="stock-card-badge">Live</div></div>' +
                    '<div class="stock-card-price ' + (isDown ? 'down' : '') + '">$' + price.toFixed(2) + '</div>' +
                    '<div class="stock-card-change"><span class="stock-card-change-badge ' + (isDown ? 'down' : '') + '">' + (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%</span><span style="color:#6b7280;font-size:12px">' + (change >= 0 ? '+' : '') + change.toFixed(2) + '</span></div></div>';
            });
            html += '</div>';
            container.innerHTML = html;
        }

        // ========================================
        // 미니 차트 (Canvas)
        // ========================================
        function loadMiniChart(symbol) {
            var canvas = document.getElementById('chart-canvas-' + symbol);
            if (!canvas) return;

            // 캐시된 데이터가 있으면 바로 그리기
            if (chartDataCache[symbol]) {
                var data = chartDataCache[symbol];
                var first = parseFloat(data[0].close);
                var last = parseFloat(data[data.length - 1].close);
                drawSparkline(canvas, data, last >= first);
                return;
            }

            // 1시간봉 API 사용
            fetch('/stock/api/chart/' + symbol + '/all?timeframe=1h')
                .then(function(r) { return r.json(); })
                .then(function(response) {
                    if (response.data && response.data.length > 1) {
                        var prices = response.data.slice(-24); // 최근 24시간
                        chartDataCache[symbol] = prices;
                        var first = parseFloat(prices[0].close);
                        var last = parseFloat(prices[prices.length - 1].close);
                        drawSparkline(canvas, prices, last >= first);
                    }
                });
        }

        // ========================================
        // View 토글
        // ========================================
        function setupViewToggle() {
            document.querySelectorAll('.view-toggle .toggle-btn').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('.view-toggle .toggle-btn').forEach(function(b) { b.classList.remove('active'); });
                    this.classList.add('active');
                    var newView = this.getAttribute('data-view');

                    if (newView !== currentView) {
                        currentView = newView;
                        renderStocks();

                        // Normal로 전환 시 미니 차트 로드
                        if (currentView === 'normal') {
                            setTimeout(function() {
                                displayedStocks.forEach(function(stock) {
                                    loadMiniChart(stock.symbol);
                                });
                            }, 100);
                        }
                    }
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
            stompClient.connect({}, function() {
                stompClient.subscribe('/topic/stock/^IXIC', function(msg) {
                    var candle = JSON.parse(msg.body);
                    if (mainAreaSeries) {
                        mainAreaSeries.update({ time: new Date(candle.timestamp).getTime() / 1000, value: parseFloat(candle.close) });
                    }
                    document.getElementById('chart-price').textContent = parseFloat(candle.close).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                });
            }, function() { setTimeout(connectWebSocket, 5000); });
        }
    </script>
</body>
</html>
