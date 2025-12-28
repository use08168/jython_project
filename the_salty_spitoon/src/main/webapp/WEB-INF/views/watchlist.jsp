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
        .navbar { background-color: #1a1f2e; border-bottom: 1px solid #252b3d; padding: 12px 32px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 100; }
        .navbar-brand { display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 700; color: #3b82f6; text-decoration: none; }
        .navbar-menu { display: flex; align-items: center; gap: 32px; }
        .navbar-menu a { color: #9ca3af; text-decoration: none; font-size: 14px; font-weight: 500; transition: color 0.2s; }
        .navbar-menu a:hover, .navbar-menu a.active { color: #ffffff; }
        .navbar-right { display: flex; align-items: center; gap: 16px; }
        .user-avatar { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; cursor: pointer; }
        .main-content { max-width: 1200px; margin: 0 auto; padding: 32px; }
        .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 32px; }
        .page-header h1 { font-size: 28px; font-weight: 700; }
        .header-actions { display: flex; gap: 12px; }
        .btn { display: flex; align-items: center; gap: 8px; padding: 10px 20px; border-radius: 10px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s; border: none; }
        .btn-primary { background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: #ffffff; }
        .btn-primary:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .btn-outline { background-color: transparent; color: #d1d5db; border: 1px solid #374151; }
        .btn-outline:hover { background-color: #1a1f2e; border-color: #6b7280; }
        .group-tabs { display: flex; gap: 8px; margin-bottom: 24px; flex-wrap: wrap; }
        .group-tab { display: flex; align-items: center; gap: 8px; padding: 10px 16px; background-color: #1a1f2e; border: 1px solid transparent; border-radius: 10px; color: #9ca3af; font-size: 14px; cursor: pointer; transition: all 0.2s; }
        .group-tab:hover { background-color: #252b3d; }
        .group-tab.active { background-color: #252b3d; border-color: #3b82f6; color: #ffffff; }
        .group-tab .dot { width: 8px; height: 8px; border-radius: 50%; }
        .group-tab .count { font-size: 12px; background-color: #374151; padding: 2px 8px; border-radius: 10px; }
        .stock-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }
        .stock-card { background-color: #1a1f2e; border-radius: 12px; padding: 20px; transition: all 0.2s; cursor: pointer; }
        .stock-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3); }
        .stock-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px; }
        .stock-info { display: flex; align-items: center; gap: 12px; }
        .stock-icon { width: 48px; height: 48px; border-radius: 12px; background-color: #252b3d; display: flex; align-items: center; justify-content: center; font-size: 20px; }
        .stock-name h3 { font-size: 18px; font-weight: 600; margin-bottom: 2px; }
        .stock-name p { font-size: 12px; color: #6b7280; }
        .stock-actions { display: flex; gap: 4px; }
        .action-btn { width: 32px; height: 32px; border-radius: 8px; background-color: #252b3d; border: none; color: #9ca3af; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
        .action-btn:hover { background-color: #374151; color: #ffffff; }
        .action-btn.remove:hover { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .action-btn svg { width: 16px; height: 16px; }
        .stock-price { display: flex; align-items: baseline; gap: 12px; }
        .price-value { font-size: 24px; font-weight: 700; }
        .price-change { font-size: 14px; padding: 4px 8px; border-radius: 6px; }
        .price-change.positive { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; }
        .price-change.negative { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .stock-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 16px; padding-top: 16px; border-top: 1px solid #252b3d; }
        .stock-group { font-size: 12px; padding: 4px 10px; border-radius: 6px; background-color: #252b3d; color: #9ca3af; }
        .stock-time { font-size: 11px; color: #6b7280; }
        .empty-state { text-align: center; padding: 80px 20px; color: #6b7280; }
        .empty-state svg { width: 80px; height: 80px; margin-bottom: 20px; opacity: 0.3; }
        .empty-state h3 { font-size: 20px; margin-bottom: 8px; color: #9ca3af; }
        .empty-state p { margin-bottom: 24px; }
        .empty-state a { display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: #ffffff; text-decoration: none; border-radius: 10px; font-weight: 500; transition: all 0.2s; }
        .empty-state a:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(0, 0, 0, 0.7); z-index: 1000; justify-content: center; align-items: center; }
        .modal-overlay.active { display: flex; }
        .modal { background-color: #1a1f2e; border-radius: 16px; padding: 24px; width: 100%; max-width: 400px; margin: 20px; }
        .modal h2 { font-size: 18px; margin-bottom: 20px; }
        .modal-input { width: 100%; padding: 12px 16px; background-color: #252b3d; border: 1px solid #374151; border-radius: 8px; color: #ffffff; font-size: 14px; margin-bottom: 16px; }
        .modal-input:focus { outline: none; border-color: #3b82f6; }
        .color-picker { display: flex; gap: 8px; margin-bottom: 20px; }
        .color-option { width: 32px; height: 32px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; transition: all 0.2s; }
        .color-option:hover, .color-option.active { border-color: #ffffff; transform: scale(1.1); }
        .modal-actions { display: flex; gap: 12px; justify-content: flex-end; }
        .modal-actions .btn { padding: 10px 20px; }
        .dropdown { position: relative; }
        .dropdown-menu { display: none; position: absolute; top: 100%; right: 0; background-color: #1a1f2e; border: 1px solid #252b3d; border-radius: 8px; min-width: 160px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3); z-index: 50; margin-top: 4px; }
        .dropdown-menu.active { display: block; }
        .dropdown-item { display: flex; align-items: center; gap: 8px; padding: 10px 16px; color: #d1d5db; font-size: 14px; cursor: pointer; transition: all 0.2s; }
        .dropdown-item:hover { background-color: #252b3d; }
        .dropdown-item.danger { color: #ef4444; }
        .dropdown-divider { height: 1px; background-color: #252b3d; margin: 4px 0; }
        @media (max-width: 768px) { .page-header { flex-direction: column; gap: 16px; align-items: flex-start; } .stock-grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="/dashboard" class="navbar-brand">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M3 3v18h18V3H3zm16 16H5V5h14v14zM7 12l3-3 2 2 4-4 3 3v5H7v-3z"/></svg>
            The Salty Spitoon
        </a>
        <div class="navbar-menu">
            <a href="/dashboard">Market</a>
            <a href="/watchlist" class="active">Watchlist</a>
            <a href="/news">News</a>
            <a href="/news/saved">Saved</a>
            <a href="/admin">Admin</a>
        </div>
        <div class="navbar-right">
            <sec:authorize access="isAuthenticated()">
                <div class="user-avatar" onclick="location.href='/logout'" title="로그아웃">
                    <sec:authentication property="principal.username" var="userEmail"/>
                    <c:out value="${userEmail.substring(0,1).toUpperCase()}"/>
                </div>
            </sec:authorize>
        </div>
    </nav>

    <main class="main-content">
        <div class="page-header">
            <h1>⭐ My Watchlist</h1>
            <div class="header-actions">
                <button class="btn btn-outline" onclick="openGroupModal()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
                    New Group
                </button>
            </div>
        </div>

        <div class="group-tabs">
            <button class="group-tab active" onclick="filterByGroup(null, this)">All <span class="count" id="all-count">0</span></button>
            <button class="group-tab" onclick="filterByGroup(0, this)">
                <span class="dot" style="background-color: #6b7280;"></span>
                Ungrouped <span class="count" id="ungrouped-count">0</span>
            </button>
            <c:forEach var="group" items="${groups}">
                <button class="group-tab" data-group-id="${group.id}" data-color="${group.color}">
                    <span class="dot"></span>
                    <c:out value="${group.name}"/>
                    <span class="count">0</span>
                </button>
            </c:forEach>
        </div>

        <div class="stock-grid" id="stock-grid"></div>

        <div class="empty-state" id="empty-state" style="display: none;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            <h3>No stocks in watchlist</h3>
            <p>Add stocks to your watchlist to track them here</p>
            <a href="/dashboard">Browse Stocks <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M12 5l7 7-7 7"/></svg></a>
        </div>
    </main>

    <div class="modal-overlay" id="group-modal">
        <div class="modal">
            <h2 id="modal-title">Create New Group</h2>
            <input type="text" class="modal-input" id="group-name" placeholder="Group name">
            <div class="color-picker" id="color-picker">
                <div class="color-option active" style="background-color: #3b82f6;" data-color="#3b82f6"></div>
                <div class="color-option" style="background-color: #22c55e;" data-color="#22c55e"></div>
                <div class="color-option" style="background-color: #f59e0b;" data-color="#f59e0b"></div>
                <div class="color-option" style="background-color: #ef4444;" data-color="#ef4444"></div>
                <div class="color-option" style="background-color: #a855f7;" data-color="#a855f7"></div>
                <div class="color-option" style="background-color: #ec4899;" data-color="#ec4899"></div>
            </div>
            <div class="modal-actions">
                <button class="btn btn-outline" onclick="closeGroupModal()">Cancel</button>
                <button class="btn btn-primary" onclick="saveGroup()">Create</button>
            </div>
        </div>
    </div>

    <script>
        var watchlistData = [];
        var groupsData = [];
        var currentGroupFilter = null;
        var editingGroupId = null;
        var selectedColor = '#3b82f6';

        var stockIcons = {
            'AAPL': '🍎', 'MSFT': '🪟', 'GOOGL': '🔍', 'AMZN': '📦',
            'NVDA': '🎮', 'TSLA': '🚗', 'META': '👤', 'NFLX': '🎬',
            'AMD': '💻', 'INTC': '🔷', 'ORCL': '☁️', 'CRM': '📊'
        };

        document.addEventListener('DOMContentLoaded', function() {
            loadWatchlist();
            loadGroups();
            setupColorPicker();
            applyGroupColors();
        });

        function applyGroupColors() {
            var tabs = document.querySelectorAll('.group-tab[data-group-id]');
            for (var i = 0; i < tabs.length; i++) {
                var tab = tabs[i];
                var color = tab.getAttribute('data-color');
                var groupId = parseInt(tab.getAttribute('data-group-id'));
                var dot = tab.querySelector('.dot');
                if (dot && color) {
                    dot.style.backgroundColor = color;
                }
                (function(gid, t) {
                    t.addEventListener('click', function() {
                        filterByGroup(gid, t);
                    });
                })(groupId, tab);
            }
        }

        function loadWatchlist() {
            fetch('/api/watchlist')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        watchlistData = data.data;
                        renderWatchlist();
                        updateCounts();
                    }
                })
                .catch(function(error) {
                    console.error('Failed to load watchlist:', error);
                });
        }

        function loadGroups() {
            fetch('/api/watchlist/groups')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        groupsData = data.data;
                    }
                })
                .catch(function(error) {
                    console.error('Failed to load groups:', error);
                });
        }

        function renderWatchlist() {
            var grid = document.getElementById('stock-grid');
            var emptyState = document.getElementById('empty-state');

            var filtered = watchlistData;
            if (currentGroupFilter !== null) {
                if (currentGroupFilter === 0) {
                    filtered = watchlistData.filter(function(w) { return !w.groupId; });
                } else {
                    filtered = watchlistData.filter(function(w) { return w.groupId === currentGroupFilter; });
                }
            }

            if (filtered.length === 0) {
                grid.innerHTML = '';
                emptyState.style.display = 'block';
                return;
            }

            emptyState.style.display = 'none';

            var html = '';
            for (var i = 0; i < filtered.length; i++) {
                var stock = filtered[i];
                var icon = stockIcons[stock.symbol] || '📈';
                var groupColor = getGroupColor(stock.groupId);
                
                html += '<div class="stock-card" onclick="location.href=\'/stock/detail/' + stock.symbol + '\'">';
                html += '<div class="stock-header">';
                html += '<div class="stock-info">';
                html += '<div class="stock-icon">' + icon + '</div>';
                html += '<div class="stock-name"><h3>' + stock.symbol + '</h3><p id="name-' + stock.symbol + '">Loading...</p></div>';
                html += '</div>';
                html += '<div class="stock-actions"><div class="dropdown">';
                html += '<button class="action-btn" onclick="event.stopPropagation(); toggleDropdown(\'' + stock.symbol + '\')">';
                html += '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>';
                html += '</button>';
                html += '<div class="dropdown-menu" id="dropdown-' + stock.symbol + '">';
                
                for (var j = 0; j < groupsData.length; j++) {
                    var g = groupsData[j];
                    html += '<div class="dropdown-item" onclick="event.stopPropagation(); moveToGroup(\'' + stock.symbol + '\', ' + g.id + ')">';
                    html += '<span class="dot" style="background-color: ' + g.color + '; width: 8px; height: 8px; border-radius: 50%;"></span>';
                    html += 'Move to ' + g.name + '</div>';
                }
                
                if (stock.groupId) {
                    html += '<div class="dropdown-item" onclick="event.stopPropagation(); moveToGroup(\'' + stock.symbol + '\', null)">Remove from group</div>';
                }
                
                html += '<div class="dropdown-divider"></div>';
                html += '<div class="dropdown-item danger" onclick="event.stopPropagation(); removeFromWatchlist(\'' + stock.symbol + '\')">';
                html += '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>';
                html += 'Remove</div>';
                html += '</div></div></div></div>';
                
                html += '<div class="stock-price">';
                html += '<span class="price-value" id="price-' + stock.symbol + '">$--</span>';
                html += '<span class="price-change positive" id="change-' + stock.symbol + '">--%</span>';
                html += '</div>';
                
                html += '<div class="stock-footer">';
                if (stock.groupName) {
                    html += '<span class="stock-group" style="border-left: 3px solid ' + groupColor + '; padding-left: 8px;">' + stock.groupName + '</span>';
                } else {
                    html += '<span></span>';
                }
                html += '<span class="stock-time">Added ' + formatDate(stock.createdAt) + '</span>';
                html += '</div></div>';
            }

            grid.innerHTML = html;

            for (var k = 0; k < filtered.length; k++) {
                fetchStockPrice(filtered[k].symbol);
            }
        }

        function fetchStockPrice(symbol) {
            fetch('/api/stocks/' + symbol + '/latest')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data) {
                        var priceEl = document.getElementById('price-' + symbol);
                        var changeEl = document.getElementById('change-' + symbol);
                        var nameEl = document.getElementById('name-' + symbol);

                        if (priceEl) {
                            var price = data.closePrice || data.close_price || 0;
                            priceEl.textContent = '$' + price.toFixed(2);
                        }
                        if (changeEl) {
                            var change = data.changePercent || data.change_percent || 0;
                            changeEl.textContent = (change >= 0 ? '+' : '') + change.toFixed(2) + '%';
                            changeEl.className = 'price-change ' + (change >= 0 ? 'positive' : 'negative');
                        }
                        if (nameEl && data.name) {
                            nameEl.textContent = data.name;
                        }
                    }
                })
                .catch(function(error) {
                    console.error('Failed to fetch price for', symbol);
                });
        }

        function filterByGroup(groupId, btn) {
            currentGroupFilter = groupId;
            var tabs = document.querySelectorAll('.group-tab');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.remove('active');
            }
            btn.classList.add('active');
            renderWatchlist();
        }

        function updateCounts() {
            document.getElementById('all-count').textContent = watchlistData.length;
            document.getElementById('ungrouped-count').textContent = watchlistData.filter(function(w) { return !w.groupId; }).length;

            for (var i = 0; i < groupsData.length; i++) {
                var group = groupsData[i];
                var tab = document.querySelector('[data-group-id="' + group.id + '"] .count');
                if (tab) {
                    tab.textContent = watchlistData.filter(function(w) { return w.groupId === group.id; }).length;
                }
            }
        }

        function getGroupColor(groupId) {
            for (var i = 0; i < groupsData.length; i++) {
                if (groupsData[i].id === groupId) {
                    return groupsData[i].color;
                }
            }
            return '#6b7280';
        }

        function formatDate(dateStr) {
            var date = new Date(dateStr);
            var now = new Date();
            var diff = now - date;
            var days = Math.floor(diff / (1000 * 60 * 60 * 24));
            if (days === 0) return 'today';
            if (days === 1) return 'yesterday';
            if (days < 7) return days + ' days ago';
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        }

        function toggleDropdown(symbol) {
            var menus = document.querySelectorAll('.dropdown-menu');
            for (var i = 0; i < menus.length; i++) {
                menus[i].classList.remove('active');
            }
            document.getElementById('dropdown-' + symbol).classList.toggle('active');
        }

        function moveToGroup(symbol, groupId) {
            fetch('/api/watchlist/move', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ symbol: symbol, groupId: groupId })
            })
            .then(function(response) { return response.json(); })
            .then(function(data) {
                if (data.success) {
                    loadWatchlist();
                }
            })
            .catch(function(error) {
                console.error('Failed to move to group:', error);
            });
        }

        function removeFromWatchlist(symbol) {
            if (!confirm('Remove ' + symbol + ' from watchlist?')) return;
            fetch('/api/watchlist/toggle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ symbol: symbol })
            })
            .then(function(response) { return response.json(); })
            .then(function(data) {
                if (data.success) {
                    loadWatchlist();
                }
            })
            .catch(function(error) {
                console.error('Failed to remove from watchlist:', error);
            });
        }

        function openGroupModal() {
            editingGroupId = null;
            document.getElementById('modal-title').textContent = 'Create New Group';
            document.getElementById('group-name').value = '';
            selectedColor = '#3b82f6';
            var options = document.querySelectorAll('.color-option');
            for (var i = 0; i < options.length; i++) {
                options[i].classList.remove('active');
            }
            document.querySelector('[data-color="#3b82f6"]').classList.add('active');
            document.getElementById('group-modal').classList.add('active');
        }

        function closeGroupModal() {
            document.getElementById('group-modal').classList.remove('active');
        }

        function setupColorPicker() {
            var options = document.querySelectorAll('.color-option');
            for (var i = 0; i < options.length; i++) {
                options[i].addEventListener('click', function() {
                    for (var j = 0; j < options.length; j++) {
                        options[j].classList.remove('active');
                    }
                    this.classList.add('active');
                    selectedColor = this.getAttribute('data-color');
                });
            }
        }

        function saveGroup() {
            var name = document.getElementById('group-name').value.trim();
            if (!name) {
                alert('Please enter a group name');
                return;
            }
            fetch('/api/watchlist/groups', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: name, color: selectedColor })
            })
            .then(function(response) { return response.json(); })
            .then(function(data) {
                if (data.success) {
                    closeGroupModal();
                    location.reload();
                } else {
                    alert(data.message);
                }
            })
            .catch(function(error) {
                console.error('Failed to create group:', error);
            });
        }

        document.addEventListener('click', function(e) {
            if (!e.target.closest('.dropdown')) {
                var menus = document.querySelectorAll('.dropdown-menu');
                for (var i = 0; i < menus.length; i++) {
                    menus[i].classList.remove('active');
                }
            }
            if (e.target.classList.contains('modal-overlay')) {
                closeGroupModal();
            }
        });
    </script>
</body>
</html>
