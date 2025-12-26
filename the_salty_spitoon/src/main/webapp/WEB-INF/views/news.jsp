<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Stock News - The Salty Spitoon</title>
    <style>
        /* ... 이전 CSS 그대로 ... */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f7fa;
            color: #333;
            line-height: 1.6;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 0;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        header h1 {
            text-align: center;
            font-size: 2.5em;
            font-weight: 700;
        }

        header p {
            text-align: center;
            font-size: 1.1em;
            opacity: 0.9;
            margin-top: 10px;
        }

        .filter-section {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .filter-title {
            font-size: 1.2em;
            font-weight: 600;
            margin-bottom: 15px;
            color: #667eea;
        }

        .symbol-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        .symbol-btn {
            padding: 10px 20px;
            border: 2px solid #e0e0e0;
            background: white;
            border-radius: 25px;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            color: #333;
            font-weight: 500;
        }

        .symbol-btn:hover {
            background: #f0f0f0;
            border-color: #667eea;
        }

        .symbol-btn.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }

        .stats {
            text-align: center;
            margin-bottom: 20px;
            color: #666;
            font-size: 1.1em;
        }

        .news-grid {
            display: grid;
            gap: 20px;
        }

        .news-card {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
            display: flex;
            flex-direction: row;
        }

        .news-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
        }

        .news-thumbnail {
            width: 200px;
            height: 150px;
            object-fit: cover;
            flex-shrink: 0;
        }

        .news-content {
            padding: 20px;
            flex: 1;
        }

        .news-meta {
            display: flex;
            gap: 15px;
            margin-bottom: 10px;
            font-size: 0.9em;
            color: #666;
        }

        .symbol-badge {
            background: #667eea;
            color: white;
            padding: 3px 10px;
            border-radius: 15px;
            font-weight: 600;
            font-size: 0.85em;
        }

        .news-date {
            color: #999;
        }

        .news-title {
            font-size: 1.3em;
            font-weight: 600;
            margin-bottom: 10px;
            color: #333;
            line-height: 1.4;
        }

        .news-title a {
            color: #333;
            text-decoration: none;
            transition: color 0.3s;
        }

        .news-title a:hover {
            color: #667eea;
        }

        .read-more {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
            font-weight: 500;
        }

        .read-more:hover {
            background: #5568d3;
        }

        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            margin-top: 40px;
        }

        .pagination a,
        .pagination span {
            padding: 10px 15px;
            border: 1px solid #e0e0e0;
            border-radius: 5px;
            text-decoration: none;
            color: #333;
            transition: all 0.3s;
        }

        .pagination a:hover {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }

        .pagination .current {
            background: #667eea;
            color: white;
            border-color: #667eea;
            font-weight: 600;
        }

        .no-news {
            text-align: center;
            padding: 60px 20px;
            color: #999;
            font-size: 1.2em;
        }

        @media (max-width: 768px) {
            .news-card {
                flex-direction: column;
            }

            .news-thumbnail {
                width: 100%;
                height: 200px;
            }

            header h1 {
                font-size: 2em;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>📰 Stock News</h1>
            <p>Latest news from NASDAQ 100 companies</p>
        </div>
    </header>

    <div class="container">
        <!-- 필터 섹션 -->
        <div class="filter-section">
            <div class="filter-title">Filter by Symbol</div>
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

        <!-- 통계 -->
        <div class="stats">
            <c:choose>
                <c:when test="${not empty selectedSymbol}">
                    📊 ${selectedSymbol} News: <strong>${totalNews}</strong> articles
                </c:when>
                <c:otherwise>
                    📊 Total News: <strong>${totalNews}</strong> articles
                </c:otherwise>
            </c:choose>
        </div>

        <!-- 뉴스 목록 -->
        <c:choose>
            <c:when test="${empty newsPage.content}">
                <div class="no-news">
                    No news available. 😔
                </div>
            </c:when>
            <c:otherwise>
                <div class="news-grid">
                    <c:forEach var="news" items="${newsPage.content}">
                        <div class="news-card">
                            <c:if test="${not empty news.thumbnailUrl}">
                                <img src="${news.thumbnailUrl}" alt="thumbnail" class="news-thumbnail" 
                                     onerror="this.style.display='none'">
                            </c:if>
                            
                            <div class="news-content">
                                <div class="news-meta">
                                    <span class="symbol-badge">${news.symbol}</span>
                                    <span class="news-date">
                                        🕒 ${news.publishedAt.toString().substring(0, 16).replace('T', ' ')}
                                    </span>
                                </div>
                                
                                <h2 class="news-title">
                                    <a href="/news/detail/${news.id}">${news.title}</a>
                                </h2>
                                
                                <a href="/news/detail/${news.id}" class="read-more">
                                    Read More →
                                </a>
                            </div>
                        </div>
                    </c:forEach>
                </div>

                <!-- 페이징 -->
                <c:if test="${totalPages > 1}">
                    <div class="pagination">
                        <!-- 이전 페이지 -->
                        <c:if test="${currentPage > 0}">
                            <a href="?page=${currentPage - 1}<c:if test='${not empty selectedSymbol}'>&symbol=${selectedSymbol}</c:if>">
                                ← Previous
                            </a>
                        </c:if>

                        <!-- 페이지 번호 -->
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

                        <!-- 다음 페이지 -->
                        <c:if test="${currentPage < totalPages - 1}">
                            <a href="?page=${currentPage + 1}<c:if test='${not empty selectedSymbol}'>&symbol=${selectedSymbol}</c:if>">
                                Next →
                            </a>
                        </c:if>
                    </div>
                </c:if>
            </c:otherwise>
        </c:choose>
    </div>
</body>
</html>