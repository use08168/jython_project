<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${news.title} - The Salty Spitoon</title>
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
            max-width: 900px;
            margin: 0 auto;
            padding: 32px;
        }

        /* 뒤로가기 */
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #9ca3af;
            text-decoration: none;
            font-size: 14px;
            margin-bottom: 24px;
            transition: color 0.2s;
        }

        .back-link:hover {
            color: #ffffff;
        }

        /* 기사 헤더 */
        .article-header {
            margin-bottom: 32px;
        }

        .article-meta {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }

        .article-symbol {
            padding: 6px 14px;
            background-color: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
        }

        .article-symbol:hover {
            background-color: rgba(59, 130, 246, 0.25);
        }

        .article-time {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .time-kst {
            font-size: 14px;
            color: #d1d5db;
        }

        .time-est {
            font-size: 12px;
            color: #6b7280;
        }

        .article-title {
            font-size: 32px;
            font-weight: 700;
            line-height: 1.3;
            margin-bottom: 16px;
        }

        .article-publisher {
            font-size: 14px;
            color: #6b7280;
        }

        .article-publisher a {
            color: #3b82f6;
            text-decoration: none;
        }

        /* 주가 변동 카드 */
        .price-change-card {
            background-color: #1a1f2e;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 32px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .price-info {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .price-symbol {
            font-size: 18px;
            font-weight: 600;
        }

        .price-value {
            font-size: 24px;
            font-weight: 700;
        }

        .price-change {
            font-size: 14px;
            padding: 6px 12px;
            border-radius: 6px;
        }

        .price-change.positive {
            background-color: rgba(34, 197, 94, 0.15);
            color: #22c55e;
        }

        .price-change.negative {
            background-color: rgba(239, 68, 68, 0.15);
            color: #ef4444;
        }

        .view-stock-btn {
            padding: 10px 20px;
            background-color: #252b3d;
            color: #ffffff;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s;
        }

        .view-stock-btn:hover {
            background-color: #374151;
        }

        /* 썸네일 */
        .article-thumbnail {
            width: 100%;
            max-height: 400px;
            object-fit: cover;
            border-radius: 12px;
            margin-bottom: 32px;
        }

        /* 기사 본문 */
        .article-content {
            background-color: #1a1f2e;
            border-radius: 12px;
            padding: 32px;
            margin-bottom: 32px;
        }

        .article-summary {
            font-size: 18px;
            color: #d1d5db;
            line-height: 1.7;
            margin-bottom: 24px;
            padding-bottom: 24px;
            border-bottom: 1px solid #252b3d;
        }

        .article-body {
            font-size: 16px;
            color: #d1d5db;
            line-height: 1.8;
        }

        .article-body p {
            margin-bottom: 16px;
        }

        /* 액션 바 */
        .action-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 0;
            border-top: 1px solid #252b3d;
            margin-top: 32px;
        }

        .action-buttons {
            display: flex;
            gap: 12px;
        }

        .action-btn {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            background-color: #252b3d;
            color: #d1d5db;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .action-btn:hover {
            background-color: #374151;
        }

        .action-btn.bookmark.active {
            background-color: rgba(245, 158, 11, 0.15);
            color: #f59e0b;
        }

        .action-btn svg {
            width: 18px;
            height: 18px;
        }

        .original-link {
            color: #3b82f6;
            text-decoration: none;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .original-link:hover {
            text-decoration: underline;
        }

        /* 반응형 */
        @media (max-width: 768px) {
            .main-content {
                padding: 16px;
            }

            .article-title {
                font-size: 24px;
            }

            .price-change-card {
                flex-direction: column;
                gap: 16px;
                align-items: flex-start;
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
    <main class="main-content">
        <!-- 뒤로가기 -->
        <a href="/news" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 12H5M12 19l-7-7 7-7"/>
            </svg>
            Back to News
        </a>

        <!-- 기사 헤더 -->
        <header class="article-header">
            <div class="article-meta">
                <a href="/stock/detail/${news.symbol}" class="article-symbol">${news.symbol}</a>
                <div class="article-time">
                    <span class="time-kst" id="time-kst"></span>
                    <span class="time-est" id="time-est"></span>
                </div>
            </div>
            <h1 class="article-title">${news.title}</h1>
            <p class="article-publisher">
                <c:if test="${not empty news.publisher}">
                    Source: ${news.publisher}
                </c:if>
            </p>
        </header>

        <!-- 주가 변동 카드 -->
        <c:if test="${not empty priceChange}">
            <div class="price-change-card">
                <div class="price-info">
                    <span class="price-symbol">${news.symbol}</span>
                    <span class="price-value">$${priceChange.currentPrice}</span>
                    <span class="price-change ${priceChange.changePercent >= 0 ? 'positive' : 'negative'}">
                        ${priceChange.changePercent >= 0 ? '+' : ''}${priceChange.changePercent}%
                        <span style="font-size: 11px; margin-left: 4px;">since article</span>
                    </span>
                </div>
                <a href="/stock/detail/${news.symbol}" class="view-stock-btn">View Stock →</a>
            </div>
        </c:if>

        <!-- 썸네일 -->
        <c:if test="${not empty news.thumbnailUrl}">
            <img src="${news.thumbnailUrl}" alt="" class="article-thumbnail" 
                 onerror="this.style.display='none'">
        </c:if>

        <!-- 기사 본문 -->
        <article class="article-content">
            <c:if test="${not empty news.summary}">
                <div class="article-summary">
                    ${news.summary}
                </div>
            </c:if>
            
            <div class="article-body">
                <c:choose>
                    <c:when test="${not empty news.fullContent}">
                        ${news.fullContent}
                    </c:when>
                    <c:otherwise>
                        <p style="color: #6b7280; text-align: center;">
                            Full article content is not available.<br>
                            Please visit the original source for the complete article.
                        </p>
                    </c:otherwise>
                </c:choose>
            </div>

            <!-- 액션 바 -->
            <div class="action-bar">
                <div class="action-buttons">
                    <c:choose>
                        <c:when test="${isBookmarked}">
                            <button class="action-btn bookmark active" data-news-id="<c:out value='${news.id}' />"
            onclick="toggleBookmark(this)" id="bookmark-btn">
                                <svg viewBox="0 0 24 24" fill="currentColor" 
                                    stroke="currentColor" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
                                </svg>
                                <span>Saved</span>
                            </button>
                        </c:when>
                        <c:otherwise>
                            <button class="action-btn bookmark" data-news-id="<c:out value='${news.id}' />"
            onclick="toggleBookmark(this)" id="bookmark-btn">
                                <svg viewBox="0 0 24 24" fill="none" 
                                    stroke="currentColor" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
                                </svg>
                                <span>Save</span>
                            </button>
                        </c:otherwise>
                    </c:choose>
                    <button class="action-btn" onclick="shareArticle()">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="18" cy="5" r="3"/>
                            <circle cx="6" cy="12" r="3"/>
                            <circle cx="18" cy="19" r="3"/>
                            <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/>
                            <line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/>
                        </svg>
                        <span>Share</span>
                    </button>
                </div>
                <c:if test="${not empty news.url}">
                    <a href="${news.url}" target="_blank" class="original-link">
                        Read Original Article
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/>
                            <polyline points="15 3 21 3 21 9"/>
                            <line x1="10" y1="14" x2="21" y2="3"/>
                        </svg>
                    </a>
                </c:if>
            </div>
        </article>
    </main>

    <script>
        // 시간 표시
        var publishedAt = '<c:out value="${news.publishedAt}" />';
        if (publishedAt) {
            var date = new Date(publishedAt);
            
            // KST
            var kstOptions = { 
                timeZone: 'Asia/Seoul',
                year: 'numeric',
                month: 'long', 
                day: 'numeric',
                hour: '2-digit', 
                minute: '2-digit',
                hour12: false
            };
            document.getElementById('time-kst').textContent = 
                date.toLocaleString('en-US', kstOptions) + ' KST';
            
            // EST
            var estOptions = { 
                timeZone: 'America/New_York',
                year: 'numeric',
                month: 'long', 
                day: 'numeric',
                hour: '2-digit', 
                minute: '2-digit',
                hour12: false
            };
            document.getElementById('time-est').textContent = 
                date.toLocaleString('en-US', estOptions) + ' EST';
        }

        // 북마크 토글
        function toggleBookmark(newsId, btn) {
            fetch('/news/api/bookmark/toggle', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ newsId: newsId })
            })
            .then(function(response) {
                if (response.status === 401) {
                    location.href = '/login';
                    return null;
                }
                return response.json();
            })
            .then(function(data) {
                if (!data) return;
                
                if (data.success) {
                    var svg = btn.querySelector('svg');
                    var span = btn.querySelector('span');
                    
                    if (data.isBookmarked) {
                        btn.classList.add('active');
                        svg.setAttribute('fill', 'currentColor');
                        span.textContent = 'Saved';
                    } else {
                        btn.classList.remove('active');
                        svg.setAttribute('fill', 'none');
                        span.textContent = 'Save';
                    }
                }
            })
            .catch(function(error) {
                console.error('Bookmark toggle failed:', error);
            });
        }

        // 공유
        function shareArticle() {
            if (navigator.share) {
                navigator.share({
                    title: document.title,
                    url: window.location.href
                });
            } else {
                navigator.clipboard.writeText(window.location.href);
                alert('Link copied to clipboard!');
            }
        }
    </script>
</body>
</html>
