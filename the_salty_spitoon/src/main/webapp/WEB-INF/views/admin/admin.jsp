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
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #131722; min-height: 100vh; color: #d1d4dc; }
        a { color: inherit; text-decoration: none; }

        .navbar { background: #1e222d; border-bottom: 1px solid #2a2e39; padding: 0 20px; position: sticky; top: 0; z-index: 1000; }
        .navbar-container { max-width: 1400px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; height: 60px; }
        .navbar-brand { font-size: 20px; font-weight: 700; background: linear-gradient(135deg, #2962ff 0%, #26a69a 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
        .navbar-menu { display: flex; gap: 8px; }
        .navbar-item { padding: 10px 16px; border-radius: 6px; font-size: 14px; font-weight: 500; color: #787b86; transition: all 0.2s; }
        .navbar-item:hover { background: #2a2e39; color: #d1d4dc; }
        .navbar-item.active { background: #2962ff; color: white; }
        
        .container { max-width: 900px; margin: 0 auto; padding: 30px 20px; }
        h1 { text-align: center; margin-bottom: 30px; font-size: 1.8rem; color: #d1d4dc; }
        h1 span { color: #2962ff; }
        
        .card { background: #1e222d; border: 1px solid #2a2e39; border-radius: 8px; padding: 24px; margin-bottom: 20px; }
        .card-title { font-size: 1.1rem; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; color: #d1d4dc; }
        
        /* 기간/개수 선택 버튼 */
        .days-selector { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
        .days-btn { padding: 12px 24px; border: 1px solid #2a2e39; background: #2a2e39; color: #787b86; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500; transition: all 0.2s; }
        .days-btn:hover { background: #363a45; color: #d1d4dc; border-color: #434651; }
        .days-btn.active { background: #2962ff; color: white; border-color: #2962ff; }
        .days-btn:disabled { opacity: 0.5; cursor: not-allowed; }
        
        /* 버튼 스타일 */
        .btn-primary { width: 100%; padding: 16px; background: #2962ff; border: none; border-radius: 10px; color: white; font-size: 1.1rem; font-weight: 600; cursor: pointer; transition: all 0.3s ease; display: flex; align-items: center; justify-content: center; gap: 10px; }
        .btn-primary:hover:not(:disabled) { transform: translateY(-2px); background: #1e53e5; box-shadow: 0 4px 12px rgba(41, 98, 255, 0.3); }
        .btn-primary:disabled { background: #2a2e39; color: #787b86; cursor: not-allowed; transform: none; box-shadow: none; }
        .btn-secondary { padding: 12px 20px; background: #2a2e39; border: 1px solid #434651; border-radius: 6px; color: #d1d4dc; font-size: 14px; cursor: pointer; transition: all 0.2s; }
        .btn-secondary:hover { background: #363a45; }
        .btn-success { background: #26a69a; border-color: #26a69a; }
        .btn-success:hover { background: #1e8e82; }
        .btn-warning { background: #f59e0b; border-color: #f59e0b; color: #000; }
        .btn-warning:hover { background: #d97706; }
        
        /* 태그 입력 스타일 */
        .tag-input-container { position: relative; margin-bottom: 15px; }
        .tag-input-wrapper { display: flex; flex-wrap: wrap; gap: 8px; padding: 12px; background: #2a2e39; border: 1px solid #434651; border-radius: 6px; min-height: 50px; align-items: center; }
        .tag-input-wrapper:focus-within { border-color: #2962ff; }
        .tag { display: inline-flex; align-items: center; gap: 6px; padding: 6px 10px; background: #2962ff; color: white; border-radius: 4px; font-size: 13px; font-weight: 500; }
        .tag-remove { cursor: pointer; opacity: 0.7; font-size: 16px; }
        .tag-remove:hover { opacity: 1; }
        .tag-text-input { flex: 1; min-width: 100px; background: transparent; border: none; color: #d1d4dc; font-size: 14px; outline: none; }
        .tag-text-input::placeholder { color: #787b86; }
        
        /* 자동완성 드롭다운 */
        .autocomplete-dropdown { position: absolute; top: 100%; left: 0; right: 0; max-height: 200px; overflow-y: auto; background: #2a2e39; border: 1px solid #434651; border-top: none; border-radius: 0 0 6px 6px; z-index: 100; display: none; }
        .autocomplete-dropdown.visible { display: block; }
        .autocomplete-item { padding: 10px 14px; cursor: pointer; display: flex; justify-content: space-between; align-items: center; }
        .autocomplete-item:hover { background: #363a45; }
        .autocomplete-item .symbol { font-weight: 600; color: #2962ff; }
        .autocomplete-item .name { font-size: 12px; color: #787b86; max-width: 60%; text-overflow: ellipsis; overflow: hidden; white-space: nowrap; }
        
        /* CSV 동기화 */
        .sync-status { padding: 16px; background: #2a2e39; border-radius: 8px; margin-bottom: 20px; }
        .sync-status .status-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
        .sync-status .status-label { color: #787b86; }
        .sync-status .status-value { font-weight: 600; }
        .sync-status .status-value.success { color: #26a69a; }
        .sync-status .status-value.warning { color: #f59e0b; }
        .missing-symbols-list { margin-top: 12px; padding: 12px; background: rgba(245, 158, 11, 0.1); border-radius: 6px; max-height: 150px; overflow-y: auto; }
        .missing-symbols-list .title { color: #f59e0b; font-weight: 500; margin-bottom: 8px; }
        .missing-symbols-list .items { display: flex; flex-wrap: wrap; gap: 6px; }
        .missing-symbols-list .item { padding: 4px 8px; background: rgba(245, 158, 11, 0.2); border-radius: 4px; font-size: 12px; }
        
        /* 진행률 영역 */
        .progress-section { display: none; }
        .progress-section.visible { display: block; }
        .progress-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .progress-text { font-size: 1.1rem; color: #787b86; }
        .progress-percent { font-size: 1.5rem; font-weight: bold; color: #2962ff; }
        .progress-bar-container { height: 12px; background: #2a2e39; border-radius: 6px; overflow: hidden; margin-bottom: 15px; }
        .progress-bar { height: 100%; background: linear-gradient(90deg, #2962ff, #26a69a); border-radius: 6px; transition: width 0.3s ease; width: 0%; }
        .current-symbol { padding: 12px 16px; background: rgba(41, 98, 255, 0.1); border-radius: 8px; margin-bottom: 15px; display: flex; align-items: center; gap: 12px; }
        .current-symbol .symbol { font-weight: bold; font-size: 1.2rem; color: #2962ff; }
        .current-symbol .status { font-size: 0.9rem; color: #787b86; }
        .current-symbol .status.success { color: #26a69a; }
        .current-symbol .status.failed { color: #ef5350; }
        .eta { text-align: center; color: #787b86; font-size: 0.9rem; }
        
        /* 로그 영역 */
        .log-section { margin-top: 20px; }
        .log-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .log-title { font-size: 1rem; color: #787b86; }
        .log-toggle { background: none; border: none; color: #2962ff; cursor: pointer; font-size: 0.9rem; }
        .log-container { max-height: 250px; overflow-y: auto; background: #2a2e39; border-radius: 8px; padding: 15px; font-family: 'Consolas', 'Monaco', monospace; font-size: 0.85rem; }
        .log-entry { padding: 4px 0; border-bottom: 1px solid #363a45; }
        .log-entry:last-child { border-bottom: none; }
        .log-entry .time { color: #787b86; margin-right: 10px; }
        .log-entry .symbol { color: #2962ff; font-weight: bold; margin-right: 8px; }
        .log-entry.success .message { color: #26a69a; }
        .log-entry.failed .message { color: #ef5350; }
        
        /* 완료 결과 */
        .result-section { display: none; }
        .result-section.visible { display: block; }
        .result-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .stat-box { background: #2a2e39; border-radius: 8px; padding: 20px; text-align: center; }
        .stat-value { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
        .stat-value.success { color: #26a69a; }
        .stat-value.failed { color: #ef5350; }
        .stat-value.total { color: #2962ff; }
        .stat-label { font-size: 0.9rem; color: #787b86; }
        .failed-list { margin-top: 15px; padding: 15px; background: rgba(239, 83, 80, 0.1); border-radius: 8px; border: 1px solid rgba(239, 83, 80, 0.3); }
        .failed-list-title { color: #ef5350; margin-bottom: 10px; font-weight: 500; }
        .failed-list-items { display: flex; flex-wrap: wrap; gap: 8px; }
        .failed-item { background: rgba(239, 83, 80, 0.2); padding: 4px 10px; border-radius: 4px; font-size: 0.85rem; }
        
        /* 재무/뉴스 섹션 */
        .financial-section { margin-top: 20px; }
        .financial-actions { display: flex; gap: 10px; flex-wrap: wrap; }
        .select-wrapper { flex: 1; min-width: 200px; }
        .select-wrapper select { width: 100%; padding: 12px; background: #2a2e39; border: 1px solid #434651; border-radius: 6px; color: #d1d4dc; font-size: 0.9rem; }
        .select-wrapper select option { background: #1e222d; }
        
        /* WebSocket 상태 */
        .ws-status { position: fixed; bottom: 20px; right: 20px; padding: 8px 16px; border-radius: 20px; font-size: 0.85rem; display: flex; align-items: center; gap: 8px; }
        .ws-status.connected { background: rgba(38, 166, 154, 0.2); color: #26a69a; }
        .ws-status.disconnected { background: rgba(239, 83, 80, 0.2); color: #ef5350; }
        .ws-dot { width: 8px; height: 8px; border-radius: 50%; background: currentColor; }
        
        /* Badge */
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }
        .badge-success { background: rgba(38, 166, 154, 0.2); color: #26a69a; }
        .badge-warning { background: rgba(245, 158, 11, 0.2); color: #f59e0b; }
        
        /* 뉴스 로그 섹션 */
        .news-log-section { margin-top: 20px; padding: 15px; background: #2a2e39; border-radius: 8px; }
        .news-log-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .news-log-title { font-size: 0.9rem; color: #787b86; }
        .news-log-container { max-height: 200px; overflow-y: auto; font-family: 'Consolas', monospace; font-size: 0.8rem; }
        .news-log-entry { padding: 6px 8px; border-bottom: 1px solid #363a45; color: #d1d4dc; }
        
        /* 수집 대상 선택 */
        .target-selector { margin-bottom: 20px; }
        .target-selector label { display: flex; align-items: center; gap: 8px; cursor: pointer; margin-bottom: 8px; }
        .target-selector input[type="radio"] { accent-color: #2962ff; }
        
        /* 달력 스타일 */
        .calendar-container { margin-bottom: 20px; }
        .calendar-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding: 10px; background: #2a2e39; border-radius: 6px; }
        .calendar-header button { background: none; border: none; color: #2962ff; font-size: 1.2rem; cursor: pointer; padding: 5px 10px; }
        .calendar-header button:hover { background: #363a45; border-radius: 4px; }
        .calendar-title { font-size: 1.1rem; font-weight: 600; color: #d1d4dc; }
        .calendar-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
        .calendar-day-header { text-align: center; font-size: 0.75rem; color: #787b86; padding: 8px 4px; font-weight: 600; }
        .calendar-day { text-align: center; padding: 10px 4px; border-radius: 6px; cursor: pointer; transition: all 0.2s; position: relative; min-height: 60px; background: #2a2e39; }
        .calendar-day:hover:not(.disabled):not(.empty) { background: #363a45; }
        .calendar-day.disabled { opacity: 0.3; cursor: not-allowed; }
        .calendar-day.empty { background: transparent; cursor: default; }
        .calendar-day.selected { background: #2962ff; color: white; }
        .calendar-day.today { border: 2px solid #26a69a; }
        .calendar-day .day-number { font-size: 0.9rem; font-weight: 500; }
        .calendar-day .news-count { font-size: 0.7rem; margin-top: 4px; }
        .calendar-day .news-count.has-news { color: #26a69a; }
        .calendar-day .news-count.no-news { color: #787b86; }
        .calendar-day .saved-badge { font-size: 0.65rem; color: #f59e0b; margin-top: 2px; }
        .calendar-legend { display: flex; gap: 20px; margin-top: 15px; justify-content: center; font-size: 0.8rem; color: #787b86; }
        .calendar-legend span { display: flex; align-items: center; gap: 6px; }
        .legend-dot { width: 10px; height: 10px; border-radius: 50%; }
        .legend-dot.available { background: #26a69a; }
        .legend-dot.saved { background: #f59e0b; }
        .legend-dot.today { border: 2px solid #26a69a; background: transparent; }
        
        /* 선택된 날짜 정보 */
        .selected-date-info { padding: 15px; background: rgba(41, 98, 255, 0.1); border-radius: 8px; margin-bottom: 20px; display: none; }
        .selected-date-info.visible { display: block; }
        .selected-date-title { font-size: 1rem; font-weight: 600; color: #2962ff; margin-bottom: 10px; }
        .selected-date-stats { display: flex; gap: 20px; flex-wrap: wrap; }
        .selected-date-stats .stat { text-align: center; }
        .selected-date-stats .stat-value { font-size: 1.3rem; font-weight: bold; }
        .selected-date-stats .stat-label { font-size: 0.8rem; color: #787b86; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="navbar-container">
            <a href="/dashboard" class="navbar-brand">The Salty Spitoon</a>
            <div class="navbar-menu">
                <a href="/dashboard" class="navbar-item">대시보드</a>
                <a href="/stock" class="navbar-item">종목</a>
                <a href="/news" class="navbar-item">뉴스</a>
                <a href="/admin" class="navbar-item active">관리자</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <h1>🛠️ <span>The Salty Spitoon</span> 관리자</h1>
        
        <!-- CSV 동기화 카드 -->
        <div class="card">
            <div class="card-title">🔄 CSV ↔ DB 동기화</div>
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                nasdaq100_tickers.csv 파일과 stocks 테이블을 비교하여 누락된 종목을 추가하고, 로고 URL을 업데이트합니다.
            </p>
            
            <div class="sync-status" id="syncStatus">
                <div class="status-row">
                    <span class="status-label">CSV 종목 수</span>
                    <span class="status-value" id="csvCount">-</span>
                </div>
                <div class="status-row">
                    <span class="status-label">DB 종목 수</span>
                    <span class="status-value" id="dbCount">-</span>
                </div>
                <div class="status-row">
                    <span class="status-label">누락 종목 수</span>
                    <span class="status-value" id="missingCount">-</span>
                </div>
                <div class="missing-symbols-list" id="missingList" style="display: none;">
                    <div class="title">⚠️ DB에 없는 종목</div>
                    <div class="items" id="missingItems"></div>
                </div>
            </div>
            
            <!-- 동기화 결과 -->
            <div id="syncResult" style="display: none; margin-bottom: 15px; padding: 16px; background: rgba(38, 166, 154, 0.1); border-radius: 8px; border: 1px solid rgba(38, 166, 154, 0.3);">
                <div style="display: flex; gap: 20px; flex-wrap: wrap;">
                    <div style="text-align: center;">
                        <div style="font-size: 1.5rem; font-weight: bold; color: #26a69a;" id="syncAddedCount">0</div>
                        <div style="font-size: 0.85rem; color: #787b86;">신규 추가</div>
                    </div>
                    <div style="text-align: center;">
                        <div style="font-size: 1.5rem; font-weight: bold; color: #2962ff;" id="syncUpdatedCount">0</div>
                        <div style="font-size: 0.85rem; color: #787b86;">로고 업데이트</div>
                    </div>
                </div>
            </div>
            
            <div style="display: flex; gap: 10px;">
                <button class="btn-secondary" onclick="checkMissingSymbols()">🔍 확인</button>
                <button class="btn-secondary btn-success" id="syncBtn" onclick="syncCsvToDb()">✅ 동기화 실행</button>
            </div>
        </div>
        
        <!-- 과거 데이터 수집 카드 -->
        <div class="card">
            <div class="card-title">📊 과거 데이터 수집 (1분봉)</div>
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                Yahoo Finance API에서 과거 1분봉 데이터를 수집합니다.<br>
                ⚠️ API 제한으로 최대 7일까지만 수집 가능합니다.
            </p>
            
            <!-- 수집 대상 선택 -->
            <div class="target-selector">
                <div style="margin-bottom: 10px; color: #d1d4dc; font-weight: 500;">📊 수집 대상</div>
                <label>
                    <input type="radio" name="historicalTarget" value="all" checked onchange="toggleHistoricalInput()">
                    <span>전체 종목 (CSV 기준)</span>
                </label>
                <label>
                    <input type="radio" name="historicalTarget" value="specific" onchange="toggleHistoricalInput()">
                    <span>특정 종목만</span>
                </label>
            </div>
            
            <!-- 태그 입력 (특정 종목) -->
            <div id="historicalSymbolsWrapper" style="display: none;">
                <div class="tag-input-container">
                    <div class="tag-input-wrapper" id="historicalTagWrapper">
                        <input type="text" class="tag-text-input" id="historicalTagInput" placeholder="종목 코드 입력 (예: AAPL)" autocomplete="off">
                    </div>
                    <div class="autocomplete-dropdown" id="historicalAutocomplete"></div>
                </div>
            </div>
            
            <div class="days-selector" id="historicalDaysSelector">
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
        
        <!-- 뉴스 수집 카드 -->
        <div class="card">
            <div class="card-title">📰 뉴스 데이터 수집</div>
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                Yahoo Finance API에서 뉴스를 수집하고, OpenAI로 한글 번역 + 마크다운 본문을 생성합니다.<br>
                ✅ 20분마다 자동 수집 | ✅ MySQL 중복 체크 | ✅ 외부 기사 스킵
            </p>
            
            <!-- 스케줄러 상태 -->
            <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 20px; padding: 15px; background: #2a2e39; border-radius: 8px;">
                <div style="flex: 1;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                        <span style="font-weight: 500; color: #d1d4dc;">🕒 자동 수집 (20분)</span>
                        <span id="schedulerBadge" class="badge ${newsSchedulerEnabled ? 'badge-success' : 'badge-warning'}">
                            ${newsSchedulerEnabled ? 'ON' : 'OFF'}
                        </span>
                    </div>
                    <div style="font-size: 0.85rem; color: #787b86;">
                        마지막 수집: <span id="lastCollectionTime">${lastNewsCollectionTime != null ? lastNewsCollectionTime : '-'}</span>
                        | 저장: <span id="lastCollectionCount">${lastNewsCollectionCount}</span>개
                    </div>
                </div>
                <button id="schedulerToggleBtn" class="btn-secondary ${newsSchedulerEnabled ? '' : 'btn-warning'}" onclick="toggleNewsScheduler()">
                    ${newsSchedulerEnabled ? '⏸️ 일시정지' : '▶️ 활성화'}
                </button>
            </div>
            
            <!-- 수집 대상 선택 -->
            <div class="target-selector">
                <div style="margin-bottom: 10px; color: #d1d4dc; font-weight: 500;">📊 수집 대상</div>
                <label>
                    <input type="radio" name="newsTarget" value="all" checked onchange="toggleNewsInput()">
                    <span>전체 종목 (NASDAQ 100)</span>
                </label>
                <label>
                    <input type="radio" name="newsTarget" value="specific" onchange="toggleNewsInput()">
                    <span>특정 종목만</span>
                </label>
            </div>
            
            <!-- 태그 입력 (특정 종목) -->
            <div id="newsSymbolsWrapper" style="display: none;">
                <div class="tag-input-container">
                    <div class="tag-input-wrapper" id="newsTagWrapper">
                        <input type="text" class="tag-text-input" id="newsTagInput" placeholder="종목 코드 입력 (예: AAPL)" autocomplete="off">
                    </div>
                    <div class="autocomplete-dropdown" id="newsAutocomplete"></div>
                </div>
            </div>
            
            <div style="margin-bottom: 10px; color: #d1d4dc; font-weight: 500;">📝 종목당 뉴스 개수</div>
            <div class="days-selector" id="newsCountSelector">
                <button class="days-btn" data-count="1">1개</button>
                <button class="days-btn" data-count="3">3개</button>
                <button class="days-btn active" data-count="5">5개</button>
                <button class="days-btn" data-count="10">10개</button>
            </div>
            
            <button id="newsCollectBtn" class="btn-primary" onclick="startNewsCollection()">
                <span>📰</span>
                <span>뉴스 수집 시작</span>
            </button>
            
            <div id="newsProgressSection" style="margin-top: 20px; display: none;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="color: #787b86;" id="newsProgressText">준비 중...</span>
                    <span style="font-weight: bold; color: #2962ff;" id="newsProgressPercent">0%</span>
                </div>
                <div style="height: 10px; background: #2a2e39; border-radius: 5px; overflow: hidden; margin-bottom: 15px;">
                    <div id="newsProgressBar" style="height: 100%; background: linear-gradient(90deg, #2962ff, #26a69a); width: 0%; transition: width 0.3s;"></div>
                </div>
                <div id="newsStatusText" style="padding: 12px 16px; background: rgba(41, 98, 255, 0.1); border-radius: 8px; color: #d1d4dc; font-size: 0.9rem;">대기 중...</div>
            </div>
            
            <!-- 수집 로그 -->
            <div class="news-log-section">
                <div class="news-log-header">
                    <span class="news-log-title">📝 수집 로그</span>
                    <button class="log-toggle" onclick="refreshNewsLogs()">🔄 새로고침</button>
                </div>
                <div class="news-log-container" id="newsLogContainer">
                    <c:forEach var="log" items="${newsCollectionLogs}">
                        <div class="news-log-entry">${log}</div>
                    </c:forEach>
                    <c:if test="${empty newsCollectionLogs}">
                        <div class="news-log-entry" style="color: #787b86;">로그가 없습니다.</div>
                    </c:if>
                </div>
            </div>
        </div>
        
        <!-- 날짜별 뉴스 수집 카드 -->
        <div class="card">
            <div class="card-title">📅 날짜별 뉴스 수집</div>
            <p style="color: #868e96; margin-bottom: 20px; font-size: 0.9rem;">
                Yahoo Finance API에서 수집 가능한 뉴스 URL을 스캔하고, 원하는 날짜의 뉴스를 선택적으로 수집합니다.<br>
                ✅ URL 스캔 → 날짜 선택 → 크롤링 + 번역 + 저장
            </p>
            
            <!-- 스캔 상태 -->
            <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 20px; padding: 15px; background: #2a2e39; border-radius: 8px;">
                <div style="flex: 1;">
                    <div style="font-weight: 500; color: #d1d4dc; margin-bottom: 5px;">📊 스캔 상태</div>
                    <div style="font-size: 0.85rem; color: #787b86;">
                        마지막 스캔: <span id="scanTimestamp">-</span>
                    </div>
                </div>
                <button id="scanUrlsBtn" class="btn-secondary btn-success" onclick="scanNewsUrls()">
                    🔍 URL 스캔
                </button>
            </div>
            
            <!-- 달력 -->
            <div class="calendar-container" id="calendarContainer" style="display: none;">
                <div class="calendar-header">
                    <button onclick="changeMonth(-1)">◀</button>
                    <span class="calendar-title" id="calendarTitle">2025년 12월</span>
                    <button onclick="changeMonth(1)">▶</button>
                </div>
                <div class="calendar-grid" id="calendarGrid">
                    <div class="calendar-day-header">일</div>
                    <div class="calendar-day-header">월</div>
                    <div class="calendar-day-header">화</div>
                    <div class="calendar-day-header">수</div>
                    <div class="calendar-day-header">목</div>
                    <div class="calendar-day-header">금</div>
                    <div class="calendar-day-header">토</div>
                </div>
                <div class="calendar-legend">
                    <span><div class="legend-dot available"></div> 수집 가능</span>
                    <span><div class="legend-dot saved"></div> 저장됨</span>
                    <span><div class="legend-dot today"></div> 오늘</span>
                </div>
            </div>
            
            <!-- 선택된 날짜 정보 -->
            <div class="selected-date-info" id="selectedDateInfo">
                <div class="selected-date-title" id="selectedDateTitle">2025년 12월 25일</div>
                <div class="selected-date-stats">
                    <div class="stat">
                        <div class="stat-value" style="color: #26a69a;" id="selectedTotal">0</div>
                        <div class="stat-label">전체 뉴스</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value" style="color: #f59e0b;" id="selectedSaved">0</div>
                        <div class="stat-label">저장됨</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value" style="color: #2962ff;" id="selectedUnsaved">0</div>
                        <div class="stat-label">미저장</div>
                    </div>
                </div>
            </div>
            
            <button id="collectByDateBtn" class="btn-primary" onclick="collectNewsByDate()" disabled>
                <span>📅</span>
                <span>선택한 날짜 뉴스 수집</span>
            </button>
            
            <!-- 진행 상태 -->
            <div id="dateCollectProgress" style="margin-top: 20px; display: none;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="color: #787b86;" id="dateProgressText">준비 중...</span>
                    <span style="font-weight: bold; color: #2962ff;" id="dateProgressPercent">0%</span>
                </div>
                <div style="height: 10px; background: #2a2e39; border-radius: 5px; overflow: hidden; margin-bottom: 15px;">
                    <div id="dateProgressBar" style="height: 100%; background: linear-gradient(90deg, #2962ff, #26a69a); width: 0%; transition: width 0.3s;"></div>
                </div>
                <div id="dateStatusText" style="padding: 12px 16px; background: rgba(41, 98, 255, 0.1); border-radius: 8px; color: #d1d4dc; font-size: 0.9rem;">대기 중...</div>
            </div>
        </div>
        
        <!-- 재무 데이터 카드 -->
        <div class="card">
            <div class="card-title">💰 재무 데이터 관리</div>
            <div class="financial-section">
                <div class="financial-actions" style="margin-bottom: 15px;">
                    <button class="btn-secondary" onclick="collectFinancialData()">📥 재무 데이터 수집</button>
                    <button class="btn-secondary" onclick="loadLatestFinancialData()">📤 최신 데이터 로드</button>
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
                    <button class="btn-secondary" onclick="loadSelectedFinancialData()">📤 선택 파일 로드</button>
                </div>
                <div id="financialResult" style="margin-top: 15px; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 8px; display: none; white-space: pre-wrap; font-family: monospace; font-size: 0.85rem;"></div>
            </div>
        </div>
    </div>
    
    <div class="ws-status disconnected" id="wsStatus">
        <div class="ws-dot"></div>
        <span>연결 끊김</span>
    </div>

    <script>
        // 전역 변수
        var selectedDays = 3;
        var selectedNewsCount = 5;
        var stompClient = null;
        var isCollecting = false;
        var startTime = null;
        var csvSymbols = []; // CSV에서 로드한 종목 목록
        var historicalTags = []; // 과거 데이터 선택된 종목
        var newsTags = []; // 뉴스 선택된 종목
        
        // DOM 요소
        var startBtn = document.getElementById('startBtn');
        var progressSection = document.getElementById('progressSection');
        var resultSection = document.getElementById('resultSection');
        var progressBar = document.getElementById('progressBar');
        var progressText = document.getElementById('progressText');
        var progressPercent = document.getElementById('progressPercent');
        var currentSymbol = document.getElementById('currentSymbol');
        var etaText = document.getElementById('etaText');
        var logContainer = document.getElementById('logContainer');
        var wsStatus = document.getElementById('wsStatus');
        
        // 페이지 로드 시 초기화
        document.addEventListener('DOMContentLoaded', function() {
            loadCsvSymbols();
            connectWebSocket();
            setupDaysSelector();
            setupNewsCountSelector();
            setupTagInputs();
            checkCollectionStatus();
            checkScannedData(); // 날짜별 뉴스 스캔 데이터 확인
        });
        
        // CSV 종목 목록 로드
        function loadCsvSymbols() {
            fetch('/admin/csv-symbols')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    csvSymbols = data;
                    console.log('CSV 종목 로드:', csvSymbols.length + '개');
                })
                .catch(function(e) {
                    console.error('CSV 로드 실패:', e);
                });
        }
        
        // 기간 선택 버튼 설정
        function setupDaysSelector() {
            document.querySelectorAll('#historicalDaysSelector .days-btn').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    if (isCollecting) return;
                    document.querySelectorAll('#historicalDaysSelector .days-btn').forEach(function(b) { b.classList.remove('active'); });
                    btn.classList.add('active');
                    selectedDays = parseInt(btn.dataset.days);
                });
            });
        }
        
        // 뉴스 개수 선택 버튼 설정
        function setupNewsCountSelector() {
            document.querySelectorAll('#newsCountSelector .days-btn').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('#newsCountSelector .days-btn').forEach(function(b) { b.classList.remove('active'); });
                    btn.classList.add('active');
                    selectedNewsCount = parseInt(btn.dataset.count);
                });
            });
        }
        
        // 태그 입력 설정
        function setupTagInputs() {
            setupTagInput('historical');
            setupTagInput('news');
        }
        
        function setupTagInput(prefix) {
            var input = document.getElementById(prefix + 'TagInput');
            var wrapper = document.getElementById(prefix + 'TagWrapper');
            var dropdown = document.getElementById(prefix + 'Autocomplete');
            var tags = prefix === 'historical' ? historicalTags : newsTags;
            
            input.addEventListener('input', function() {
                var query = input.value.trim().toUpperCase();
                if (query.length === 0) {
                    dropdown.classList.remove('visible');
                    return;
                }
                
                var matches = csvSymbols.filter(function(s) {
                    return s.symbol.toUpperCase().indexOf(query) === 0 || 
                           s.name.toUpperCase().indexOf(query) !== -1;
                }).slice(0, 8);
                
                if (matches.length === 0) {
                    dropdown.classList.remove('visible');
                    return;
                }
                
                var html = '';
                for (var i = 0; i < matches.length; i++) {
                    html += '<div class="autocomplete-item" data-symbol="' + matches[i].symbol + '">' +
                            '<span class="symbol">' + matches[i].symbol + '</span>' +
                            '<span class="name">' + matches[i].name + '</span></div>';
                }
                dropdown.innerHTML = html;
                dropdown.classList.add('visible');
                
                // 클릭 이벤트
                dropdown.querySelectorAll('.autocomplete-item').forEach(function(item) {
                    item.addEventListener('click', function() {
                        addTag(prefix, item.dataset.symbol);
                        input.value = '';
                        dropdown.classList.remove('visible');
                    });
                });
            });
            
            input.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' && input.value.trim()) {
                    e.preventDefault();
                    var symbol = input.value.trim().toUpperCase();
                    addTag(prefix, symbol);
                    input.value = '';
                    dropdown.classList.remove('visible');
                }
                if (e.key === 'Backspace' && input.value === '' && tags.length > 0) {
                    removeTag(prefix, tags.length - 1);
                }
            });
            
            // 외부 클릭 시 드롭다운 닫기
            document.addEventListener('click', function(e) {
                if (!wrapper.contains(e.target)) {
                    dropdown.classList.remove('visible');
                }
            });
        }
        
        function addTag(prefix, symbol) {
            var tags = prefix === 'historical' ? historicalTags : newsTags;
            if (tags.indexOf(symbol) !== -1) return; // 중복 방지
            
            tags.push(symbol);
            renderTags(prefix);
        }
        
        function removeTag(prefix, index) {
            var tags = prefix === 'historical' ? historicalTags : newsTags;
            tags.splice(index, 1);
            renderTags(prefix);
        }
        
        function renderTags(prefix) {
            var tags = prefix === 'historical' ? historicalTags : newsTags;
            var wrapper = document.getElementById(prefix + 'TagWrapper');
            var input = document.getElementById(prefix + 'TagInput');
            
            // 기존 태그 제거
            wrapper.querySelectorAll('.tag').forEach(function(t) { t.remove(); });
            
            // 태그 추가
            for (var i = 0; i < tags.length; i++) {
                var tag = document.createElement('span');
                tag.className = 'tag';
                tag.innerHTML = tags[i] + ' <span class="tag-remove" data-index="' + i + '">×</span>';
                wrapper.insertBefore(tag, input);
            }
            
            // 삭제 버튼 이벤트
            wrapper.querySelectorAll('.tag-remove').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    removeTag(prefix, parseInt(btn.dataset.index));
                });
            });
        }
        
        // 토글 함수
        function toggleHistoricalInput() {
            var isSpecific = document.querySelector('input[name="historicalTarget"]:checked').value === 'specific';
            document.getElementById('historicalSymbolsWrapper').style.display = isSpecific ? 'block' : 'none';
        }
        
        function toggleNewsInput() {
            var isSpecific = document.querySelector('input[name="newsTarget"]:checked').value === 'specific';
            document.getElementById('newsSymbolsWrapper').style.display = isSpecific ? 'block' : 'none';
        }
        
        // CSV 동기화
        function checkMissingSymbols() {
            fetch('/admin/missing-symbols')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        document.getElementById('csvCount').textContent = data.csvCount;
                        document.getElementById('dbCount').textContent = data.dbCount;
                        document.getElementById('missingCount').textContent = data.missingCount;
                        
                        if (data.missingCount > 0) {
                            document.getElementById('missingCount').classList.add('warning');
                            document.getElementById('missingCount').classList.remove('success');
                            document.getElementById('missingList').style.display = 'block';
                            
                            var html = '';
                            for (var i = 0; i < data.missingSymbols.length; i++) {
                                html += '<span class="item">' + data.missingSymbols[i].symbol + '</span>';
                            }
                            document.getElementById('missingItems').innerHTML = html;
                        } else {
                            document.getElementById('missingCount').classList.remove('warning');
                            document.getElementById('missingCount').classList.add('success');
                            document.getElementById('missingList').style.display = 'none';
                        }
                    }
                })
                .catch(function(e) {
                    alert('확인 실패: ' + e.message);
                });
        }
        
        function syncCsvToDb() {
            if (!confirm('종목 동기화를 실행하시겠습니까?\n- 누락된 종목 추가\n- 로고 URL 업데이트')) return;
            
            fetch('/admin/sync-csv-to-db', { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        // 결과 표시
                        document.getElementById('syncResult').style.display = 'block';
                        document.getElementById('syncAddedCount').textContent = data.addedCount || 0;
                        document.getElementById('syncUpdatedCount').textContent = data.updatedCount || 0;
                        
                        alert('✅ ' + data.message);
                        checkMissingSymbols();
                    } else {
                        alert('❌ ' + data.message);
                    }
                })
                .catch(function(e) {
                    alert('동기화 실패: ' + e.message);
                });
        }
        
        // WebSocket 연결
        function connectWebSocket() {
            var socket = new SockJS('/ws');
            stompClient = Stomp.over(socket);
            stompClient.debug = null;
            
            stompClient.connect({}, 
                function(frame) {
                    updateWsStatus(true);
                    stompClient.subscribe('/topic/admin/progress', function(message) {
                        handleProgress(JSON.parse(message.body));
                    });
                },
                function(error) {
                    updateWsStatus(false);
                    setTimeout(connectWebSocket, 5000);
                }
            );
        }
        
        function updateWsStatus(connected) {
            wsStatus.className = 'ws-status ' + (connected ? 'connected' : 'disconnected');
            wsStatus.innerHTML = '<div class="ws-dot"></div><span>' + (connected ? '연결됨' : '연결 끊김') + '</span>';
        }
        
        // 수집 시작 버튼 이벤트
        startBtn.addEventListener('click', startCollection);
        document.getElementById('clearLogBtn').addEventListener('click', function() {
            logContainer.innerHTML = '';
        });
        
        function startCollection() {
            if (isCollecting) return;
            
            var isSpecific = document.querySelector('input[name="historicalTarget"]:checked').value === 'specific';
            var symbols = isSpecific ? historicalTags.join(',') : '';
            
            if (isSpecific && historicalTags.length === 0) {
                alert('종목을 선택해주세요.');
                return;
            }
            
            var url = '/admin/collect-historical?days=' + selectedDays;
            if (symbols) url += '&symbols=' + encodeURIComponent(symbols);
            
            fetch(url, { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        isCollecting = true;
                        startTime = Date.now();
                        startBtn.disabled = true;
                        startBtn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                        progressSection.classList.add('visible');
                        resultSection.classList.remove('visible');
                        logContainer.innerHTML = '';
                    } else {
                        alert(data.message);
                    }
                })
                .catch(function(e) {
                    alert('수집 시작 실패');
                });
        }
        
        function handleProgress(data) {
            if (data.type === 'progress') {
                var percent = Math.round((data.current / data.total) * 100);
                progressBar.style.width = percent + '%';
                progressText.textContent = data.current + ' / ' + data.total + ' 종목';
                progressPercent.textContent = percent + '%';
                
                var symbolSpan = currentSymbol.querySelector('.symbol');
                var statusSpan = currentSymbol.querySelector('.status');
                symbolSpan.textContent = data.symbol;
                
                if (data.status === 'processing') {
                    statusSpan.textContent = data.message;
                    statusSpan.className = 'status';
                } else if (data.status === 'success') {
                    statusSpan.textContent = '✅ ' + data.candleCount + ' candles';
                    statusSpan.className = 'status success';
                } else {
                    statusSpan.textContent = '❌ ' + data.message;
                    statusSpan.className = 'status failed';
                }
                
                if (data.current > 0 && startTime) {
                    var elapsed = Date.now() - startTime;
                    var avgTime = elapsed / data.current;
                    var remaining = (data.total - data.current) * avgTime;
                    etaText.textContent = '예상 남은 시간: ' + formatTime(remaining);
                }
                
                if (data.status === 'success' || data.status === 'failed') {
                    addLogEntry(data.symbol, data.status, data.status === 'success' ? data.candleCount + ' candles' : data.message);
                }
            } else if (data.type === 'complete') {
                handleComplete(data);
            } else if (data.type === 'error') {
                alert(data.message);
                resetUI();
            }
        }
        
        function handleComplete(data) {
            isCollecting = false;
            resetUI();
            progressSection.classList.remove('visible');
            resultSection.classList.add('visible');
            
            document.getElementById('resultSuccess').textContent = data.successCount;
            document.getElementById('resultFailed').textContent = data.failedCount;
            document.getElementById('resultCandles').textContent = data.totalCandles.toLocaleString();
            document.getElementById('resultDuration').textContent = data.duration;
            
            var failedList = document.getElementById('failedList');
            var failedItems = document.getElementById('failedListItems');
            
            if (data.failedSymbols && data.failedSymbols.length > 0) {
                failedList.style.display = 'block';
                var html = '';
                for (var i = 0; i < data.failedSymbols.length; i++) {
                    html += '<span class="failed-item">' + data.failedSymbols[i] + '</span>';
                }
                failedItems.innerHTML = html;
            } else {
                failedList.style.display = 'none';
            }
        }
        
        function resetUI() {
            startBtn.disabled = false;
            startBtn.innerHTML = '<span>🚀</span><span>수집 시작</span>';
        }
        
        function addLogEntry(symbol, status, message) {
            var now = new Date();
            var time = now.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
            var entry = document.createElement('div');
            entry.className = 'log-entry ' + status;
            entry.innerHTML = '<span class="time">[' + time + ']</span><span class="symbol">' + symbol + '</span><span class="message">' + message + '</span>';
            logContainer.appendChild(entry);
            logContainer.scrollTop = logContainer.scrollHeight;
        }
        
        function formatTime(ms) {
            var seconds = Math.floor(ms / 1000);
            var minutes = Math.floor(seconds / 60);
            var secs = seconds % 60;
            return minutes > 0 ? minutes + '분 ' + secs + '초' : secs + '초';
        }
        
        // 수집 상태 확인
        function checkCollectionStatus() {
            fetch('/admin/historical-collection-status')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.isCollecting) {
                        isCollecting = true;
                        startTime = Date.now();
                        startBtn.disabled = true;
                        startBtn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                        progressSection.classList.add('visible');
                    }
                });
            
            fetch('/admin/news-collection-status')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.isCollecting) {
                        isNewsCollecting = true;
                        var btn = document.getElementById('newsCollectBtn');
                        btn.disabled = true;
                        btn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                        document.getElementById('newsProgressSection').style.display = 'block';
                        updateNewsProgress(data);
                        newsPollingInterval = setInterval(pollNewsStatus, 2000);
                    }
                });
        }
        
        // 뉴스 수집
        var isNewsCollecting = false;
        var newsPollingInterval = null;
        
        function startNewsCollection() {
            if (isNewsCollecting) {
                alert('이미 뉴스 수집이 진행 중입니다.');
                return;
            }
            
            var isSpecific = document.querySelector('input[name="newsTarget"]:checked').value === 'specific';
            var symbols = isSpecific ? newsTags.join(',') : '';
            
            if (isSpecific && newsTags.length === 0) {
                alert('종목을 선택해주세요.');
                return;
            }
            
            var url = '/admin/collect-news?count=' + selectedNewsCount;
            if (symbols) url += '&symbols=' + encodeURIComponent(symbols);
            
            fetch(url, { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        isNewsCollecting = true;
                        var btn = document.getElementById('newsCollectBtn');
                        btn.disabled = true;
                        btn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
                        document.getElementById('newsProgressSection').style.display = 'block';
                        newsPollingInterval = setInterval(pollNewsStatus, 2000);
                    } else {
                        alert(data.message);
                    }
                })
                .catch(function(e) {
                    alert('뉴스 수집 시작 실패');
                });
        }
        
        function pollNewsStatus() {
            fetch('/admin/news-collection-status')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    updateNewsProgress(data);
                    if (!data.isCollecting) {
                        clearInterval(newsPollingInterval);
                        isNewsCollecting = false;
                        var btn = document.getElementById('newsCollectBtn');
                        btn.disabled = false;
                        btn.innerHTML = '<span>📰</span><span>뉴스 수집 시작</span>';
                        if (data.status.indexOf('✅') !== -1) {
                            alert('뉴스 수집이 완료되었습니다!');
                        }
                    }
                });
        }
        
        function updateNewsProgress(data) {
            document.getElementById('newsStatusText').textContent = data.status;
            if (data.total > 0) {
                var percent = Math.round((data.progress / data.total) * 100);
                document.getElementById('newsProgressText').textContent = data.progress + ' / ' + data.total + ' 기사';
                document.getElementById('newsProgressPercent').textContent = percent + '%';
                document.getElementById('newsProgressBar').style.width = percent + '%';
            } else {
                document.getElementById('newsProgressText').textContent = data.status;
                document.getElementById('newsProgressPercent').textContent = '';
            }
        }
        
        // 재무 데이터
        function collectFinancialData() {
            var resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 재무 데이터 수집 시작 중...';
            
            fetch('/admin/collect-financial-data', { method: 'POST' })
                .then(function(r) { return r.text(); })
                .then(function(data) { resultDiv.textContent = data; })
                .catch(function(e) { resultDiv.textContent = '❌ 오류: ' + e; });
        }
        
        function loadLatestFinancialData() {
            var resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 최신 재무 데이터 로드 중...';
            
            fetch('/admin/load-latest-financial-data', { method: 'POST' })
                .then(function(r) { return r.text(); })
                .then(function(data) { resultDiv.textContent = data; })
                .catch(function(e) { resultDiv.textContent = '❌ 오류: ' + e; });
        }
        
        function loadSelectedFinancialData() {
            var fileName = document.getElementById('jsonFileSelect').value;
            if (!fileName) {
                alert('JSON 파일을 선택해주세요.');
                return;
            }
            
            var resultDiv = document.getElementById('financialResult');
            resultDiv.style.display = 'block';
            resultDiv.textContent = '🔄 ' + fileName + ' 로드 중...';
            
            fetch('/admin/load-financial-data?jsonFileName=' + encodeURIComponent(fileName), { method: 'POST' })
                .then(function(r) { return r.text(); })
                .then(function(data) { resultDiv.textContent = data; })
                .catch(function(e) { resultDiv.textContent = '❌ 오류: ' + e; });
        }
        
        // 뉴스 스케줄러 토글
        function toggleNewsScheduler() {
            var badge = document.getElementById('schedulerBadge');
            var btn = document.getElementById('schedulerToggleBtn');
            var isCurrentlyEnabled = badge.textContent.trim() === 'ON';
            var newEnabled = !isCurrentlyEnabled;
            
            fetch('/admin/news-scheduler-toggle?enabled=' + newEnabled, { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        badge.textContent = data.enabled ? 'ON' : 'OFF';
                        badge.className = 'badge ' + (data.enabled ? 'badge-success' : 'badge-warning');
                        btn.textContent = data.enabled ? '⏸️ 일시정지' : '▶️ 활성화';
                        btn.className = 'btn-secondary' + (data.enabled ? '' : ' btn-warning');
                        refreshNewsLogs();
                    }
                })
                .catch(function(e) {
                    alert('스케줄러 토글 실패: ' + e);
                });
        }
        
        // 뉴스 로그 새로고침
        function refreshNewsLogs() {
            fetch('/admin/news-collection-status')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    var container = document.getElementById('newsLogContainer');
                    if (data.logs && data.logs.length > 0) {
                        var html = '';
                        for (var i = 0; i < data.logs.length; i++) {
                            html += '<div class="news-log-entry">' + data.logs[i] + '</div>';
                        }
                        container.innerHTML = html;
                    } else {
                        container.innerHTML = '<div class="news-log-entry" style="color: #787b86;">로그가 없습니다.</div>';
                    }
                    
                    // 상태 업데이트
                    document.getElementById('lastCollectionCount').textContent = data.lastCollectionCount || 0;
                    if (data.lastCollectionTime) {
                        document.getElementById('lastCollectionTime').textContent = data.lastCollectionTime;
                    }
                });
        }
        
        // ========================================
        // 날짜별 뉴스 수집 (달력)
        // ========================================
        var scannedDates = {}; // { '2025-12-25': { total: 45, saved: 20, unsaved: 25 } }
        var selectedDate = null;
        var currentMonth = new Date();
        var isDateCollecting = false;
        var datePollingInterval = null;
        
        // URL 스캔 시작
        function scanNewsUrls() {
            var btn = document.getElementById('scanUrlsBtn');
            btn.disabled = true;
            btn.textContent = '⚙️ 스캔 중...';
            
            fetch('/admin/scan-news-urls', { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        // 폴링으로 상태 확인
                        var pollInterval = setInterval(function() {
                            fetch('/admin/scanned-news-summary')
                                .then(function(r) { return r.json(); })
                                .then(function(summary) {
                                    if (!summary.isCollecting) {
                                        clearInterval(pollInterval);
                                        btn.disabled = false;
                                        btn.textContent = '🔍 URL 스캔';
                                        loadScannedData(summary);
                                    } else {
                                        btn.textContent = '⚙️ ' + summary.status;
                                    }
                                });
                        }, 2000);
                    } else {
                        alert(data.message);
                        btn.disabled = false;
                        btn.textContent = '🔍 URL 스캔';
                    }
                })
                .catch(function(e) {
                    alert('URL 스캔 실패: ' + e);
                    btn.disabled = false;
                    btn.textContent = '🔍 URL 스캔';
                });
        }
        
        // 스캔 데이터 로드
        function loadScannedData(summary) {
            if (summary.scanTimestamp) {
                document.getElementById('scanTimestamp').textContent = summary.scanTimestamp;
            }
            
            scannedDates = summary.dates || {};
            
            if (Object.keys(scannedDates).length > 0) {
                document.getElementById('calendarContainer').style.display = 'block';
                renderCalendar();
            }
        }
        
        // 페이지 로드 시 스캔 데이터 확인
        function checkScannedData() {
            fetch('/admin/scanned-news-summary')
                .then(function(r) { return r.json(); })
                .then(function(summary) {
                    if (summary.success && summary.dates && Object.keys(summary.dates).length > 0) {
                        loadScannedData(summary);
                    }
                });
        }
        
        // 달력 렌더링
        function renderCalendar() {
            var year = currentMonth.getFullYear();
            var month = currentMonth.getMonth();
            
            // 헤더 업데이트
            var monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
            document.getElementById('calendarTitle').textContent = year + '년 ' + monthNames[month];
            
            // 그리드 초기화
            var grid = document.getElementById('calendarGrid');
            var headers = grid.querySelectorAll('.calendar-day-header');
            grid.innerHTML = '';
            headers.forEach(function(h) { grid.appendChild(h); });
            
            // 첫날 요일과 마지막 날
            var firstDay = new Date(year, month, 1).getDay();
            var lastDate = new Date(year, month + 1, 0).getDate();
            
            // 오늘 날짜
            var today = new Date();
            var todayStr = today.toISOString().split('T')[0];
            
            // 빈 칸 추가
            for (var i = 0; i < firstDay; i++) {
                var emptyCell = document.createElement('div');
                emptyCell.className = 'calendar-day empty';
                grid.appendChild(emptyCell);
            }
            
            // 날짜 칸 추가
            for (var day = 1; day <= lastDate; day++) {
                var dateStr = year + '-' + String(month + 1).padStart(2, '0') + '-' + String(day).padStart(2, '0');
                var dateData = scannedDates[dateStr];
                
                var cell = document.createElement('div');
                cell.className = 'calendar-day';
                cell.dataset.date = dateStr;
                
                // 오늘인지 확인
                if (dateStr === todayStr) {
                    cell.classList.add('today');
                }
                
                // 날짜 번호
                var dayNum = document.createElement('div');
                dayNum.className = 'day-number';
                dayNum.textContent = day;
                cell.appendChild(dayNum);
                
                if (dateData) {
                    // 뉴스 개수
                    var countDiv = document.createElement('div');
                    countDiv.className = 'news-count has-news';
                    countDiv.textContent = dateData.total + '개';
                    cell.appendChild(countDiv);
                    
                    // 저장된 개수
                    if (dateData.saved > 0) {
                        var savedDiv = document.createElement('div');
                        savedDiv.className = 'saved-badge';
                        savedDiv.textContent = '저장: ' + dateData.saved;
                        cell.appendChild(savedDiv);
                    }
                    
                    // 클릭 이벤트
                    cell.addEventListener('click', function() {
                        selectDate(this.dataset.date);
                    });
                } else {
                    cell.classList.add('disabled');
                    var noNews = document.createElement('div');
                    noNews.className = 'news-count no-news';
                    noNews.textContent = '-';
                    cell.appendChild(noNews);
                }
                
                // 선택된 날짜인지 확인
                if (selectedDate === dateStr) {
                    cell.classList.add('selected');
                }
                
                grid.appendChild(cell);
            }
        }
        
        // 월 변경
        function changeMonth(delta) {
            currentMonth.setMonth(currentMonth.getMonth() + delta);
            renderCalendar();
        }
        
        // 날짜 선택
        function selectDate(dateStr) {
            selectedDate = dateStr;
            var dateData = scannedDates[dateStr];
            
            // 달력 업데이트
            renderCalendar();
            
            // 선택 정보 표시
            var infoDiv = document.getElementById('selectedDateInfo');
            infoDiv.classList.add('visible');
            
            var parts = dateStr.split('-');
            document.getElementById('selectedDateTitle').textContent = 
                parts[0] + '년 ' + parseInt(parts[1]) + '월 ' + parseInt(parts[2]) + '일';
            
            document.getElementById('selectedTotal').textContent = dateData.total;
            document.getElementById('selectedSaved').textContent = dateData.saved;
            document.getElementById('selectedUnsaved').textContent = dateData.unsaved;
            
            // 버튼 활성화
            var btn = document.getElementById('collectByDateBtn');
            if (dateData.unsaved > 0) {
                btn.disabled = false;
                btn.innerHTML = '<span>📅</span><span>' + dateStr + ' 뉴스 ' + dateData.unsaved + '개 수집</span>';
            } else {
                btn.disabled = true;
                btn.innerHTML = '<span>✅</span><span>모든 뉴스가 이미 저장됨</span>';
            }
        }
        
        // 날짜별 뉴스 수집
        function collectNewsByDate() {
            if (!selectedDate || isDateCollecting) return;
            
            var dateData = scannedDates[selectedDate];
            if (!confirm(selectedDate + ' 뉴스 ' + dateData.unsaved + '개를 수집하시겠습니까?')) return;
            
            isDateCollecting = true;
            var btn = document.getElementById('collectByDateBtn');
            btn.disabled = true;
            btn.innerHTML = '<span>⏳</span><span>수집 중...</span>';
            document.getElementById('dateCollectProgress').style.display = 'block';
            
            fetch('/admin/collect-news-by-date?date=' + selectedDate, { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        // 폴링으로 상태 확인
                        datePollingInterval = setInterval(pollDateCollectionStatus, 2000);
                    } else {
                        alert(data.message);
                        resetDateCollectUI();
                    }
                })
                .catch(function(e) {
                    alert('수집 시작 실패: ' + e);
                    resetDateCollectUI();
                });
        }
        
        // 날짜별 수집 상태 폴링
        function pollDateCollectionStatus() {
            fetch('/admin/scanned-news-summary')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    document.getElementById('dateStatusText').textContent = data.status;
                    
                    if (!data.isCollecting) {
                        clearInterval(datePollingInterval);
                        isDateCollecting = false;
                        
                        // 스캔 데이터 재로드
                        loadScannedData(data);
                        
                        if (data.status.indexOf('Complete') !== -1) {
                            alert('뉴스 수집이 완료되었습니다!');
                        }
                        
                        resetDateCollectUI();
                        
                        // 선택된 날짜 정보 업데이트
                        if (selectedDate && scannedDates[selectedDate]) {
                            selectDate(selectedDate);
                        }
                    }
                });
        }
        
        // UI 초기화
        function resetDateCollectUI() {
            isDateCollecting = false;
            var btn = document.getElementById('collectByDateBtn');
            
            if (selectedDate && scannedDates[selectedDate]) {
                var dateData = scannedDates[selectedDate];
                if (dateData.unsaved > 0) {
                    btn.disabled = false;
                    btn.innerHTML = '<span>📅</span><span>' + selectedDate + ' 뉴스 ' + dateData.unsaved + '개 수집</span>';
                } else {
                    btn.disabled = true;
                    btn.innerHTML = '<span>✅</span><span>모든 뉴스가 이미 저장됨</span>';
                }
            } else {
                btn.disabled = true;
                btn.innerHTML = '<span>📅</span><span>선택한 날짜 뉴스 수집</span>';
            }
            
            document.getElementById('dateCollectProgress').style.display = 'none';
        }
        
    </script>
</body>
</html>
