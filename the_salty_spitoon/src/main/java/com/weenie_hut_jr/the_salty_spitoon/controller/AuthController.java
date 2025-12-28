package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.dto.*;
import com.weenie_hut_jr.the_salty_spitoon.service.EmailService;
import com.weenie_hut_jr.the_salty_spitoon.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 인증 관련 컨트롤러
 */
@Slf4j
@Controller
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final EmailService emailService;

    // ========================================
    // 페이지 매핑
    // ========================================

    /**
     * 로그인 페이지
     */
    @GetMapping("/login")
    public String loginPage() {
        return "auth/login";
    }

    /**
     * 회원가입 페이지
     */
    @GetMapping("/signup")
    public String signupPage() {
        return "auth/signup";
    }

    /**
     * 비밀번호 찾기 페이지
     */
    @GetMapping("/forgot-password")
    public String forgotPasswordPage() {
        return "auth/forgot-password";
    }

    // ========================================
    // API 엔드포인트
    // ========================================

    /**
     * 이메일 중복 확인
     */
    @GetMapping("/api/auth/check-email")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> checkEmail(@RequestParam String email) {
        Map<String, Object> response = new HashMap<>();
        boolean exists = userService.isEmailExists(email);
        response.put("exists", exists);
        response.put("message", exists ? "이미 사용 중인 이메일입니다." : "사용 가능한 이메일입니다.");
        return ResponseEntity.ok(response);
    }

    /**
     * 닉네임 중복 확인
     */
    @GetMapping("/api/auth/check-nickname")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> checkNickname(@RequestParam String nickname) {
        Map<String, Object> response = new HashMap<>();
        boolean exists = userService.isNicknameExists(nickname);
        response.put("exists", exists);
        response.put("message", exists ? "이미 사용 중인 닉네임입니다." : "사용 가능한 닉네임입니다.");
        return ResponseEntity.ok(response);
    }

    /**
     * 이메일 인증 코드 발송
     */
    @PostMapping("/api/auth/send-code")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> sendVerificationCode(@Valid @RequestBody EmailVerificationRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // 이메일 중복 확인
            if (userService.isEmailExists(request.getEmail())) {
                response.put("success", false);
                response.put("message", "이미 가입된 이메일입니다.");
                return ResponseEntity.badRequest().body(response);
            }
            
            emailService.sendVerificationCode(request.getEmail());
            response.put("success", true);
            response.put("message", "인증 코드가 발송되었습니다. 5분 내에 입력해주세요.");
            log.info("인증 코드 발송 요청: {}", request.getEmail());
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
            log.error("인증 코드 발송 실패: {}", request.getEmail(), e);
        }
        
        return ResponseEntity.ok(response);
    }

    /**
     * 인증 코드 확인
     */
    @PostMapping("/api/auth/verify-code")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> verifyCode(@Valid @RequestBody VerifyCodeRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            boolean verified = emailService.verifyCode(request.getEmail(), request.getCode());
            
            if (verified) {
                response.put("success", true);
                response.put("message", "이메일 인증이 완료되었습니다.");
                log.info("이메일 인증 성공: {}", request.getEmail());
            } else {
                response.put("success", false);
                response.put("message", "인증 코드가 일치하지 않거나 만료되었습니다.");
            }
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    /**
     * 회원가입 처리
     */
    @PostMapping("/api/auth/signup")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> signup(@Valid @RequestBody SignupRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            userService.signup(request);
            response.put("success", true);
            response.put("message", "회원가입이 완료되었습니다.");
            log.info("회원가입 완료: {}", request.getEmail());
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
            log.error("회원가입 실패: {}", request.getEmail(), e);
        }
        
        return ResponseEntity.ok(response);
    }

    /**
     * 비밀번호 찾기 - 인증 코드 발송
     */
    @PostMapping("/api/auth/forgot-password/send-code")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> sendPasswordResetCode(@Valid @RequestBody EmailVerificationRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // 등록된 이메일인지 확인
            if (!userService.isEmailExists(request.getEmail())) {
                response.put("success", false);
                response.put("message", "등록되지 않은 이메일입니다.");
                return ResponseEntity.badRequest().body(response);
            }
            
            emailService.sendPasswordResetCode(request.getEmail());
            response.put("success", true);
            response.put("message", "인증 코드가 발송되었습니다. 5분 내에 입력해주세요.");
            log.info("비밀번호 재설정 코드 발송 요청: {}", request.getEmail());
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
            log.error("비밀번호 재설정 코드 발송 실패: {}", request.getEmail(), e);
        }
        
        return ResponseEntity.ok(response);
    }

    /**
     * 비밀번호 재설정
     */
    @PostMapping("/api/auth/reset-password")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            userService.resetPassword(request);
            response.put("success", true);
            response.put("message", "비밀번호가 변경되었습니다. 새 비밀번호로 로그인해주세요.");
            log.info("비밀번호 재설정 완료: {}", request.getEmail());
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", e.getMessage());
            log.error("비밀번호 재설정 실패: {}", request.getEmail(), e);
        }
        
        return ResponseEntity.ok(response);
    }
}
