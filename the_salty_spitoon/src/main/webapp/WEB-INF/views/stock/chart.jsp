<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>실시간 주식 차트 - The Salty Spitoon</title>
    
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    
    <style>
        body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #131722;
            color: #d1d4dc;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 20px;
            background: #1e222d;
            border-radius: 8px;
        }
        
        .stock-info {
            display: flex;
            align-items: baseline;
            gap: 15px;
        }
        
        .symbol {
            font-size: 24px;
            font-weight: bold;
        }
        
        .price {
            font-size: 32px;
            font-weight: bold;
            color: #26a69a;
        }
        
        .price.down {
            color: #ef5350;
        }
        
        .change {
            font-size: 18px;
            color: #26a69a;
        }
        
        .change.down {
            color: #ef5350;
        }
        
        .connection-status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #ef5350;
            margin-right: 5px;
        }
        
        .connection-status.connected {
            background: #26a69a;
        }
        
        .symbol-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 15px;
        }
        
        .symbol-tab {
            padding: 10px 20px;
            background: #2a2e39;
            color: #787b86;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .symbol-tab:hover {
            background: #363a45;
            color: #d1d4dc;
        }
        
        .symbol-tab.active {
            background: #2962ff;
            color: white;
        }
        
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
            background: #2962ff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }
        
        .btn:hover {
            background: #1e53e5;
        }
        
        .btn.active {
            background: #26a69a;
        }
        
        .btn-group {
            display: flex;
            gap: 5px;
        }
        
        .chart-container {
            background: #1e222d;
            border-radius: 8px;
            padding: 20px;
        }
        
        #chart {
            height: 600px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="stock-info">
                <span class="symbol" id="symbolDisplay">AAPL</span>
                <span class="price" id="currentPrice">--</span>
                <span class="change" id="priceChange">--</span>
            </div>
            
            <div style="display: flex; align-items: center; gap: 15px;">
                <div style="display: flex; align-items: center; gap: 5px;">
                    <span class="connection-status" id="connectionStatus"></span>
                    <span id="connectionText" style="font-size: 12px; color: #787b86;">연결 중...</span>
                </div>
            </div>
        </div>
        
        <div class="symbol-tabs">
            <button class="symbol-tab active" onclick="changeSymbol('AAPL', this)">🍎 AAPL</button>
            <button class="symbol-tab" onclick="changeSymbol('TSLA', this)">🚗 TSLA</button>
            <button class="symbol-tab" onclick="changeSymbol('NVDA', this)">💻 NVDA</button>
            <button class="symbol-tab" onclick="changeSymbol('MSFT', this)">🪟 MSFT</button>
            <button class="symbol-tab" onclick="changeSymbol('GOOGL', this)">🔍 GOOGL</button>
        </div>
        
        <div class="controls">
            <div class="btn-group">
                <button class="btn active" onclick="changeTimeframe('1m', this)">1분</button>
                <button class="btn" onclick="changeTimeframe('5m', this)">5분</button>
                <button class="btn" onclick="changeTimeframe('1h', this)">1시간</button>
                <button class="btn" onclick="changeTimeframe('1d', this)">1일</button>
            </div>
            
            <div style="width: 1px; background: #434651;"></div>
            
            <button class="btn active" onclick="toggleIndicator('MA5', this)">MA5</button>
            <button class="btn active" onclick="toggleIndicator('MA20', this)">MA20</button>
            <button class="btn" onclick="toggleIndicator('MA50', this)">MA50</button>
            <button class="btn" onclick="toggleIndicator('MA200', this)">MA200</button>
            <button class="btn" onclick="toggleIndicator('RSI', this)">RSI</button>
            
            <span style="margin-left: auto; color: #787b86;">실시간 업데이트 활성화</span>
        </div>
        
        <div class="chart-container">
            <div id="chart"></div>
        </div>
    </div>

    <script>
        let chart;
        let candlestickSeries;
        let indicatorSeries = {};
        
        let currentSymbol = 'AAPL';
        let currentTimeframe = '1m';
        let activeIndicators = new Set(['MA5', 'MA20']);
        
        let stompClient = null;
        let currentSubscription = null;

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
            
            window.addEventListener('resize', () => {
                chart.applyOptions({
                    width: document.getElementById('chart').offsetWidth
                });
            });
        }

        function connectWebSocket() {
            console.log('WebSocket 연결 시도...');
            
            const socket = new SockJS('/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null;
            
            stompClient.connect({}, 
                function(frame) {
                    console.log('WebSocket 연결 성공:', frame);
                    updateConnectionStatus(true);
                    subscribeToSymbol(currentSymbol);
                }, 
                function(error) {
                    console.error('WebSocket 연결 실패:', error);
                    updateConnectionStatus(false);
                    setTimeout(connectWebSocket, 5000);
                }
            );
        }

        function subscribeToSymbol(symbol) {
            if (currentSubscription) {
                currentSubscription.unsubscribe();
            }
            
            console.log('종목 구독:', symbol);
            
            currentSubscription = stompClient.subscribe(
                '/topic/stock/' + symbol,
                function(message) {
                    const candle = JSON.parse(message.body);
                    console.log('새 캔들 수신:', candle);
                    updateChartWithNewCandle(candle);
                }
            );
        }

        function updateChartWithNewCandle(candle) {
            if (currentTimeframe !== '1m') {
                loadChartData(currentSymbol);
                return;
            }
            
            // Volume = 0 스킵
            if (!candle.volume || candle.volume === 0) {
                console.log('⚠️ Volume=0 캔들 스킵:', candle.symbol, candle.timestamp);
                return;
            }
            
            const candleData = {
                time: new Date(candle.timestamp).getTime() / 1000,
                open: parseFloat(candle.open),
                high: parseFloat(candle.high),
                low: parseFloat(candle.low),
                close: parseFloat(candle.close)
            };
            
            console.log('✅ 차트 업데이트:', candleData);
            candlestickSeries.update(candleData);
            updateRealTimePrice(currentSymbol);
        }

        function updateConnectionStatus(connected) {
            const statusElement = document.getElementById('connectionStatus');
            const textElement = document.getElementById('connectionText');
            
            if (connected) {
                statusElement.classList.add('connected');
                textElement.textContent = '실시간 연결';
            } else {
                statusElement.classList.remove('connected');
                textElement.textContent = '연결 끊김';
            }
        }

        async function loadChartData(symbol) {
            try {
                const indicators = Array.from(activeIndicators).join(',');
                const days = currentTimeframe === '1m' ? 1 : 
                            (currentTimeframe === '5m' ? 2 : 7);
                
                const response = await fetch(
                    `/stock/api/chart/${symbol}?timeframe=${currentTimeframe}&days=${days}&indicators=${indicators}`
                );
                const data = await response.json();
                
                if (data.error) {
                    alert('데이터 조회 실패: ' + data.message);
                    return;
                }
                
                console.log('📊 차트 데이터 로드:', data);
                
                // ========================================
                // ✅ 오늘 데이터만 필터링 + Volume > 0
                // ========================================
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const todayTimestamp = today.getTime() / 1000;
                
                const originalCount = data.data.length;
                
                const candleData = data.data
                    .filter(item => {
                        const itemDate = new Date(item.date).getTime() / 1000;
                        return itemDate >= todayTimestamp && item.volume && item.volume > 0;
                    })
                    .map(item => ({
                        time: new Date(item.date).getTime() / 1000,
                        open: parseFloat(item.open),
                        high: parseFloat(item.high),
                        low: parseFloat(item.low),
                        close: parseFloat(item.close)
                    }));
                
                const filteredCount = candleData.length;
                const skippedCount = originalCount - filteredCount;
                
                console.log(`📈 원본: ${originalCount}개 | 표시: ${filteredCount}개 | 스킵: ${skippedCount}개 (과거+Vol=0)`);
                
                // ========================================
                // ✅ 가격 범위 검증 (디버깅용)
                // ========================================
                if (filteredCount > 0) {
                    const prices = candleData.map(c => c.close);
                    const minPrice = Math.min(...prices);
                    const maxPrice = Math.max(...prices);
                    
                    console.log(`💰 가격 범위: $${minPrice.toFixed(2)} ~ $${maxPrice.toFixed(2)}`);
                    
                    // 비정상 범위 경고
                    if (maxPrice / minPrice > 2) {
                        console.error('⚠️ 비정상적인 가격 범위!');
                        console.error(`   최소: $${minPrice}, 최대: $${maxPrice}`);
                    }
                }
                
                if (filteredCount === 0) {
                    console.warn('⚠️ 오늘 거래 데이터가 없습니다');
                    alert('오늘 거래 데이터가 없습니다.');
                    return;
                }
                
                candlestickSeries.setData(candleData);
                
                if (data.indicators) {
                    updateIndicators(data.data, data.indicators);
                }
                
                updateRealTimePrice(symbol);
                
            } catch (error) {
                console.error('❌ 차트 데이터 로드 실패:', error);
                alert('데이터를 불러오는데 실패했습니다.');
            }
        }

        function updateIndicators(rawData, indicators) {
            Object.values(indicatorSeries).forEach(series => chart.removeSeries(series));
            indicatorSeries = {};
            
            const colors = {
                ma5: '#2962ff',
                ma20: '#ff6d00',
                ma50: '#ab47bc',
                ma200: '#66bb6a'
            };
            
            Object.keys(indicators).forEach(key => {
                const lineData = [];
                const indicatorValues = indicators[key];
                
                rawData.forEach((item, index) => {
                    if (indicatorValues[index] != null && 
                        item.volume && item.volume > 0) {
                        lineData.push({
                            time: new Date(item.date).getTime() / 1000,
                            value: parseFloat(indicatorValues[index])
                        });
                    }
                });
                
                if (lineData.length > 0) {
                    indicatorSeries[key] = chart.addLineSeries({
                        color: colors[key],
                        lineWidth: 2
                    });
                    indicatorSeries[key].setData(lineData);
                }
            });
        }

        async function updateRealTimePrice(symbol) {
            try {
                const response = await fetch('/stock/api/realtime/' + symbol);
                const data = await response.json();
                
                if (data.error) return;
                
                document.getElementById('currentPrice').textContent = 
                    '$' + parseFloat(data.price).toFixed(2);
                
                const changePercent = parseFloat(data.changePercent);
                const changeElement = document.getElementById('priceChange');
                changeElement.textContent = 
                    (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%';
                
                const priceElement = document.getElementById('currentPrice');
                if (changePercent >= 0) {
                    priceElement.classList.remove('down');
                    changeElement.classList.remove('down');
                } else {
                    priceElement.classList.add('down');
                    changeElement.classList.add('down');
                }
                
            } catch (error) {
                console.error('실시간 가격 업데이트 실패:', error);
            }
        }

        function changeSymbol(symbol, buttonElement) {
            console.log('🔄 종목 변경:', symbol);
            
            document.querySelectorAll('.symbol-tab').forEach(tab => 
                tab.classList.remove('active')
            );
            buttonElement.classList.add('active');
            
            currentSymbol = symbol;
            document.getElementById('symbolDisplay').textContent = symbol;
            
            loadChartData(symbol);
            
            if (stompClient && stompClient.connected) {
                subscribeToSymbol(symbol);
            }
        }

        function changeTimeframe(timeframe, button) {
            console.log('⏱️ 타임프레임 변경:', timeframe);
            
            document.querySelectorAll('.btn-group .btn').forEach(btn => 
                btn.classList.remove('active')
            );
            button.classList.add('active');
            
            currentTimeframe = timeframe;
            loadChartData(currentSymbol);
        }

        function toggleIndicator(indicator, button) {
            if (activeIndicators.has(indicator)) {
                activeIndicators.delete(indicator);
                button.classList.remove('active');
                console.log('📉 지표 비활성화:', indicator);
            } else {
                activeIndicators.add(indicator);
                button.classList.add('active');
                console.log('📈 지표 활성화:', indicator);
            }
            
            loadChartData(currentSymbol);
        }

        window.onload = function() {
            console.log('🚀 페이지 로드 완료');
            
            initChart();
            loadChartData(currentSymbol);
            connectWebSocket();
        };
    </script>
</body>
</html>
```

---

## 🚀 **적용 순서**

### **1단계: Repository**
```
위치: src/main/java/.../repository/StockCandle1mRepository.java
→ 전체 교체
```

### **2단계: Service**
```
위치: src/main/java/.../service/FileDataCollector.java
→ 전체 교체
```

### **3단계: JSP**
```
위치: src/main/webapp/WEB-INF/views/stock/chart.jsp
→ 전체 교체