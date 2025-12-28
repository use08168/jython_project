<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - The Salty Spitoon</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; background-color: #0f1419; color: #ffffff; min-height: 100vh; }
        
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
        .header-section { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px; }
        .welcome-text h1 { font-size: 28px; font-weight: 700; margin-bottom: 8px; }
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
        
        /* 지수 카드 */
        .index-cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 24px; }
        .index-card { background-color: #1a1f2e; border-radius: 12px; padding: 20px; display: flex; justify-content: space-between; align-items: flex-start; cursor: pointer; transition: all 0.2s; }
        .index-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3); }
        .index-card-left { display: flex; align-items: center; gap: 12px; }
        .index-icon { width: 48px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 18px; background-color: #ffffff; overflow: hidden; }
        .index-icon img { height: 28px; width: auto; max-width: 100%; object-fit: contain; }
        .index-icon-fallback { font-size: 20px; }
        .index-name { font-size: 14px; color: #9ca3af; margin-bottom: 4px; }
        .index-value { font-size: 20px; font-weight: 700; }
        .index-change { font-size: 13px; margin-top: 4px; }
        .index-change.positive { color: #22c55e; }
        .index-change.negative { color: #ef4444; }
        .index-badge { padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; }
        .index-badge.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .index-badge.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        
        /* 메인 그리드 */
        .main-grid { display: grid; grid-template-columns: 1fr 320px; gap: 24px; }
        
        /* 차트 섹션 */
        .chart-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; }
        .chart-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .chart-title h2 { font-size: 18px; font-weight: 600; }
        .chart-title .badge { padding: 4px 8px; background-color: #252b3d; border-radius: 4px; font-size: 11px; color: #9ca3af; margin-left: 8px; }
        .chart-info { display: flex; align-items: baseline; gap: 12px; margin-top: 8px; }
        .chart-price { font-size: 32px; font-weight: 700; }
        .chart-change { font-size: 14px; padding: 4px 8px; border-radius: 4px; }
        .chart-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .chart-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .chart-periods { display: flex; gap: 4px; background-color: #252b3d; padding: 4px; border-radius: 8px; }
        .chart-period { padding: 8px 16px; font-size: 13px; font-weight: 500; color: #9ca3af; background: none; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
        .chart-period:hover { color: #ffffff; }
        .chart-period.active { background-color: #374151; color: #ffffff; }
        #main-chart { width: 100%; height: 400px; margin-top: 16px; }
        
        /* 워치리스트 */
        .watchlist-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; }
        .watchlist-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .watchlist-header h3 { font-size: 16px; font-weight: 600; }
        .watchlist-add { width: 28px; height: 28px; border-radius: 6px; background-color: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; text-decoration: none; }
        .watchlist-add:hover { background-color: #374151; color: #ffffff; }
        .watchlist-item { display: flex; align-items: center; justify-content: space-between; padding: 14px 0; border-bottom: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .watchlist-item:hover { background-color: #252b3d; margin: 0 -24px; padding: 14px 24px; }
        .watchlist-item:last-child { border-bottom: none; }
        .watchlist-left { display: flex; align-items: center; gap: 12px; }
        .stock-icon { width: 40px; height: 40px; border-radius: 10px; background-color: #252b3d; display: flex; align-items: center; justify-content: center; font-size: 16px; }
        .stock-info h4 { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
        .stock-info p { font-size: 12px; color: #6b7280; }
        .watchlist-right { text-align: right; }
        .stock-price { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
        .stock-change { font-size: 12px; }
        .stock-change.positive { color: #22c55e; }
        .stock-change.negative { color: #ef4444; }
        .watchlist-empty { text-align: center; padding: 40px 20px; color: #6b7280; }
        .watchlist-empty svg { width: 48px; height: 48px; margin-bottom: 12px; opacity: 0.3; }
        .watchlist-empty p { font-size: 14px; line-height: 1.6; }
        .watchlist-empty a { color: #3b82f6; text-decoration: none; }
        .watchlist-empty a:hover { text-decoration: underline; }
        
        /* 하단 그리드 */
        .bottom-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 24px; }
        
        /* 섹터 퍼포먼스 */
        .sector-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; }
        .sector-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .sector-header h3 { font-size: 16px; font-weight: 600; }
        .sector-header a { font-size: 13px; color: #3b82f6; text-decoration: none; }
        .sector-header a:hover { text-decoration: underline; }
        .sector-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
        .sector-item { padding: 14px 10px; border-radius: 10px; text-align: center; cursor: pointer; transition: all 0.2s; }
        .sector-item:hover { transform: translateY(-2px); }
        .sector-item.positive { background-color: rgba(34, 197, 94, 0.1); }
        .sector-item.negative { background-color: rgba(239, 68, 68, 0.1); }
        .sector-item.neutral { background-color: #252b3d; }
        .sector-name { font-size: 12px; font-weight: 500; margin-bottom: 4px; color: #d1d5db; }
        .sector-change { font-size: 13px; font-weight: 600; }
        .sector-change.positive { color: #22c55e; }
        .sector-change.negative { color: #ef4444; }
        .sector-change.neutral { color: #9ca3af; }
        
        /* 마켓 리캡 */
        .recap-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; }
        .recap-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .recap-header h3 { font-size: 16px; font-weight: 600; }
        .recap-refresh { width: 28px; height: 28px; border-radius: 6px; background-color: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; }
        .recap-refresh:hover { background-color: #374151; color: #ffffff; }
        .recap-item { padding: 14px 0; border-bottom: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .recap-item:hover { background-color: #252b3d; margin: 0 -24px; padding: 14px 24px; }
        .recap-item:last-child { border-bottom: none; }
        .recap-item h4 { font-size: 14px; font-weight: 500; line-height: 1.5; margin-bottom: 8px; }
        .recap-meta { display: flex; align-items: center; gap: 8px; }
        .recap-tag { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: 500; background-color: #252b3d; color: #9ca3af; }
        .recap-time { font-size: 12px; color: #6b7280; }
        
        /* 반응형 */
        @media (max-width: 1200px) {
            .main-grid { grid-template-columns: 1fr; }
            .bottom-grid { grid-template-columns: 1fr; }
            .index-cards { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 768px) {
            .index-cards { grid-template-columns: 1fr; }
            .navbar-search { display: none; }
            .sector-grid { grid-template-columns: repeat(2, 1fr); }
            .header-section { flex-direction: column; gap: 16px; }
            .exchange-rate-card { width: 100%; justify-content: center; }
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
            <input type="text" placeholder="Search tickers, news...">
        </div>

        <div class="navbar-menu">
            <a href="/dashboard" class="active">Market</a>
            <a href="/stock">Stocks</a>
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
            <div class="welcome-text">
                <h1>
                    <sec:authorize access="isAuthenticated()">Good Morning! 👋</sec:authorize>
                    <sec:authorize access="!isAuthenticated()">Welcome to The Salty Spitoon</sec:authorize>
                </h1>
                <div class="market-info">
                    <div class="market-status" id="market-status"><span>Checking...</span></div>
                    <div class="time-display">
                        <div class="time-item">🇰🇷 KST <span class="time-value" id="time-kst">--:--:--</span></div>
                        <div class="time-item">🇺🇸 EST <span class="time-value" id="time-est">--:--:--</span></div>
                    </div>
                </div>
            </div>
            <div class="exchange-rate-card" id="exchange-rate-card">
                <div class="exchange-icon">💲</div>
                <div class="exchange-info">
                    <div class="exchange-label">USD/KRW</div>
                    <div class="exchange-value" id="usd-krw-value">--</div>
                </div>
                <div class="exchange-change" id="usd-krw-change">--</div>
            </div>
        </div>

        <!-- 지수 카드 -->
        <div class="index-cards">
            <div class="index-card" onclick="location.href='/stock/detail/%5EIXIC'">
                <div class="index-card-left">
                    <div class="index-icon" id="ixic-icon"><span class="index-icon-fallback">📈</span></div>
                    <div>
                        <div class="index-name">NASDAQ Composite</div>
                        <div class="index-value" id="ixic-value">--</div>
                        <div class="index-change positive" id="ixic-change">--</div>
                    </div>
                </div>
                <div class="index-badge positive" id="ixic-badge">--</div>
            </div>
            <div class="index-card" onclick="location.href='/stock/detail/%5EGSPC'">
                <div class="index-card-left">
                    <div class="index-icon" id="gspc-icon"><span class="index-icon-fallback">📊</span></div>
                    <div>
                        <div class="index-name">S&P 500</div>
                        <div class="index-value" id="gspc-value">--</div>
                        <div class="index-change positive" id="gspc-change">--</div>
                    </div>
                </div>
                <div class="index-badge positive" id="gspc-badge">--</div>
            </div>
            <div class="index-card" onclick="location.href='/stock/detail/%5EDJI'">
                <div class="index-card-left">
                    <div class="index-icon" id="dji-icon"><span class="index-icon-fallback">📉</span></div>
                    <div>
                        <div class="index-name">Dow Jones</div>
                        <div class="index-value" id="dji-value">--</div>
                        <div class="index-change negative" id="dji-change">--</div>
                    </div>
                </div>
                <div class="index-badge negative" id="dji-badge">--</div>
            </div>
            <div class="index-card" onclick="location.href='/stock/detail/%5EVIX'">
                <div class="index-card-left">
                    <div class="index-icon" id="vix-icon"><span class="index-icon-fallback">⚡</span></div>
                    <div>
                        <div class="index-name">VIX (Fear Index)</div>
                        <div class="index-value" id="vix-value">--</div>
                        <div class="index-change negative" id="vix-change">--</div>
                    </div>
                </div>
                <div class="index-badge negative" id="vix-badge">--</div>
            </div>
        </div>

        <!-- 메인 그리드 -->
        <div class="main-grid">
            <div class="chart-section">
                <div class="chart-header">
                    <div class="chart-title">
                        <div>
                            <h2>NASDAQ Composite<span class="badge">^IXIC</span></h2>
                            <div class="chart-info">
                                <span class="chart-price" id="chart-price">$--</span>
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

            <div class="watchlist-section">
                <div class="watchlist-header">
                    <h3>⭐ My Watchlist</h3>
                    <a href="/watchlist" class="watchlist-add" title="Manage Watchlist">+</a>
                </div>
                <div id="watchlist-container">
                    <div class="watchlist-empty">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                        <p>Loading watchlist...</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- 하단 그리드 -->
        <div class="bottom-grid">
            <div class="sector-section">
                <div class="sector-header">
                    <h3>📊 Sector Performance</h3>
                    <a href="/stock">View All →</a>
                </div>
                <div class="sector-grid" id="sector-grid">
                    <!-- 동적으로 로드됨 -->
                </div>
            </div>

            <div class="recap-section">
                <div class="recap-header">
                    <h3>📰 Market News</h3>
                    <button class="recap-refresh" onclick="loadNews()" title="Refresh">↻</button>
                </div>
                <div id="recap-container">
                    <p style="color: #6b7280; text-align: center; padding: 20px;">Loading news...</p>
                </div>
            </div>
        </div>
    </main>

    <script>
        var mainChart = null;
        var areaSeries = null;
        
        var stockIcons = {
            'AAPL': '🍎', 'MSFT': '🪟', 'NVDA': '🎮', 'AMZN': '📦', 'TSLA': '🚗',
            'GOOGL': '🔍', 'META': '👤', 'NFLX': '🎬', 'AMD': '💻', 'INTC': '🔷'
        };
        
        var sectorETFs = [
            { symbol: 'XLK', name: 'Technology' },
            { symbol: 'XLF', name: 'Financials' },
            { symbol: 'XLE', name: 'Energy' },
            { symbol: 'XLV', name: 'Healthcare' },
            { symbol: 'XLY', name: 'Consumer Disc.' },
            { symbol: 'XLP', name: 'Consumer Staples' },
            { symbol: 'XLI', name: 'Industrials' },
            { symbol: 'XLB', name: 'Materials' },
            { symbol: 'XLRE', name: 'Real Estate' },
            { symbol: 'XLU', name: 'Utilities' },
            { symbol: 'XLC', name: 'Communication' }
        ];

        document.addEventListener('DOMContentLoaded', function() {
            initChart();
            updateTime();
            setInterval(updateTime, 1000);
            updateMarketStatus();
            setInterval(updateMarketStatus, 60000);
            
            loadIndexData();
            loadExchangeRate();
            loadWatchlist();
            loadSectorPerformance();
            loadNews();
            loadChartData('1m');
            
            // Period 버튼 이벤트
            var periodBtns = document.querySelectorAll('.chart-period');
            for (var i = 0; i < periodBtns.length; i++) {
                periodBtns[i].addEventListener('click', function() {
                    for (var j = 0; j < periodBtns.length; j++) {
                        periodBtns[j].classList.remove('active');
                    }
                    this.classList.add('active');
                    loadChartData(this.getAttribute('data-period'));
                });
            }
        });

        function updateTime() {
            var now = new Date();
            var kstOptions = { timeZone: 'Asia/Seoul', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            var estOptions = { timeZone: 'America/New_York', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            document.getElementById('time-kst').textContent = now.toLocaleString('en-US', kstOptions);
            document.getElementById('time-est').textContent = now.toLocaleString('en-US', estOptions);
        }

        function updateMarketStatus() {
            var now = new Date();
            var nyTime = new Date(now.toLocaleString("en-US", {timeZone: "America/New_York"}));
            var day = nyTime.getDay();
            var hour = nyTime.getHours();
            var minute = nyTime.getMinutes();
            var statusEl = document.getElementById('market-status');
            
            if (day === 0 || day === 6) {
                statusEl.className = 'market-status closed';
                statusEl.innerHTML = '<span>Market Closed (Weekend)</span>';
                return;
            }
            
            var marketOpen = hour > 9 || (hour === 9 && minute >= 30);
            var marketClose = hour < 16;
            
            if (marketOpen && marketClose) {
                statusEl.className = 'market-status open';
                statusEl.innerHTML = '<span>Market Open</span>';
            } else {
                statusEl.className = 'market-status closed';
                statusEl.innerHTML = '<span>Market Closed</span>';
            }
        }

        function initChart() {
            var container = document.getElementById('main-chart');
            mainChart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 400,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { color: '#252b3d' }, horzLines: { color: '#252b3d' } },
                crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
                rightPriceScale: { borderColor: '#252b3d' },
                timeScale: { borderColor: '#252b3d', timeVisible: true }
            });

            areaSeries = mainChart.addAreaSeries({
                topColor: 'rgba(59, 130, 246, 0.4)',
                bottomColor: 'rgba(59, 130, 246, 0.0)',
                lineColor: '#3b82f6',
                lineWidth: 2
            });

            window.addEventListener('resize', function() {
                mainChart.applyOptions({ width: container.clientWidth });
            });
        }

        function loadChartData(timeframe) {
            // detail 페이지와 동일한 API 사용 (timeframe 파라미터로 집계)
            fetch('/stock/api/chart/%5EIXIC/all?timeframe=' + timeframe)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    console.log('Chart API response (' + timeframe + '):', data);
                    
                    if (!data || data.error || !data.data || data.data.length === 0) {
                        console.warn('No chart data available for NASDAQ');
                        return;
                    }
                    
                    var chartData = [];
                    for (var i = 0; i < data.data.length; i++) {
                        var item = data.data[i];
                        var timestamp = item.date || item.timestamp;
                        var closePrice = item.close;
                        
                        if (timestamp && closePrice) {
                            chartData.push({
                                time: new Date(timestamp).getTime() / 1000,
                                value: parseFloat(closePrice)
                            });
                        }
                    }
                    
                    console.log('Processed chart data:', chartData.length, 'points (timeframe:', timeframe, ')');
                    
                    if (chartData.length > 0) {
                        areaSeries.setData(chartData);
                        mainChart.timeScale().fitContent();
                    }
                })
                .catch(function(error) {
                    console.error('Chart data error:', error);
                });
        }

        function loadIndexData() {
            var indices = [
                { symbol: '^IXIC', id: 'ixic' },
                { symbol: '^GSPC', id: 'gspc' },
                { symbol: '^DJI', id: 'dji' },
                { symbol: '^VIX', id: 'vix' }
            ];
            
            indices.forEach(function(index) {
                fetch('/api/stocks/' + encodeURIComponent(index.symbol) + '/latest')
                    .then(function(response) { return response.json(); })
                    .then(function(data) {
                        if (data) {
                            var price = data.closePrice || data.close_price || data.close || 0;
                            var change = data.changePercent || data.change_percent || 0;
                            var isVix = index.id === 'vix';
                            
                            // VIX는 색상 반대로 (상승=빨강, 하락=초록)
                            var isPositive = isVix ? change < 0 : change >= 0;
                            
                            // 로고 설정
                            var logoUrl = data.logoUrl || data.logo_url;
                            if (logoUrl) {
                                var iconEl = document.getElementById(index.id + '-icon');
                                if (iconEl) {
                                    iconEl.innerHTML = '<img src="' + logoUrl + '" alt="' + index.symbol + '" onerror="this.parentElement.innerHTML=\'<span class=index-icon-fallback>📈</span>\'">';
                                }
                            }
                            
                            document.getElementById(index.id + '-value').textContent = 
                                (index.id === 'vix' ? '' : '') + price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                            
                            var changeEl = document.getElementById(index.id + '-change');
                            changeEl.textContent = (change >= 0 ? '↑ ' : '↓ ') + Math.abs(change).toFixed(2) + '%';
                            changeEl.className = 'index-change ' + (isPositive ? 'positive' : 'negative');
                            
                            var badgeEl = document.getElementById(index.id + '-badge');
                            badgeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            badgeEl.className = 'index-badge ' + (isPositive ? 'positive' : 'negative');
                            
                            // 차트 가격 업데이트
                            if (index.id === 'ixic') {
                                document.getElementById('chart-price').textContent = price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                                var chartChange = document.getElementById('chart-change');
                                chartChange.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                                chartChange.className = 'chart-change ' + (change >= 0 ? 'positive' : 'negative');
                            }
                        }
                    })
                    .catch(function(error) {
                        console.error('Index data error for ' + index.symbol + ':', error);
                    });
            });
        }

        function loadExchangeRate() {
            fetch('/api/stocks/' + encodeURIComponent('KRW=X') + '/latest')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data) {
                        var rate = data.closePrice || data.close_price || data.close || 0;
                        var change = data.changePercent || data.change_percent || 0;
                        
                        // 환율은 원화 강세 기준 (환율 하락 = 원화 강세 = 초록)
                        var isPositive = change <= 0;
                        
                        document.getElementById('usd-krw-value').textContent = '₩' + rate.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                        
                        var changeEl = document.getElementById('usd-krw-change');
                        changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                        changeEl.className = 'exchange-change ' + (isPositive ? 'positive' : 'negative');
                    }
                })
                .catch(function(error) {
                    console.error('Exchange rate error:', error);
                    document.getElementById('usd-krw-value').textContent = '--';
                });
        }

        function loadWatchlist() {
            var container = document.getElementById('watchlist-container');
            
            fetch('/api/watchlist')
                .then(function(response) {
                    if (response.status === 401) {
                        container.innerHTML = '<div class="watchlist-empty">' +
                            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>' +
                            '<p><a href="/login">로그인</a>하고 관심 종목을<br>추가해보세요!</p></div>';
                        return null;
                    }
                    return response.json();
                })
                .then(function(data) {
                    if (!data) return;
                    
                    if (!data.success || !data.data || data.data.length === 0) {
                        container.innerHTML = '<div class="watchlist-empty">' +
                            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>' +
                            '<p>아직 관심 종목이 없어요.<br><a href="/stock">종목 페이지</a>에서 ⭐를 눌러<br>관심 종목을 추가해보세요!</p></div>';
                        return;
                    }
                    
                    var stocks = data.data.slice(0, 6);
                    var html = '';
                    
                    for (var i = 0; i < stocks.length; i++) {
                        var stock = stocks[i];
                        var icon = stockIcons[stock.symbol] || '📈';
                        html += '<div class="watchlist-item" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                            '<div class="watchlist-left">' +
                            '<div class="stock-icon">' + icon + '</div>' +
                            '<div class="stock-info"><h4>' + stock.symbol + '</h4><p id="name-' + stock.symbol + '">Loading...</p></div>' +
                            '</div>' +
                            '<div class="watchlist-right">' +
                            '<div class="stock-price" id="price-' + stock.symbol + '">$--</div>' +
                            '<div class="stock-change positive" id="change-' + stock.symbol + '">--</div>' +
                            '</div></div>';
                    }
                    
                    container.innerHTML = html;
                    
                    for (var j = 0; j < stocks.length; j++) {
                        fetchStockPrice(stocks[j].symbol);
                    }
                })
                .catch(function(error) {
                    console.error('Watchlist error:', error);
                    container.innerHTML = '<div class="watchlist-empty">' +
                        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>' +
                        '<p>아직 관심 종목이 없어요.<br><a href="/stock">종목 페이지</a>에서 ⭐를 눌러<br>관심 종목을 추가해보세요!</p></div>';
                });
        }

        function fetchStockPrice(symbol) {
            fetch('/api/stocks/' + symbol + '/latest')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data) {
                        var priceEl = document.getElementById('price-' + symbol);
                        var changeEl = document.getElementById('change-' + symbol);
                        var nameEl = document.getElementById('name-' + symbol);
                        
                        if (priceEl) {
                            var price = data.closePrice || data.close_price || 0;
                            priceEl.textContent = '$' + price.toFixed(2);
                        }
                        if (changeEl) {
                            var change = data.changePercent || data.change_percent || 0;
                            changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            changeEl.className = 'stock-change ' + (change >= 0 ? 'positive' : 'negative');
                        }
                        if (nameEl && data.name) {
                            nameEl.textContent = data.name;
                        }
                    }
                })
                .catch(function(error) {
                    console.error('Price fetch error for ' + symbol);
                });
        }

        function loadSectorPerformance() {
            var grid = document.getElementById('sector-grid');
            var html = '';
            
            for (var i = 0; i < sectorETFs.length; i++) {
                var sector = sectorETFs[i];
                html += '<div class="sector-item neutral" id="sector-' + sector.symbol + '" onclick="location.href=\'/stock/detail/' + sector.symbol + '\'">' +
                    '<div class="sector-name">' + sector.name + '</div>' +
                    '<div class="sector-change neutral" id="sector-change-' + sector.symbol + '">--</div>' +
                    '</div>';
            }
            
            grid.innerHTML = html;
            
            for (var j = 0; j < sectorETFs.length; j++) {
                fetchSectorData(sectorETFs[j].symbol);
            }
        }

        function fetchSectorData(symbol) {
            fetch('/api/stocks/' + symbol + '/latest')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data) {
                        var change = data.changePercent || data.change_percent || 0;
                        var isPositive = change > 0;
                        var isNegative = change < 0;
                        
                        var itemEl = document.getElementById('sector-' + symbol);
                        var changeEl = document.getElementById('sector-change-' + symbol);
                        
                        if (itemEl) {
                            itemEl.className = 'sector-item ' + (isPositive ? 'positive' : isNegative ? 'negative' : 'neutral');
                        }
                        if (changeEl) {
                            changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            changeEl.className = 'sector-change ' + (isPositive ? 'positive' : isNegative ? 'negative' : 'neutral');
                        }
                    }
                })
                .catch(function(error) {
                    console.error('Sector data error for ' + symbol);
                });
        }

        function loadNews() {
            var container = document.getElementById('recap-container');
            
            fetch('/api/news/latest?limit=4')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data || data.length === 0) {
                        container.innerHTML = '<p style="color: #6b7280; text-align: center; padding: 20px;">No news available</p>';
                        return;
                    }
                    
                    var html = '';
                    for (var i = 0; i < data.length; i++) {
                        var news = data[i];
                        var timeAgo = getTimeAgo(news.publishedAt || news.published_at);
                        html += '<div class="recap-item" onclick="location.href=\'/news/detail/' + news.id + '\'">' +
                            '<h4>' + news.title + '</h4>' +
                            '<div class="recap-meta">' +
                            '<span class="recap-tag">' + (news.symbol || 'Market') + '</span>' +
                            '<span class="recap-time">' + timeAgo + '</span>' +
                            '</div></div>';
                    }
                    
                    container.innerHTML = html;
                })
                .catch(function(error) {
                    console.error('News error:', error);
                    container.innerHTML = '<p style="color: #6b7280; text-align: center; padding: 20px;">Failed to load news</p>';
                });
        }

        function getTimeAgo(dateString) {
            if (!dateString) return '';
            var date = new Date(dateString);
            var now = new Date();
            var diffMs = now - date;
            var diffMins = Math.floor(diffMs / 60000);
            var diffHours = Math.floor(diffMs / 3600000);
            var diffDays = Math.floor(diffMs / 86400000);
            
            if (diffMins < 60) return diffMins + 'm ago';
            if (diffHours < 24) return diffHours + 'h ago';
            return diffDays + 'd ago';
        }
    </script>
</body>
</html>
