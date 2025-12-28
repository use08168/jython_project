<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><c:out value="${symbol}"/> - <c:out value="${name}"/> | The Salty Spitoon</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; background-color: #0f1419; color: #ffffff; min-height: 100vh; }
        .navbar { background-color: #1a1f2e; border-bottom: 1px solid #252b3d; padding: 12px 32px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 100; }
        .navbar-brand { display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 700; color: #3b82f6; text-decoration: none; }
        .navbar-menu { display: flex; align-items: center; gap: 32px; }
        .navbar-menu a { color: #9ca3af; text-decoration: none; font-size: 14px; font-weight: 500; transition: color 0.2s; }
        .navbar-menu a:hover, .navbar-menu a.active { color: #ffffff; }
        .navbar-right { display: flex; align-items: center; gap: 16px; }
        .user-avatar { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; cursor: pointer; }
        .main-content { max-width: 1400px; margin: 0 auto; padding: 24px 32px; }
        .stock-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px; }
        .stock-info { display: flex; align-items: center; gap: 16px; }
        .stock-icon { width: 150px; height: 56px; border-radius: 14px; background-color: #ffffff; display: flex; align-items: center; justify-content: center; font-size: 28px; overflow: hidden; padding: 8px;}
        .stock-icon img { height: 40px; width: auto; max-width: 100%; object-fit: contain; }
        .stock-title h1 { font-size: 28px; font-weight: 700; display: flex; align-items: center; gap: 12px; }
        .stock-title p { font-size: 14px; color: #6b7280; margin-top: 4px; }
        .stock-price-section { display: flex; align-items: baseline; gap: 16px; margin-top: 12px; }
        .current-price { font-size: 36px; font-weight: 700; }
        .price-change { font-size: 16px; padding: 6px 12px; border-radius: 8px; }
        .price-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .price-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .stock-actions { display: flex; gap: 12px; }
        .action-btn { display: flex; align-items: center; gap: 8px; padding: 12px 20px; border-radius: 10px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s; border: none; }
        .btn-watchlist { background-color: #1a1f2e; color: #d1d5db; border: 1px solid #374151; }
        .btn-watchlist:hover { background-color: #252b3d; }
        .btn-watchlist.active { background-color: rgba(245, 158, 11, 0.15); color: #f59e0b; border-color: #f59e0b; }
        .btn-watchlist svg { width: 18px; height: 18px; }
        .time-display { display: flex; gap: 16px; margin-top: 8px; }
        .time-item { font-size: 12px; color: #6b7280; }
        .time-item span { color: #9ca3af; }
        .content-grid { display: grid; grid-template-columns: 1fr 360px; gap: 24px; }
        .chart-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; }
        .chart-controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .timeframe-tabs { display: flex; gap: 4px; background-color: #252b3d; padding: 4px; border-radius: 8px; }
        .timeframe-tab { padding: 8px 16px; font-size: 13px; font-weight: 500; color: #9ca3af; background: none; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
        .timeframe-tab:hover { color: #ffffff; }
        .timeframe-tab.active { background-color: #374151; color: #ffffff; }
        .indicator-controls { display: flex; gap: 8px; }
        .indicator-btn { padding: 6px 12px; font-size: 12px; background-color: #252b3d; color: #9ca3af; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
        .indicator-btn:hover { background-color: #374151; }
        .indicator-btn.active { background-color: #3b82f6; color: #ffffff; }
        #chart-container { height: 450px; }
        .connection-status { display: flex; align-items: center; gap: 8px; font-size: 12px; color: #6b7280; }
        .status-dot { width: 8px; height: 8px; border-radius: 50%; background-color: #ef4444; }
        .status-dot.connected { background-color: #22c55e; }
        .sidebar { display: flex; flex-direction: column; gap: 16px; }
        .info-card { background-color: #1a1f2e; border-radius: 12px; padding: 20px; }
        .info-card h3 { font-size: 14px; font-weight: 600; color: #9ca3af; margin-bottom: 16px; text-transform: uppercase; letter-spacing: 0.5px; }
        .info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #252b3d; }
        .info-row:last-child { border-bottom: none; }
        .info-label { font-size: 13px; color: #6b7280; }
        .info-value { font-size: 13px; font-weight: 500; }
        .financial-section { background-color: #1a1f2e; border-radius: 16px; padding: 24px; margin-top: 24px; }
        .financial-tabs { display: flex; gap: 4px; margin-bottom: 20px; overflow-x: auto; }
        .financial-tab { padding: 10px 20px; font-size: 14px; font-weight: 500; color: #9ca3af; background: none; border: none; border-bottom: 2px solid transparent; cursor: pointer; transition: all 0.2s; white-space: nowrap; }
        .financial-tab:hover { color: #ffffff; }
        .financial-tab.active { color: #3b82f6; border-bottom-color: #3b82f6; }
        .tab-content { display: none; }
        .tab-content.active { display: block; }
        .period-selector { display: flex; gap: 8px; margin-bottom: 16px; }
        .period-btn { padding: 6px 14px; font-size: 12px; background-color: #252b3d; color: #9ca3af; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
        .period-btn:hover { background-color: #374151; }
        .period-btn.active { background-color: #3b82f6; color: #ffffff; }
        .financial-table { width: 100%; border-collapse: collapse; }
        .financial-table th { text-align: left; padding: 12px; font-size: 12px; font-weight: 600; color: #6b7280; background-color: #252b3d; border-bottom: 1px solid #374151; }
        .financial-table th.number { text-align: right; }
        .financial-table td { padding: 12px; font-size: 13px; border-bottom: 1px solid #252b3d; }
        .financial-table td.number { text-align: right; font-family: 'SF Mono', monospace; }
        .financial-table tr:hover { background-color: #252b3d; }
        .related-news { margin-top: 16px; }
        .news-item { padding: 16px 0; border-bottom: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .news-item:hover { background-color: #252b3d; margin: 0 -20px; padding: 16px 20px; }
        .news-item:last-child { border-bottom: none; }
        .news-item h4 { font-size: 14px; font-weight: 500; line-height: 1.5; margin-bottom: 6px; }
        .news-item-meta { font-size: 12px; color: #6b7280; }
        .loading { display: flex; align-items: center; justify-content: center; padding: 40px; color: #6b7280; }
        .loading-spinner { width: 24px; height: 24px; border: 2px solid #252b3d; border-top-color: #3b82f6; border-radius: 50%; animation: spin 0.8s linear infinite; margin-right: 12px; }
        @keyframes spin { to { transform: rotate(360deg); } }
        .no-data { text-align: center; padding: 40px; color: #6b7280; }
        @media (max-width: 1200px) { .content-grid { grid-template-columns: 1fr; } }
        @media (max-width: 768px) { .stock-header { flex-direction: column; gap: 16px; } .stock-actions { width: 100%; } .action-btn { flex: 1; justify-content: center; } }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/></svg>
            The Salty Spitoon
        </a>
        <div class="navbar-menu">
            <a href="/dashboard" class="active">Market</a>
            <a href="/watchlist">Watchlist</a>
            <a href="/news">News</a>
            <a href="/admin">Admin</a>
        </div>
        <div class="navbar-right">
            <div class="connection-status">
                <span class="status-dot" id="statusDot"></span>
                <span id="statusText">Connecting...</span>
            </div>
            <sec:authorize access="isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/logout'" title="로그아웃">
                    <sec:authentication property="principal.username" var="userEmail"/>
                    <c:out value="${userEmail.substring(0,1).toUpperCase()}"/>
                </div>
            </sec:authorize>
        </div>
    </nav>

    <main class="main-content">
        <div class="stock-header">
            <div>
                <div class="stock-info">
                    <div class="stock-icon" id="stock-icon">
                        <c:choose>
                            <c:when test="${not empty stock.logoUrl}">
                                <img src="${stock.logoUrl}" alt="${symbol}" onerror="this.parentElement.innerHTML='📈'">
                            </c:when>
                            <c:otherwise>
                                📈
                            </c:otherwise>
                        </c:choose>
                    </div>
                    <div class="stock-title">
                        <h1><c:out value="${symbol}"/> <span style="font-weight: 400; color: #6b7280; font-size: 18px;"><c:out value="${name}"/></span></h1>
                        <p id="sector-industry">Loading...</p>
                    </div>
                </div>
                <div class="stock-price-section">
                    <span class="current-price" id="currentPrice">$--</span>
                    <span class="price-change positive" id="priceChange">--%</span>
                </div>
                <div class="time-display">
                    <div class="time-item">🇰🇷 KST: <span id="time-kst">--</span></div>
                    <div class="time-item">🇺🇸 EST: <span id="time-est">--</span></div>
                </div>
            </div>
            <div class="stock-actions">
                <button class="action-btn btn-watchlist" id="watchlist-btn" onclick="toggleWatchlist()">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    <span>Add to Watchlist</span>
                </button>
            </div>
        </div>

        <div class="content-grid">
            <div class="chart-section">
                <div class="chart-controls">
                    <div class="timeframe-tabs">
                        <button class="timeframe-tab active" data-tf="1m">1m</button>
                        <button class="timeframe-tab" data-tf="5m">5m</button>
                        <button class="timeframe-tab" data-tf="1h">1h</button>
                        <button class="timeframe-tab" data-tf="1d">1d</button>
                    </div>
                    <div class="indicator-controls">
                        <button class="indicator-btn active" data-ind="MA5">MA5</button>
                        <button class="indicator-btn active" data-ind="MA20">MA20</button>
                        <button class="indicator-btn" data-ind="MA50">MA50</button>
                        <button class="indicator-btn" data-ind="RSI">RSI</button>
                    </div>
                </div>
                <div id="chart-container"></div>
            </div>

            <div class="sidebar">
                <div class="info-card">
                    <h3>Key Statistics</h3>
                    <div id="key-stats"><div class="loading"><div class="loading-spinner"></div>Loading...</div></div>
                </div>
                <div class="info-card">
                    <h3>Related News</h3>
                    <div class="related-news" id="related-news"><div class="loading"><div class="loading-spinner"></div>Loading...</div></div>
                </div>
            </div>
        </div>

        <div class="financial-section">
            <div class="financial-tabs">
                <button class="financial-tab active" data-tab="income">Income Statement</button>
                <button class="financial-tab" data-tab="balance">Balance Sheet</button>
                <button class="financial-tab" data-tab="cashflow">Cash Flow</button>
                <button class="financial-tab" data-tab="metrics">Key Metrics</button>
                <button class="financial-tab" data-tab="dividends">Dividends</button>
                <button class="financial-tab" data-tab="company">Company Info</button>
            </div>

            <div class="tab-content active" id="tab-income">
                <div class="period-selector">
                    <button class="period-btn active" data-period="quarterly">Quarterly</button>
                    <button class="period-btn" data-period="yearly">Yearly</button>
                </div>
                <div id="income-content"><div class="loading"><div class="loading-spinner"></div>Loading...</div></div>
            </div>
            <div class="tab-content" id="tab-balance">
                <div class="period-selector">
                    <button class="period-btn active" data-period="quarterly">Quarterly</button>
                    <button class="period-btn" data-period="yearly">Yearly</button>
                </div>
                <div id="balance-content"></div>
            </div>
            <div class="tab-content" id="tab-cashflow">
                <div class="period-selector">
                    <button class="period-btn active" data-period="quarterly">Quarterly</button>
                    <button class="period-btn" data-period="yearly">Yearly</button>
                </div>
                <div id="cashflow-content"></div>
            </div>
            <div class="tab-content" id="tab-metrics"><div id="metrics-content"></div></div>
            <div class="tab-content" id="tab-dividends"><div id="dividends-content"></div></div>
            <div class="tab-content" id="tab-company"><div id="company-content"></div></div>
        </div>
    </main>

    <script>
        var SYMBOL = '<c:out value="${symbol}"/>';
        var chart, candlestickSeries, volumeSeries;
        var indicatorSeries = {};
        var currentTimeframe = '1m';
        var activeIndicators = ['MA5', 'MA20'];
        var stompClient = null;
        var isInWatchlist = false;

        document.addEventListener('DOMContentLoaded', function() {
            initChart();
            loadChartData();
            connectWebSocket();
            loadKeyStats();
            loadRelatedNews();
            loadIncomeStatement('quarterly');
            checkWatchlistStatus();
            updateTime();
            setInterval(updateTime, 1000);
            setupTabs();
        });

        function updateTime() {
            var now = new Date();
            var kstOptions = { timeZone: 'Asia/Seoul', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            var estOptions = { timeZone: 'America/New_York', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false };
            document.getElementById('time-kst').textContent = now.toLocaleString('en-US', kstOptions);
            document.getElementById('time-est').textContent = now.toLocaleString('en-US', estOptions);
        }

        function initChart() {
            var container = document.getElementById('chart-container');
            chart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 450,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { color: '#252b3d' }, horzLines: { color: '#252b3d' } },
                crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
                rightPriceScale: { borderColor: '#252b3d' },
                timeScale: { borderColor: '#252b3d', timeVisible: true }
            });

            candlestickSeries = chart.addCandlestickSeries({
                upColor: '#22c55e', downColor: '#ef4444', borderVisible: false,
                wickUpColor: '#22c55e', wickDownColor: '#ef4444'
            });

            volumeSeries = chart.addHistogramSeries({
                color: '#3b82f6', priceFormat: { type: 'volume' }, priceScaleId: '',
                scaleMargins: { top: 0.85, bottom: 0 }
            });

            window.addEventListener('resize', function() {
                chart.applyOptions({ width: container.clientWidth });
            });

            var tfTabs = document.querySelectorAll('.timeframe-tab');
            for (var i = 0; i < tfTabs.length; i++) {
                tfTabs[i].addEventListener('click', function() {
                    for (var j = 0; j < tfTabs.length; j++) { tfTabs[j].classList.remove('active'); }
                    this.classList.add('active');
                    currentTimeframe = this.getAttribute('data-tf');
                    loadChartData();
                });
            }

            var indBtns = document.querySelectorAll('.indicator-btn');
            for (var i = 0; i < indBtns.length; i++) {
                indBtns[i].addEventListener('click', function() {
                    var ind = this.getAttribute('data-ind');
                    var idx = activeIndicators.indexOf(ind);
                    if (idx > -1) {
                        activeIndicators.splice(idx, 1);
                        this.classList.remove('active');
                    } else {
                        activeIndicators.push(ind);
                        this.classList.add('active');
                    }
                    loadChartData();
                });
            }
        }

        function loadChartData() {
            var indicators = activeIndicators.length > 0 ? activeIndicators.join(',') : 'MA5,MA20';
            var url = '/stock/api/chart/' + SYMBOL + '/all?timeframe=' + currentTimeframe + '&indicators=' + indicators;
            
            fetch(url)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.error || !data.data || data.data.length === 0) {
                        console.warn('No chart data');
                        return;
                    }

                    var candleData = [];
                    var volumeData = [];
                    for (var i = 0; i < data.data.length; i++) {
                        var item = data.data[i];
                        candleData.push({
                            time: new Date(item.date).getTime() / 1000,
                            open: parseFloat(item.open),
                            high: parseFloat(item.high),
                            low: parseFloat(item.low),
                            close: parseFloat(item.close)
                        });
                        volumeData.push({
                            time: new Date(item.date).getTime() / 1000,
                            value: parseFloat(item.volume || 0),
                            color: parseFloat(item.close) >= parseFloat(item.open) ? '#22c55e40' : '#ef444440'
                        });
                    }

                    candlestickSeries.setData(candleData);
                    volumeSeries.setData(volumeData);

                    if (data.indicators) {
                        updateIndicators(data.data, data.indicators);
                    }
                    updatePrice();
                })
                .catch(function(error) {
                    console.error('Chart load failed:', error);
                });
        }

        function updateIndicators(rawData, indicators) {
            for (var key in indicatorSeries) {
                chart.removeSeries(indicatorSeries[key]);
            }
            indicatorSeries = {};

            var colors = { MA5: '#3b82f6', MA20: '#f59e0b', MA50: '#a855f7', MA200: '#22c55e', RSI: '#ef4444' };

            for (var key in indicators) {
                var lineData = [];
                for (var i = 0; i < indicators[key].length; i++) {
                    var val = indicators[key][i];
                    if (val != null) {
                        lineData.push({
                            time: new Date(rawData[i].date).getTime() / 1000,
                            value: parseFloat(val)
                        });
                    }
                }
                if (lineData.length > 0) {
                    indicatorSeries[key] = chart.addLineSeries({ color: colors[key] || '#fff', lineWidth: 2 });
                    indicatorSeries[key].setData(lineData);
                }
            }
        }

        function connectWebSocket() {
            var socket = new SockJS('/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null;

            stompClient.connect({}, function(frame) {
                document.getElementById('statusDot').classList.add('connected');
                document.getElementById('statusText').textContent = 'Live';

                stompClient.subscribe('/topic/stock/' + SYMBOL, function(msg) {
                    var candle = JSON.parse(msg.body);
                    if (currentTimeframe === '1m') {
                        candlestickSeries.update({
                            time: new Date(candle.timestamp).getTime() / 1000,
                            open: parseFloat(candle.open),
                            high: parseFloat(candle.high),
                            low: parseFloat(candle.low),
                            close: parseFloat(candle.close)
                        });
                    }
                    updatePrice();
                });
            }, function(error) {
                document.getElementById('statusDot').classList.remove('connected');
                document.getElementById('statusText').textContent = 'Disconnected';
                setTimeout(connectWebSocket, 5000);
            });
        }

        function updatePrice() {
            fetch('/stock/api/realtime/' + SYMBOL)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.error) return;
                    document.getElementById('currentPrice').textContent = '$' + parseFloat(data.price).toFixed(2);
                    var change = parseFloat(data.changePercent);
                    var changeEl = document.getElementById('priceChange');
                    changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                    changeEl.className = 'price-change ' + (change >= 0 ? 'positive' : 'negative');
                })
                .catch(function(error) {
                    console.error('Price update failed:', error);
                });
        }

        function loadKeyStats() {
            fetch('/stock/api/financial/' + SYMBOL + '/metrics')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data) {
                        document.getElementById('key-stats').innerHTML = '<div class="no-data">No data available</div>';
                        return;
                    }
                    var m = data.data;
                    var html = '';
                    html += '<div class="info-row"><span class="info-label">Market Cap</span><span class="info-value">$' + formatLargeNumber(m.marketCap) + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">P/E Ratio</span><span class="info-value">' + (m.trailingPe ? m.trailingPe.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">EPS</span><span class="info-value">$' + (m.trailingEps ? m.trailingEps.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Dividend Yield</span><span class="info-value">' + (m.dividendYield ? (m.dividendYield * 100).toFixed(2) + '%' : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Beta</span><span class="info-value">' + (m.beta ? m.beta.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">52W High</span><span class="info-value">$' + (m.fiftyTwoWeekHigh ? m.fiftyTwoWeekHigh.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">52W Low</span><span class="info-value">$' + (m.fiftyTwoWeekLow ? m.fiftyTwoWeekLow.toFixed(2) : '-') + '</span></div>';
                    document.getElementById('key-stats').innerHTML = html;

                    if (m.sector || m.industry) {
                        document.getElementById('sector-industry').textContent = (m.sector || '') + ' · ' + (m.industry || '');
                    }
                })
                .catch(function(error) {
                    console.error('Key stats load failed:', error);
                });
        }

        function loadRelatedNews() {
            fetch('/api/news/latest?symbol=' + SYMBOL + '&limit=5')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data || data.length === 0) {
                        document.getElementById('related-news').innerHTML = '<div class="no-data">No news available for this stock</div>';
                        return;
                    }
                    var html = '';
                    for (var i = 0; i < data.length; i++) {
                        var news = data[i];
                        html += '<div class="news-item" onclick="location.href=\'/news/detail/' + news.id + '\'">';
                        html += '<h4>' + news.title + '</h4>';
                        html += '<div class="news-item-meta">' + formatTimeAgo(news.publishedAt || news.published_at) + '</div>';
                        html += '</div>';
                    }
                    document.getElementById('related-news').innerHTML = html;
                })
                .catch(function(error) {
                    console.error('News load failed:', error);
                    document.getElementById('related-news').innerHTML = '<div class="no-data">No news available</div>';
                });
        }

        function setupTabs() {
            var finTabs = document.querySelectorAll('.financial-tab');
            for (var i = 0; i < finTabs.length; i++) {
                finTabs[i].addEventListener('click', function() {
                    var tabId = this.getAttribute('data-tab');
                    for (var j = 0; j < finTabs.length; j++) { finTabs[j].classList.remove('active'); }
                    var contents = document.querySelectorAll('.tab-content');
                    for (var k = 0; k < contents.length; k++) { contents[k].classList.remove('active'); }
                    this.classList.add('active');
                    document.getElementById('tab-' + tabId).classList.add('active');

                    switch(tabId) {
                        case 'income': loadIncomeStatement('quarterly'); break;
                        case 'balance': loadBalanceSheet('quarterly'); break;
                        case 'cashflow': loadCashflow('quarterly'); break;
                        case 'metrics': loadMetrics(); break;
                        case 'dividends': loadDividends(); break;
                        case 'company': loadCompanyInfo(); break;
                    }
                });
            }

            var periodBtns = document.querySelectorAll('.period-btn');
            for (var i = 0; i < periodBtns.length; i++) {
                periodBtns[i].addEventListener('click', function() {
                    var period = this.getAttribute('data-period');
                    var parent = this.closest('.tab-content');
                    var siblings = parent.querySelectorAll('.period-btn');
                    for (var j = 0; j < siblings.length; j++) { siblings[j].classList.remove('active'); }
                    this.classList.add('active');

                    var tabId = parent.id.replace('tab-', '');
                    switch(tabId) {
                        case 'income': loadIncomeStatement(period); break;
                        case 'balance': loadBalanceSheet(period); break;
                        case 'cashflow': loadCashflow(period); break;
                    }
                });
            }
        }

        function loadIncomeStatement(period) {
            var content = document.getElementById('income-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/income-statement?period=' + period)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data || data.data.length === 0) {
                        content.innerHTML = '<div class="no-data">No data available</div>';
                        return;
                    }
                    var rows = [
                        { label: 'Total Revenue', key: 'totalRevenue' },
                        { label: 'Gross Profit', key: 'grossProfit' },
                        { label: 'Operating Income', key: 'operatingIncome' },
                        { label: 'Net Income', key: 'netIncome' },
                        { label: 'EBITDA', key: 'ebitda' },
                        { label: 'EPS (Basic)', key: 'basicEps' },
                        { label: 'EPS (Diluted)', key: 'dilutedEps' }
                    ];
                    content.innerHTML = buildFinancialTable(data.data.slice(0, 4), rows);
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function loadBalanceSheet(period) {
            var content = document.getElementById('balance-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/balance-sheet?period=' + period)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data || data.data.length === 0) {
                        content.innerHTML = '<div class="no-data">No data available</div>';
                        return;
                    }
                    var rows = [
                        { label: 'Total Assets', key: 'totalAssets' },
                        { label: 'Current Assets', key: 'currentAssets' },
                        { label: 'Cash & Equivalents', key: 'cashAndCashEquivalents' },
                        { label: 'Total Liabilities', key: 'totalLiabilitiesNetMinorityInterest' },
                        { label: 'Current Liabilities', key: 'currentLiabilities' },
                        { label: 'Long Term Debt', key: 'longTermDebt' },
                        { label: 'Stockholders Equity', key: 'stockholdersEquity' }
                    ];
                    content.innerHTML = buildFinancialTable(data.data.slice(0, 4), rows);
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function loadCashflow(period) {
            var content = document.getElementById('cashflow-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/cashflow?period=' + period)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data || data.data.length === 0) {
                        content.innerHTML = '<div class="no-data">No data available</div>';
                        return;
                    }
                    var rows = [
                        { label: 'Operating Cash Flow', key: 'operatingCashFlow' },
                        { label: 'Investing Cash Flow', key: 'investingCashFlow' },
                        { label: 'Financing Cash Flow', key: 'financingCashFlow' },
                        { label: 'Free Cash Flow', key: 'freeCashFlow' },
                        { label: 'Capital Expenditure', key: 'capitalExpenditure' }
                    ];
                    content.innerHTML = buildFinancialTable(data.data.slice(0, 4), rows);
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function loadMetrics() {
            var content = document.getElementById('metrics-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/metrics')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data) {
                        content.innerHTML = '<div class="no-data">No data available</div>';
                        return;
                    }
                    var m = data.data;
                    var html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">';
                    
                    html += '<div class="info-card" style="margin: 0;"><h3>Profitability</h3>';
                    html += '<div class="info-row"><span class="info-label">Profit Margin</span><span class="info-value">' + formatPercent(m.profitMargins) + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Operating Margin</span><span class="info-value">' + formatPercent(m.operatingMargins) + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">ROE</span><span class="info-value">' + formatPercent(m.returnOnEquity) + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">ROA</span><span class="info-value">' + formatPercent(m.returnOnAssets) + '</span></div>';
                    html += '</div>';
                    
                    html += '<div class="info-card" style="margin: 0;"><h3>Valuation</h3>';
                    html += '<div class="info-row"><span class="info-label">P/E (Trailing)</span><span class="info-value">' + (m.trailingPe ? m.trailingPe.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">P/E (Forward)</span><span class="info-value">' + (m.forwardPe ? m.forwardPe.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">PEG Ratio</span><span class="info-value">' + (m.pegRatio ? m.pegRatio.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Price to Book</span><span class="info-value">' + (m.priceToBook ? m.priceToBook.toFixed(2) : '-') + '</span></div>';
                    html += '</div>';
                    
                    html += '<div class="info-card" style="margin: 0;"><h3>Financial Health</h3>';
                    html += '<div class="info-row"><span class="info-label">Current Ratio</span><span class="info-value">' + (m.currentRatio ? m.currentRatio.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Quick Ratio</span><span class="info-value">' + (m.quickRatio ? m.quickRatio.toFixed(2) : '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Debt to Equity</span><span class="info-value">' + (m.debtToEquity ? m.debtToEquity.toFixed(2) : '-') + '</span></div>';
                    html += '</div>';
                    
                    html += '</div>';
                    content.innerHTML = html;
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function loadDividends() {
            var content = document.getElementById('dividends-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/dividends')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data || data.data.length === 0) {
                        content.innerHTML = '<div class="no-data">No dividend data available</div>';
                        return;
                    }
                    var html = '<table class="financial-table"><thead><tr><th>Payment Date</th><th class="number">Dividend Amount</th></tr></thead><tbody>';
                    for (var i = 0; i < data.data.length; i++) {
                        var d = data.data[i];
                        html += '<tr><td>' + d.paymentDate + '</td><td class="number">$' + parseFloat(d.dividendAmount).toFixed(4) + '</td></tr>';
                    }
                    html += '</tbody></table>';
                    content.innerHTML = html;
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function loadCompanyInfo() {
            var content = document.getElementById('company-content');
            content.innerHTML = '<div class="loading"><div class="loading-spinner"></div>Loading...</div>';

            fetch('/stock/api/financial/' + SYMBOL + '/info')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (!data.success || !data.data) {
                        content.innerHTML = '<div class="no-data">No company info available</div>';
                        return;
                    }
                    var info = data.data;
                    var html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">';
                    
                    html += '<div class="info-card" style="margin: 0;"><h3>Company Profile</h3>';
                    html += '<div class="info-row"><span class="info-label">Name</span><span class="info-value">' + (info.longName || '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Sector</span><span class="info-value">' + (info.sector || '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Industry</span><span class="info-value">' + (info.industry || '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Employees</span><span class="info-value">' + (info.fullTimeEmployees ? info.fullTimeEmployees.toLocaleString() : '-') + '</span></div>';
                    html += '</div>';
                    
                    html += '<div class="info-card" style="margin: 0;"><h3>Contact</h3>';
                    html += '<div class="info-row"><span class="info-label">Country</span><span class="info-value">' + (info.country || '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">City</span><span class="info-value">' + (info.city || '-') + '</span></div>';
                    html += '<div class="info-row"><span class="info-label">Website</span><span class="info-value">' + (info.website ? '<a href="' + info.website + '" target="_blank" style="color: #3b82f6;">Visit</a>' : '-') + '</span></div>';
                    html += '</div>';
                    
                    html += '</div>';
                    
                    if (info.longBusinessSummary) {
                        html += '<div class="info-card" style="margin-top: 16px;"><h3>Business Summary</h3>';
                        html += '<p style="color: #9ca3af; line-height: 1.7; font-size: 14px;">' + info.longBusinessSummary + '</p>';
                        html += '</div>';
                    }
                    content.innerHTML = html;
                })
                .catch(function(error) {
                    content.innerHTML = '<div class="no-data">Failed to load data</div>';
                });
        }

        function buildFinancialTable(data, rows) {
            var html = '<table class="financial-table"><thead><tr><th>Item</th>';
            for (var i = 0; i < data.length; i++) {
                html += '<th class="number">' + data[i].fiscalDate + '</th>';
            }
            html += '</tr></thead><tbody>';
            
            for (var r = 0; r < rows.length; r++) {
                var row = rows[r];
                html += '<tr><td>' + row.label + '</td>';
                for (var d = 0; d < data.length; d++) {
                    var val = data[d][row.key];
                    if (val == null) {
                        html += '<td class="number">-</td>';
                    } else if (row.key.indexOf('Eps') > -1) {
                        html += '<td class="number">$' + parseFloat(val).toFixed(2) + '</td>';
                    } else {
                        html += '<td class="number">$' + formatLargeNumber(val) + '</td>';
                    }
                }
                html += '</tr>';
            }
            html += '</tbody></table>';
            return html;
        }

        function formatLargeNumber(num) {
            if (num == null || isNaN(num)) return '-';
            if (Math.abs(num) >= 1e12) return (num / 1e12).toFixed(2) + 'T';
            if (Math.abs(num) >= 1e9) return (num / 1e9).toFixed(2) + 'B';
            if (Math.abs(num) >= 1e6) return (num / 1e6).toFixed(2) + 'M';
            if (Math.abs(num) >= 1e3) return (num / 1e3).toFixed(2) + 'K';
            return num.toFixed(2);
        }

        function formatPercent(num) {
            if (num == null || isNaN(num)) return '-';
            return (num * 100).toFixed(2) + '%';
        }

        function formatTimeAgo(dateStr) {
            if (!dateStr) return '';
            var date = new Date(dateStr);
            var now = new Date();
            var diff = now - date;
            var hours = Math.floor(diff / 3600000);
            var days = Math.floor(diff / 86400000);
            if (hours < 1) return 'Just now';
            if (hours < 24) return hours + 'h ago';
            if (days < 7) return days + 'd ago';
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        }

        function checkWatchlistStatus() {
            fetch('/api/watchlist/check/' + SYMBOL)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    isInWatchlist = data.isInWatchlist;
                    updateWatchlistButton();
                })
                .catch(function(error) {
                    console.error('Watchlist check failed:', error);
                });
        }

        function toggleWatchlist() {
            fetch('/api/watchlist/toggle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ symbol: SYMBOL })
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
                    isInWatchlist = data.isInWatchlist;
                    updateWatchlistButton();
                }
            })
            .catch(function(error) {
                console.error('Watchlist toggle failed:', error);
            });
        }

        function updateWatchlistButton() {
            var btn = document.getElementById('watchlist-btn');
            var svg = btn.querySelector('svg');
            var span = btn.querySelector('span');

            if (isInWatchlist) {
                btn.classList.add('active');
                svg.setAttribute('fill', 'currentColor');
                span.textContent = 'In Watchlist';
            } else {
                btn.classList.remove('active');
                svg.setAttribute('fill', 'none');
                span.textContent = 'Add to Watchlist';
            }
        }
    </script>
</body>
</html>
