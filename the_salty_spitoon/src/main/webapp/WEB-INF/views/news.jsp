<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Stock News - The Salty Spitoon</title>
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
            line-height: 1.6;
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
            max-width: 1400px;
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
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px 20px;
        }

        /* ========================================
           페이지 헤더
           ======================================== */
        .page-header {
            margin-bottom: 30px;
        }

        .page-title {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
            color: #d1d4dc;
        }

        .page-subtitle {
            font-size: 14px;
            color: #787b86;
        }

        /* ========================================
           필터 섹션
           ======================================== */
        .filter-section {
            background: #1e222d;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 24px;
            border: 1px solid #2a2e39;
        }

        .filter-title {
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 12px;
            color: #787b86;
        }

        .symbol-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .symbol-btn {
            padding: 8px 16px;
            border: 1px solid #2a2e39;
            background: #2a2e39;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
            color: #787b86;
            font-weight: 500;
            font-size: 13px;
        }

        .symbol-btn:hover {
            background: #363a45;
            color: #d1d4dc;
            border-color: #434651;
        }

        .symbol-btn.active {
            background: #2962ff;
            color: white;
            border-color: #2962ff;
        }

        /* ========================================
           통계 바
           ======================================== */
        .stats-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 12px 16px;
            background: #1e222d;
            border-radius: 8px;
            border: 1px solid #2a2e39;
        }

        .stats-text {
            font-size: 14px;
            color: #787b86;
        }

        .stats-text strong {
            color: #2962ff;
        }

        /* ========================================
           뉴스 그리드
           ======================================== */
        .news-grid {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .news-card {
            background: #1e222d;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #2a2e39;
            transition: all 0.2s;
            display: flex;
            flex-direction: row;
        }

        .news-card:hover {
            border-color: #2962ff;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(41, 98, 255, 0.15);
        }

        .news-thumbnail {
            width: 200px;
            height: 140px;
            object-fit: cover;
            flex-shrink: 0;
            background: #2a2e39;
        }

        .news-content {
            padding: 20px;
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .news-meta {
            display: flex;
            gap: 12px;
            margin-bottom: 10px;
            align-items: center;
        }

        .symbol-badge {
            background: rgba(41, 98, 255, 0.15);
            color: #2962ff;
            padding: 4px 10px;
            border-radius: 4px;
            font-weight: 600;
            font-size: 12px;
        }

        .news-date {
            color: #787b86;
            font-size: 13px;
        }

        .news-title {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 12px;
            color: #d1d4dc;
            line-height: 1.4;
            flex: 1;
        }

        .news-title:hover {
            color: #2962ff;
        }

        .read-more {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 16px;
            background: #2a2e39;
            color: #d1d4dc;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.2s;
            width: fit-content;
        }

        .read-more:hover {
            background: #2962ff;
            color: white;
        }

        /* ========================================
           페이지네이션
           ======================================== */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 40px;
        }

        .pagination a,
        .pagination span {
            padding: 10px 14px;
            border: 1px solid #2a2e39;
            border-radius: 6px;
            color: #787b86;
            font-size: 14px;
            transition: all 0.2s;
            background: #1e222d;
        }

        .pagination a:hover {
            background: #2a2e39;
            color: #d1d4dc;
            border-color: #434651;
        }

        .pagination .current {
            background: #2962ff;
            color: white;
            border-color: #2962ff;
            font-weight: 600;
        }

        /* ========================================
           빈 상태
           ======================================== */
        .no-news {
            text-align: center;
            padding: 80px 20px;
            color: #787b86;
            font-size: 16px;
        }

        .no-news-icon {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.5;
        }

        /* ========================================
           반응형
           ======================================== */
        @media (max-width: 768px) {
            .news-card {
                flex-direction: column;
            }

            .news-thumbnail {
                width: 100%;
                height: 180px;
            }

            .navbar-menu {
                gap: 4px;
            }

            .navbar-item {
                padding: 8px 12px;
                font-size: 13px;
            }

            .page-title {
                font-size: 24px;
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
                <a href="/stock" class="navbar-item">대시보드</a>
                <a href="/stock/chart?symbol=AAPL" class="navbar-item">차트</a>
                <a href="/news" class="navbar-item active">뉴스</a>
                <a href="/admin" class="navbar-item">관리자</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <!-- 페이지 헤더 -->
        <div class="page-header">
            <h1 class="page-title">📰 Stock News</h1>
            <p class="page-subtitle">NASDAQ 100 기업들의 최신 뉴스</p>
        </div>

        <!-- 필터 섹션 -->
        <div class="filter-section">
            <div class="filter-title">종목 필터</div>
            <div class="symbol-filters">
                <a href="/news" class="symbol-btn ${empty selectedSymbol ? 'active' : ''}">
                    ALL
                </a>
                <c:forEach var="sym" items="${symbols}">
                    <a href="/news?symbol=${sym}" 
                       class="symbol-btn ${selectedSymbol eq sym ? 'active' : ''}">
                        ${sym}
                    </a>
                </c:forEach>
            </div>
        </div>

        <!-- 통계 바 -->
        <div class="stats-bar">
            <span class="stats-text">
                <c:choose>
                    <c:when test="${not empty selectedSymbol}">
                        ${selectedSymbol} 뉴스: <strong>${totalNews}</strong>개
                    </c:when>
                    <c:otherwise>
                        전체 뉴스: <strong>${totalNews}</strong>개
                    </c:otherwise>
                </c:choose>
            </span>
        </div>

        <!-- 뉴스 목록 -->
        <c:choose>
            <c:when test="${empty newsPage.content}">
                <div class="no-news">
                    <div class="no-news-icon">📭</div>
                    <p>표시할 뉴스가 없습니다.</p>
                </div>
            </c:when>
            <c:otherwise>
                <div class="news-grid">
                    <c:forEach var="news" items="${newsPage.content}">
                        <article class="news-card">
                            <c:if test="${not empty news.thumbnailUrl}">
                                <img src="${news.thumbnailUrl}" alt="thumbnail" class="news-thumbnail" 
                                     onerror="this.style.display='none'">
                            </c:if>
                            
                            <div class="news-content">
                                <div class="news-meta">
                                    <span class="symbol-badge">${news.symbol}</span>
                                    <span class="news-date">
                                        ${news.publishedAt.toString().substring(0, 16).replace('T', ' ')}
                                    </span>
                                </div>
                                
                                <a href="/news/detail/${news.id}" class="news-title">
                                    ${news.title}
                                </a>
                                
                                <a href="/news/detail/${news.id}" class="read-more">
                                    자세히 보기 →
                                </a>
                            </div>
                        </article>
                    </c:forEach>
                </div>

                <!-- 페이지네이션 -->
                <c:if test="${totalPages > 1}">
                    <div class="pagination">
                        <c:if test="${currentPage > 0}">
                            <a href="?page=${currentPage - 1}<c:if test='${not empty selectedSymbol}'>&symbol=${selectedSymbol}</c:if>">
                                ← 이전
                            </a>
                        </c:if>

                        <c:forEach begin="0" end="${totalPages - 1}" var="i">
                            <c:choose>
                                <c:when test="${i == currentPage}">
                                    <span class="current">${i + 1}</span>
                                </c:when>
                                <c:otherwise>
                                    <a href="?page=${i}<c:if test='${not empty selectedSymbol}'>&symbol=${selectedSymbol}</c:if>">
                                        ${i + 1}
                                    </a>
                                </c:otherwise>
                            </c:choose>
                        </c:forEach>

                        <c:if test="${currentPage < totalPages - 1}">
                            <a href="?page=${currentPage + 1}<c:if test='${not empty selectedSymbol}'>&symbol=${selectedSymbol}</c:if>">
                                다음 →
                            </a>
                        </c:if>
                    </div>
                </c:if>
            </c:otherwise>
        </c:choose>
    </div>
</body>
</html>
