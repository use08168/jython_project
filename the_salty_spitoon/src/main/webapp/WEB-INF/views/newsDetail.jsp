<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${news.title} - The Salty Spitoon</title>
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
            line-height: 1.8;
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
            max-width: 900px;
            margin: 0 auto;
            padding: 30px 20px;
        }

        /* ========================================
           뒤로가기
           ======================================== */
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            background: #1e222d;
            border: 1px solid #2a2e39;
            border-radius: 6px;
            color: #787b86;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
            margin-bottom: 24px;
        }

        .back-link:hover {
            background: #2a2e39;
            color: #d1d4dc;
            border-color: #434651;
        }

        /* ========================================
           기사 카드
           ======================================== */
        .article {
            background: #1e222d;
            border-radius: 12px;
            overflow: hidden;
            border: 1px solid #2a2e39;
        }

        /* 썸네일 이미지 */
        .article-thumbnail {
            width: 100%;
            max-height: 400px;
            object-fit: cover;
            display: block;
        }

        .article-body {
            padding: 32px;
        }

        .article-meta {
            display: flex;
            gap: 16px;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 1px solid #2a2e39;
            flex-wrap: wrap;
        }

        .symbol-badge {
            background: rgba(41, 98, 255, 0.15);
            color: #2962ff;
            padding: 6px 14px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 14px;
        }

        .publisher {
            color: #787b86;
            font-weight: 500;
            font-size: 14px;
        }

        .publish-date {
            color: #787b86;
            font-size: 14px;
        }

        .article-title {
            font-size: 28px;
            font-weight: 700;
            line-height: 1.4;
            margin-bottom: 24px;
            color: #d1d4dc;
        }

        .article-summary {
            font-size: 16px;
            color: #787b86;
            font-style: italic;
            margin-bottom: 32px;
            padding: 20px;
            background: #2a2e39;
            border-left: 4px solid #2962ff;
            border-radius: 0 8px 8px 0;
            line-height: 1.7;
        }

        .article-content {
            font-size: 16px;
            line-height: 1.9;
            color: #d1d4dc;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .article-content p {
            margin-bottom: 16px;
        }

        /* ========================================
           원문 링크
           ======================================== */
        .source-link {
            margin-top: 40px;
            padding-top: 24px;
            border-top: 1px solid #2a2e39;
            text-align: center;
        }

        .source-link a {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 14px 28px;
            background: #2962ff;
            color: white;
            border-radius: 8px;
            font-weight: 600;
            font-size: 15px;
            transition: all 0.2s;
        }

        .source-link a:hover {
            background: #1e53e5;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(41, 98, 255, 0.3);
        }

        /* ========================================
           주가 변동률 카드
           ======================================== */
        .price-change-card {
            margin-top: 24px;
            background: #1e222d;
            border-radius: 12px;
            padding: 24px;
            border: 1px solid #2a2e39;
        }

        .price-change-title {
            font-size: 16px;
            font-weight: 600;
            color: #d1d4dc;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .price-change-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 16px;
        }

        .price-box {
            background: #2a2e39;
            border-radius: 8px;
            padding: 16px;
            text-align: center;
        }

        .price-box-label {
            font-size: 12px;
            color: #787b86;
            margin-bottom: 8px;
        }

        .price-box-value {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 4px;
        }

        .price-box-change {
            font-size: 14px;
            font-weight: 600;
        }

        .price-box-change.up {
            color: #26a69a;
        }

        .price-box-change.down {
            color: #ef5350;
        }

        .price-box-change.neutral {
            color: #787b86;
        }

        .price-box-time {
            font-size: 11px;
            color: #787b86;
            margin-top: 6px;
        }

        .no-data {
            text-align: center;
            color: #787b86;
            padding: 20px;
            font-size: 14px;
        }

        /* ========================================
           관련 종목 링크
           ======================================== */
        .related-stock {
            margin-top: 24px;
            padding: 20px;
            background: #1e222d;
            border: 1px solid #2a2e39;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .related-stock-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .related-stock-symbol {
            font-size: 18px;
            font-weight: 700;
            color: #2962ff;
        }

        .related-stock-text {
            color: #787b86;
            font-size: 14px;
        }

        .related-stock-btn {
            padding: 10px 20px;
            background: #2a2e39;
            color: #d1d4dc;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }

        .related-stock-btn:hover {
            background: #2962ff;
            color: white;
        }

        /* ========================================
           반응형
           ======================================== */
        @media (max-width: 768px) {
            .container {
                padding: 20px 16px;
            }

            .article-body {
                padding: 24px 20px;
            }

            .article-title {
                font-size: 22px;
            }

            .navbar-menu {
                gap: 4px;
            }

            .navbar-item {
                padding: 8px 12px;
                font-size: 13px;
            }

            .related-stock {
                flex-direction: column;
                gap: 16px;
                text-align: center;
            }

            .price-change-grid {
                grid-template-columns: 1fr;
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
        <!-- 뒤로가기 -->
        <a href="/news" class="back-link">
            ← 뉴스 목록으로
        </a>

        <!-- 기사 본문 -->
        <article class="article">
            <!-- 썸네일 이미지 -->
            <c:if test="${not empty news.thumbnailUrl}">
                <img src="${news.thumbnailUrl}" alt="thumbnail" class="article-thumbnail" 
                     onerror="this.style.display='none'">
            </c:if>

            <div class="article-body">
                <div class="article-meta">
                    <span class="symbol-badge">${news.symbol}</span>
                    <span class="publisher">📰 ${news.publisher}</span>
                    <span class="publish-date">
                        ${news.publishedAt.toString().substring(0, 16).replace('T', ' ')}
                    </span>
                </div>

                <h1 class="article-title">${news.title}</h1>

                <c:if test="${not empty news.summary}">
                    <div class="article-summary">
                        ${news.summary}
                    </div>
                </c:if>

                <div class="article-content">
                    ${news.fullContent}
                </div>

                <!-- 원문 링크 -->
                <div class="source-link">
                    <a href="${news.url}" target="_blank" rel="noopener noreferrer">
                        원문 기사 보기 ↗
                    </a>
                </div>
            </div>
        </article>

        <!-- 주가 변동률 카드 -->
        <div class="price-change-card">
            <div class="price-change-title">
                📊 뉴스 발행 후 ${news.symbol} 주가 변동
            </div>

            <c:choose>
                <c:when test="${priceChange.available == true}">
                    <div class="price-change-grid">
                        <!-- 발행 직전 가격 -->
                        <div class="price-box">
                            <div class="price-box-label">발행 직전</div>
                            <div class="price-box-value" style="color: #d1d4dc;">
                                $${String.format("%.2f", priceChange.beforePrice)}
                            </div>
                            <div class="price-box-change neutral">기준가</div>
                            <c:if test="${not empty priceChange.beforeTime}">
                                <div class="price-box-time">
                                    ${priceChange.beforeTime.toString().substring(0, 16).replace('T', ' ')}
                                </div>
                            </c:if>
                        </div>

                        <!-- 1시간 후 -->
                        <div class="price-box">
                            <div class="price-box-label">1시간 후</div>
                            <c:choose>
                                <c:when test="${not empty priceChange.after1hPrice}">
                                    <div class="price-box-value" style="color: #d1d4dc;">
                                        $${String.format("%.2f", priceChange.after1hPrice)}
                                    </div>
                                    <div class="price-box-change ${priceChange.change1h >= 0 ? 'up' : 'down'}">
                                        ${priceChange.change1h >= 0 ? '+' : ''}${priceChange.change1h}%
                                    </div>
                                    <c:if test="${not empty priceChange.after1hTime}">
                                        <div class="price-box-time">
                                            ${priceChange.after1hTime.toString().substring(0, 16).replace('T', ' ')}
                                        </div>
                                    </c:if>
                                </c:when>
                                <c:otherwise>
                                    <div class="price-box-value" style="color: #787b86;">-</div>
                                    <div class="price-box-change neutral">데이터 없음</div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <!-- 1일 후 -->
                        <div class="price-box">
                            <div class="price-box-label">1일 후</div>
                            <c:choose>
                                <c:when test="${not empty priceChange.after1dPrice}">
                                    <div class="price-box-value" style="color: #d1d4dc;">
                                        $${String.format("%.2f", priceChange.after1dPrice)}
                                    </div>
                                    <div class="price-box-change ${priceChange.change1d >= 0 ? 'up' : 'down'}">
                                        ${priceChange.change1d >= 0 ? '+' : ''}${priceChange.change1d}%
                                    </div>
                                    <c:if test="${not empty priceChange.after1dTime}">
                                        <div class="price-box-time">
                                            ${priceChange.after1dTime.toString().substring(0, 16).replace('T', ' ')}
                                        </div>
                                    </c:if>
                                </c:when>
                                <c:otherwise>
                                    <div class="price-box-value" style="color: #787b86;">-</div>
                                    <div class="price-box-change neutral">데이터 없음</div>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="no-data">
                        ⚠️ ${priceChange.message != null ? priceChange.message : '해당 시간대의 주가 데이터가 없습니다.'}
                    </div>
                </c:otherwise>
            </c:choose>
        </div>

        <!-- 관련 종목 -->
        <div class="related-stock">
            <div class="related-stock-info">
                <span class="related-stock-symbol">${news.symbol}</span>
                <span class="related-stock-text">종목 상세 정보 및 차트 확인</span>
            </div>
            <a href="/stock/detail/${news.symbol}" class="related-stock-btn">
                차트 보기 →
            </a>
        </div>
    </div>
</body>
</html>
