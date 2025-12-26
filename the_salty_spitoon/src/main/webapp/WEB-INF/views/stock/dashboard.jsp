<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>NASDAQ 100 Dashboard - Stock Tracker</title>
    <style>
        /* 
            ========================================
            전역 리셋 및 기본 설정
            ========================================
            - box-sizing: border-box로 패딩 포함 크기 계산
        */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;  /* padding, border를 width에 포함 */
        }
        
        /* 
            ========================================
            Body 스타일
            ========================================
            - 다크 테마: TradingView 스타일
            - 폰트: 시스템 기본 폰트 스택
        */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #131722;  /* 다크 배경 */
            color: #d1d4dc;       /* 밝은 텍스트 */
            padding: 20px;
        }
        
        .container {
            max-width: 1600px;    /* 최대 너비 (대형 모니터 대응) */
            margin: 0 auto;       /* 중앙 정렬 */
        }
        
        /* 
            ========================================
            헤더 영역
            ========================================
            - 타이틀: 그라디언트 효과
            - 통계: 총 종목 수, 마지막 업데이트 시각
        */
        .header {
            padding: 30px 0;
            border-bottom: 1px solid #2a2e39;  /* 하단 구분선 */
            margin-bottom: 30px;
        }
        
        .header-top {
            display: flex;
            justify-content: space-between;  /* 양쪽 끝 정렬 */
            align-items: center;             /* 수직 중앙 */
            margin-bottom: 15px;
            flex-wrap: wrap;                 /* 작은 화면에서 줄바꿈 */
            gap: 15px;
        }
        
        /* 
            타이틀 그라디언트 효과
            - linear-gradient: 파란색 → 초록색
            - background-clip: text로 텍스트에만 그라디언트 적용
        */
        .header h1 {
            font-size: 32px;
            background: linear-gradient(135deg, #2962ff 0%, #26a69a 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        /* 헤더 통계 영역 */
        .header-stats {
            display: flex;
            gap: 20px;
            font-size: 14px;
        }
        
        .stat-item {
            display: flex;
            flex-direction: column;  /* 세로 정렬 */
            align-items: flex-end;   /* 오른쪽 정렬 */
        }
        
        .stat-label {
            color: #787b86;  /* 회색 라벨 */
            font-size: 12px;
        }
        
        .stat-value {
            color: #d1d4dc;  /* 밝은 값 */
            font-weight: 600;
            font-size: 18px;
        }
        
        .header p {
            color: #787b86;
            font-size: 14px;
        }
        
        /* 
            ========================================
            컨트롤 패널
            ========================================
            - 검색창: 종목/회사명 검색
            - 뷰 토글: Normal/Compact 전환
        */
        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 15px 20px;
            background: #1e222d;
            border-radius: 8px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .search-box {
            flex: 1;              /* 남은 공간 차지 */
            max-width: 400px;     /* 최대 너비 제한 */
        }
        
        /* 검색 입력창 */
        .search-input {
            width: 100%;
            padding: 10px 16px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #d1d4dc;
            font-size: 14px;
        }
        
        .search-input:focus {
            outline: none;
            border-color: #2962ff;  /* 포커스 시 파란색 */
        }
        
        .view-toggle {
            display: flex;
            gap: 10px;
        }
        
        /* 뷰 토글 버튼 */
        .toggle-btn {
            padding: 8px 16px;
            background: #2a2e39;
            border: 1px solid #434651;
            border-radius: 6px;
            color: #d1d4dc;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .toggle-btn:hover,
        .toggle-btn.active {
            background: #2962ff;
            border-color: #2962ff;
        }
        
        /* 
            ========================================
            종목 그리드 (Stock Grid)
            ========================================
            - CSS Grid 레이아웃
            - 반응형: 화면 크기에 따라 열 개수 자동 조정
        */
        .stock-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            /* 
                auto-fill: 가능한 많은 열 생성
                minmax(280px, 1fr): 최소 280px, 최대 1fr(남은 공간 균등 분배)
            */
            gap: 16px;  /* 카드 간 간격 */
        }
        
        /* Compact 뷰 */
        .stock-grid.compact {
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 12px;  /* 더 작은 간격 */
        }
        
        /* 
            ========================================
            종목 카드 (Stock Card)
            ========================================
            - 호버 효과: 상단 그라디언트 바, 그림자, 이동
        */
        .stock-card {
            background: #1e222d;
            border-radius: 12px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.3s;  /* 부드러운 애니메이션 */
            border: 2px solid transparent;
            position: relative;
            overflow: hidden;
        }
        
        /* 
            상단 그라디언트 바 (호버 시 나타남)
            - ::before 가상 요소 사용
        */
        .stock-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #2962ff, #26a69a);
            transform: scaleX(0);  /* 초기: 숨김 */
            transition: transform 0.3s;
        }
        
        .stock-card:hover::before {
            transform: scaleX(1);  /* 호버 시: 나타남 */
        }
        
        /* 호버 효과 */
        .stock-card:hover {
            border-color: #2962ff;
            transform: translateY(-4px);  /* 위로 4px 이동 */
            box-shadow: 0 8px 24px rgba(41, 98, 255, 0.2);  /* 파란색 그림자 */
        }
        
        /* 카드 헤더: 심볼 + 회사명 + 배지 */
        .stock-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 12px;
        }
        
        /* 종목 심볼 (예: AAPL) */
        .stock-symbol {
            font-size: 18px;
            font-weight: bold;
            color: #2962ff;  /* 파란색 */
        }
        
        /* 회사명 (예: Apple Inc.) */
        .stock-name {
            font-size: 11px;
            color: #787b86;
            margin-top: 4px;
            white-space: nowrap;     /* 줄바꿈 방지 */
            overflow: hidden;        /* 넘치는 텍스트 숨김 */
            text-overflow: ellipsis; /* ... 표시 */
        }
        
        /* 
            상태 배지 (Live/N/A)
            - Live: 데이터 있음 (초록)
            - N/A: 데이터 없음 (빨강)
        */
        .stock-badge {
            background: rgba(38, 166, 154, 0.1);  /* 반투명 초록 */
            color: #26a69a;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 600;
        }
        
        .stock-badge.error {
            background: rgba(239, 83, 80, 0.1);  /* 반투명 빨강 */
            color: #ef5350;
        }
        
        /* 
            현재가 표시
            - 상승: 초록색
            - 하락: 빨간색
            - 데이터 없음: 회색
        */
        .stock-price {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 8px;
            color: #26a69a;  /* 기본: 초록 */
        }
        
        .stock-price.down {
            color: #ef5350;  /* 하락: 빨강 */
        }
        
        .stock-price.unavailable {
            color: #787b86;  /* 데이터 없음: 회색 */
            font-size: 16px;
        }
        
        /* 등락 정보 */
        .stock-change {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
        }
        
        /* 등락률 배지 */
        .change-badge {
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 600;
            background: rgba(38, 166, 154, 0.1);  /* 반투명 초록 */
            color: #26a69a;
        }
        
        .change-badge.down {
            background: rgba(239, 83, 80, 0.1);  /* 반투명 빨강 */
            color: #ef5350;
        }
        
        /* 
            ========================================
            로딩 상태
            ========================================
            - 회전 스피너 애니메이션
        */
        .loading {
            text-align: center;
            padding: 60px 20px;
            color: #787b86;
        }
        
        /* 회전 스피너 */
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #2a2e39;
            border-top-color: #2962ff;  /* 상단만 파란색 */
            border-radius: 50%;
            animation: spin 1s linear infinite;  /* 1초마다 360도 회전 */
            margin: 0 auto 16px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        /* 
            ========================================
            검색 결과 없음
            ========================================
        */
        .no-results {
            text-align: center;
            padding: 60px 20px;
            color: #787b86;
            grid-column: 1 / -1;  /* 그리드 전체 열 차지 */
        }
        
        /* 
            ========================================
            반응형 디자인
            ========================================
            - 768px 이하: 모바일/태블릿
        */
        @media (max-width: 768px) {
            .header h1 {
                font-size: 24px;
            }
            
            .stock-grid {
                grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- 
            ========================================
            헤더: 타이틀 및 통계
            ========================================
        -->
        <div class="header">
            <div class="header-top">
                <h1>NASDAQ 100 Dashboard</h1>
                <div class="header-stats">
                    <!-- 총 종목 수 -->
                    <div class="stat-item">
                        <span class="stat-label">Total Stocks</span>
                        <span class="stat-value" id="totalStocks">--</span>
                    </div>
                    <!-- 마지막 업데이트 시각 -->
                    <div class="stat-item">
                        <span class="stat-label">Last Update</span>
                        <span class="stat-value" id="lastUpdate">--</span>
                    </div>
                </div>
            </div>
            <p>Real-time market data • Updates every 30 seconds</p>
        </div>
        
        <!-- 
            ========================================
            컨트롤 패널: 검색 및 뷰 전환
            ========================================
        -->
        <div class="controls">
            <!-- 검색창 -->
            <div class="search-box">
                <input 
                    type="text" 
                    class="search-input" 
                    id="searchInput"
                    placeholder="Search by symbol or company name..."
                    oninput="filterStocks()"
                >
            </div>
            <!-- 뷰 토글 버튼 -->
            <div class="view-toggle">
                <button class="toggle-btn active" onclick="setView('normal')">Normal</button>
                <button class="toggle-btn" onclick="setView('compact')">Compact</button>
            </div>
        </div>
        
        <!-- 
            ========================================
            종목 그리드
            ========================================
            - 초기: 로딩 스피너 표시
            - 로드 완료: JavaScript로 카드 렌더링
        -->
        <div class="stock-grid" id="stockGrid">
            <div class="loading">
                <div class="loading-spinner"></div>
                <p>Loading NASDAQ 100 stocks...</p>
            </div>
        </div>
    </div>

    <script>
        /* 
            ========================================
            전역 변수
            ========================================
        */
        
        let allStocks = [];          // 전체 종목 데이터 (필터링용 원본)
        let currentView = 'normal';  // 현재 뷰 모드 (normal/compact)
        
        /**
         * 대시보드 데이터 로드
         * 
         * 기능:
         * - Spring Boot API에서 NASDAQ 100 전체 종목 데이터 조회
         * - 각 종목의 실시간 주가 정보 표시
         * - 에러 발생 시 5초 후 재시도
         * 
         * API 엔드포인트:
         * - /stock/api/dashboard
         * - GET 메서드
         * - 응답: JSON 배열 (100개 종목)
         * 
         * 응답 데이터 구조:
         * [
         *   {
         *     symbol: "AAPL",
         *     name: "Apple Inc.",
         *     price: 273.67,
         *     change: 1.48,
         *     changePercent: 0.54,
         *     error: false
         *   },
         *   ...
         * ]
         * 
         * 동작 과정:
         * 1. fetch() API 호출
         * 2. HTTP 상태 확인 (200 OK)
         * 3. JSON 파싱
         * 4. 전역 변수에 저장 (allStocks)
         * 5. 통계 업데이트 (총 종목 수, 업데이트 시각)
         * 6. 카드 렌더링
         * 
         * 에러 처리:
         * - HTTP 에러: catch 블록
         * - 로딩 중 메시지 표시
         * - 5초 후 자동 재시도
         * 
         * 호출 시점:
         * - window.onload (초기)
         * - setInterval 30초마다 (자동 갱신)
         */
        function loadDashboard() {
            fetch('/stock/api/dashboard')
                .then(function(response) { 
                    // HTTP 상태 확인
                    if (!response.ok) {
                        throw new Error('HTTP ' + response.status);
                    }
                    return response.json(); 
                })
                .then(function(stocks) {
                    console.log('Loaded ' + stocks.length + ' stocks');
                    
                    // 전역 변수에 저장 (필터링용)
                    allStocks = stocks;
                    
                    // 통계 업데이트
                    document.getElementById('totalStocks').textContent = stocks.length;
                    updateLastUpdateTime();
                    
                    // 카드 렌더링
                    renderStocks(stocks);
                })
                .catch(function(error) {
                    console.error('Error loading dashboard:', error);
                    
                    // 에러 메시지 표시
                    document.getElementById('stockGrid').innerHTML = 
                        '<div class="loading">Failed to load data. Retrying...</div>';
                    
                    // 5초 후 재시도
                    setTimeout(loadDashboard, 5000);
                });
        }
        
        /**
         * 종목 카드 렌더링
         * 
         * 기능:
         * - 종목 데이터를 HTML 카드로 변환
         * - 동적으로 DOM 생성 및 추가
         * - 각 카드에 클릭 이벤트 연결
         * 
         * 카드 구조:
         * - 헤더: 심볼, 회사명, 상태 배지
         * - 본문: 현재가, 등락률, 등락폭
         * 
         * 데이터 처리:
         * - error: true → "No Data" 표시
         * - error: false → 실제 주가 정보 표시
         * - 상승/하락에 따라 색상 변경
         * 
         * 클릭 이벤트:
         * - 카드 클릭 시 상세 차트 페이지로 이동
         * - URL: /stock/detail/{symbol}
         * 
         * 검색 필터:
         * - data-symbol, data-name 속성 설정
         * - filterStocks()에서 사용
         * 
         * @param {array} stocks 종목 데이터 배열
         */
        function renderStocks(stocks) {
            var grid = document.getElementById('stockGrid');
            
            // 결과 없음 체크
            if (stocks.length === 0) {
                grid.innerHTML = '<div class="no-results">No stocks found</div>';
                return;
            }
            
            // 그리드 초기화
            grid.innerHTML = '';
            
            // 각 종목 카드 생성
            stocks.forEach(function(stock) {
                // 카드 div 생성
                var card = document.createElement('div');
                card.className = 'stock-card';
                
                // 검색 필터용 속성
                card.setAttribute('data-symbol', stock.symbol.toLowerCase());
                card.setAttribute('data-name', stock.name.toLowerCase());
                
                // 클릭 이벤트: 상세 차트로 이동
                card.onclick = function() {
                    window.location.href = '/stock/detail/' + stock.symbol;
                };
                
                // ========== 데이터 처리 ==========
                
                // 에러 체크
                var hasError = stock.error === true;
                var price = hasError ? 0 : parseFloat(stock.price);
                var change = hasError ? 0 : parseFloat(stock.change);
                var changePercent = hasError ? 0 : parseFloat(stock.changePercent);
                
                // 상승/하락 판단
                var isDown = changePercent < 0;
                
                // CSS 클래스 결정
                var priceClass = hasError ? 'unavailable' : (isDown ? 'down' : '');
                var changeClass = isDown ? 'down' : '';
                var badgeClass = hasError ? 'error' : '';
                var badgeText = hasError ? 'N/A' : 'Live';
                
                // ========== HTML 생성 ==========
                
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
                
                // 그리드에 카드 추가
                grid.appendChild(card);
            });
        }
        
        /**
         * 종목 검색 필터
         * 
         * 기능:
         * - 검색어 입력 시 실시간 필터링
         * - 심볼 또는 회사명으로 검색
         * - 대소문자 구분 없음
         * 
         * 동작:
         * 1. 검색 입력창 값 가져오기
         * 2. 소문자 변환
         * 3. 빈 문자열이면 전체 표시
         * 4. 필터링: symbol 또는 name에 검색어 포함
         * 5. 결과 렌더링
         * 
         * 검색 예시:
         * - "app" → AAPL (Apple Inc.) 매칭
         * - "tesla" → TSLA (Tesla, Inc.) 매칭
         * - "micro" → MSFT (Microsoft Corporation) 매칭
         * 
         * 호출:
         * - oninput 이벤트 (실시간)
         * - 타이핑할 때마다 자동 실행
         */
        function filterStocks() {
            // 검색어 가져오기 (소문자)
            var query = document.getElementById('searchInput').value.toLowerCase();
            
            // 빈 검색어: 전체 표시
            if (query === '') {
                renderStocks(allStocks);
                return;
            }
            
            // 필터링: symbol 또는 name에 검색어 포함
            var filtered = allStocks.filter(function(stock) {
                return stock.symbol.toLowerCase().includes(query) || 
                       stock.name.toLowerCase().includes(query);
            });
            
            // 결과 렌더링
            renderStocks(filtered);
        }
        
        /**
         * 뷰 모드 변경 (Normal/Compact)
         * 
         * 기능:
         * - Normal: 큰 카드 (280px)
         * - Compact: 작은 카드 (220px)
         * 
         * 동작:
         * 1. 현재 뷰 모드 저장
         * 2. 모든 버튼 비활성화
         * 3. 클릭한 버튼만 활성화
         * 4. 그리드에 'compact' 클래스 추가/제거
         * 
         * CSS 변경:
         * - .stock-grid: grid-template-columns 변경
         * - .stock-grid.compact: 더 작은 minmax
         * 
         * @param {string} view 뷰 모드 (normal/compact)
         */
        function setView(view) {
            currentView = view;
            
            var grid = document.getElementById('stockGrid');
            var buttons = document.querySelectorAll('.toggle-btn');
            
            // 모든 버튼 비활성화
            buttons.forEach(function(btn) {
                btn.classList.remove('active');
            });
            
            // 클릭한 버튼 활성화
            event.target.classList.add('active');
            
            // 그리드 클래스 변경
            if (view === 'compact') {
                grid.classList.add('compact');
            } else {
                grid.classList.remove('compact');
            }
        }
        
        /**
         * 마지막 업데이트 시각 표시
         * 
         * 기능:
         * - 현재 시각을 HH:MM:SS 형식으로 표시
         * - 1초마다 자동 갱신
         * 
         * 형식:
         * - 14:30:45 (24시간 형식)
         * - padStart(2, '0'): 한 자리 숫자 앞에 0 추가
         * 
         * 호출:
         * - loadDashboard() 완료 후
         * - setInterval 1초마다
         */
        function updateLastUpdateTime() {
            var now = new Date();
            
            // 시, 분, 초 추출 (2자리로 패딩)
            var hours = now.getHours().toString().padStart(2, '0');
            var minutes = now.getMinutes().toString().padStart(2, '0');
            var seconds = now.getSeconds().toString().padStart(2, '0');
            
            // 표시 (HH:MM:SS)
            document.getElementById('lastUpdate').textContent = 
                hours + ':' + minutes + ':' + seconds;
        }
        
        /**
         * 페이지 로드 완료 시 초기화
         * 
         * 실행 내용:
         * 1. 초기 대시보드 로드
         * 2. 30초마다 자동 갱신 (setInterval)
         * 3. 1초마다 시각 업데이트 (setInterval)
         * 
         * 자동 갱신 이유:
         * - WebSocket 없이 실시간 업데이트 효과
         * - 30초마다 전체 데이터 재조회
         * - 서버 부하 분산
         * 
         * 타이머:
         * - 30000ms = 30초 (데이터 갱신)
         * - 1000ms = 1초 (시각 표시)
         * 
         * 초기 상태:
         * - 로딩 스피너 표시
         * - 데이터 로드 중...
         * - 완료 후 100개 카드 렌더링
         */
        window.onload = function() {
            console.log('NASDAQ 100 Dashboard loaded');
            
            // 1. 초기 데이터 로드
            loadDashboard();
            
            // 2. 30초마다 자동 갱신
            setInterval(function() {
                loadDashboard();
                console.log('Dashboard refreshed');
            }, 30000);  // 30초 = 30,000ms
            
            // 3. 1초마다 시각 업데이트
            setInterval(updateLastUpdateTime, 1000);  // 1초 = 1,000ms
        };
    </script>
</body>
</html>