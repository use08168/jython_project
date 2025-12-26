<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>NASDAQ 100 Dashboard - The Salty Spitoon</title>
    <style>
        /* ========================================
           공통 스타일 (다크 테마)
           ======================================== */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #131722;
            color: #d1d4dc;
            min-height: 100vh;
        }

        a {
            color: inherit;
            text-decoration: none;
        }

        /* ========================================
           공통 네비게이션
           ======================================== */
        .navbar {
            background: #1e222d;
            border-bottom: 1px solid #2a2e39;
            padding: 0 20px;
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .navbar-container {
            max-width: 1600px;
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

        /* ========================================
           컨테이너
           ======================================== */
        .container {
            max-width: 1600px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        
        /* ========================================
           헤더 영역
           ======================================== */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 16px;
        }
        
        .header-left h1 {
            font-size: 28px;
            font-weight: 700;
            color: #d1d4dc;
            margin-bottom: 4px;
        }
        
        .header-left p {
            color: #787b86;
            font-size: 14px;
        }
        
        .header-stats {
            display: flex;
            gap: 24px;
        }
        
        .stat-item {
            text-align: right;
        }
        
        .stat-label {
            color: #787b86;
            font-size: 12px;
            margin-bottom: 4px;
        }
        
        .stat-value {
            color: #d1d4dc;
            font-weight: 600;
            font-size: 18px;
        }
        
        /* ========================================
           컨트롤 패널
           ======================================== */
        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            padding: 16px 20px;
            background: #1e222d;
            border-radius: 8px;
            border: 1px solid #2a2e39;
            flex-wrap: wrap;
            gap: 16px;
        }
        
        .search-box {
            flex: 1;
            max-width: 400px;
        }
        
        .search-input {
            width: 100%;
            padding: 12px 16px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #d1d4dc;
            font-size: 14px;
        }
        
        .search-input:focus {
            outline: none;
            border-color: #2962ff;
        }
        
        .search-input::placeholder {
            color: #787b86;
        }
        
        .view-toggle {
            display: flex;
            gap: 8px;
        }
        
        .toggle-btn {
            padding: 10px 18px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #787b86;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .toggle-btn:hover {
            background: #363a45;
            color: #d1d4dc;
        }
        
        .toggle-btn.active {
            background: #2962ff;
            border-color: #2962ff;
            color: white;
        }
        
        /* ========================================
           종목 그리드
           ======================================== */
        .stock-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 16px;
        }
        
        .stock-grid.compact {
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 12px;
        }
        
        /* ========================================
           종목 카드
           ======================================== */
        .stock-card {
            background: #1e222d;
            border-radius: 8px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid #2a2e39;
            position: relative;
            overflow: hidden;
        }
        
        .stock-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #2962ff, #26a69a);
            transform: scaleX(0);
            transition: transform 0.2s;
        }
        
        .stock-card:hover::before {
            transform: scaleX(1);
        }
        
        .stock-card:hover {
            border-color: #2962ff;
            transform: translateY(-2px);
            box-shadow: 0 4px 16px rgba(41, 98, 255, 0.15);
        }
        
        .stock-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 12px;
        }
        
        .stock-symbol {
            font-size: 18px;
            font-weight: bold;
            color: #2962ff;
        }
        
        .stock-name {
            font-size: 12px;
            color: #787b86;
            margin-top: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .stock-badge {
            background: rgba(38, 166, 154, 0.15);
            color: #26a69a;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .stock-badge.error {
            background: rgba(239, 83, 80, 0.15);
            color: #ef5350;
        }
        
        .stock-price {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 8px;
            color: #26a69a;
        }
        
        .stock-price.down {
            color: #ef5350;
        }
        
        .stock-price.unavailable {
            color: #787b86;
            font-size: 16px;
        }
        
        .stock-change {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .change-badge {
            padding: 4px 10px;
            border-radius: 4px;
            font-weight: 600;
            font-size: 13px;
            background: rgba(38, 166, 154, 0.15);
            color: #26a69a;
        }
        
        .change-badge.down {
            background: rgba(239, 83, 80, 0.15);
            color: #ef5350;
        }
        
        /* ========================================
           로딩 상태
           ======================================== */
        .loading {
            text-align: center;
            padding: 60px 20px;
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
        
        .no-results {
            text-align: center;
            padding: 60px 20px;
            color: #787b86;
            grid-column: 1 / -1;
        }
        
        /* ========================================
           반응형
           ======================================== */
        @media (max-width: 768px) {
            .header-left h1 {
                font-size: 24px;
            }
            
            .stock-grid {
                grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            }

            .navbar-menu {
                gap: 4px;
            }

            .navbar-item {
                padding: 8px 12px;
                font-size: 13px;
            }
        }
    </style>
</head>
<body>
    <!-- 공통 네비게이션 -->
    <nav class="navbar">
        <div class="navbar-container">
            <a href="/stock" class="navbar-brand">The Salty Spitoon</a>
            <div class="navbar-menu">
                <a href="/stock" class="navbar-item active">대시보드</a>
                <a href="/stock/chart?symbol=AAPL" class="navbar-item">차트</a>
                <a href="/news" class="navbar-item">뉴스</a>
                <a href="/admin" class="navbar-item">관리자</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <!-- 헤더 -->
        <div class="header">
            <div class="header-left">
                <h1>NASDAQ 100 Dashboard</h1>
                <p>실시간 시세 • 30초마다 자동 업데이트</p>
            </div>
            <div class="header-stats">
                <div class="stat-item">
                    <div class="stat-label">Total Stocks</div>
                    <div class="stat-value" id="totalStocks">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Last Update</div>
                    <div class="stat-value" id="lastUpdate">--</div>
                </div>
            </div>
        </div>
        
        <!-- 컨트롤 패널 -->
        <div class="controls">
            <div class="search-box">
                <input 
                    type="text" 
                    class="search-input" 
                    id="searchInput"
                    placeholder="종목명 또는 심볼로 검색..."
                    oninput="filterStocks()"
                >
            </div>
            <div class="view-toggle">
                <button class="toggle-btn active" onclick="setView('normal')">Normal</button>
                <button class="toggle-btn" onclick="setView('compact')">Compact</button>
            </div>
        </div>
        
        <!-- 종목 그리드 -->
        <div class="stock-grid" id="stockGrid">
            <div class="loading">
                <div class="loading-spinner"></div>
                <p>Loading NASDAQ 100 stocks...</p>
            </div>
        </div>
    </div>

    <script>
        let allStocks = [];
        let currentView = 'normal';
        
        function loadDashboard() {
            fetch('/stock/api/dashboard')
                .then(function(response) { 
                    if (!response.ok) {
                        throw new Error('HTTP ' + response.status);
                    }
                    return response.json(); 
                })
                .then(function(stocks) {
                    console.log('Loaded ' + stocks.length + ' stocks');
                    allStocks = stocks;
                    document.getElementById('totalStocks').textContent = stocks.length;
                    updateLastUpdateTime();
                    renderStocks(stocks);
                })
                .catch(function(error) {
                    console.error('Error loading dashboard:', error);
                    document.getElementById('stockGrid').innerHTML = 
                        '<div class="loading">Failed to load data. Retrying...</div>';
                    setTimeout(loadDashboard, 5000);
                });
        }
        
        function renderStocks(stocks) {
            var grid = document.getElementById('stockGrid');
            
            if (stocks.length === 0) {
                grid.innerHTML = '<div class="no-results">No stocks found</div>';
                return;
            }
            
            grid.innerHTML = '';
            
            stocks.forEach(function(stock) {
                var card = document.createElement('div');
                card.className = 'stock-card';
                card.setAttribute('data-symbol', stock.symbol.toLowerCase());
                card.setAttribute('data-name', stock.name.toLowerCase());
                
                card.onclick = function() {
                    window.location.href = '/stock/detail/' + stock.symbol;
                };
                
                var hasError = stock.error === true;
                var price = hasError ? 0 : parseFloat(stock.price);
                var change = hasError ? 0 : parseFloat(stock.change);
                var changePercent = hasError ? 0 : parseFloat(stock.changePercent);
                
                var isDown = changePercent < 0;
                var priceClass = hasError ? 'unavailable' : (isDown ? 'down' : '');
                var changeClass = isDown ? 'down' : '';
                var badgeClass = hasError ? 'error' : '';
                var badgeText = hasError ? 'N/A' : 'Live';
                
                card.innerHTML = 
                    '<div class="stock-header">' +
                        '<div style="flex: 1; min-width: 0;">' +
                            '<div class="stock-symbol">' + stock.symbol + '</div>' +
                            '<div class="stock-name" title="' + stock.name + '">' + stock.name + '</div>' +
                        '</div>' +
                        '<div class="stock-badge ' + badgeClass + '">' + badgeText + '</div>' +
                    '</div>' +
                    '<div class="stock-price ' + priceClass + '">' +
                        (hasError ? 'No Data' : '$' + price.toFixed(2)) +
                    '</div>' +
                    (hasError ? '' : 
                        '<div class="stock-change">' +
                            '<span class="change-badge ' + changeClass + '">' +
                                (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%' +
                            '</span>' +
                            '<span style="color: #787b86; font-size: 12px;">' +
                                (change >= 0 ? '+' : '') + change.toFixed(2) +
                            '</span>' +
                        '</div>'
                    );
                
                grid.appendChild(card);
            });
        }
        
        function filterStocks() {
            var query = document.getElementById('searchInput').value.toLowerCase();
            
            if (query === '') {
                renderStocks(allStocks);
                return;
            }
            
            var filtered = allStocks.filter(function(stock) {
                return stock.symbol.toLowerCase().includes(query) || 
                       stock.name.toLowerCase().includes(query);
            });
            
            renderStocks(filtered);
        }
        
        function setView(view) {
            currentView = view;
            
            var grid = document.getElementById('stockGrid');
            var buttons = document.querySelectorAll('.toggle-btn');
            
            buttons.forEach(function(btn) {
                btn.classList.remove('active');
            });
            
            event.target.classList.add('active');
            
            if (view === 'compact') {
                grid.classList.add('compact');
            } else {
                grid.classList.remove('compact');
            }
        }
        
        function updateLastUpdateTime() {
            var now = new Date();
            var hours = now.getHours().toString().padStart(2, '0');
            var minutes = now.getMinutes().toString().padStart(2, '0');
            var seconds = now.getSeconds().toString().padStart(2, '0');
            
            document.getElementById('lastUpdate').textContent = 
                hours + ':' + minutes + ':' + seconds;
        }
        
        window.onload = function() {
            console.log('NASDAQ 100 Dashboard loaded');
            loadDashboard();
            setInterval(function() {
                loadDashboard();
                console.log('Dashboard refreshed');
            }, 30000);
            setInterval(updateLastUpdateTime, 1000);
        };
    </script>
</body>
</html>
