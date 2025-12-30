<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Watchlist - The Salty Spitoon</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
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
        .main-content { flex: 1; min-width: 0; }
        .sidebar { width: 300px; flex-shrink: 0; }

        /* 페이지 헤더 */
        .page-header { margin-bottom: 24px; }
        .page-header h1 { font-size: 28px; font-weight: 700; margin-bottom: 8px; }
        .page-header p { color: #6b7280; font-size: 14px; }

        /* 그룹 탭 - 가로 스크롤 */
        .group-tabs-container { display: flex; align-items: center; gap: 12px; margin-bottom: 24px; }
        .group-tabs-scroll-btn { width: 32px; height: 32px; border-radius: 8px; background: #252b3d; border: 1px solid #374151; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; flex-shrink: 0; }
        .group-tabs-scroll-btn:hover { background: #374151; color: #ffffff; }
        .group-tabs-scroll-btn:disabled { opacity: 0.3; cursor: not-allowed; }
        .group-tabs-scroll-btn svg { width: 16px; height: 16px; }
        .group-tabs-wrapper { flex: 1; overflow-x: auto; -ms-overflow-style: none; scrollbar-width: none; scroll-behavior: smooth; }
        .group-tabs-wrapper::-webkit-scrollbar { display: none; }
        .group-tabs { display: flex; gap: 8px; padding: 4px 0; }
        .group-tab { display: flex; align-items: center; gap: 8px; padding: 10px 16px; background-color: #1a1f2e; border: 1px solid transparent; border-radius: 10px; color: #9ca3af; font-size: 14px; cursor: pointer; transition: all 0.2s; white-space: nowrap; flex-shrink: 0; }
        .group-tab:hover { background-color: #252b3d; }
        .group-tab.active { background-color: #252b3d; border-color: #3b82f6; color: #ffffff; }
        .group-tab .dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
        .group-tab .count { font-size: 12px; background-color: #374151; padding: 2px 8px; border-radius: 10px; margin-left: 4px; }
        .group-tab.active .count { background-color: #3b82f6; }
        .group-tab-actions { display: flex; gap: 4px; margin-left: 8px; }
        .group-tab-btn { width: 20px; height: 20px; border-radius: 4px; background: transparent; border: none; color: #6b7280; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; font-size: 12px; }
        .group-tab-btn:hover { background-color: #374151; color: #ffffff; }
        .group-tab-btn.delete:hover { background-color: rgba(239, 68, 68, 0.2); color: #ef4444; }

        /* Create Group 버튼 */
        .create-group-btn { display: flex; align-items: center; gap: 8px; padding: 10px 20px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); border: none; border-radius: 10px; color: #ffffff; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s; white-space: nowrap; flex-shrink: 0; }
        .create-group-btn:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }

        /* 컨트롤 패널 */
        .controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px 20px; background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; flex-wrap: wrap; gap: 16px; }
        .search-filter { flex: 0 1 300px; position: relative; }
        .search-filter input { width: 100%; padding: 10px 16px 10px 40px; font-size: 14px; background-color: #252b3d; border: 1px solid #374151; border-radius: 8px; color: #ffffff; }
        .search-filter input:focus { outline: none; border-color: #3b82f6; }
        .search-filter svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); width: 16px; height: 16px; color: #6b7280; }
        .sort-options { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .sort-label { font-size: 13px; color: #6b7280; margin-right: 4px; }
        .sort-btn { padding: 8px 14px; background: #252b3d; border: 1px solid #374151; border-radius: 6px; color: #9ca3af; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.2s; display: flex; align-items: center; gap: 6px; }
        .sort-btn:hover { background: #374151; color: #ffffff; }
        .sort-btn.active { background: #3b82f6; border-color: #3b82f6; color: #ffffff; }
        .sort-btn svg { width: 14px; height: 14px; }
        .stock-count { font-size: 13px; color: #6b7280; }
        .stock-count span { color: #d1d5db; font-weight: 600; }

        /* 테이블 */
        .stock-table { width: 100%; background: #1a1f2e; border-radius: 12px; overflow: hidden; border: 1px solid #252b3d; }
        .table-header { display: grid; grid-template-columns: 2fr 1fr 1fr 150px 120px; gap: 16px; padding: 16px 24px; background: #252b3d; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; }
        .table-row { display: grid; grid-template-columns: 2fr 1fr 1fr 250px 120px; gap: 16px; padding: 16px 24px; border-bottom: 1px solid #252b3d; align-items: center; transition: background 0.2s; cursor: pointer; }
        .table-row:last-child { border-bottom: none; }
        .table-row:hover { background: #1e2433; }

        /* 테이블 셀 */
        .cell-company { display: flex; align-items: center; gap: 12px; }
        .company-logo { width: 120px; height: 40px; border-radius: 8px; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; padding: 4px; flex-shrink: 0; }
        .company-logo img { max-width: 100%; max-height: 100%; object-fit: contain; }
        .company-info { min-width: 0; }
        .company-symbol { font-size: 15px; font-weight: 600; color: #ffffff; }
        .company-name { font-size: 12px; color: #6b7280; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .cell-price { font-size: 15px; font-weight: 600; color: #ffffff; padding-left: 40px;}
        .cell-change { font-size: 14px; font-weight: 500; padding-left: 70px;}
        .cell-change.positive { color: #22c55e; }
        .cell-change.negative { color: #ef4444; }
        .cell-chart { width: 250px; height: 40px; }
        .cell-chart canvas { width: 100%; height: 100%; }
        .cell-actions { display: flex; gap: 8px; justify-content: flex-end; position: relative; }
        .action-btn { width: 32px; height: 32px; border-radius: 6px; background: #252b3d; border: none; color: #6b7280; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; position: relative; }
        .action-btn:hover { background: #374151; color: #ffffff; }
        .action-btn.delete:hover { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .action-btn.add:hover { background: rgba(59, 130, 246, 0.15); color: #3b82f6; }
        .action-btn svg { width: 16px; height: 16px; }

        /* 그룹 드롭다운 - position: fixed로 변경 */
        .group-dropdown { position: fixed; background: #1a1f2e; border: 1px solid #374151; border-radius: 10px; padding: 8px 0; min-width: 200px; z-index: 1000; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5); display: none; }
        .group-dropdown.active { display: block; }
        .group-dropdown-title { padding: 8px 16px; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; }
        .group-dropdown-item { display: flex; align-items: center; gap: 10px; padding: 10px 16px; cursor: pointer; transition: background 0.2s; }
        .group-dropdown-item:hover { background: #252b3d; }
        .group-dropdown-item .dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
        .group-dropdown-item .name { flex: 1; font-size: 14px; color: #d1d5db; }
        .group-dropdown-item .check { color: #22c55e; font-size: 14px; }
        .group-dropdown-empty { padding: 16px; text-align: center; color: #6b7280; font-size: 13px; }

        /* 더보기 버튼 */
        .load-more-section { text-align: center; margin-top: 24px; }
        .load-more-btn { padding: 14px 48px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); border: none; border-radius: 10px; color: #ffffff; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
        .load-more-btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .load-more-btn:disabled { background: #374151; cursor: not-allowed; transform: none; box-shadow: none; }
        .load-more-info { font-size: 13px; color: #6b7280; margin-top: 12px; }

        /* 빈 상태 */
        .empty-state { text-align: center; padding: 80px 20px; }
        .empty-state svg { width: 80px; height: 80px; color: #374151; margin-bottom: 20px; }
        .empty-state h3 { font-size: 20px; font-weight: 600; margin-bottom: 8px; color: #9ca3af; }
        .empty-state p { color: #6b7280; margin-bottom: 24px; }
        .empty-state a { display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: #ffffff; border-radius: 10px; font-weight: 500; transition: all 0.2s; }
        .empty-state a:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }

        /* 사이드바 */
        .sidebar-card { background: #1a1f2e; border-radius: 12px; border: 1px solid #252b3d; padding: 20px; margin-top: 160px;}
        .sidebar-card h3 { font-size: 14px; font-weight: 600; color: #9ca3af; margin-bottom: 16px; }
        .sidebar-placeholder { height: 200px; display: flex; align-items: center; justify-content: center; color: #374151; font-size: 13px; }

        /* 북마크 뉴스 섹션 */
        .bookmark-news-list { max-height: 700px; overflow-y: auto; }
        .bookmark-news-list::-webkit-scrollbar { width: 4px; }
        .bookmark-news-list::-webkit-scrollbar-track { background: #1a1f2e; }
        .bookmark-news-list::-webkit-scrollbar-thumb { background: #374151; border-radius: 2px; }
        .bookmark-news-item { display: flex; gap: 12px; padding: 12px 0; border-bottom: 1px solid #252b3d; cursor: pointer; transition: all 0.2s; }
        .bookmark-news-item:last-child { border-bottom: none; }
        .bookmark-news-item:hover { background: #252b3d; margin: 0 -20px; padding: 12px 20px; }
        .bookmark-news-thumb { width: 60px; height: 40px; border-radius: 6px; object-fit: cover; background: #252b3d; flex-shrink: 0; }
        .bookmark-news-info { flex: 1; min-width: 0; }
        .bookmark-news-symbol { font-size: 11px; color: #3b82f6; font-weight: 600; margin-bottom: 4px; }
        .bookmark-news-title { font-size: 12px; color: #d1d5db; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .bookmark-news-time { font-size: 10px; color: #6b7280; margin-top: 4px; }
        .bookmark-news-empty { text-align: center; padding: 30px 10px; color: #6b7280; font-size: 13px; }
        .bookmark-news-empty a { color: #3b82f6; }
        .bookmark-unbookmark-btn { padding: 4px; border-radius: 4px; background: transparent; border: none; color: #f59e0b; cursor: pointer; transition: all 0.2s; flex-shrink: 0; }
        .bookmark-unbookmark-btn:hover { background: rgba(245, 158, 11, 0.15); }

        /* 모달 */
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(0, 0, 0, 0.7); z-index: 1000; justify-content: center; align-items: center; }
        .modal-overlay.active { display: flex; }
        .modal { background-color: #1a1f2e; border-radius: 16px; padding: 24px; width: 100%; max-width: 400px; margin: 20px; position: relative; }
        .modal-close { position: absolute; top: 16px; right: 16px; width: 32px; height: 32px; border-radius: 8px; background: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .modal-close:hover { background: #374151; color: #ffffff; }
        .modal h2 { font-size: 18px; font-weight: 600; margin-bottom: 20px; padding-right: 40px; }
        .modal-input { width: 100%; padding: 12px 16px; background-color: #252b3d; border: 1px solid #374151; border-radius: 8px; color: #ffffff; font-size: 14px; margin-bottom: 16px; }
        .modal-input:focus { outline: none; border-color: #3b82f6; }
        .color-picker { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
        .color-option { width: 32px; height: 32px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; transition: all 0.2s; }
        .color-option:hover, .color-option.active { border-color: #ffffff; transform: scale(1.1); }
        .modal-actions { display: flex; gap: 12px; justify-content: flex-end; }
        .modal-btn { padding: 10px 20px; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s; border: none; }
        .modal-btn.cancel { background: #252b3d; color: #9ca3af; }
        .modal-btn.cancel:hover { background: #374151; color: #ffffff; }
        .modal-btn.primary { background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: #ffffff; }
        .modal-btn.primary:hover { box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .modal-btn.danger { background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); color: #ffffff; }
        .modal-btn.danger:hover { box-shadow: 0 4px 12px rgba(239, 68, 68, 0.4); }
        .modal-message { font-size: 14px; color: #9ca3af; margin-bottom: 20px; line-height: 1.6; }

        /* 로딩 */
        .loading { text-align: center; padding: 60px 20px; color: #6b7280; }
        .loading-spinner { width: 40px; height: 40px; border: 3px solid #252b3d; border-top-color: #3b82f6; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* 반응형 */
        @media (max-width: 1200px) {
            .sidebar { display: none; }
        }
        @media (max-width: 768px) {
            .main-layout { padding: 16px; }
            .table-header, .table-row { grid-template-columns: 2fr 1fr 1fr 100px; }
            .cell-chart { display: none; }
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
            <input type="text" placeholder="Search tickers, news..." disabled>
        </div>
        <div class="navbar-menu">
            <a href="/dashboard">Market</a>
            <a href="/stock">Stocks</a>
            <a href="/watchlist" class="active">Watchlist</a>
            <a href="/news">News</a>
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
        <main class="main-content">
            <!-- 페이지 헤더 -->
            <div class="page-header">
                <h1>⭐ My Watchlist</h1>
                <p>Track your favorite stocks and manage them in groups</p>
            </div>

            <!-- 그룹 탭 -->
            <div class="group-tabs-container">
                <button class="group-tabs-scroll-btn" id="scroll-left-btn" onclick="scrollGroupTabs(-200)">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>
                </button>
                <div class="group-tabs-wrapper" id="group-tabs-wrapper">
                    <div class="group-tabs" id="group-tabs">
                        <!-- JavaScript로 렌더링 -->
                    </div>
                </div>
                <button class="group-tabs-scroll-btn" id="scroll-right-btn" onclick="scrollGroupTabs(200)">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg>
                </button>
                <button class="create-group-btn" onclick="openCreateGroupModal()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>
                    Create Group
                </button>
            </div>

            <!-- 컨트롤 패널 -->
            <div class="controls">
                <div class="search-filter">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                    <input type="text" id="searchInput" placeholder="Search in watchlist..." oninput="filterStocks()">
                </div>
                <div class="sort-options">
                    <span class="sort-label">Sort by:</span>
                    <button class="sort-btn active" data-sort="alpha" onclick="sortStocks('alpha')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h12M3 18h6"/></svg>
                        A-Z
                    </button>
                    <button class="sort-btn" data-sort="alpha-desc" onclick="sortStocks('alpha-desc')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h6M3 12h12M3 18h18"/></svg>
                        Z-A
                    </button>
                    <button class="sort-btn" data-sort="price-high" onclick="sortStocks('price-high')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12l7-7 7 7"/></svg>
                        Price ↑
                    </button>
                    <button class="sort-btn" data-sort="price-low" onclick="sortStocks('price-low')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12l7 7 7-7"/></svg>
                        Price ↓
                    </button>
                </div>
                <div class="stock-count">Showing <span id="stockCount">0</span> stocks</div>
            </div>

            <!-- 테이블 -->
            <div class="stock-table" id="stock-table">
                <div class="table-header">
                    <div>Company</div>
                    <div>Price</div>
                    <div>Change</div>
                    <div>Trend (24h)</div>
                    <div style="text-align: center;">Actions</div>
                </div>
                <div id="table-body">
                    <div class="loading">
                        <div class="loading-spinner"></div>
                        <p>Loading watchlist...</p>
                    </div>
                </div>
            </div>

            <!-- 더보기 버튼 -->
            <div class="load-more-section" id="load-more-section" style="display: none;">
                <button class="load-more-btn" id="load-more-btn" onclick="loadMore()">Load More</button>
                <div class="load-more-info" id="load-more-info"></div>
            </div>
        </main>

        <!-- 사이드바 -->
        <aside class="sidebar">
            <div class="sidebar-card">
                <h3>📄 Saved News</h3>
                <div id="bookmarked-news-container">
                    <div class="loading">
                        <div class="loading-spinner"></div>
                    </div>
                </div>
            </div>
        </aside>
    </div>

    <!-- 그룹 생성/수정 모달 -->
    <div class="modal-overlay" id="group-modal">
        <div class="modal">
            <button class="modal-close" onclick="closeGroupModal()">✕</button>
            <h2 id="group-modal-title">Create New Group</h2>
            <input type="text" class="modal-input" id="group-name-input" placeholder="Group name">
            <div class="color-picker" id="color-picker">
                <div class="color-option active" style="background-color: #3b82f6;" data-color="#3b82f6"></div>
                <div class="color-option" style="background-color: #22c55e;" data-color="#22c55e"></div>
                <div class="color-option" style="background-color: #f59e0b;" data-color="#f59e0b"></div>
                <div class="color-option" style="background-color: #ef4444;" data-color="#ef4444"></div>
                <div class="color-option" style="background-color: #a855f7;" data-color="#a855f7"></div>
                <div class="color-option" style="background-color: #ec4899;" data-color="#ec4899"></div>
                <div class="color-option" style="background-color: #06b6d4;" data-color="#06b6d4"></div>
                <div class="color-option" style="background-color: #6b7280;" data-color="#6b7280"></div>
            </div>
            <div class="modal-actions">
                <button class="modal-btn cancel" onclick="closeGroupModal()">Cancel</button>
                <button class="modal-btn primary" id="group-modal-submit" onclick="saveGroup()">Create</button>
            </div>
        </div>
    </div>

    <!-- 그룹 삭제 확인 모달 -->
    <div class="modal-overlay" id="delete-modal">
        <div class="modal">
            <button class="modal-close" onclick="closeDeleteModal()">✕</button>
            <h2>Delete Group</h2>
            <p class="modal-message" id="delete-modal-message">Are you sure you want to delete this group?</p>
            <div class="modal-actions">
                <button class="modal-btn cancel" onclick="closeDeleteModal()">Cancel</button>
                <button class="modal-btn danger" onclick="confirmDeleteGroup()">Delete</button>
            </div>
        </div>
    </div>

    <!-- 종목 삭제 확인 모달 -->
    <div class="modal-overlay" id="stock-delete-modal">
        <div class="modal">
            <button class="modal-close" onclick="closeStockDeleteModal()">✕</button>
            <h2>Remove Stock</h2>
            <p class="modal-message" id="stock-delete-modal-message">Are you sure you want to remove this stock?</p>
            <div class="modal-actions">
                <button class="modal-btn cancel" onclick="closeStockDeleteModal()">Cancel</button>
                <button class="modal-btn danger" onclick="confirmRemoveStock()">Remove</button>
            </div>
        </div>
    </div>

    <script>
        // ========================================
        // 상태 변수
        // ========================================
        var groupsData = [];
        var watchlistData = [];
        var filteredData = [];
        var displayedData = [];
        var stockInfoCache = {};
        var chartDataCache = {};
        var stockGroupsCache = {}; // 종목별 그룹 ID 캐시
        
        var currentGroupFilter = null;
        var currentSort = 'alpha';
        var itemsPerPage = 10;
        var currentPage = 0;
        
        var selectedColor = '#3b82f6';
        var editingGroupId = null;
        var deletingGroupId = null;
        var deletingStockSymbol = null;
        var activeDropdown = null;

        // ========================================
        // 초기화
        // ========================================
        document.addEventListener('DOMContentLoaded', function() {
            loadGroups();
            loadBookmarkedNews();
            setupColorPicker();
            setupModalClose();
            setupGroupTabsScroll();
            
            // 드롭다운 외부 클릭 시 닫기
            document.addEventListener('click', function(e) {
                if (!e.target.closest('.group-dropdown') && !e.target.closest('.action-btn.add')) {
                    closeAllDropdowns();
                }
            });
            
            // 스크롤 시 드롭다운 닫기
            window.addEventListener('scroll', closeAllDropdowns);
        });

        // ========================================
        // 그룹 탭 스크롤
        // ========================================
        function setupGroupTabsScroll() {
            var wrapper = document.getElementById('group-tabs-wrapper');
            if (!wrapper) return;
            
            // 마우스 휠 가로 스크롤
            wrapper.addEventListener('wheel', function(e) {
                if (e.deltaY !== 0) {
                    e.preventDefault();
                    wrapper.scrollLeft += e.deltaY;
                    updateScrollButtons();
                }
            }, { passive: false });
            
            // 스크롤 이벤트로 버튼 상태 업데이트
            wrapper.addEventListener('scroll', updateScrollButtons);
            
            // 초기 버튼 상태
            setTimeout(updateScrollButtons, 100);
        }
        
        function scrollGroupTabs(amount) {
            var wrapper = document.getElementById('group-tabs-wrapper');
            if (wrapper) {
                wrapper.scrollLeft += amount;
                setTimeout(updateScrollButtons, 300);
            }
        }
        
        function updateScrollButtons() {
            var wrapper = document.getElementById('group-tabs-wrapper');
            var leftBtn = document.getElementById('scroll-left-btn');
            var rightBtn = document.getElementById('scroll-right-btn');
            
            if (!wrapper || !leftBtn || !rightBtn) return;
            
            var scrollLeft = wrapper.scrollLeft;
            var maxScroll = wrapper.scrollWidth - wrapper.clientWidth;
            
            leftBtn.disabled = scrollLeft <= 0;
            rightBtn.disabled = scrollLeft >= maxScroll - 1;
        }

        // ========================================
        // 그룹 관련
        // ========================================
        function loadGroups() {
            fetch('/api/watchlist/groups')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        groupsData = data.data;
                        renderGroupTabs(data.allCount, data.ungroupedCount);
                        loadWatchlist();
                    }
                });
        }

        function renderGroupTabs(allCount, ungroupedCount) {
            var html = '';
            
            html += '<div class="group-tab ' + (currentGroupFilter === null ? 'active' : '') + '" onclick="filterByGroup(null, this)">';
            html += 'All <span class="count">' + (allCount || 0) + '</span>';
            html += '</div>';
            
            html += '<div class="group-tab ' + (currentGroupFilter === 0 ? 'active' : '') + '" onclick="filterByGroup(0, this)">';
            html += '<span class="dot" style="background-color: #6b7280;"></span>';
            html += 'Ungrouped <span class="count">' + (ungroupedCount || 0) + '</span>';
            html += '</div>';
            
            groupsData.forEach(function(group) {
                html += '<div class="group-tab ' + (currentGroupFilter === group.id ? 'active' : '') + '" data-group-id="' + group.id + '">';
                html += '<span class="dot" style="background-color: ' + group.color + ';"></span>';
                html += '<span onclick="filterByGroup(' + group.id + ', this.parentElement)">' + escapeHtml(group.name) + '</span>';
                html += '<span class="count">' + (group.count || 0) + '</span>';
                html += '<div class="group-tab-actions">';
                html += '<button class="group-tab-btn" onclick="event.stopPropagation(); openEditGroupModal(' + group.id + ', \'' + escapeHtml(group.name) + '\', \'' + group.color + '\')" title="Edit">✎</button>';
                html += '<button class="group-tab-btn delete" onclick="event.stopPropagation(); openDeleteModal(' + group.id + ', \'' + escapeHtml(group.name) + '\')" title="Delete">✕</button>';
                html += '</div>';
                html += '</div>';
            });
            
            document.getElementById('group-tabs').innerHTML = html;
            
            // 스크롤 버튼 상태 업데이트
            setTimeout(updateScrollButtons, 50);
        }

        function filterByGroup(groupId, element) {
            currentGroupFilter = groupId;
            currentPage = 0;
            displayedData = [];
            
            document.querySelectorAll('.group-tab').forEach(function(tab) {
                tab.classList.remove('active');
            });
            if (element) {
                element.classList.add('active');
            }
            
            loadWatchlist();
        }

        function escapeHtml(text) {
            var div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // ========================================
        // 워치리스트 로드
        // ========================================
        function loadWatchlist() {
            var url = '/api/watchlist';
            if (currentGroupFilter !== null) {
                url += '?groupId=' + currentGroupFilter;
            }
            
            fetch(url)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        watchlistData = data.data;
                        
                        // 종목별 그룹 ID 캐시 업데이트
                        watchlistData.forEach(function(item) {
                            if (item.groupIds) {
                                stockGroupsCache[item.symbol] = item.groupIds;
                            }
                        });
                        
                        filteredData = watchlistData.slice();
                        applySorting();
                        currentPage = 0;
                        displayedData = [];
                        loadMore();
                    }
                });
        }

        // ========================================
        // 검색 & 정렬
        // ========================================
        function filterStocks() {
            var q = document.getElementById('searchInput').value.toLowerCase();
            
            filteredData = watchlistData.filter(function(item) {
                var symbol = item.symbol.toLowerCase();
                var info = stockInfoCache[item.symbol];
                var name = info ? info.name.toLowerCase() : '';
                return symbol.includes(q) || name.includes(q);
            });
            
            applySorting();
            currentPage = 0;
            displayedData = [];
            loadMore();
        }

        function sortStocks(sortType) {
            currentSort = sortType;
            document.querySelectorAll('.sort-btn').forEach(function(btn) {
                btn.classList.toggle('active', btn.getAttribute('data-sort') === sortType);
            });
            
            var currentDisplayCount = displayedData.length || itemsPerPage;
            applySorting();
            currentPage = 0;
            displayedData = [];
            
            var pagesToLoad = Math.ceil(currentDisplayCount / itemsPerPage);
            for (var i = 0; i < pagesToLoad; i++) {
                var start = currentPage * itemsPerPage;
                var end = Math.min(start + itemsPerPage, filteredData.length);
                var newItems = filteredData.slice(start, end);
                displayedData = displayedData.concat(newItems);
                currentPage++;
            }
            
            renderTable();
            updateLoadMoreButton();
            loadAllCharts();
        }

        function applySorting() {
            filteredData.sort(function(a, b) {
                var infoA = stockInfoCache[a.symbol] || {};
                var infoB = stockInfoCache[b.symbol] || {};
                
                switch (currentSort) {
                    case 'alpha':
                        return a.symbol.localeCompare(b.symbol);
                    case 'alpha-desc':
                        return b.symbol.localeCompare(a.symbol);
                    case 'price-high':
                        return (parseFloat(infoB.price) || 0) - (parseFloat(infoA.price) || 0);
                    case 'price-low':
                        return (parseFloat(infoA.price) || 0) - (parseFloat(infoB.price) || 0);
                    default:
                        return 0;
                }
            });
        }

        // ========================================
        // 페이지네이션
        // ========================================
        function loadMore() {
            var start = currentPage * itemsPerPage;
            var end = Math.min(start + itemsPerPage, filteredData.length);
            var newItems = filteredData.slice(start, end);
            
            displayedData = displayedData.concat(newItems);
            currentPage++;
            
            document.getElementById('stockCount').textContent = filteredData.length;
            
            // 먼저 모든 종목 정보 로드
            var promises = newItems.map(function(item) {
                return loadStockInfoAsync(item.symbol);
            });
            
            Promise.all(promises).then(function() {
                renderTable();
                updateLoadMoreButton();
                
                // 테이블 렌더링 후 차트 로드
                setTimeout(function() {
                    displayedData.forEach(function(item) {
                        loadMiniChart(item.symbol);
                    });
                }, 50);
            });
        }

        function updateLoadMoreButton() {
            var section = document.getElementById('load-more-section');
            var btn = document.getElementById('load-more-btn');
            var info = document.getElementById('load-more-info');
            var remaining = filteredData.length - displayedData.length;
            
            if (remaining > 0) {
                section.style.display = 'block';
                btn.disabled = false;
                btn.textContent = 'Load More (' + Math.min(remaining, itemsPerPage) + ')';
                info.textContent = 'Showing ' + displayedData.length + ' of ' + filteredData.length + ' stocks';
            } else if (displayedData.length > itemsPerPage) {
                section.style.display = 'block';
                btn.disabled = true;
                btn.textContent = 'All Loaded';
                info.textContent = 'Showing all ' + filteredData.length + ' stocks';
            } else {
                section.style.display = 'none';
            }
        }

        // ========================================
        // 테이블 렌더링
        // ========================================
        function renderTable() {
            var tbody = document.getElementById('table-body');
            
            if (displayedData.length === 0) {
                tbody.innerHTML = '<div class="empty-state">' +
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>' +
                    '<h3>No stocks in watchlist</h3>' +
                    '<p>Add stocks to your watchlist to track them here</p>' +
                    '<a href="/stock">Browse Stocks →</a>' +
                    '</div>';
                return;
            }
            
            var html = '';
            displayedData.forEach(function(item) {
                var info = stockInfoCache[item.symbol] || {};
                var price = info.price || '--';
                var change = info.changePercent || 0;
                var isNegative = change < 0;
                var logoUrl = info.logoUrl;
                
                html += '<div class="table-row" onclick="location.href=\'/stock/detail/' + item.symbol + '\'">';
                
                // Company
                html += '<div class="cell-company">';
                html += '<div class="company-logo">';
                if (logoUrl) {
                    html += '<img src="' + logoUrl + '" onerror="this.parentElement.innerHTML=\'📈\'">';
                } else {
                    html += '📈';
                }
                html += '</div>';
                html += '<div class="company-info">';
                html += '<div class="company-symbol">' + item.symbol + '</div>';
                html += '<div class="company-name">' + (info.name || 'Loading...') + '</div>';
                html += '</div>';
                html += '</div>';
                
                // Price
                html += '<div class="cell-price">$' + (typeof price === 'number' ? price.toFixed(2) : price) + '</div>';
                
                // Change
                html += '<div class="cell-change ' + (isNegative ? 'negative' : 'positive') + '">';
                html += (change >= 0 ? '↑ ' : '↓ ') + Math.abs(change).toFixed(2) + '%';
                html += '</div>';
                
                // Chart
                html += '<div class="cell-chart"><canvas id="chart-' + item.symbol + '" width="150" height="40"></canvas></div>';
                
                // Actions
                html += '<div class="cell-actions">';
                // Add to Group 버튼
                html += '<button class="action-btn add" onclick="event.stopPropagation(); toggleGroupDropdown(\'' + item.symbol + '\', this)" title="Add to Group">';
                html += '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>';
                html += '</button>';
                // 드롭다운 (숨김 상태)
                html += '<div class="group-dropdown" id="dropdown-' + item.symbol + '">';
                html += renderGroupDropdown(item.symbol);
                html += '</div>';
                // Alert 버튼
                html += '<button class="action-btn" onclick="event.stopPropagation();" title="Set Alert (Coming Soon)">';
                html += '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>';
                html += '</button>';
                // Delete 버튼
                html += '<button class="action-btn delete" onclick="event.stopPropagation(); removeStock(\'' + item.symbol + '\')" title="Remove">';
                html += '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>';
                html += '</button>';
                html += '</div>';
                
                html += '</div>';
            });
            
            tbody.innerHTML = html;
        }

        function renderGroupDropdown(symbol) {
            var groupIds = stockGroupsCache[symbol] || [];
            var html = '<div class="group-dropdown-title">Add to Group</div>';
            
            if (groupsData.length === 0) {
                html += '<div class="group-dropdown-empty">No groups yet.<br>Create one first!</div>';
            } else {
                groupsData.forEach(function(group) {
                    var isInGroup = groupIds.indexOf(group.id) !== -1;
                    html += '<div class="group-dropdown-item" onclick="event.stopPropagation(); toggleStockGroup(\'' + symbol + '\', ' + group.id + ', ' + isInGroup + ')">';
                    html += '<span class="dot" style="background-color: ' + group.color + ';"></span>';
                    html += '<span class="name">' + escapeHtml(group.name) + '</span>';
                    if (isInGroup) {
                        html += '<span class="check">✓</span>';
                    }
                    html += '</div>';
                });
            }
            
            return html;
        }

        // ========================================
        // 그룹 드롭다운
        // ========================================
        function toggleGroupDropdown(symbol, btn) {
            var dropdown = document.getElementById('dropdown-' + symbol);
            var isActive = dropdown.classList.contains('active');
            
            closeAllDropdowns();
            
            if (!isActive) {
                // 버튼 위치 기준으로 드롭다운 위치 계산
                var rect = btn.getBoundingClientRect();
                var dropdownHeight = 200; // 예상 높이
                var viewportHeight = window.innerHeight;
                
                // 아래 공간이 부족하면 위로 표시
                if (rect.bottom + dropdownHeight > viewportHeight) {
                    dropdown.style.bottom = (viewportHeight - rect.top + 8) + 'px';
                    dropdown.style.top = 'auto';
                } else {
                    dropdown.style.top = (rect.bottom + 8) + 'px';
                    dropdown.style.bottom = 'auto';
                }
                
                dropdown.style.right = (window.innerWidth - rect.right) + 'px';
                dropdown.classList.add('active');
                activeDropdown = dropdown;
            }
        }

        function closeAllDropdowns() {
            document.querySelectorAll('.group-dropdown.active').forEach(function(d) {
                d.classList.remove('active');
            });
            activeDropdown = null;
        }

        function toggleStockGroup(symbol, groupId, isInGroup) {
            var url = isInGroup ? '/api/watchlist/removeFromGroup' : '/api/watchlist/addToGroup';
            
            fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ symbol: symbol, groupId: groupId })
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    // 캐시 업데이트
                    stockGroupsCache[symbol] = data.groupIds || [];
                    
                    // 드롭다운 업데이트
                    var dropdown = document.getElementById('dropdown-' + symbol);
                    if (dropdown) {
                        dropdown.innerHTML = renderGroupDropdown(symbol);
                    }
                    
                    // 그룹 카운트 업데이트
                    loadGroups();
                }
            });
        }

        // ========================================
        // 주식 정보 & 차트 로드
        // ========================================
        function loadStockInfoAsync(symbol) {
            return new Promise(function(resolve) {
                if (stockInfoCache[symbol]) {
                    resolve();
                    return;
                }
                
                fetch('/api/stocks/' + symbol + '/latest')
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        if (data && !data.error) {
                            stockInfoCache[symbol] = {
                                name: data.name || symbol,
                                price: data.closePrice || data.close_price || 0,
                                changePercent: data.changePercent || data.change_percent || 0,
                                logoUrl: data.logoUrl
                            };
                        }
                        resolve();
                    })
                    .catch(function() { resolve(); });
            });
        }

        function loadAllCharts() {
            setTimeout(function() {
                displayedData.forEach(function(item) {
                    loadMiniChart(item.symbol);
                });
            }, 50);
        }

        function loadMiniChart(symbol) {
            var canvas = document.getElementById('chart-' + symbol);
            if (!canvas) return;
            
            if (chartDataCache[symbol]) {
                drawSparkline(canvas, chartDataCache[symbol]);
                return;
            }
            
            fetch('/stock/api/chart/' + symbol + '/all?timeframe=1h')
                .then(function(r) { return r.json(); })
                .then(function(response) {
                    if (response.data && response.data.length > 1) {
                        var prices = response.data.slice(-24);
                        chartDataCache[symbol] = prices;
                        drawSparkline(canvas, prices);
                    }
                });
        }

        function drawSparkline(canvas, data) {
            if (!canvas || !data || data.length < 2) return;
            
            var ctx = canvas.getContext('2d');
            var width = canvas.width;
            var height = canvas.height;
            var padding = 4;
            
            var prices = data.map(function(d) { return parseFloat(d.close || d.closePrice || 0); });
            var min = Math.min.apply(null, prices);
            var max = Math.max.apply(null, prices);
            var range = max - min || 1;
            
            var first = prices[0];
            var last = prices[prices.length - 1];
            var isPositive = last >= first;
            
            var lineColor = isPositive ? '#22c55e' : '#ef4444';
            var fillColor = isPositive ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)';
            
            ctx.clearRect(0, 0, width, height);
            
            var points = prices.map(function(price, i) {
                return {
                    x: padding + (i / (prices.length - 1)) * (width - padding * 2),
                    y: padding + (1 - (price - min) / range) * (height - padding * 2)
                };
            });
            
            var gradient = ctx.createLinearGradient(0, 0, 0, height);
            gradient.addColorStop(0, fillColor);
            gradient.addColorStop(1, 'transparent');
            
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (var i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.lineTo(points[points.length - 1].x, height - padding);
            ctx.lineTo(points[0].x, height - padding);
            ctx.closePath();
            ctx.fillStyle = gradient;
            ctx.fill();
            
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (var i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.strokeStyle = lineColor;
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // ========================================
        // 종목 제거
        // ========================================
        function removeStock(symbol) {
            deletingStockSymbol = symbol;
            var isGroupTab = currentGroupFilter !== null && currentGroupFilter !== 0;
            
            if (isGroupTab) {
                var groupName = '';
                groupsData.forEach(function(g) {
                    if (g.id === currentGroupFilter) groupName = g.name;
                });
                document.getElementById('stock-delete-modal-message').textContent = 
                    'Remove "' + symbol + '" from group "' + groupName + '"?';
            } else {
                document.getElementById('stock-delete-modal-message').textContent = 
                    'Are you sure you want to remove "' + symbol + '" from your watchlist completely?';
            }
            document.getElementById('stock-delete-modal').classList.add('active');
        }

        function closeStockDeleteModal() {
            document.getElementById('stock-delete-modal').classList.remove('active');
            deletingStockSymbol = null;
        }

        function confirmRemoveStock() {
            if (!deletingStockSymbol) return;
            
            var symbol = deletingStockSymbol;
            var isGroupTab = currentGroupFilter !== null && currentGroupFilter !== 0;
            
            if (isGroupTab) {
                fetch('/api/watchlist/removeFromGroup', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ symbol: symbol, groupId: currentGroupFilter })
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        closeStockDeleteModal();
                        loadGroups();
                    }
                });
            } else {
                fetch('/api/watchlist/toggle', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ symbol: symbol })
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        closeStockDeleteModal();
                        loadGroups();
                    }
                });
            }
        }

        // ========================================
        // 그룹 모달
        // ========================================
        function setupColorPicker() {
            document.querySelectorAll('.color-option').forEach(function(option) {
                option.addEventListener('click', function() {
                    document.querySelectorAll('.color-option').forEach(function(o) { o.classList.remove('active'); });
                    this.classList.add('active');
                    selectedColor = this.getAttribute('data-color');
                });
            });
        }

        function setupModalClose() {
            document.querySelectorAll('.modal-overlay').forEach(function(overlay) {
                overlay.addEventListener('click', function(e) {
                    if (e.target === overlay) {
                        closeGroupModal();
                        closeDeleteModal();
                        closeStockDeleteModal();
                    }
                });
            });
        }

        function openCreateGroupModal() {
            editingGroupId = null;
            document.getElementById('group-modal-title').textContent = 'Create New Group';
            document.getElementById('group-name-input').value = '';
            document.getElementById('group-modal-submit').textContent = 'Create';
            selectedColor = '#3b82f6';
            document.querySelectorAll('.color-option').forEach(function(o) {
                o.classList.toggle('active', o.getAttribute('data-color') === '#3b82f6');
            });
            document.getElementById('group-modal').classList.add('active');
        }

        function openEditGroupModal(groupId, name, color) {
            editingGroupId = groupId;
            document.getElementById('group-modal-title').textContent = 'Edit Group';
            document.getElementById('group-name-input').value = name;
            document.getElementById('group-modal-submit').textContent = 'Save';
            selectedColor = color;
            document.querySelectorAll('.color-option').forEach(function(o) {
                o.classList.toggle('active', o.getAttribute('data-color') === color);
            });
            document.getElementById('group-modal').classList.add('active');
        }

        function closeGroupModal() {
            document.getElementById('group-modal').classList.remove('active');
            editingGroupId = null;
        }

        function saveGroup() {
            var name = document.getElementById('group-name-input').value.trim();
            if (!name) {
                alert('Please enter a group name');
                return;
            }
            
            var url, method, body;
            
            if (editingGroupId) {
                url = '/api/watchlist/groups/' + editingGroupId;
                method = 'PUT';
                body = { name: name, color: selectedColor };
            } else {
                url = '/api/watchlist/groups';
                method = 'POST';
                body = { name: name, color: selectedColor };
            }
            
            fetch(url, {
                method: method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    closeGroupModal();
                    loadGroups();
                } else {
                    alert(data.message);
                }
            });
        }

        // ========================================
        // 그룹 삭제 모달
        // ========================================
        function openDeleteModal(groupId, groupName) {
            deletingGroupId = groupId;
            document.getElementById('delete-modal-message').textContent = 
                'Are you sure you want to delete "' + groupName + '"? Stocks in this group will be moved to Ungrouped.';
            document.getElementById('delete-modal').classList.add('active');
        }

        function closeDeleteModal() {
            document.getElementById('delete-modal').classList.remove('active');
            deletingGroupId = null;
        }

        function confirmDeleteGroup() {
            if (!deletingGroupId) return;
            
            fetch('/api/watchlist/groups/' + deletingGroupId, {
                method: 'DELETE'
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    closeDeleteModal();
                    currentGroupFilter = null;
                    loadGroups();
                } else {
                    alert(data.message);
                }
            });
        }

        // ========================================
        // 북마크된 뉴스 (사이드바)
        // ========================================
        var bookmarkedNewsData = [];

        function loadBookmarkedNews() {
            fetch('/news/api/bookmarks')
                .then(function(r) { 
                    if (r.status === 401) return { success: false };
                    return r.json(); 
                })
                .then(function(data) {
                    if (data && data.success && data.data && data.data.length > 0) {
                        // newsId 목록으로 상세 정보 가져오기
                        var newsIds = data.data.map(function(b) { return b.newsId; });
                        loadBookmarkedNewsDetails(newsIds);
                    } else {
                        renderBookmarkedNews([]);
                    }
                })
                .catch(function() {
                    renderBookmarkedNews([]);
                });
        }

        function loadBookmarkedNewsDetails(newsIds) {
            // 각 뉴스 ID에 대해 상세 정보 로드 (최대 10개)
            var idsToLoad = newsIds.slice(0, 10);
            var promises = idsToLoad.map(function(id) {
                return fetch('/news/api/detail/' + id)
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        if (data && data.success) {
                            return data.data;
                        }
                        return null;
                    })
                    .catch(function() { return null; });
            });

            Promise.all(promises).then(function(results) {
                bookmarkedNewsData = results.filter(function(r) { return r !== null; });
                renderBookmarkedNews(bookmarkedNewsData);
            });
        }

        function renderBookmarkedNews(newsList) {
            var container = document.getElementById('bookmarked-news-container');
            
            if (newsList.length === 0) {
                container.innerHTML = '<div class="bookmark-news-empty">No saved news yet.<br><a href="/news">Browse news →</a></div>';
                return;
            }

            var html = '<div class="bookmark-news-list">';
            newsList.forEach(function(news) {
                html += '<div class="bookmark-news-item" onclick="location.href=\'/news/detail/' + news.id + '\'">';
                if (news.thumbnailUrl) {
                    html += '<img src="' + news.thumbnailUrl + '" class="bookmark-news-thumb" onerror="this.style.display=\'none\'">';
                }
                html += '<div class="bookmark-news-info">';
                html += '<div class="bookmark-news-symbol">' + (news.symbol || '') + '</div>';
                html += '<div class="bookmark-news-title">' + escapeHtml(news.title) + '</div>';
                html += '<div class="bookmark-news-time">' + formatNewsTime(news.publishedAt) + '</div>';
                html += '</div>';
                html += '<button class="bookmark-unbookmark-btn" onclick="event.stopPropagation(); unbookmarkNews(' + news.id + ')" title="Remove bookmark">';
                html += '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>';
                html += '</button>';
                html += '</div>';
            });
            html += '</div>';

            container.innerHTML = html;
        }

        function unbookmarkNews(newsId) {
            fetch('/news/api/bookmark/toggle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ newsId: newsId })
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    // 리스트에서 제거 후 다시 렌더링
                    bookmarkedNewsData = bookmarkedNewsData.filter(function(n) { return n.id !== newsId; });
                    renderBookmarkedNews(bookmarkedNewsData);
                }
            });
        }

        function formatNewsTime(dateStr) {
            if (!dateStr) return '';
            var date = new Date(dateStr);
            return date.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' });
        }
    </script>
</body>
</html>
