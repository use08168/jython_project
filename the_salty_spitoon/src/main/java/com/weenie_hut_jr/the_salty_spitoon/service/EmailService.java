package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.entity.EmailVerification;
import com.weenie_hut_jr.the_salty_spitoon.repository.EmailVerificationRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.io.UnsupportedEncodingException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

/**
 * 이메일 서비스
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final EmailVerificationRepository verificationRepository;
    
    @Value("${spring.mail.username}")
    private String fromEmail;

    private static final int CODE_LENGTH = 6;
    private static final int CODE_EXPIRY_MINUTES = 5;
    private static final int MAX_REQUESTS_PER_MINUTE = 5;

    /**
     * 인증 코드 생성 (6자리 숫자)
     */
    private String generateVerificationCode() {
        SecureRandom random = new SecureRandom();
        StringBuilder code = new StringBuilder();
        for (int i = 0; i < CODE_LENGTH; i++) {
            code.append(random.nextInt(10));
        }
        return code.toString();
    }

    /**
     * 이메일 인증 코드 발송
     */
    @Transactional
    public void sendVerificationCode(String email) {
        // 1분 내 요청 횟수 체크
        LocalDateTime oneMinuteAgo = LocalDateTime.now().minusMinutes(1);
        long recentCount = verificationRepository.countRecentByEmail(email, oneMinuteAgo);
        
        if (recentCount >= MAX_REQUESTS_PER_MINUTE) {
            throw new RuntimeException("1분에 최대 " + MAX_REQUESTS_PER_MINUTE + "번까지 요청할 수 있습니다. 잠시 후 다시 시도해주세요.");
        }

        // 인증 코드 생성
        String code = generateVerificationCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(CODE_EXPIRY_MINUTES);

        // DB 저장
        EmailVerification verification = EmailVerification.builder()
                .email(email)
                .code(code)
                .expiresAt(expiresAt)
                .verified(false)
                .build();
        verificationRepository.save(verification);

        // 이메일 발송
        try {
            sendEmail(email, "The Salty Spitoon - 이메일 인증 코드", buildVerificationEmailContent(code));
            log.info("인증 코드 발송 완료: {} -> {}", email, code);
        } catch (Exception e) {
            log.error("이메일 발송 실패: {}", email, e);
            throw new RuntimeException("이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.");
        }
    }

    /**
     * 인증 코드 확인
     */
    @Transactional
    public boolean verifyCode(String email, String code) {
        LocalDateTime now = LocalDateTime.now();
        
        return verificationRepository.findLatestValidByEmail(email, now)
                .map(verification -> {
                    if (verification.isValid(code)) {
                        verification.setVerified(true);
                        verificationRepository.save(verification);
                        log.info("이메일 인증 성공: {}", email);
                        return true;
                    }
                    return false;
                })
                .orElse(false);
    }

    /**
     * 이메일 인증 여부 확인
     */
    public boolean isEmailVerified(String email) {
        LocalDateTime now = LocalDateTime.now();
        return verificationRepository.findLatestValidByEmail(email, now)
                .map(EmailVerification::getVerified)
                .orElse(false);
    }

    /**
     * 이메일 발송
     */
    private void sendEmail(String to, String subject, String content) throws MessagingException, UnsupportedEncodingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        
        helper.setFrom(fromEmail, "The Salty Spitoon");
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(content, true);
        
        mailSender.send(message);
    }

    /**
     * 인증 코드 이메일 내용 생성
     */
    private String buildVerificationEmailContent(String code) {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #0f1419; color: #ffffff; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background-color: #1a1f2e; border-radius: 12px; padding: 40px; }
                    .header { text-align: center; margin-bottom: 30px; }
                    .header h1 { color: #3b82f6; margin: 0; font-size: 28px; }
                    .code-box { background-color: #252b3d; border-radius: 8px; padding: 30px; text-align: center; margin: 30px 0; }
                    .code { font-size: 36px; font-weight: bold; color: #3b82f6; letter-spacing: 8px; }
                    .info { color: #9ca3af; font-size: 14px; text-align: center; }
                    .footer { margin-top: 30px; text-align: center; color: #6b7280; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🔐 The Salty Spitoon</h1>
                    </div>
                    <p style="text-align: center;">이메일 인증을 위한 인증 코드입니다.</p>
                    <div class="code-box">
                        <div class="code">%s</div>
                    </div>
                    <p class="info">이 코드는 5분 후에 만료됩니다.</p>
                    <p class="info">본인이 요청하지 않았다면 이 이메일을 무시해주세요.</p>
                    <div class="footer">
                        <p>© 2025 The Salty Spitoon. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(code);
    }

    /**
     * 비밀번호 재설정 이메일 발송
     */
    @Transactional
    public void sendPasswordResetCode(String email) {
        // 1분 내 요청 횟수 체크
        LocalDateTime oneMinuteAgo = LocalDateTime.now().minusMinutes(1);
        long recentCount = verificationRepository.countRecentByEmail(email, oneMinuteAgo);
        
        if (recentCount >= MAX_REQUESTS_PER_MINUTE) {
            throw new RuntimeException("1분에 최대 " + MAX_REQUESTS_PER_MINUTE + "번까지 요청할 수 있습니다. 잠시 후 다시 시도해주세요.");
        }

        // 인증 코드 생성
        String code = generateVerificationCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(CODE_EXPIRY_MINUTES);

        // DB 저장
        EmailVerification verification = EmailVerification.builder()
                .email(email)
                .code(code)
                .expiresAt(expiresAt)
                .verified(false)
                .build();
        verificationRepository.save(verification);

        // 이메일 발송
        try {
            sendEmail(email, "The Salty Spitoon - 비밀번호 재설정 코드", buildPasswordResetEmailContent(code));
            log.info("비밀번호 재설정 코드 발송 완료: {} -> {}", email, code);
        } catch (Exception e) {
            log.error("이메일 발송 실패: {}", email, e);
            throw new RuntimeException("이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.");
        }
    }

    /**
     * 비밀번호 재설정 이메일 내용 생성
     */
    private String buildPasswordResetEmailContent(String code) {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #0f1419; color: #ffffff; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background-color: #1a1f2e; border-radius: 12px; padding: 40px; }
                    .header { text-align: center; margin-bottom: 30px; }
                    .header h1 { color: #f59e0b; margin: 0; font-size: 28px; }
                    .code-box { background-color: #252b3d; border-radius: 8px; padding: 30px; text-align: center; margin: 30px 0; }
                    .code { font-size: 36px; font-weight: bold; color: #f59e0b; letter-spacing: 8px; }
                    .info { color: #9ca3af; font-size: 14px; text-align: center; }
                    .footer { margin-top: 30px; text-align: center; color: #6b7280; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🔑 비밀번호 재설정</h1>
                    </div>
                    <p style="text-align: center;">비밀번호 재설정을 위한 인증 코드입니다.</p>
                    <div class="code-box">
                        <div class="code">%s</div>
                    </div>
                    <p class="info">이 코드는 5분 후에 만료됩니다.</p>
                    <p class="info">본인이 요청하지 않았다면 이 이메일을 무시해주세요.</p>
                    <div class="footer">
                        <p>© 2025 The Salty Spitoon. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(code);
    }
}
