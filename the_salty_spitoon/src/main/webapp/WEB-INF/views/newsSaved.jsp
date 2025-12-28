<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Saved News - The Salty Spitoon</title>
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

        .main-content {
            max-width: 1000px;
            margin: 0 auto;
            padding: 32px;
        }

        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 32px;
        }

        .page-header h1 {
            font-size: 28px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .page-header h1 svg {
            color: #f59e0b;
        }

        .bookmark-count {
            font-size: 14px;
            color: #6b7280;
        }

        .news-list {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

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
            width: 140px;
            height: 90px;
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

        .news-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: auto;
        }

        .saved-date {
            font-size: 12px;
            color: #6b7280;
        }

        .remove-btn {
            background: none;
            border: none;
            cursor: pointer;
            padding: 8px;
            border-radius: 6px;
            transition: all 0.2s;
            color: #ef4444;
            opacity: 0.7;
        }

        .remove-btn:hover {
            background-color: rgba(239, 68, 68, 0.15);
            opacity: 1;
        }

        .remove-btn svg {
            width: 18px;
            height: 18px;
        }

        .empty-state {
            text-align: center;
            padding: 80px 20px;
            color: #6b7280;
        }

        .empty-state svg {
            width: 80px;
            height: 80px;
            margin-bottom: 20px;
            color: #f59e0b;
            opacity: 0.3;
        }

        .empty-state h3 {
            font-size: 20px;
            margin-bottom: 8px;
            color: #9ca3af;
        }

        .empty-state p {
            margin-bottom: 24px;
        }

        .empty-state a {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: #ffffff;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 500;
            transition: all 0.2s;
        }

        .empty-state a:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
        }

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

        @media (max-width: 768px) {
            .news-card-inner {
                flex-direction: column;
            }

            .news-thumbnail {
                width: 100%;
                height: 160px;
            }
        }
    </style>
</head>
<body>
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
            <a href="/news">News</a>
            <a href="/news/saved" class="active">Saved</a>
            <a href="/admin">Admin</a>
        </div>

        <div class="navbar-right">
            <sec:authorize access="isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/logout'" title="로그아웃">
                    <sec:authentication property="principal.username" var="userEmail"/>
                    ${userEmail.substring(0,1).toUpperCase()}
                </div>
            </sec:authorize>
        </div>
    </nav>

    <main class="main-content">
        <div class="page-header">
            <h1>
                <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
                </svg>
                Saved News
            </h1>
            <span class="bookmark-count">${totalBookmarks} articles saved</span>
        </div>

        <c:choose>
            <c:when test="${empty bookmarks.content}">
                <div class="empty-state">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
                    </svg>
                    <h3>No saved articles yet</h3>
                    <p>Start saving articles to read them later</p>
                    <a href="/news">
                        Browse News
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M5 12h14M12 5l7 7-7 7"/>
                        </svg>
                    </a>
                </div>
            </c:when>
            <c:otherwise>
                <div class="news-list">
                    <c:forEach var="bookmark" items="${bookmarks.content}">
                        <div class="news-card" id="bookmark-${bookmark.id}">
                            <div class="news-card-inner" onclick="location.href='/news/detail/${bookmark.news.id}'">
                                <c:if test="${not empty bookmark.news.thumbnailUrl}">
                                    <img src="${bookmark.news.thumbnailUrl}" alt="" class="news-thumbnail"
                                         onerror="this.style.display='none'">
                                </c:if>
                                <div class="news-content">
                                    <div class="news-meta">
                                        <span class="news-symbol">${bookmark.news.symbol}</span>
                                        <span class="news-time" data-time="${bookmark.news.publishedAt}"></span>
                                    </div>
                                    <h3 class="news-title">${bookmark.news.title}</h3>
                                    <div class="news-footer">
                                        <span class="saved-date">
                                            Saved <span data-saved="${bookmark.createdAt}"></span>
                                        </span>
                                        <button class="remove-btn" onclick="event.stopPropagation(); removeBookmark(${bookmark.news.id}, ${bookmark.id})" title="Remove">
                                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <polyline points="3 6 5 6 21 6"/>
                                                <path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </div>

                <c:if test="${totalPages > 1}">
                    <div class="pagination">
                        <c:if test="${currentPage > 0}">
                            <a href="?page=${currentPage - 1}">← Prev</a>
                        </c:if>

                        <c:forEach begin="${Math.max(0, currentPage - 2)}" 
                                   end="${Math.min(totalPages - 1, currentPage + 2)}" var="i">
                            <c:choose>
                                <c:when test="${i == currentPage}">
                                    <span class="active">${i + 1}</span>
                                </c:when>
                                <c:otherwise>
                                    <a href="?page=${i}">${i + 1}</a>
                                </c:otherwise>
                            </c:choose>
                        </c:forEach>

                        <c:if test="${currentPage < totalPages - 1}">
                            <a href="?page=${currentPage + 1}">Next →</a>
                        </c:if>
                    </div>
                </c:if>
            </c:otherwise>
        </c:choose>
    </main>

    <script>
        // 시간 표시
        document.querySelectorAll('[data-time]').forEach(el => {
            const date = new Date(el.dataset.time);
            el.textContent = date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
            });
        });

        document.querySelectorAll('[data-saved]').forEach(el => {
            const date = new Date(el.dataset.saved);
            const now = new Date();
            const diff = now - date;
            const days = Math.floor(diff / (1000 * 60 * 60 * 24));
            
            if (days === 0) {
                el.textContent = 'today';
            } else if (days === 1) {
                el.textContent = 'yesterday';
            } else if (days < 7) {
                el.textContent = days + ' days ago';
            } else {
                el.textContent = date.toLocaleDateString('en-US', {
                    month: 'short',
                    day: 'numeric'
                });
            }
        });

        // 북마크 제거
        async function removeBookmark(newsId, bookmarkId) {
            if (!confirm('Remove this article from saved?')) return;

            try {
                const response = await fetch('/news/api/bookmark/toggle', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ newsId: newsId })
                });

                const data = await response.json();

                if (data.success && !data.isBookmarked) {
                    const card = document.getElementById('bookmark-' + bookmarkId);
                    card.style.opacity = '0';
                    card.style.transform = 'translateX(-20px)';
                    setTimeout(() => card.remove(), 300);
                }
            } catch (error) {
                console.error('Remove bookmark failed:', error);
            }
        }
    </script>
</body>
</html>
