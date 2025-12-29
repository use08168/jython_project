<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>News Feed - The Salty Spitoon</title>
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

        /* 메인 레이아웃 */
        .main-layout { display: flex; max-width: 1600px; margin: 0 auto; padding: 24px 32px; gap: 24px; }
        
        /* 왼쪽 사이드바 - Watchlist */
        .sidebar-left { width: 280px; flex-shrink: 0; }
        .sidebar-card { background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; padding: 20px; position: sticky; top: 80px; margin-top: 58px;}
        .sidebar-card h3 { font-size: 16px; font-weight: 600; margin-bottom: 16px; display: flex; align-items: center; gap: 8px; }
        .watchlist-item { display: flex; align-items: center; gap: 12px; padding: 12px 8px; border-radius: 8px; cursor: pointer; transition: all 0.2s; margin-bottom: 4px; }
        .watchlist-item:hover { background-color: #252b3d; }
        .watchlist-logo { width: 80px; height: 32px; border-radius: 6px; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; padding: 4px; flex-shrink: 0; }
        .watchlist-logo img { max-width: 100%; max-height: 100%; object-fit: contain; }
        .watchlist-info { flex: 1; min-width: 0; }
        .watchlist-symbol { font-size: 14px; font-weight: 600; }
        .watchlist-name { font-size: 11px; color: #6b7280; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .watchlist-empty { text-align: center; padding: 30px 10px; color: #6b7280; font-size: 13px; }
        .watchlist-empty a { color: #3b82f6; }

        /* 메인 컨텐츠 */
        .main-content { flex: 1; min-width: 0; }

        /* 페이지 헤더 */
        .page-header { text-align: center; margin-bottom: 24px; }
        .page-header h1 { font-size: 24px; font-weight: 700; }

        /* 컨트롤 패널 */
        .controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px 20px; background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; flex-wrap: wrap; gap: 16px; }
        .sort-options { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .sort-label { font-size: 13px; color: #6b7280; margin-right: 4px; }
        .sort-btn { padding: 8px 14px; background: #252b3d; border: 1px solid #374151; border-radius: 6px; color: #9ca3af; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.2s; display: flex; align-items: center; gap: 6px; }
        .sort-btn:hover { background: #374151; color: #ffffff; }
        .sort-btn.active { background: #3b82f6; border-color: #3b82f6; color: #ffffff; }
        .sort-btn svg { width: 14px; height: 14px; }
        .news-count { font-size: 13px; color: #6b7280; }
        .news-count span { color: #d1d5db; font-weight: 600; }

        /* 뉴스 그리드 */
        .news-grid { display: flex; flex-direction: column; gap: 16px; }

        /* 큰 카드 (Watchlist 종목) */
        .news-card-large { background: #1a1f2e; border-radius: 16px; border: 1px solid #252b3d; overflow: hidden; }
        .news-card-large-header { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-bottom: 1px solid #252b3d; }
        .news-card-large-symbol { font-size: 20px; font-weight: 700; color: #3b82f6; }
        .news-card-large-badge { padding: 4px 10px; background: rgba(59, 130, 246, 0.15); color: #3b82f6; border-radius: 6px; font-size: 12px; font-weight: 500; }
        .news-card-large-body { display: grid; grid-template-columns: 1fr 1fr; gap: 0; }
        .news-card-chart { padding: 20px; border-right: 1px solid #252b3d; }
        .news-card-chart-container { height: 200px; }
        .news-card-highlight { padding: 20px; display: flex; flex-direction: column; }
        .news-highlight-title { font-size: 16px; font-weight: 600; line-height: 1.5; margin-bottom: 12px; cursor: pointer; transition: color 0.2s; }
        .news-highlight-title:hover { color: #3b82f6; }
        .news-highlight-content { font-size: 13px; color: #9ca3af; line-height: 1.6; flex: 1; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 5; -webkit-box-orient: vertical; }
        .news-highlight-meta { display: flex; align-items: center; gap: 8px; margin-top: 12px; font-size: 12px; color: #6b7280; }
        .news-card-list { border-top: 1px solid #252b3d; max-height: 200px; overflow-y: auto; }
        .news-card-list::-webkit-scrollbar { width: 6px; }
        .news-card-list::-webkit-scrollbar-track { background: #1a1f2e; }
        .news-card-list::-webkit-scrollbar-thumb { background: #374151; border-radius: 3px; }
        .news-list-item { display: flex; align-items: center; gap: 12px; padding: 12px 20px; border-bottom: 1px solid #252b3d; cursor: pointer; transition: background 0.2s; }
        .news-list-item:last-child { border-bottom: none; }
        .news-list-item:hover { background: #252b3d; }
        .news-list-thumb { width: 60px; height: 40px; border-radius: 6px; object-fit: cover; background: #252b3d; flex-shrink: 0; }
        .news-list-info { flex: 1; min-width: 0; }
        .news-list-title { font-size: 13px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .news-list-time { font-size: 11px; color: #6b7280; margin-top: 4px; }
        .news-list-bookmark { padding: 6px; border-radius: 4px; background: transparent; border: none; color: #6b7280; cursor: pointer; transition: all 0.2s; }
        .news-list-bookmark:hover { color: #f59e0b; background: rgba(245, 158, 11, 0.1); }
        .news-list-bookmark.active { color: #f59e0b; }

        /* 작은 카드 (비 Watchlist 종목) */
        .news-card-small { background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; overflow: hidden; }
        .news-card-small-header { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; border-bottom: 1px solid #252b3d; }
        .news-card-small-symbol { font-size: 14px; font-weight: 600; color: #9ca3af; }
        .news-card-small-count { font-size: 12px; color: #6b7280; }
        .news-card-small-list { max-height: 150px; overflow-y: auto; }
        .news-card-small-list::-webkit-scrollbar { width: 4px; }
        .news-card-small-list::-webkit-scrollbar-track { background: #1a1f2e; }
        .news-card-small-list::-webkit-scrollbar-thumb { background: #374151; border-radius: 2px; }
        .news-small-item { padding: 10px 16px; border-bottom: 1px solid #252b3d; cursor: pointer; transition: background 0.2s; }
        .news-small-item:last-child { border-bottom: none; }
        .news-small-item:hover { background: #252b3d; }
        .news-small-title { font-size: 12px; font-weight: 500; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .news-small-time { font-size: 10px; color: #6b7280; margin-top: 4px; }

        /* 작은 카드 그리드 */
        .news-small-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }

        /* 더보기 버튼 */
        .load-more-section { text-align: center; margin-top: 24px; }
        .load-more-btn { padding: 14px 48px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); border: none; border-radius: 10px; color: #ffffff; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
        .load-more-btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .load-more-btn:disabled { background: #374151; cursor: not-allowed; transform: none; box-shadow: none; }

        /* 오른쪽 사이드바 - 달력 */
        .sidebar-right { width: 300px; flex-shrink: 0; }
        .calendar-card { background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; padding: 20px; position: sticky; top: 80px; margin-top: 58px;}
        .calendar-card h3 { font-size: 16px; font-weight: 600; margin-bottom: 16px; }
        .calendar-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .calendar-month { font-size: 16px; font-weight: 600; }
        .calendar-nav { display: flex; gap: 8px; }
        .calendar-nav button { width: 28px; height: 28px; border-radius: 6px; background: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .calendar-nav button:hover { background: #374151; color: #ffffff; }
        .calendar-weekdays { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; margin-bottom: 8px; }
        .calendar-weekday { text-align: center; font-size: 11px; color: #6b7280; font-weight: 500; padding: 8px 0; }
        .calendar-days { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
        .calendar-day { aspect-ratio: 1; display: flex; align-items: center; justify-content: center; font-size: 13px; border-radius: 8px; cursor: pointer; transition: all 0.2s; position: relative; }
        .calendar-day.empty { cursor: default; }
        .calendar-day.has-news { background: #252b3d; color: #ffffff; font-weight: 500; }
        .calendar-day.no-news { background: transparent; color: #4b5563; }
        .calendar-day.has-news:hover { background: #374151; }
        .calendar-day.selected { background: #3b82f6 !important; color: #ffffff; }
        .calendar-day.today { border: 2px solid #3b82f6; }
        .calendar-day .news-dot { position: absolute; bottom: 4px; left: 50%; transform: translateX(-50%); width: 4px; height: 4px; border-radius: 50%; background: #22c55e; }

        /* 빈 상태 */
        .empty-state { text-align: center; padding: 60px 20px; color: #6b7280; }
        .empty-state svg { width: 64px; height: 64px; margin-bottom: 16px; opacity: 0.3; }
        .empty-state h3 { font-size: 18px; color: #9ca3af; margin-bottom: 8px; }

        /* 로딩 */
        .loading { text-align: center; padding: 60px 20px; color: #6b7280; }
        .loading-spinner { width: 40px; height: 40px; border: 3px solid #252b3d; border-top-color: #3b82f6; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* 반응형 */
        @media (max-width: 1400px) {
            .sidebar-right { width: 260px; }
            .news-small-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 1200px) {
            .sidebar-left { display: none; }
        }
        @media (max-width: 1000px) {
            .sidebar-right { display: none; }
            .news-card-large-body { grid-template-columns: 1fr; }
            .news-card-chart { border-right: none; border-bottom: 1px solid #252b3d; }
        }
        @media (max-width: 768px) {
            .main-layout { padding: 16px; }
            .news-small-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <!-- 네비게이션 -->
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/></svg>
            The Salty Spitoon
        </a>
        <div class="navbar-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
            <input type="text" id="searchInput" placeholder="Search news..." oninput="filterNews()">
        </div>
        <div class="navbar-menu">
            <a href="/dashboard">Market</a>
            <a href="/stock">Stocks</a>
            <a href="/watchlist">Watchlist</a>
            <a href="/news" class="active">News</a>
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

    <div class="main-layout">
        <!-- 왼쪽 사이드바 - My Watchlist -->
        <aside class="sidebar-left">
            <div class="sidebar-card">
                <h3>📋 My Watchlist</h3>
                <div id="watchlist-container">
                    <div class="loading">
                        <div class="loading-spinner"></div>
                    </div>
                </div>
            </div>
        </aside>

        <!-- 메인 컨텐츠 -->
        <main class="main-content">
            <!-- 페이지 헤더 -->
            <div class="page-header">
                <h1 id="page-title">오늘의 뉴스 기사</h1>
            </div>

            <!-- 컨트롤 패널 -->
            <div class="controls">
                <div class="sort-options">
                    <span class="sort-label">Sort by:</span>
                    <button class="sort-btn active" data-sort="latest" onclick="sortNews('latest')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
                        Latest
                    </button>
                    <button class="sort-btn" data-sort="watchlist" onclick="sortNews('watchlist')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                        Watchlist First
                    </button>
                    <button class="sort-btn" data-sort="alpha" onclick="sortNews('alpha')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h12M3 18h6"/></svg>
                        A-Z
                    </button>
                </div>
                <div class="news-count">
                    <span id="newsCount">0</span> articles
                </div>
            </div>

            <!-- 뉴스 그리드 -->
            <div class="news-grid" id="news-container">
                <div class="loading">
                    <div class="loading-spinner"></div>
                    <p>Loading news...</p>
                </div>
            </div>

            <!-- 더보기 버튼 -->
            <div class="load-more-section" id="load-more-section" style="display: none;">
                <button class="load-more-btn" id="load-more-btn" onclick="loadMore()">Load More</button>
            </div>
        </main>

        <!-- 오른쪽 사이드바 - 달력 -->
        <aside class="sidebar-right">
            <div class="calendar-card">
                <h3>📅 날짜 선택</h3>
                <div class="calendar-header">
                    <span class="calendar-month" id="calendar-month"></span>
                    <div class="calendar-nav">
                        <button onclick="changeMonth(-1)">←</button>
                        <button onclick="changeMonth(1)">→</button>
                    </div>
                </div>
                <div class="calendar-weekdays">
                    <div class="calendar-weekday">SUN</div>
                    <div class="calendar-weekday">MON</div>
                    <div class="calendar-weekday">TUE</div>
                    <div class="calendar-weekday">WED</div>
                    <div class="calendar-weekday">THU</div>
                    <div class="calendar-weekday">FRI</div>
                    <div class="calendar-weekday">SAT</div>
                </div>
                <div class="calendar-days" id="calendar-days"></div>
            </div>
        </aside>
    </div>

    <script>
        // ========================================
        // 상태 변수
        // ========================================
        var watchlistSymbols = new Set();
        var watchlistData = [];
        var allNewsData = [];
        var filteredNewsData = [];
        var groupedNews = {};
        var displayedRows = 0;
        var rowsPerPage = 5;
        var currentSort = 'latest';
        var selectedDate = new Date();
        var calendarDate = new Date();
        var datesWithNews = new Set();
        var chartInstances = {};
        var bookmarkedNewsIds = new Set();

        // ========================================
        // 초기화
        // ========================================
        document.addEventListener('DOMContentLoaded', function() {
            loadWatchlist();
            loadBookmarks();
            loadDatesWithNews();
            renderCalendar();
            loadNewsByDate(selectedDate);
        });

        // ========================================
        // Watchlist 로드
        // ========================================
        function loadWatchlist() {
            fetch('/api/watchlist')
                .then(function(r) { return r.status === 401 ? { success: false } : r.json(); })
                .then(function(data) {
                    if (data && data.success && data.data) {
                        watchlistData = data.data;
                        watchlistSymbols = new Set(data.data.map(function(s) { return s.symbol; }));
                        renderWatchlistSidebar();
                    } else {
                        renderWatchlistSidebar();
                    }
                })
                .catch(function() {
                    renderWatchlistSidebar();
                });
        }

        function renderWatchlistSidebar() {
            var container = document.getElementById('watchlist-container');
            
            if (watchlistData.length === 0) {
                container.innerHTML = '<div class="watchlist-empty">No stocks in watchlist.<br><a href="/stock">Browse stocks →</a></div>';
                return;
            }

            var html = '';
            watchlistData.forEach(function(item) {
                html += '<div class="watchlist-item" onclick="location.href=\'/stock/detail/' + item.symbol + '\'">';
                html += '<div class="watchlist-logo">';
                if (item.logoUrl) {
                    html += '<img src="' + item.logoUrl + '" alt="' + item.symbol + '" onerror="this.style.display=\'none\'; this.parentElement.innerHTML=\'<span style=font-size:16px>📈</span>\'">';
                } else {
                    html += '<span style="font-size:16px">📈</span>';
                }
                html += '</div>';
                html += '<div class="watchlist-info">';
                html += '<div class="watchlist-symbol">' + item.symbol + '</div>';
                html += '<div class="watchlist-name">' + (item.name || '') + '</div>';
                html += '</div>';
                html += '</div>';
            });

            container.innerHTML = html;
        }

        // ========================================
        // 북마크 로드
        // ========================================
        function loadBookmarks() {
            fetch('/news/api/bookmarks')
                .then(function(r) { return r.status === 401 ? { success: false } : r.json(); })
                .then(function(data) {
                    if (data && data.success && data.data) {
                        bookmarkedNewsIds = new Set(data.data.map(function(b) { return b.newsId; }));
                    }
                })
                .catch(function() {});
        }

        // ========================================
        // 달력 관련
        // ========================================
        function loadDatesWithNews() {
            var year = calendarDate.getFullYear();
            var month = calendarDate.getMonth() + 1;
            
            fetch('/news/api/datesWithNews?year=' + year + '&month=' + month)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && data.success && data.data) {
                        datesWithNews = new Set(data.data);
                        renderCalendar();
                    }
                })
                .catch(function() {
                    renderCalendar();
                });
        }

        function renderCalendar() {
            var year = calendarDate.getFullYear();
            var month = calendarDate.getMonth();
            var today = new Date();
            
            var monthNames = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
                              'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
            document.getElementById('calendar-month').textContent = monthNames[month] + ' ' + year;

            var firstDay = new Date(year, month, 1).getDay();
            var daysInMonth = new Date(year, month + 1, 0).getDate();
            
            var html = '';
            
            // 빈 칸
            for (var i = 0; i < firstDay; i++) {
                html += '<div class="calendar-day empty"></div>';
            }
            
            // 날짜
            for (var day = 1; day <= daysInMonth; day++) {
                var dateStr = year + '-' + String(month + 1).padStart(2, '0') + '-' + String(day).padStart(2, '0');
                var hasNews = datesWithNews.has(dateStr);
                var isToday = (today.getFullYear() === year && today.getMonth() === month && today.getDate() === day);
                var isSelected = (selectedDate.getFullYear() === year && selectedDate.getMonth() === month && selectedDate.getDate() === day);
                
                var classes = 'calendar-day';
                if (hasNews) classes += ' has-news';
                else classes += ' no-news';
                if (isToday) classes += ' today';
                if (isSelected) classes += ' selected';
                
                html += '<div class="' + classes + '" onclick="selectDate(' + year + ', ' + month + ', ' + day + ', ' + hasNews + ')">';
                html += day;
                if (hasNews) html += '<span class="news-dot"></span>';
                html += '</div>';
            }
            
            document.getElementById('calendar-days').innerHTML = html;
        }

        function changeMonth(delta) {
            calendarDate.setMonth(calendarDate.getMonth() + delta);
            loadDatesWithNews();
        }

        function selectDate(year, month, day, hasNews) {
            if (!hasNews) {
                alert('해당 날짜에는 뉴스 기사가 없습니다.');
                return;
            }
            
            selectedDate = new Date(year, month, day);
            renderCalendar();
            loadNewsByDate(selectedDate);
        }

        // ========================================
        // 뉴스 로드
        // ========================================
        function loadNewsByDate(date) {
            var dateStr = date.getFullYear() + '-' + 
                          String(date.getMonth() + 1).padStart(2, '0') + '-' + 
                          String(date.getDate()).padStart(2, '0');
            
            // 타이틀 업데이트
            var options = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };
            var titleDate = date.toLocaleDateString('ko-KR', options);
            document.getElementById('page-title').textContent = titleDate + ' 뉴스 기사';
            
            document.getElementById('news-container').innerHTML = '<div class="loading"><div class="loading-spinner"></div><p>Loading news...</p></div>';
            
            fetch('/news/api/byDate?date=' + dateStr)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data && data.success) {
                        allNewsData = data.data || [];
                        filteredNewsData = allNewsData.slice();
                        document.getElementById('newsCount').textContent = allNewsData.length;
                        groupNewsBySymbol();
                        displayedRows = 0;
                        applySorting();
                        renderNews();
                    } else {
                        renderEmptyState();
                    }
                })
                .catch(function() {
                    renderEmptyState();
                });
        }

        function groupNewsBySymbol() {
            groupedNews = {};
            filteredNewsData.forEach(function(news) {
                var symbol = news.symbol || 'OTHER';
                if (!groupedNews[symbol]) {
                    groupedNews[symbol] = [];
                }
                groupedNews[symbol].push(news);
            });
            
            // 각 그룹 내에서 최신순 정렬
            Object.keys(groupedNews).forEach(function(symbol) {
                groupedNews[symbol].sort(function(a, b) {
                    return new Date(b.publishedAt) - new Date(a.publishedAt);
                });
            });
        }

        function applySorting() {
            var symbols = Object.keys(groupedNews);
            
            if (currentSort === 'watchlist') {
                symbols.sort(function(a, b) {
                    var aInWatchlist = watchlistSymbols.has(a) ? 0 : 1;
                    var bInWatchlist = watchlistSymbols.has(b) ? 0 : 1;
                    if (aInWatchlist !== bInWatchlist) return aInWatchlist - bInWatchlist;
                    return a.localeCompare(b);
                });
            } else if (currentSort === 'alpha') {
                symbols.sort();
            } else {
                // latest - 가장 최신 뉴스가 있는 종목 먼저
                symbols.sort(function(a, b) {
                    var aInWatchlist = watchlistSymbols.has(a) ? 0 : 1;
                    var bInWatchlist = watchlistSymbols.has(b) ? 0 : 1;
                    if (aInWatchlist !== bInWatchlist) return aInWatchlist - bInWatchlist;
                    
                    var aLatest = new Date(groupedNews[a][0].publishedAt);
                    var bLatest = new Date(groupedNews[b][0].publishedAt);
                    return bLatest - aLatest;
                });
            }
            
            // 정렬된 순서로 재구성
            var sortedGrouped = {};
            symbols.forEach(function(sym) {
                sortedGrouped[sym] = groupedNews[sym];
            });
            groupedNews = sortedGrouped;
        }

        function sortNews(sortType) {
            currentSort = sortType;
            document.querySelectorAll('.sort-btn').forEach(function(btn) {
                btn.classList.toggle('active', btn.getAttribute('data-sort') === sortType);
            });
            
            applySorting();
            displayedRows = 0;
            renderNews();
        }

        function filterNews() {
            var query = document.getElementById('searchInput').value.toLowerCase();
            
            if (query === '') {
                filteredNewsData = allNewsData.slice();
            } else {
                filteredNewsData = allNewsData.filter(function(news) {
                    return news.title.toLowerCase().includes(query) ||
                           (news.symbol && news.symbol.toLowerCase().includes(query));
                });
            }
            
            document.getElementById('newsCount').textContent = filteredNewsData.length;
            groupNewsBySymbol();
            displayedRows = 0;
            applySorting();
            renderNews();
        }

        // ========================================
        // 뉴스 렌더링
        // ========================================
        function renderNews() {
            var container = document.getElementById('news-container');
            var symbols = Object.keys(groupedNews);
            
            if (symbols.length === 0) {
                renderEmptyState();
                return;
            }
            
            // Watchlist 종목과 비 Watchlist 종목 분리
            var watchlistSymbolsList = [];
            var otherSymbolsList = [];
            
            symbols.forEach(function(sym) {
                if (watchlistSymbols.has(sym)) {
                    watchlistSymbolsList.push(sym);
                } else {
                    otherSymbolsList.push(sym);
                }
            });
            
            var html = '';
            var currentRow = 0;
            var maxRows = displayedRows + rowsPerPage;
            
            // Watchlist 종목 (큰 카드) - 각각 1 row
            watchlistSymbolsList.forEach(function(symbol) {
                if (currentRow >= maxRows) return;
                html += renderLargeCard(symbol, groupedNews[symbol]);
                currentRow++;
            });
            
            // 비 Watchlist 종목 (작은 카드 그리드) - 3개당 1 row
            var smallCards = [];
            otherSymbolsList.forEach(function(symbol) {
                smallCards.push({ symbol: symbol, news: groupedNews[symbol] });
            });
            
            for (var i = 0; i < smallCards.length; i += 3) {
                if (currentRow >= maxRows) break;
                
                html += '<div class="news-small-grid">';
                for (var j = i; j < Math.min(i + 3, smallCards.length); j++) {
                    html += renderSmallCard(smallCards[j].symbol, smallCards[j].news);
                }
                html += '</div>';
                currentRow++;
            }
            
            container.innerHTML = html;
            displayedRows = currentRow;
            
            // 총 row 수 계산
            var totalRows = watchlistSymbolsList.length + Math.ceil(smallCards.length / 3);
            updateLoadMoreButton(totalRows);
            
            // 차트 로드
            watchlistSymbolsList.forEach(function(symbol) {
                if (currentRow <= maxRows) {
                    loadChart(symbol);
                }
            });
        }

        function renderLargeCard(symbol, newsList) {
            var latestNews = newsList[0];
            var content = latestNews.fullContent || latestNews.summary || '내용이 없습니다.';
            
            // Watchlist에서 로고 URL 찾기
            var watchlistItem = watchlistData.find(function(w) { return w.symbol === symbol; });
            var logoUrl = watchlistItem ? watchlistItem.logoUrl : null;
            var stockName = watchlistItem ? watchlistItem.name : '';
            
            var html = '<div class="news-card-large">';
            html += '<div class="news-card-large-header">';
            html += '<div style="display:flex; align-items:center; gap:12px; cursor:pointer;" onclick="location.href=\'/stock/detail/' + symbol + '\'">';
            if (logoUrl) {
                html += '<div style="width:80px; height:40px; background:#fff; border-radius:6px; display:flex; align-items:center; justify-content:center; padding:4px; overflow:hidden;">';
                html += '<img src="' + logoUrl + '" style="max-width:100%; max-height:100%; object-fit:contain;" onerror="this.parentElement.innerHTML=\'<span style=font-size:16px>📈</span>\'">';
                html += '</div>';
            }
            html += '<div>';
            html += '<span class="news-card-large-symbol">' + symbol + '</span>';
            if (stockName) {
                html += '<div style="font-size:12px; color:#6b7280; margin-top:2px;">' + escapeHtml(stockName) + '</div>';
            }
            html += '</div>';
            html += '</div>';
            html += '<span class="news-card-large-badge">' + newsList.length + ' articles</span>';
            html += '</div>';
            
            html += '<div class="news-card-large-body">';
            
            // 차트
            html += '<div class="news-card-chart">';
            html += '<div class="news-card-chart-container" id="chart-' + symbol + '"></div>';
            html += '</div>';
            
            // 하이라이트 뉴스
            html += '<div class="news-card-highlight">';
            html += '<div class="news-highlight-title" onclick="location.href=\'/news/detail/' + latestNews.id + '\'">' + escapeHtml(latestNews.title) + '</div>';
            html += '<div class="news-highlight-content">' + escapeHtml(content.substring(0, 300)) + '...</div>';
            html += '<div class="news-highlight-meta">';
            html += '<span>' + formatTime(latestNews.publishedAt) + '</span>';
            if (latestNews.publisher) {
                html += '<span>• ' + escapeHtml(latestNews.publisher) + '</span>';
            }
            html += '</div>';
            html += '</div>';
            
            html += '</div>';
            
            // 뉴스 리스트 (2번째부터)
            if (newsList.length > 1) {
                html += '<div class="news-card-list">';
                for (var i = 1; i < newsList.length; i++) {
                    html += renderNewsListItem(newsList[i]);
                }
                html += '</div>';
            }
            
            html += '</div>';
            return html;
        }

        function renderSmallCard(symbol, newsList) {
            var html = '<div class="news-card-small">';
            html += '<div class="news-card-small-header">';
            html += '<span class="news-card-small-symbol">' + symbol + '</span>';
            html += '<span class="news-card-small-count">' + newsList.length + '</span>';
            html += '</div>';
            
            html += '<div class="news-card-small-list">';
            newsList.forEach(function(news) {
                html += '<div class="news-small-item" onclick="location.href=\'/news/detail/' + news.id + '\'">';
                html += '<div class="news-small-title">' + escapeHtml(news.title) + '</div>';
                html += '<div class="news-small-time">' + formatTime(news.publishedAt) + '</div>';
                html += '</div>';
            });
            html += '</div>';
            
            html += '</div>';
            return html;
        }

        function renderNewsListItem(news) {
            var isBookmarked = bookmarkedNewsIds.has(news.id);
            
            var html = '<div class="news-list-item" onclick="location.href=\'/news/detail/' + news.id + '\'">';
            if (news.thumbnailUrl) {
                html += '<img src="' + news.thumbnailUrl + '" class="news-list-thumb" onerror="this.style.display=\'none\'">';
            }
            html += '<div class="news-list-info">';
            html += '<div class="news-list-title">' + escapeHtml(news.title) + '</div>';
            html += '<div class="news-list-time">' + formatTime(news.publishedAt) + '</div>';
            html += '</div>';
            html += '<button class="news-list-bookmark ' + (isBookmarked ? 'active' : '') + '" onclick="event.stopPropagation(); toggleBookmark(' + news.id + ', this)">';
            html += '<svg width="16" height="16" viewBox="0 0 24 24" fill="' + (isBookmarked ? 'currentColor' : 'none') + '" stroke="currentColor" stroke-width="2"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>';
            html += '</button>';
            html += '</div>';
            return html;
        }

        function renderEmptyState() {
            document.getElementById('news-container').innerHTML = 
                '<div class="empty-state">' +
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/></svg>' +
                '<h3>뉴스가 없습니다</h3>' +
                '<p>해당 날짜에 수집된 뉴스가 없습니다.</p>' +
                '</div>';
            document.getElementById('load-more-section').style.display = 'none';
        }

        function updateLoadMoreButton(totalRows) {
            var section = document.getElementById('load-more-section');
            var btn = document.getElementById('load-more-btn');
            
            if (displayedRows < totalRows) {
                section.style.display = 'block';
                btn.disabled = false;
                btn.textContent = 'Load More';
            } else {
                section.style.display = 'none';
            }
        }

        function loadMore() {
            renderNews();
        }

        // ========================================
        // 차트 로드
        // ========================================
        function loadChart(symbol) {
            var container = document.getElementById('chart-' + symbol);
            if (!container) return;
            
            // 기존 차트 제거
            if (chartInstances[symbol]) {
                chartInstances[symbol].remove();
            }
            
            var chart = LightweightCharts.createChart(container, {
                width: container.clientWidth,
                height: 200,
                layout: { background: { type: 'solid', color: 'transparent' }, textColor: '#9ca3af' },
                grid: { vertLines: { color: '#252b3d' }, horzLines: { color: '#252b3d' } },
                rightPriceScale: { borderColor: '#252b3d' },
                timeScale: { borderColor: '#252b3d', timeVisible: true }
            });
            
            chartInstances[symbol] = chart;
            
            var areaSeries = chart.addAreaSeries({
                topColor: 'rgba(59, 130, 246, 0.4)',
                bottomColor: 'rgba(59, 130, 246, 0.0)',
                lineColor: '#3b82f6',
                lineWidth: 2
            });
            
            // 1시간봉 최근 7일 데이터
            fetch('/stock/api/chart/' + symbol + '/all?timeframe=1h')
                .then(function(r) { return r.json(); })
                .then(function(response) {
                    if (response.data && response.data.length > 0) {
                        // 최근 7일 (24 * 7 = 168시간)
                        var recentData = response.data.slice(-168);
                        var chartData = recentData.map(function(item) {
                            return {
                                time: new Date(item.date).getTime() / 1000,
                                value: parseFloat(item.close)
                            };
                        });
                        areaSeries.setData(chartData);
                        chart.timeScale().fitContent();
                    }
                });
            
            // 차트 클릭 시 종목 상세 페이지로 이동
            container.style.cursor = 'pointer';
            container.onclick = function() {
                location.href = '/stock/detail/' + symbol;
            };
        }

        // ========================================
        // 북마크 토글
        // ========================================
        function toggleBookmark(newsId, btn) {
            fetch('/news/api/bookmark/toggle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ newsId: newsId })
            })
            .then(function(r) {
                if (r.status === 401) {
                    location.href = '/login';
                    return null;
                }
                return r.json();
            })
            .then(function(data) {
                if (!data) return;
                
                if (data.success) {
                    var svg = btn.querySelector('svg');
                    if (data.isBookmarked) {
                        btn.classList.add('active');
                        svg.setAttribute('fill', 'currentColor');
                        bookmarkedNewsIds.add(newsId);
                    } else {
                        btn.classList.remove('active');
                        svg.setAttribute('fill', 'none');
                        bookmarkedNewsIds.delete(newsId);
                    }
                }
            });
        }

        // ========================================
        // 유틸리티
        // ========================================
        function escapeHtml(text) {
            if (!text) return '';
            var div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function formatTime(dateStr) {
            if (!dateStr) return '';
            var date = new Date(dateStr);
            return date.toLocaleString('ko-KR', {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            });
        }
    </script>
</body>
</html>
