<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>회원가입 - The Salty Spitoon</title>
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
            padding: 20px;
        }

        .signup-container {
            width: 100%;
            max-width: 480px;
        }

        .logo {
            text-align: center;
            margin-bottom: 30px;
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

        .signup-card {
            background-color: #1a1f2e;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
        }

        .signup-card h2 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
            text-align: center;
        }

        .signup-card > p {
            color: #9ca3af;
            font-size: 14px;
            text-align: center;
            margin-bottom: 30px;
        }

        /* 스텝 인디케이터 */
        .step-indicator {
            display: flex;
            justify-content: center;
            gap: 16px;
            margin-bottom: 30px;
        }

        .step {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .step-number {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: #374151;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }

        .step.active .step-number {
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
        }

        .step.completed .step-number {
            background-color: #22c55e;
        }

        .step-label {
            font-size: 13px;
            color: #6b7280;
        }

        .step.active .step-label {
            color: #ffffff;
        }

        .step-line {
            width: 40px;
            height: 2px;
            background-color: #374151;
            align-self: center;
        }

        .step-line.completed {
            background-color: #22c55e;
        }

        /* 폼 그룹 */
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

        .form-group input.error {
            border-color: #ef4444;
        }

        .form-group input.success {
            border-color: #22c55e;
        }

        .form-group .help-text {
            font-size: 12px;
            margin-top: 6px;
            color: #9ca3af;
        }

        .form-group .error-text {
            font-size: 12px;
            margin-top: 6px;
            color: #f87171;
        }

        .form-group .success-text {
            font-size: 12px;
            margin-top: 6px;
            color: #4ade80;
        }

        /* 인증 코드 입력 */
        .code-input-wrapper {
            display: flex;
            gap: 10px;
        }

        .code-input-wrapper input {
            flex: 1;
        }

        .btn-send-code {
            padding: 14px 20px;
            font-size: 14px;
            font-weight: 500;
            background-color: #374151;
            color: #ffffff;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.2s;
        }

        .btn-send-code:hover {
            background-color: #4b5563;
        }

        .btn-send-code:disabled {
            background-color: #252b3d;
            color: #6b7280;
            cursor: not-allowed;
        }

        /* 타이머 */
        .timer {
            text-align: center;
            font-size: 14px;
            color: #f59e0b;
            margin-bottom: 20px;
        }

        /* 버튼 */
        .btn-primary {
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

        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
        }

        .btn-primary:disabled {
            background: #374151;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .btn-secondary {
            width: 100%;
            padding: 14px;
            font-size: 16px;
            font-weight: 600;
            background-color: transparent;
            color: #9ca3af;
            border: 1px solid #374151;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 12px;
        }

        .btn-secondary:hover {
            border-color: #6b7280;
            color: #ffffff;
        }

        /* 메시지 */
        .message {
            padding: 12px 16px;
            border-radius: 10px;
            font-size: 14px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .message.error {
            background-color: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: #f87171;
        }

        .message.success {
            background-color: rgba(34, 197, 94, 0.1);
            border: 1px solid rgba(34, 197, 94, 0.3);
            color: #4ade80;
        }

        /* 로그인 링크 */
        .login-link {
            text-align: center;
            font-size: 14px;
            color: #9ca3af;
            margin-top: 24px;
        }

        .login-link a {
            color: #3b82f6;
            text-decoration: none;
            font-weight: 500;
        }

        .login-link a:hover {
            text-decoration: underline;
        }

        /* 단계별 표시/숨김 */
        .step-content {
            display: none;
        }

        .step-content.active {
            display: block;
        }

        /* 비밀번호 강도 표시 */
        .password-strength {
            margin-top: 8px;
        }

        .strength-bar {
            height: 4px;
            background-color: #374151;
            border-radius: 2px;
            overflow: hidden;
            margin-bottom: 4px;
        }

        .strength-fill {
            height: 100%;
            border-radius: 2px;
            transition: all 0.3s;
        }

        .strength-fill.weak { width: 33%; background-color: #ef4444; }
        .strength-fill.medium { width: 66%; background-color: #f59e0b; }
        .strength-fill.strong { width: 100%; background-color: #22c55e; }

        .strength-text {
            font-size: 12px;
        }

        .strength-text.weak { color: #ef4444; }
        .strength-text.medium { color: #f59e0b; }
        .strength-text.strong { color: #22c55e; }
    </style>
</head>
<body>
    <div class="signup-container">
        <div class="logo">
            <h1>📈 The Salty Spitoon</h1>
        </div>

        <div class="signup-card">
            <h2>회원가입</h2>
            <p>NASDAQ 100 분석 서비스에 가입하세요</p>

            <!-- 스텝 인디케이터 -->
            <div class="step-indicator">
                <div class="step active" id="step-indicator-1">
                    <div class="step-number">1</div>
                    <span class="step-label">이메일</span>
                </div>
                <div class="step-line" id="step-line-1"></div>
                <div class="step" id="step-indicator-2">
                    <div class="step-number">2</div>
                    <span class="step-label">인증</span>
                </div>
                <div class="step-line" id="step-line-2"></div>
                <div class="step" id="step-indicator-3">
                    <div class="step-number">3</div>
                    <span class="step-label">정보</span>
                </div>
            </div>

            <!-- 메시지 영역 -->
            <div id="message-container"></div>

            <!-- Step 1: 이메일 입력 -->
            <div class="step-content active" id="step-1">
                <div class="form-group">
                    <label for="email">이메일</label>
                    <div class="code-input-wrapper">
                        <input type="email" id="email" placeholder="이메일을 입력하세요" required>
                        <button type="button" class="btn-send-code" id="btn-send-code" onclick="sendVerificationCode()">
                            인증 코드 발송
                        </button>
                    </div>
                    <p class="help-text">인증 코드가 이메일로 발송됩니다.</p>
                </div>
            </div>

            <!-- Step 2: 인증 코드 입력 -->
            <div class="step-content" id="step-2">
                <div class="form-group">
                    <label for="verify-email">이메일</label>
                    <input type="email" id="verify-email" disabled>
                </div>

                <div class="form-group">
                    <label for="verification-code">인증 코드</label>
                    <input type="text" id="verification-code" placeholder="6자리 인증 코드" maxlength="6" required>
                    <p class="help-text">이메일로 발송된 6자리 코드를 입력하세요.</p>
                </div>

                <div class="timer" id="timer">남은 시간: 05:00</div>

                <button type="button" class="btn-primary" onclick="verifyCode()">인증 확인</button>
                <button type="button" class="btn-secondary" onclick="resendCode()">인증 코드 재발송</button>
            </div>

            <!-- Step 3: 추가 정보 입력 -->
            <div class="step-content" id="step-3">
                <div class="form-group">
                    <label for="signup-email">이메일</label>
                    <input type="email" id="signup-email" disabled>
                </div>

                <div class="form-group">
                    <label for="password">비밀번호</label>
                    <input type="password" id="password" placeholder="비밀번호를 입력하세요" required oninput="checkPasswordStrength()">
                    <div class="password-strength" id="password-strength" style="display: none;">
                        <div class="strength-bar">
                            <div class="strength-fill" id="strength-fill"></div>
                        </div>
                        <span class="strength-text" id="strength-text"></span>
                    </div>
                    <p class="help-text">영문, 숫자, 특수문자 포함 8자 이상</p>
                </div>

                <div class="form-group">
                    <label for="password-confirm">비밀번호 확인</label>
                    <input type="password" id="password-confirm" placeholder="비밀번호를 다시 입력하세요" required oninput="checkPasswordMatch()">
                    <p class="error-text" id="password-match-error" style="display: none;">비밀번호가 일치하지 않습니다.</p>
                </div>

                <div class="form-group">
                    <label for="name">이름</label>
                    <input type="text" id="name" placeholder="이름을 입력하세요" required>
                </div>

                <div class="form-group">
                    <label for="nickname">닉네임</label>
                    <input type="text" id="nickname" placeholder="닉네임을 입력하세요" maxlength="20" required oninput="checkNickname()">
                    <p class="help-text" id="nickname-status">20자 이내로 입력하세요.</p>
                </div>

                <button type="button" class="btn-primary" id="btn-signup" onclick="signup()">회원가입</button>
            </div>

            <div class="login-link">
                이미 계정이 있으신가요? <a href="/login">로그인</a>
            </div>
        </div>
    </div>

    <script>
        let currentStep = 1;
        let verifiedEmail = '';
        let timerInterval = null;
        let remainingSeconds = 300; // 5분

        // 스텝 변경
        function goToStep(step) {
            // 이전 스텝 숨기기
            document.getElementById('step-' + currentStep).classList.remove('active');
            
            // 새 스텝 표시
            document.getElementById('step-' + step).classList.add('active');
            
            // 인디케이터 업데이트
            for (let i = 1; i <= 3; i++) {
                const indicator = document.getElementById('step-indicator-' + i);
                indicator.classList.remove('active', 'completed');
                
                if (i < step) {
                    indicator.classList.add('completed');
                } else if (i === step) {
                    indicator.classList.add('active');
                }
                
                // 라인 업데이트
                if (i < 3) {
                    const line = document.getElementById('step-line-' + i);
                    line.classList.toggle('completed', i < step);
                }
            }
            
            currentStep = step;
        }

        // 메시지 표시
        function showMessage(message, type) {
            const container = document.getElementById('message-container');
            container.innerHTML = '<div class="message ' + type + '">' + 
                (type === 'error' ? '⚠️ ' : '✅ ') + message + '</div>';
            
            setTimeout(() => {
                container.innerHTML = '';
            }, 5000);
        }

        // 인증 코드 발송
        async function sendVerificationCode() {
            const email = document.getElementById('email').value.trim();
            const btn = document.getElementById('btn-send-code');
            
            if (!email) {
                showMessage('이메일을 입력해주세요.', 'error');
                return;
            }
            
            // 이메일 형식 검사
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                showMessage('유효한 이메일 형식이 아닙니다.', 'error');
                return;
            }
            
            btn.disabled = true;
            btn.textContent = '발송 중...';
            
            try {
                const response = await fetch('/api/auth/send-code', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email: email })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    verifiedEmail = email;
                    document.getElementById('verify-email').value = email;
                    showMessage(data.message, 'success');
                    goToStep(2);
                    startTimer();
                } else {
                    showMessage(data.message, 'error');
                }
            } catch (error) {
                showMessage('오류가 발생했습니다. 다시 시도해주세요.', 'error');
            } finally {
                btn.disabled = false;
                btn.textContent = '인증 코드 발송';
            }
        }

        // 타이머 시작
        function startTimer() {
            remainingSeconds = 300;
            updateTimerDisplay();
            
            if (timerInterval) {
                clearInterval(timerInterval);
            }
            
            timerInterval = setInterval(() => {
                remainingSeconds--;
                updateTimerDisplay();
                
                if (remainingSeconds <= 0) {
                    clearInterval(timerInterval);
                    showMessage('인증 코드가 만료되었습니다. 다시 발송해주세요.', 'error');
                }
            }, 1000);
        }

        // 타이머 표시 업데이트
        function updateTimerDisplay() {
            const minutes = Math.floor(remainingSeconds / 60);
            const seconds = remainingSeconds % 60;
            document.getElementById('timer').textContent = 
                '남은 시간: ' + String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
        }

        // 인증 코드 재발송
        async function resendCode() {
            const email = verifiedEmail;
            
            try {
                const response = await fetch('/api/auth/send-code', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email: email })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showMessage('인증 코드가 재발송되었습니다.', 'success');
                    startTimer();
                } else {
                    showMessage(data.message, 'error');
                }
            } catch (error) {
                showMessage('오류가 발생했습니다.', 'error');
            }
        }

        // 인증 코드 확인
        async function verifyCode() {
            const code = document.getElementById('verification-code').value.trim();
            
            if (!code || code.length !== 6) {
                showMessage('6자리 인증 코드를 입력해주세요.', 'error');
                return;
            }
            
            try {
                const response = await fetch('/api/auth/verify-code', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email: verifiedEmail, code: code })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    clearInterval(timerInterval);
                    document.getElementById('signup-email').value = verifiedEmail;
                    showMessage(data.message, 'success');
                    goToStep(3);
                } else {
                    showMessage(data.message, 'error');
                }
            } catch (error) {
                showMessage('오류가 발생했습니다.', 'error');
            }
        }

        // 비밀번호 강도 체크
        function checkPasswordStrength() {
            const password = document.getElementById('password').value;
            const strengthDiv = document.getElementById('password-strength');
            const strengthFill = document.getElementById('strength-fill');
            const strengthText = document.getElementById('strength-text');
            
            if (!password) {
                strengthDiv.style.display = 'none';
                return;
            }
            
            strengthDiv.style.display = 'block';
            
            let strength = 0;
            if (password.length >= 8) strength++;
            if (/[a-zA-Z]/.test(password)) strength++;
            if (/\d/.test(password)) strength++;
            if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) strength++;
            
            strengthFill.className = 'strength-fill';
            strengthText.className = 'strength-text';
            
            if (strength <= 2) {
                strengthFill.classList.add('weak');
                strengthText.classList.add('weak');
                strengthText.textContent = '약함';
            } else if (strength === 3) {
                strengthFill.classList.add('medium');
                strengthText.classList.add('medium');
                strengthText.textContent = '보통';
            } else {
                strengthFill.classList.add('strong');
                strengthText.classList.add('strong');
                strengthText.textContent = '강함';
            }
        }

        // 비밀번호 일치 확인
        function checkPasswordMatch() {
            const password = document.getElementById('password').value;
            const confirm = document.getElementById('password-confirm').value;
            const error = document.getElementById('password-match-error');
            
            if (confirm && password !== confirm) {
                error.style.display = 'block';
            } else {
                error.style.display = 'none';
            }
        }

        // 닉네임 중복 확인
        let nicknameTimeout = null;
        async function checkNickname() {
            const nickname = document.getElementById('nickname').value.trim();
            const status = document.getElementById('nickname-status');
            
            if (nicknameTimeout) {
                clearTimeout(nicknameTimeout);
            }
            
            if (!nickname) {
                status.textContent = '20자 이내로 입력하세요.';
                status.className = 'help-text';
                return;
            }
            
            nicknameTimeout = setTimeout(async () => {
                try {
                    const response = await fetch('/api/auth/check-nickname?nickname=' + encodeURIComponent(nickname));
                    const data = await response.json();
                    
                    if (data.exists) {
                        status.textContent = '이미 사용 중인 닉네임입니다.';
                        status.className = 'error-text';
                    } else {
                        status.textContent = '사용 가능한 닉네임입니다.';
                        status.className = 'success-text';
                    }
                } catch (error) {
                    status.textContent = '확인 중 오류가 발생했습니다.';
                    status.className = 'error-text';
                }
            }, 500);
        }

        // 회원가입
        async function signup() {
            const password = document.getElementById('password').value;
            const passwordConfirm = document.getElementById('password-confirm').value;
            const name = document.getElementById('name').value.trim();
            const nickname = document.getElementById('nickname').value.trim();
            
            // 유효성 검사
            if (!password || !passwordConfirm || !name || !nickname) {
                showMessage('모든 필드를 입력해주세요.', 'error');
                return;
            }
            
            if (password !== passwordConfirm) {
                showMessage('비밀번호가 일치하지 않습니다.', 'error');
                return;
            }
            
            const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$/;
            if (!passwordRegex.test(password)) {
                showMessage('비밀번호는 영문, 숫자, 특수문자를 포함하여 8자 이상이어야 합니다.', 'error');
                return;
            }
            
            if (nickname.length > 20) {
                showMessage('닉네임은 20자 이내여야 합니다.', 'error');
                return;
            }
            
            const btn = document.getElementById('btn-signup');
            btn.disabled = true;
            btn.textContent = '가입 중...';
            
            try {
                const response = await fetch('/api/auth/signup', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        email: verifiedEmail,
                        password: password,
                        passwordConfirm: passwordConfirm,
                        name: name,
                        nickname: nickname
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showMessage(data.message, 'success');
                    setTimeout(() => {
                        window.location.href = '/login?signup=true';
                    }, 1500);
                } else {
                    showMessage(data.message, 'error');
                    btn.disabled = false;
                    btn.textContent = '회원가입';
                }
            } catch (error) {
                showMessage('오류가 발생했습니다.', 'error');
                btn.disabled = false;
                btn.textContent = '회원가입';
            }
        }

        // Enter 키 처리
        document.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                if (currentStep === 1) {
                    sendVerificationCode();
                } else if (currentStep === 2) {
                    verifyCode();
                } else if (currentStep === 3) {
                    signup();
                }
            }
        });
    </script>
</body>
</html>
