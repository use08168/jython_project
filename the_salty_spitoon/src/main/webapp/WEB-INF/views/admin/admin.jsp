<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - The Salty Spitoon</title>
    
    <!-- Bootstrap 3.3.7 -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    
    <style>
        body {
            background-color: #1a1a1a;
            color: #e0e0e0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
        }
        
        .section {
            background-color: #2a2a2a;
            border: 1px solid #3a3a3a;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 20px;
            color: #4CAF50;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }
        
        .btn-custom {
            margin: 5px;
            min-width: 150px;
        }
        
        .status-box {
            background-color: #1a1a1a;
            border: 1px solid #3a3a3a;
            border-radius: 5px;
            padding: 15px;
            margin-top: 15px;
            font-family: 'Courier New', monospace;
            white-space: pre-wrap;
            max-height: 400px;
            overflow-y: auto;
        }
        
        .table {
            color: #e0e0e0;
        }
        
        .table-striped > tbody > tr:nth-of-type(odd) {
            background-color: #2a2a2a;
        }
        
        .table-bordered {
            border: 1px solid #3a3a3a;
        }
        
        .table-bordered > thead > tr > th,
        .table-bordered > tbody > tr > td {
            border: 1px solid #3a3a3a;
        }
        
        .label-ok {
            background-color: #4CAF50;
        }
        
        .label-gap {
            background-color: #FF9800;
        }
        
        .label-no-data {
            background-color: #F44336;
        }
        
        .label-null {
            background-color: #9C27B0;
        }
        
        .label-anomaly {
            background-color: #FF5722;
        }
        
        .progress {
            height: 30px;
            background-color: #1a1a1a;
        }
        
        .progress-bar {
            font-size: 14px;
            line-height: 30px;
        }
        
        .issue-detail {
            font-size: 12px;
            color: #aaa;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 style="color: #4CAF50; margin-bottom: 30px;">
            📊 Admin Dashboard - The Salty Spitoon
        </h1>
        
        <!-- ========================================
             Section 1: 최신 데이터 로드 (Latest Data Load)
             ======================================== -->
        <div class="section">
            <div class="section-title">
                📊 최신 데이터 로드 (Latest Data Load)
            </div>
            
            <p style="color: #aaa;">
                MySQL에 저장된 데이터와 현재 시각을 비교하여 공백을 자동으로 채웁니다.
            </p>
            
            <div style="margin-bottom: 20px;">
                <button class="btn btn-primary btn-custom" onclick="checkDataStatus()">
                    🔍 데이터 상태 확인
                </button>
                
                <button class="btn btn-success btn-custom" onclick="loadLatestData()" id="loadLatestBtn">
                    ✅ 최신 데이터 로드
                </button>
            </div>
            
            <!-- 데이터 상태 표시 영역 -->
            <div id="dataStatusArea" style="display: none;">
                <h4 style="color: #4CAF50; margin-top: 20px;">📋 데이터 상태</h4>
                
                <div style="margin-bottom: 15px;">
                    <span id="statusSummary" style="font-size: 16px;"></span>
                </div>
                
                <div class="table-responsive">
                    <table class="table table-bordered table-striped" id="statusTable">
                        <thead style="background-color: #3a3a3a;">
                            <tr>
                                <th>종목</th>
                                <th>회사명</th>
                                <th>MySQL 최신</th>
                                <th>현재 시각</th>
                                <th>공백 (분)</th>
                                <th>상태</th>
                            </tr>
                        </thead>
                        <tbody id="statusTableBody">
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- 수집 진행 상황 -->
            <div id="loadProgressArea" style="display: none;">
                <h4 style="color: #4CAF50; margin-top: 20px;">🔄 수집 진행 중...</h4>
                
                <div class="progress">
                    <div class="progress-bar progress-bar-success progress-bar-striped active" 
                         id="loadProgressBar" 
                         role="progressbar" 
                         style="width: 0%">
                        0%
                    </div>
                </div>
                
                <div id="loadProgressText" style="margin-top: 10px; font-size: 14px;">
                </div>
            </div>
            
            <!-- 수집 결과 -->
            <div id="loadResultArea" style="display: none;">
                <h4 style="color: #4CAF50; margin-top: 20px;">✅ 수집 완료</h4>
                <div class="status-box" id="loadResultBox"></div>
            </div>
        </div>
        
        <!-- ========================================
             Section 2: 데이터 무결성 검사 (Data Integrity Check) - Phase 3
             ======================================== -->
        <div class="section">
            <div class="section-title">
                🔍 데이터 무결성 검사 (Data Integrity Check)
            </div>
            
            <p style="color: #aaa;">
                데이터 공백, NULL 값, 이상치를 감지하고 자동으로 수정합니다.
            </p>
            
            <div style="margin-bottom: 20px;">
                <button class="btn btn-warning btn-custom" onclick="checkIntegrity()">
                    🔍 무결성 검사
                </button>
                
                <button class="btn btn-danger btn-custom" onclick="fixAllIssues()" id="fixIssuesBtn" style="display: none;">
                    🔧 전체 수정
                </button>
            </div>
            
            <!-- 검사 결과 표시 영역 -->
            <div id="integrityResultArea" style="display: none;">
                <h4 style="color: #4CAF50; margin-top: 20px;">📋 검사 결과</h4>
                
                <div style="margin-bottom: 15px;">
                    <span id="integritySummary" style="font-size: 16px;"></span>
                </div>
                
                <div class="table-responsive">
                    <table class="table table-bordered table-striped" id="integrityTable">
                        <thead style="background-color: #3a3a3a;">
                            <tr>
                                <th>종목</th>
                                <th>유형</th>
                                <th>시작 시각</th>
                                <th>종료 시각</th>
                                <th>상세 정보</th>
                                <th>수정 가능</th>
                            </tr>
                        </thead>
                        <tbody id="integrityTableBody">
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- 수정 결과 -->
            <div id="fixResultArea" style="display: none;">
                <h4 style="color: #4CAF50; margin-top: 20px;">✅ 수정 완료</h4>
                <div class="status-box" id="fixResultBox"></div>
            </div>
        </div>
        
        <!-- ========================================
             Section 3: 재무 데이터 관리 (Financial Data)
             ======================================== -->
        <div class="section">
            <div class="section-title">
                💰 재무 데이터 관리 (Financial Data)
            </div>
            
            <p style="color: #aaa;">
                NASDAQ 100 종목의 재무제표, 대차대조표, 현금흐름표 등 재무 데이터를 관리합니다.
            </p>
            
            <div style="margin-bottom: 20px;">
                <button class="btn btn-primary btn-custom" onclick="collectFinancialData()">
                    📥 재무 데이터 수집
                </button>
                
                <button class="btn btn-success btn-custom" onclick="loadLatestFinancialData()">
                    ✅ 최신 재무 데이터 로드
                </button>
                
                <button class="btn btn-info btn-custom" onclick="checkCollectionStatus()">
                    🔄 수집 상태 확인
                </button>
            </div>
            
            <div class="status-box" id="financialStatus"></div>
            
            <!-- JSON 파일 목록 -->
            <c:if test="${not empty financialJsonFiles}">
                <h4 style="color: #4CAF50; margin-top: 20px;">📁 사용 가능한 JSON 파일</h4>
                <div class="table-responsive">
                    <table class="table table-bordered table-striped">
                        <thead style="background-color: #3a3a3a;">
                            <tr>
                                <th>파일명</th>
                                <th>작업</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${financialJsonFiles}" var="jsonFile">
                                <tr>
                                    <td>${jsonFile}</td>
                                    <td>
                                        <button class="btn btn-sm btn-success" onclick="loadFinancialData('${jsonFile}')">
                                            로드
                                        </button>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:if>
        </div>
        
        <!-- ========================================
             Section 4: 레거시 (삭제 예정)
             ======================================== -->
        <div class="section" style="opacity: 0.5;">
            <div class="section-title">
                🗂️ 레거시 기능 (삭제 예정)
            </div>
            
            <button class="btn btn-warning btn-custom" onclick="loadNasdaq100()">
                NASDAQ 100 종목 로드
            </button>
            
            <button class="btn btn-warning btn-custom" onclick="loadHistoricalData()">
                과거 데이터 로드 (Config 기반)
            </button>
            
            <div class="status-box" id="legacyStatus"></div>
        </div>
    </div>
    
    <!-- jQuery & Bootstrap JS -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    
    <script>
        // 전역 변수 (무결성 검사 결과 저장)
        let currentIssues = [];
        
        // ========================================
        // Latest Data Load Functions
        // ========================================
        
        function checkDataStatus() {
            $('#dataStatusArea').hide();
            $('#loadProgressArea').hide();
            $('#loadResultArea').hide();
            
            $.ajax({
                url: '/admin/check-data-status',
                method: 'GET',
                success: function(data) {
                    displayDataStatus(data);
                },
                error: function(xhr) {
                    alert('데이터 상태 확인 실패: ' + xhr.responseText);
                }
            });
        }
        
        function displayDataStatus(statusList) {
            let totalSymbols = statusList.length;
            let okCount = statusList.filter(s => s.status === 'OK').length;
            let gapCount = statusList.filter(s => s.status === 'GAP').length;
            let noDataCount = statusList.filter(s => s.status === 'NO_DATA').length;
            
            $('#statusSummary').html(
                '총 ' + totalSymbols + '개 종목 | ' +
                '<span class="label label-ok">' + okCount + ' OK</span> ' +
                '<span class="label label-gap">' + gapCount + ' GAP</span> ' +
                '<span class="label label-no-data">' + noDataCount + ' NO DATA</span>'
            );
            
            let tbody = $('#statusTableBody');
            tbody.empty();
            
            statusList.forEach(function(status) {
                let statusLabel = '';
                if (status.status === 'OK') {
                    statusLabel = '<span class="label label-ok">OK</span>';
                } else if (status.status === 'GAP') {
                    statusLabel = '<span class="label label-gap">GAP</span>';
                } else if (status.status === 'NO_DATA') {
                    statusLabel = '<span class="label label-no-data">NO DATA</span>';
                }
                
                let mysqlLatest = status.mysqlLatest || '-';
                let yahooLatest = status.yahooLatest || '-';
                
                tbody.append(
                    '<tr>' +
                    '<td>' + status.symbol + '</td>' +
                    '<td>' + status.name + '</td>' +
                    '<td>' + mysqlLatest + '</td>' +
                    '<td>' + yahooLatest + '</td>' +
                    '<td>' + status.gapMinutes + '</td>' +
                    '<td>' + statusLabel + '</td>' +
                    '</tr>'
                );
            });
            
            $('#dataStatusArea').show();
        }
        
        function loadLatestData() {
            if (!confirm('최신 데이터를 수집하시겠습니까?\n\n공백이 있는 모든 종목의 데이터를 자동으로 수집합니다.\n예상 시간: 5-10분')) {
                return;
            }
            
            $('#loadLatestBtn').prop('disabled', true);
            $('#loadProgressArea').show();
            $('#loadResultArea').hide();
            
            $.ajax({
                url: '/admin/load-latest-data',
                method: 'POST',
                success: function(result) {
                    displayLoadResult(result);
                    $('#loadLatestBtn').prop('disabled', false);
                },
                error: function(xhr) {
                    alert('데이터 로드 실패: ' + xhr.responseText);
                    $('#loadLatestBtn').prop('disabled', false);
                    $('#loadProgressArea').hide();
                }
            });
        }
        
        function displayLoadResult(result) {
            $('#loadProgressArea').hide();
            
            let resultText = '========================================\n';
            resultText += '최신 데이터 로드 완료\n';
            resultText += '========================================\n\n';
            resultText += '총 종목: ' + result.totalSymbols + '\n';
            resultText += '성공: ' + result.successCount + '\n';
            resultText += '실패: ' + result.failureCount + '\n';
            resultText += '총 수집 캔들: ' + result.totalCandles + '\n\n';
            resultText += '시작: ' + result.startTime + '\n';
            resultText += '종료: ' + result.endTime + '\n\n';
            resultText += '메시지: ' + result.message + '\n';
            
            if (result.symbolResults && result.symbolResults.length > 0) {
                resultText += '\n========================================\n';
                resultText += '종목별 결과\n';
                resultText += '========================================\n\n';
                
                result.symbolResults.forEach(function(sr) {
                    resultText += sr.symbol + ': ';
                    if (sr.success) {
                        resultText += '✅ ' + sr.candlesCollected + '개 수집\n';
                    } else {
                        resultText += '❌ ' + sr.message + '\n';
                    }
                });
            }
            
            $('#loadResultBox').text(resultText);
            $('#loadResultArea').show();
            
            checkDataStatus();
        }
        
        // ========================================
        // Data Integrity Check Functions (Phase 3)
        // ========================================
        
        function checkIntegrity() {
            $('#integrityResultArea').hide();
            $('#fixResultArea').hide();
            $('#fixIssuesBtn').hide();
            
            $.ajax({
                url: '/admin/check-integrity',
                method: 'GET',
                success: function(data) {
                    currentIssues = data;
                    displayIntegrityResult(data);
                },
                error: function(xhr) {
                    alert('무결성 검사 실패: ' + xhr.responseText);
                }
            });
        }
        
        function displayIntegrityResult(issues) {
            let gapCount = issues.filter(i => i.type === 'GAP').length;
            let nullCount = issues.filter(i => i.type === 'NULL').length;
            let anomalyCount = issues.filter(i => i.type === 'ANOMALY').length;
            let fixableCount = issues.filter(i => i.fixable).length;
            
            $('#integritySummary').html(
                '총 문제: ' + issues.length + '개 | ' +
                '<span class="label label-gap">' + gapCount + ' 공백</span> ' +
                '<span class="label label-null">' + nullCount + ' NULL</span> ' +
                '<span class="label label-anomaly">' + anomalyCount + ' 이상치</span> ' +
                '<span class="label label-info">' + fixableCount + ' 수정 가능</span>'
            );
            
            let tbody = $('#integrityTableBody');
            tbody.empty();
            
            if (issues.length === 0) {
                tbody.append(
                    '<tr>' +
                    '<td colspan="6" style="text-align: center; color: #4CAF50;">✅ 문제가 발견되지 않았습니다!</td>' +
                    '</tr>'
                );
            } else {
                issues.forEach(function(issue) {
                    let typeLabel = '';
                    if (issue.type === 'GAP') {
                        typeLabel = '<span class="label label-gap">공백</span>';
                    } else if (issue.type === 'NULL') {
                        typeLabel = '<span class="label label-null">NULL</span>';
                    } else if (issue.type === 'ANOMALY') {
                        typeLabel = '<span class="label label-anomaly">이상치</span>';
                    }
                    
                    let detail = '';
                    if (issue.type === 'GAP') {
                        detail = issue.gapMinutes + '분 공백';
                    } else if (issue.type === 'NULL') {
                        detail = 'NULL: ' + issue.nullField;
                    } else if (issue.type === 'ANOMALY') {
                        detail = issue.anomalyDescription;
                    }
                    
                    let fixable = issue.fixable ? 
                        '<span class="label label-success">가능</span>' : 
                        '<span class="label label-danger">불가</span>';
                    
                    tbody.append(
                        '<tr>' +
                        '<td>' + issue.symbol + '</td>' +
                        '<td>' + typeLabel + '</td>' +
                        '<td>' + issue.startTime + '</td>' +
                        '<td>' + (issue.endTime || '-') + '</td>' +
                        '<td class="issue-detail">' + detail + '</td>' +
                        '<td>' + fixable + '</td>' +
                        '</tr>'
                    );
                });
                
                if (fixableCount > 0) {
                    $('#fixIssuesBtn').show();
                }
            }
            
            $('#integrityResultArea').show();
        }
        
        function fixAllIssues() {
            if (currentIssues.length === 0) {
                alert('수정할 문제가 없습니다.');
                return;
            }
            
            let fixableIssues = currentIssues.filter(i => i.fixable);
            
            if (fixableIssues.length === 0) {
                alert('수정 가능한 문제가 없습니다.');
                return;
            }
            
            if (!confirm('총 ' + fixableIssues.length + '개의 문제를 수정하시겠습니까?\n\n예상 시간: ' + 
                        Math.ceil(fixableIssues.length / 10) + '-' + Math.ceil(fixableIssues.length / 5) + '분')) {
                return;
            }
            
            $('#fixIssuesBtn').prop('disabled', true);
            
            $.ajax({
                url: '/admin/fix-issues',
                method: 'POST',
                contentType: 'application/json',
                data: JSON.stringify(fixableIssues),
                success: function(result) {
                    displayFixResult(result);
                    $('#fixIssuesBtn').prop('disabled', false);
                    
                    // 재검사
                    setTimeout(function() {
                        checkIntegrity();
                    }, 2000);
                },
                error: function(xhr) {
                    alert('수정 실패: ' + xhr.responseText);
                    $('#fixIssuesBtn').prop('disabled', false);
                }
            });
        }
        
        function displayFixResult(result) {
            let resultText = '========================================\n';
            resultText += '문제 수정 완료\n';
            resultText += '========================================\n\n';
            resultText += '총 종목: ' + result.totalSymbols + '\n';
            resultText += '성공: ' + result.successCount + '\n';
            resultText += '실패: ' + result.failureCount + '\n';
            resultText += '총 수집 캔들: ' + result.totalCandles + '\n\n';
            resultText += '시작: ' + result.startTime + '\n';
            resultText += '종료: ' + result.endTime + '\n\n';
            resultText += '메시지: ' + result.message + '\n';
            
            if (result.symbolResults && result.symbolResults.length > 0) {
                resultText += '\n========================================\n';
                resultText += '종목별 결과\n';
                resultText += '========================================\n\n';
                
                result.symbolResults.forEach(function(sr) {
                    resultText += sr.symbol + ': ';
                    if (sr.success) {
                        resultText += '✅ ' + sr.message + '\n';
                    } else {
                        resultText += '❌ ' + sr.message + '\n';
                    }
                });
            }
            
            $('#fixResultBox').text(resultText);
            $('#fixResultArea').show();
        }
        
        // ========================================
        // Financial Data Functions
        // ========================================
        
        function collectFinancialData() {
            if (!confirm('재무 데이터 수집을 시작하시겠습니까?\n\n예상 소요 시간: 10-15분')) {
                return;
            }
            
            $.post('/admin/collect-financial-data', function(data) {
                $('#financialStatus').text(data);
            }).fail(function(xhr) {
                $('#financialStatus').text('Error: ' + xhr.responseText);
            });
        }
        
        function loadLatestFinancialData() {
            $.post('/admin/load-latest-financial-data', function(data) {
                $('#financialStatus').text(data);
            }).fail(function(xhr) {
                $('#financialStatus').text('Error: ' + xhr.responseText);
            });
        }
        
        function loadFinancialData(fileName) {
            $.post('/admin/load-financial-data', { jsonFileName: fileName }, function(data) {
                $('#financialStatus').text(data);
            }).fail(function(xhr) {
                $('#financialStatus').text('Error: ' + xhr.responseText);
            });
        }
        
        function checkCollectionStatus() {
            $.get('/admin/collection-status', function(data) {
                $('#financialStatus').text(data);
            });
        }
        
        // ========================================
        // Legacy Functions
        // ========================================
        
        function loadNasdaq100() {
            $.post('/admin/load-nasdaq100', function(data) {
                $('#legacyStatus').text(data);
            });
        }
        
        function loadHistoricalData() {
            $.post('/admin/load-historical-data', function(data) {
                $('#legacyStatus').text(data);
            });
        }
    </script>
</body>
</html>