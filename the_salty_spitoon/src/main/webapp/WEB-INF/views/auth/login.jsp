<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>로그인 - The Salty Spitoon</title>
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
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-container {
            width: 100%;
            max-width: 420px;
            padding: 40px;
        }

        .logo {
            text-align: center;
            margin-bottom: 40px;
        }

        .logo h1 {
            font-size: 28px;
            font-weight: 700;
            color: #3b82f6;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }

        .logo-icon {
            font-size: 32px;
        }

        .login-card {
            background-color: #1a1f2e;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
        }

        .login-card h2 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
            text-align: center;
        }

        .login-card p {
            color: #9ca3af;
            font-size: 14px;
            text-align: center;
            margin-bottom: 30px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 8px;
            color: #e5e7eb;
        }

        .form-group input {
            width: 100%;
            padding: 14px 16px;
            font-size: 15px;
            background-color: #252b3d;
            border: 1px solid #374151;
            border-radius: 10px;
            color: #ffffff;
            transition: all 0.2s;
        }

        .form-group input:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
        }

        .form-group input::placeholder {
            color: #6b7280;
        }

        .error-message {
            background-color: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: #f87171;
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 14px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .success-message {
            background-color: rgba(34, 197, 94, 0.1);
            border: 1px solid rgba(34, 197, 94, 0.3);
            color: #4ade80;
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 14px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-login {
            width: 100%;
            padding: 14px;
            font-size: 16px;
            font-weight: 600;
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: #ffffff;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-login:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
        }

        .btn-login:active {
            transform: translateY(0);
        }

        .forgot-password {
            text-align: right;
            margin-bottom: 20px;
        }

        .forgot-password a {
            color: #9ca3af;
            font-size: 13px;
            text-decoration: none;
            transition: color 0.2s;
        }

        .forgot-password a:hover {
            color: #3b82f6;
        }

        .divider {
            display: flex;
            align-items: center;
            margin: 30px 0;
        }

        .divider::before,
        .divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background-color: #374151;
        }

        .divider span {
            padding: 0 16px;
            color: #6b7280;
            font-size: 13px;
        }

        .signup-link {
            text-align: center;
            font-size: 14px;
            color: #9ca3af;
        }

        .signup-link a {
            color: #3b82f6;
            text-decoration: none;
            font-weight: 500;
        }

        .signup-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">
            <h1><span class="logo-icon">📈</span> The Salty Spitoon</h1>
        </div>

        <div class="login-card">
            <h2>로그인</h2>
            <p>계정에 로그인하여 NASDAQ 100 분석을 시작하세요</p>

            <c:if test="${param.error != null}">
                <div class="error-message">
                    ⚠️ 이메일 또는 비밀번호가 올바르지 않습니다.
                </div>
            </c:if>

            <c:if test="${param.logout != null}">
                <div class="success-message">
                    ✅ 로그아웃되었습니다.
                </div>
            </c:if>

            <c:if test="${param.expired != null}">
                <div class="error-message">
                    ⚠️ 세션이 만료되었습니다. 다시 로그인해주세요.
                </div>
            </c:if>

            <c:if test="${param.signup != null}">
                <div class="success-message">
                    ✅ 회원가입이 완료되었습니다. 로그인해주세요.
                </div>
            </c:if>

            <form action="/api/auth/login" method="POST">
                <div class="form-group">
                    <label for="email">이메일</label>
                    <input type="email" id="email" name="email" placeholder="이메일을 입력하세요" required>
                </div>

                <div class="form-group">
                    <label for="password">비밀번호</label>
                    <input type="password" id="password" name="password" placeholder="비밀번호를 입력하세요" required>
                </div>

                <div class="forgot-password">
                    <a href="/forgot-password">비밀번호를 잊으셨나요?</a>
                </div>

                <button type="submit" class="btn-login">로그인</button>
            </form>

            <div class="divider">
                <span>또는</span>
            </div>

            <div class="signup-link">
                계정이 없으신가요? <a href="/signup">회원가입</a>
            </div>
        </div>
    </div>
</body>
</html>
