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
        .index-icon { width: 80px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 18px; background-color: #ffffff; overflow: hidden; padding: 4px;}
        .index-icon img { height: 100%; width: 100%; max-width: 100%; object-fit: contain; }
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
        .stock-icon { width: 80px; height: 40px; border-radius: 10px; background-color: #ffffff; display: flex; align-items: center; justify-content: center; font-size: 16px; overflow: hidden; padding: 4px;}
        .stock-icon img { width: 100%; height: 100%; object-fit: contain; }
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
        .sector-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        .sector-item { padding: 16px 20px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.05); cursor: pointer; transition: all 0.3s ease; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .sector-item:hover {transform: translateY(-2px);border-color: rgba(255,255,255,0.1);box-shadow: 0 4px 12px rgba(0,0,0,0.3);}
        .sector-item.positive { background-color: rgba(34, 197, 94, 0.1); }
        .sector-item.negative { background-color: rgba(239, 68, 68, 0.1); }
        .sector-item.neutral { background-color: #252b3d; }
        .sector-wrapper-1 { display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; background-color: rgba(255, 255, 255, 0.9); border-radius: 8px; flex-shrink: 0; }
        .sector-wrapper-2 {display: flex; flex-direction: column; align-items: flex-end; gap: 4px;}
        .sector-name {font-size: 14px;font-weight: 500;color: #e0e0e0;}
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
                <div class="sector-grid" id="sector-grid"></div>
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
        
        var sectorETFs = [
            { symbol: 'XLK', name: 'Technology', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M20 3H4a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zM4 9V5h16v4zm16 4H4a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-4a2 2 0 0 0-2-2zM4 19v-4h16v4z"></path><path d="M17 6h2v2h-2zm-3 0h2v2h-2zm3 10h2v2h-2zm-3 0h2v2h-2z"></path></svg>' },
            { symbol: 'XLF', name: 'Financials', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M3 3v17a1 1 0 0 0 1 1h17v-2H5V3H3z"></path><path d="M15.293 14.707a.999.999 0 0 0 1.414 0l5-5-1.414-1.414L16 12.586l-2.293-2.293a.999.999 0 0 0-1.414 0l-5 5 1.414 1.414L13 12.414l2.293 2.293z"></path></svg>' },
            { symbol: 'XLE', name: 'Energy', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"></path><path d="m13 6-6 7h4v5l6-7h-4z"></path></svg>' },
            { symbol: 'XLV', name: 'Healthcare', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M4 21h9.62a3.995 3.995 0 0 0 3.037-1.397l5.102-5.952a1 1 0 0 0-.442-1.6l-1.968-.656a3.043 3.043 0 0 0-2.823.503l-3.185 2.547-.617-1.235A3.98 3.98 0 0 0 9.146 11H4c-1.103 0-2 .897-2 2v6c0 1.103.897 2 2 2zm0-8h5.146c.763 0 1.448.423 1.789 1.105l.447.895H7v2h6.014a.996.996 0 0 0 .442-.11l.003-.001.004-.002h.003l.002-.001h.004l.001-.001c.009.003.003-.001.003-.001.01 0 .002-.001.002-.001h.001l.002-.001.003-.001.002-.001.002-.001.003-.001.002-.001c.003 0 .001-.001.002-.001l.003-.002.002-.001.002-.001.003-.001.002-.001h.001l.002-.001h.001l.002-.001.002-.001c.009-.001.003-.001.003-.001l.002-.001a.915.915 0 0 0 .11-.078l4.146-3.317c.262-.208.623-.273.94-.167l.557.186-4.133 4.823a2.029 2.029 0 0 1-1.52.688H4v-6zM16 2h-.017c-.163.002-1.006.039-1.983.705-.951-.648-1.774-.7-1.968-.704L12.002 2h-.004c-.801 0-1.555.313-2.119.878C9.313 3.445 9 4.198 9 5s.313 1.555.861 2.104l3.414 3.586a1.006 1.006 0 0 0 1.45-.001l3.396-3.568C18.688 6.555 19 5.802 19 5s-.313-1.555-.878-2.121A2.978 2.978 0 0 0 16.002 2H16zm1 3c0 .267-.104.518-.311.725L14 8.55l-2.707-2.843C11.104 5.518 11 5.267 11 5s.104-.518.294-.708A.977.977 0 0 1 11.979 4c.025.001.502.032 1.067.485.081.065.163.139.247.222l.707.707.707-.707c.084-.083.166-.157.247-.222.529-.425.976-.478 1.052-.484a.987.987 0 0 1 .701.292c.189.189.293.44.293.707z"></path></svg>' },
            { symbol: 'XLY', name: 'Consumer Disc.', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m20.772 10.156-1.368-4.105A2.995 2.995 0 0 0 16.559 4H7.441a2.995 2.995 0 0 0-2.845 2.051l-1.368 4.105A2.003 2.003 0 0 0 2 12v5c0 .753.423 1.402 1.039 1.743-.013.066-.039.126-.039.195V21a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-2h12v2a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-2.062c0-.069-.026-.13-.039-.195A1.993 1.993 0 0 0 22 17v-5c0-.829-.508-1.541-1.228-1.844zM4 17v-5h16l.002 5H4zM7.441 6h9.117c.431 0 .813.274.949.684L18.613 10H5.387l1.105-3.316A1 1 0 0 1 7.441 6z"></path><circle cx="6.5" cy="14.5" r="1.5"></circle><circle cx="17.5" cy="14.5" r="1.5"></circle></svg>' },
            { symbol: 'XLP', name: 'Consumer Staples', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M7 19.66V21a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-1.34A10 10 0 0 0 22 11a1 1 0 0 0-1-1 3.58 3.58 0 0 0-1.8-3 3.66 3.66 0 0 0-3.63-3.13 3.86 3.86 0 0 0-1 .13 3.7 3.7 0 0 0-5.11 0 3.86 3.86 0 0 0-1-.13A3.66 3.66 0 0 0 4.81 7 3.58 3.58 0 0 0 3 10a1 1 0 0 0-1 1 10 10 0 0 0 5 8.66zm-.89-11 .83-.26-.16-.9a1.64 1.64 0 0 1 1.66-1.62 1.78 1.78 0 0 1 .83.2l.81.45.5-.77a1.71 1.71 0 0 1 2.84 0l.5.77.81-.45a1.78 1.78 0 0 1 .83-.2 1.65 1.65 0 0 1 1.67 1.6l-.16.85.82.28A1.59 1.59 0 0 1 19 10H5a1.59 1.59 0 0 1 1.11-1.39zM19.94 12a8 8 0 0 1-4.39 6.16 1 1 0 0 0-.55.9V20H9v-.94a1 1 0 0 0-.55-.9A8 8 0 0 1 4.06 12z"></path></svg>' },
            { symbol: 'XLI', name: 'Industrials', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M21 15a9.11 9.11 0 0 0-.18-1.81 8.53 8.53 0 0 0-.53-1.69 8.08 8.08 0 0 0-.83-1.5 8.73 8.73 0 0 0-1.1-1.33A8.27 8.27 0 0 0 17 7.54a8.08 8.08 0 0 0-1.53-.83L15 6.52V5a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v1.52l-.5.19a8.08 8.08 0 0 0-1.5.83 8.27 8.27 0 0 0-1.33 1.1A8.27 8.27 0 0 0 4.54 10a8.08 8.08 0 0 0-.83 1.53 9 9 0 0 0-.53 1.69A9.11 9.11 0 0 0 3 15v3H2v2h20v-2h-1zM5 15a7.33 7.33 0 0 1 .14-1.41 6.64 6.64 0 0 1 .41-1.31 7.15 7.15 0 0 1 .64-1.19 7.15 7.15 0 0 1 1.9-1.9A7.33 7.33 0 0 1 9 8.68V15h2V6h2v9h2V8.68a8.13 8.13 0 0 1 .91.51 7.09 7.09 0 0 1 1 .86 6.44 6.44 0 0 1 .85 1 6 6 0 0 1 .65 1.19 7.13 7.13 0 0 1 .41 1.31A7.33 7.33 0 0 1 19 15v3H5z"></path></svg>' },
            { symbol: 'XLB', name: 'Materials', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="m19.616 6.48.014-.017-4-3.24-1.26 1.554 2.067 1.674a2.99 2.99 0 0 0-1.395 3.058c.149.899.766 1.676 1.565 2.112.897.49 1.685.446 2.384.197L18.976 18a.996.996 0 0 1-1.39.922.995.995 0 0 1-.318-.217.996.996 0 0 1-.291-.705L17 16a2.98 2.98 0 0 0-.877-2.119A3 3 0 0 0 14 13h-1V5c0-1.103-.897-2-2-2H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h7c1.103 0 2-.897 2-2v-4h1c.136 0 .267.027.391.078a1.028 1.028 0 0 1 .531.533A.994.994 0 0 1 15 16l-.024 2c0 .406.079.799.236 1.168.151.359.368.68.641.951a2.97 2.97 0 0 0 2.123.881c.406 0 .798-.078 1.168-.236.358-.15.68-.367.951-.641A2.983 2.983 0 0 0 20.976 18L21 9a2.997 2.997 0 0 0-1.384-2.52zM4 5h7l.001 4H4V5zm0 14v-8h7.001l.001 8H4zm14-9a1 1 0 1 1 0-2 1 1 0 0 1 0 2z"></path></svg>' },
            { symbol: 'XLRE', name: 'Real Estate', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M19 2H9c-1.103 0-2 .897-2 2v5.586l-4.707 4.707A1 1 0 0 0 3 16v5a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1V4c0-1.103-.897-2-2-2zm-8 18H5v-5.586l3-3 3 3V20zm8 0h-6v-4a.999.999 0 0 0 .707-1.707L9 9.586V4h10v16z"></path><path d="M11 6h2v2h-2zm4 0h2v2h-2zm0 4.031h2V12h-2zM15 14h2v2h-2zm-8 1h2v2H7z"></path></svg>' },
            { symbol: 'XLU', name: 'Utilities', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M5.996 9c1.413 0 2.16-.747 2.705-1.293.49-.49.731-.707 1.292-.707s.802.217 1.292.707C11.83 8.253 12.577 9 13.991 9c1.415 0 2.163-.747 2.71-1.293.491-.49.732-.707 1.295-.707s.804.217 1.295.707C19.837 8.253 20.585 9 22 9V7c-.563 0-.804-.217-1.295-.707C20.159 5.747 19.411 5 17.996 5s-2.162.747-2.709 1.292c-.491.491-.731.708-1.296.708-.562 0-.802-.217-1.292-.707C12.154 5.747 11.407 5 9.993 5s-2.161.747-2.706 1.293c-.49.49-.73.707-1.291.707s-.801-.217-1.291-.707C4.16 5.747 3.413 5 2 5v2c.561 0 .801.217 1.291.707C3.836 8.253 4.583 9 5.996 9zm0 5c1.413 0 2.16-.747 2.705-1.293.49-.49.731-.707 1.292-.707s.802.217 1.292.707c.545.546 1.292 1.293 2.706 1.293 1.415 0 2.163-.747 2.71-1.293.491-.49.732-.707 1.295-.707s.804.217 1.295.707C19.837 13.253 20.585 14 22 14v-2c-.563 0-.804-.217-1.295-.707-.546-.546-1.294-1.293-2.709-1.293s-2.162.747-2.709 1.292c-.491.491-.731.708-1.296.708-.562 0-.802-.217-1.292-.707C12.154 10.747 11.407 10 9.993 10s-2.161.747-2.706 1.293c-.49.49-.73.707-1.291.707s-.801-.217-1.291-.707C4.16 10.747 3.413 10 2 10v2c.561 0 .801.217 1.291.707C3.836 13.253 4.583 14 5.996 14zm0 5c1.413 0 2.16-.747 2.705-1.293.49-.49.731-.707 1.292-.707s.802.217 1.292.707c.545.546 1.292 1.293 2.706 1.293 1.415 0 2.163-.747 2.71-1.293.491-.49.732-.707 1.295-.707s.804.217 1.295.707C19.837 18.253 20.585 19 22 19v-2c-.563 0-.804-.217-1.295-.707-.546-.546-1.294-1.293-2.709-1.293s-2.162.747-2.709 1.292c-.491.491-.731.708-1.296.708-.562 0-.802-.217-1.292-.707C12.154 15.747 11.407 15 9.993 15s-2.161.747-2.706 1.293c-.49.49-.73.707-1.291.707s-.801-.217-1.291-.707C4.16 15.747 3.413 15 2 15v2c.561 0 .801.217 1.291.707C3.836 18.253 4.583 19 5.996 19z"></path></svg>' },
            { symbol: 'XLC', name: 'Communication', icon : '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1);transform: ;msFilter:;"><path d="M16 2H8C4.691 2 2 4.691 2 8v12a1 1 0 0 0 1 1h13c3.309 0 6-2.691 6-6V8c0-3.309-2.691-6-6-6zm4 13c0 2.206-1.794 4-4 4H4V8c0-2.206 1.794-4 4-4h8c2.206 0 4 1.794 4 4v7z"></path><circle cx="9.5" cy="11.5" r="1.5"></circle><circle cx="14.5" cy="11.5" r="1.5"></circle></svg>' }
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
            fetch('/stock/api/chart/%5EIXIC/all?timeframe=' + timeframe)
                .then(function(response) { return response.json(); })
                .then(function(data) {
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
                            var isPositive = isVix ? change < 0 : change >= 0;
                            
                            var logoUrl = data.logoUrl || data.logo_url;
                            if (logoUrl) {
                                var iconEl = document.getElementById(index.id + '-icon');
                                if (iconEl) {
                                    iconEl.innerHTML = '<img src="' + logoUrl + '" alt="' + index.symbol + '" onerror="this.parentElement.innerHTML=\'<span class=index-icon-fallback>📈</span>\'">';
                                }
                            }
                            
                            document.getElementById(index.id + '-value').textContent = price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                            
                            var changeEl = document.getElementById(index.id + '-change');
                            changeEl.textContent = (change >= 0 ? '↑ ' : '↓ ') + Math.abs(change).toFixed(2) + '%';
                            changeEl.className = 'index-change ' + (isPositive ? 'positive' : 'negative');
                            
                            var badgeEl = document.getElementById(index.id + '-badge');
                            badgeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            badgeEl.className = 'index-badge ' + (isPositive ? 'positive' : 'negative');
                            
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
                        html += '<div class="watchlist-item" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">' +
                            '<div class="watchlist-left">' +
                            '<div class="stock-icon" id="icon-' + stock.symbol + '">📈</div>' +
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
                        var iconEl = document.getElementById('icon-' + symbol);
                        
                        if (priceEl) {
                            var price = data.closePrice || data.close_price || 0;
                            priceEl.textContent = '$' + parseFloat(price).toFixed(2);
                        }
                        if (changeEl) {
                            var change = data.changePercent || data.change_percent || 0;
                            changeEl.textContent = (change >= 0 ? '+' : '') + parseFloat(change).toFixed(2) + '%';
                            changeEl.className = 'stock-change ' + (change >= 0 ? 'positive' : 'negative');
                        }
                        if (nameEl && data.name) {
                            nameEl.textContent = data.name;
                        }
                        if (iconEl && data.logoUrl) {
                            iconEl.innerHTML = '<img src="' + data.logoUrl + '" onerror="this.parentElement.innerHTML=\'📈\'" alt="' + symbol + '">';
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
                            '<div class="sector-wrapper-1">' + sector.icon + 
                            '</div>' +
                            '<div class="sector-wrapper-2">' +
                                '<div class="sector-name">' + sector.name + '</div>' +
                                '<div class="sector-change neutral" id="sector-change-' + sector.symbol + '">--</div>' +
                            '</div>' +
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
