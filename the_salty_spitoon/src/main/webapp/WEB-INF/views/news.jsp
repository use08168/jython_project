<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>News Feed - The Salty Spitoon</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: #0f1419;
            color: #ffffff;
            min-height: 100vh;
        }

        /* 네비게이션 */
        .navbar {
            background-color: #1a1f2e;
            border-bottom: 1px solid #252b3d;
            padding: 12px 32px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .navbar-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 18px;
            font-weight: 700;
            color: #3b82f6;
            text-decoration: none;
        }

        .navbar-menu {
            display: flex;
            align-items: center;
            gap: 32px;
        }

        .navbar-menu a {
            color: #9ca3af;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: color 0.2s;
        }

        .navbar-menu a:hover,
        .navbar-menu a.active {
            color: #ffffff;
        }

        .navbar-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
        }

        /* 메인 컨텐츠 */
        .main-content {
            max-width: 1400px;
            margin: 0 auto;
            padding: 24px 32px;
            display: grid;
            grid-template-columns: 280px 1fr;
            gap: 24px;
        }

        /* 사이드바 */
        .sidebar {
            position: sticky;
            top: 80px;
            height: fit-content;
        }

        .sidebar-section {
            background-color: #1a1f2e;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 16px;
        }

        .sidebar-title {
            font-size: 14px;
            font-weight: 600;
            color: #9ca3af;
            margin-bottom: 16px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .filter-list {
            list-style: none;
        }

        .filter-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 12px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
            margin-bottom: 4px;
            text-decoration: none;
            color: #d1d5db;
        }

        .filter-item:hover {
            background-color: #252b3d;
        }

        .filter-item.active {
            background-color: #3b82f6;
            color: #ffffff;
        }

        .filter-item .count {
            font-size: 12px;
            color: #6b7280;
            background-color: #252b3d;
            padding: 2px 8px;
            border-radius: 10px;
        }

        .filter-item.active .count {
            background-color: rgba(255,255,255,0.2);
            color: #ffffff;
        }

        /* 뉴스 피드 */
        .news-feed {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .news-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }

        .news-header h1 {
            font-size: 24px;
            font-weight: 700;
        }

        .news-header .result-count {
            font-size: 14px;
            color: #6b7280;
        }

        .search-bar {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
        }

        .search-input {
            flex: 1;
            padding: 12px 16px;
            background-color: #1a1f2e;
            border: 1px solid #374151;
            border-radius: 10px;
            color: #ffffff;
            font-size: 14px;
        }

        .search-input:focus {
            outline: none;
            border-color: #3b82f6;
        }

        .search-btn {
            padding: 12px 24px;
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            border: none;
            border-radius: 10px;
            color: #ffffff;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
        }

        .search-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
        }

        /* 뉴스 카드 */
        .news-card {
            background-color: #1a1f2e;
            border-radius: 12px;
            overflow: hidden;
            transition: all 0.2s;
            cursor: pointer;
        }

        .news-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
        }

        .news-card-inner {
            display: flex;
            padding: 20px;
            gap: 20px;
        }

        .news-thumbnail {
            width: 160px;
            height: 100px;
            border-radius: 8px;
            object-fit: cover;
            background-color: #252b3d;
            flex-shrink: 0;
        }

        .news-content {
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .news-meta {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 8px;
        }

        .news-symbol {
            padding: 4px 10px;
            background-color: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .news-time {
            font-size: 12px;
            color: #6b7280;
        }

        .news-title {
            font-size: 16px;
            font-weight: 600;
            line-height: 1.5;
            margin-bottom: 8px;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .news-summary {
            font-size: 14px;
            color: #9ca3af;
            line-height: 1.5;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
            flex: 1;
        }

        .news-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 12px;
        }

        .news-publisher {
            font-size: 12px;
            color: #6b7280;
        }

        .bookmark-btn {
            background: none;
            border: none;
            cursor: pointer;
            padding: 8px;
            border-radius: 6px;
            transition: all 0.2s;
            color: #6b7280;
        }

        .bookmark-btn:hover {
            background-color: #252b3d;
            color: #f59e0b;
        }

        .bookmark-btn.active {
            color: #f59e0b;
        }

        .bookmark-btn svg {
            width: 20px;
            height: 20px;
        }

        /* 페이지네이션 */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 32px;
        }

        .pagination a,
        .pagination span {
            padding: 10px 16px;
            border-radius: 8px;
            font-size: 14px;
            text-decoration: none;
            transition: all 0.2s;
        }

        .pagination a {
            background-color: #1a1f2e;
            color: #d1d5db;
        }

        .pagination a:hover {
            background-color: #252b3d;
        }

        .pagination .active {
            background-color: #3b82f6;
            color: #ffffff;
        }

        .pagination .disabled {
            opacity: 0.5;
            pointer-events: none;
        }

        /* 시간 표시 */
        .time-dual {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .time-kst {
            font-size: 12px;
            color: #9ca3af;
        }

        .time-est {
            font-size: 11px;
            color: #6b7280;
        }

        /* 빈 상태 */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6b7280;
        }

        .empty-state svg {
            width: 64px;
            height: 64px;
            margin-bottom: 16px;
            opacity: 0.5;
        }

        .empty-state h3 {
            font-size: 18px;
            margin-bottom: 8px;
            color: #9ca3af;
        }

        /* 반응형 */
        @media (max-width: 1024px) {
            .main-content {
                grid-template-columns: 1fr;
            }

            .sidebar {
                position: static;
            }
        }

        @media (max-width: 768px) {
            .news-card-inner {
                flex-direction: column;
            }

            .news-thumbnail {
                width: 100%;
                height: 180px;
            }
        }
    </style>
</head>
<body>
    <!-- 네비게이션 -->
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/>
            </svg>
            The Salty Spitoon
        </a>

        <div class="navbar-menu">
            <a href="/dashboard">Market</a>
            <a href="/watchlist">Watchlist</a>
            <a href="/news" class="active">News</a>
            <a href="/news/saved">Saved</a>
            <a href="/admin">Admin</a>
        </div>

        <div class="navbar-right">
            <sec:authorize access="isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/logout'" title="로그아웃">
                    <sec:authentication property="principal.username" var="userEmail"/>
                    ${userEmail.substring(0,1).toUpperCase()}
                </div>
            </sec:authorize>
            <sec:authorize access="!isAuthenticated()">
                <a href="/login" class="user-avatar" title="로그인">?</a>
            </sec:authorize>
        </div>
    </nav>

    <!-- 메인 컨텐츠 -->
    <div class="main-content">
        <!-- 사이드바 -->
        <aside class="sidebar">
            <div class="sidebar-section">
                <h3 class="sidebar-title">Filter by Ticker</h3>
                <ul class="filter-list">
                    <li>
                        <a href="/news" class="filter-item ${empty selectedSymbol ? 'active' : ''}">
                            <span>All News</span>
                            <span class="count">${totalNews}</span>
                        </a>
                    </li>
                    <c:forEach var="sym" items="${symbols}">
                        <li>
                            <a href="/news?symbol=${sym}" class="filter-item ${selectedSymbol == sym ? 'active' : ''}">
                                <span>${sym}</span>
                            </a>
                        </li>
                    </c:forEach>
                </ul>
            </div>
        </aside>

        <!-- 뉴스 피드 -->
        <div class="news-feed">
            <div class="news-header">
                <h1>
                    <c:choose>
                        <c:when test="${not empty keyword}">
                            Search: "${keyword}"
                        </c:when>
                        <c:when test="${not empty selectedSymbol}">
                            ${selectedSymbol} News
                        </c:when>
                        <c:otherwise>
                            Latest News
                        </c:otherwise>
                    </c:choose>
                </h1>
                <span class="result-count">${totalNews} articles</span>
            </div>

            <!-- 검색 바 -->
            <form action="/news/search" method="get" class="search-bar">
                <input type="text" name="keyword" class="search-input" 
                       placeholder="Search news..." value="${keyword}">
                <button type="submit" class="search-btn">Search</button>
            </form>

            <!-- 뉴스 목록 -->
            <c:choose>
                <c:when test="${empty newsPage.content}">
                    <div class="empty-state">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
                        </svg>
                        <h3>No news found</h3>
                        <p>Try adjusting your search or filter</p>
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="news" items="${newsPage.content}">
                        <div class="news-card" onclick="location.href='/news/detail/${news.id}'">
                            <div class="news-card-inner">
                                <c:if test="${not empty news.thumbnailUrl}">
                                    <img src="${news.thumbnailUrl}" alt="" class="news-thumbnail" 
                                         onerror="this.style.display='none'">
                                </c:if>
                                <div class="news-content">
                                    <div class="news-meta">
                                        <span class="news-symbol">${news.symbol}</span>
                                        <div class="time-dual">
                                            <span class="time-kst" data-time="${news.publishedAt}"></span>
                                            <span class="time-est" data-time-est="${news.publishedAt}"></span>
                                        </div>
                                    </div>
                                    <h3 class="news-title">${news.title}</h3>
                                    <div class="news-footer">
                                        <span class="news-publisher"></span>
                                        <button class="bookmark-btn ${bookmarkedIds.contains(news.id) ? 'active' : ''}" 
                                                onclick="event.stopPropagation(); toggleBookmark(${news.id}, this)">
                                            <svg viewBox="0 0 24 24" fill="${bookmarkedIds.contains(news.id) ? 'currentColor' : 'none'}" 
                                                 stroke="currentColor" stroke-width="2">
                                                <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>

            <!-- 페이지네이션 -->
            <c:if test="${totalPages > 1}">
                <div class="pagination">
                    <c:if test="${currentPage > 0}">
                        <a href="?page=${currentPage - 1}${not empty selectedSymbol ? '&symbol='.concat(selectedSymbol) : ''}${not empty keyword ? '&keyword='.concat(keyword) : ''}">← Prev</a>
                    </c:if>

                    <c:forEach begin="${Math.max(0, currentPage - 2)}" 
                               end="${Math.min(totalPages - 1, currentPage + 2)}" var="i">
                        <c:choose>
                            <c:when test="${i == currentPage}">
                                <span class="active">${i + 1}</span>
                            </c:when>
                            <c:otherwise>
                                <a href="?page=${i}${not empty selectedSymbol ? '&symbol='.concat(selectedSymbol) : ''}${not empty keyword ? '&keyword='.concat(keyword) : ''}">${i + 1}</a>
                            </c:otherwise>
                        </c:choose>
                    </c:forEach>

                    <c:if test="${currentPage < totalPages - 1}">
                        <a href="?page=${currentPage + 1}${not empty selectedSymbol ? '&symbol='.concat(selectedSymbol) : ''}${not empty keyword ? '&keyword='.concat(keyword) : ''}">Next →</a>
                    </c:if>
                </div>
            </c:if>
        </div>
    </div>

    <script>
        // 시간 변환 (KST/EST)
        document.querySelectorAll('[data-time]').forEach(el => {
            const isoTime = el.dataset.time;
            if (!isoTime) return;

            const date = new Date(isoTime);
            
            // KST
            const kstOptions = { 
                timeZone: 'Asia/Seoul',
                month: 'short', 
                day: 'numeric',
                hour: '2-digit', 
                minute: '2-digit',
                hour12: false
            };
            el.textContent = date.toLocaleString('en-US', kstOptions) + ' KST';
        });

        document.querySelectorAll('[data-time-est]').forEach(el => {
            const isoTime = el.dataset.timeEst;
            if (!isoTime) return;

            const date = new Date(isoTime);
            
            // EST
            const estOptions = { 
                timeZone: 'America/New_York',
                month: 'short', 
                day: 'numeric',
                hour: '2-digit', 
                minute: '2-digit',
                hour12: false
            };
            el.textContent = date.toLocaleString('en-US', estOptions) + ' EST';
        });

        // 북마크 토글
        async function toggleBookmark(newsId, btn) {
            try {
                const response = await fetch('/news/api/bookmark/toggle', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ newsId: newsId })
                });

                const data = await response.json();

                if (response.status === 401) {
                    location.href = '/login';
                    return;
                }

                if (data.success) {
                    const svg = btn.querySelector('svg');
                    if (data.isBookmarked) {
                        btn.classList.add('active');
                        svg.setAttribute('fill', 'currentColor');
                    } else {
                        btn.classList.remove('active');
                        svg.setAttribute('fill', 'none');
                    }
                }
            } catch (error) {
                console.error('Bookmark toggle failed:', error);
            }
        }
    </script>
</body>
</html>
