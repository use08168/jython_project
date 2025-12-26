package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * 사용자 관리 컨트롤러
 * 
 * 역할:
 * - 사용자 관련 페이지 라우팅
 * - JSP 뷰 렌더링 테스트
 * - 향후 사용자 인증/권한 관리 확장 예정
 * 
 * 현재 상태:
 * - 기본 구조만 구현 (스켈레톤 코드)
 * - 실제 사용자 CRUD 기능은 미구현
 * - JSP 렌더링 테스트용 엔드포인트 포함
 * 
 * 향후 확장 계획:
 * 1. 회원가입/로그인 기능
 * 2. 사용자 프로필 관리
 * 3. 즐겨찾기 종목 관리
 * 4. 포트폴리오 추적
 * 
 * 엔드포인트:
 * - GET /users : 사용자 목록 페이지 (미구현)
 * - GET /users/test : JSP 렌더링 테스트 페이지
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Controller // Spring MVC Controller
@RequestMapping("/users") // 기본 경로: /users
@RequiredArgsConstructor // final 필드 생성자 주입
public class UserController {

    // 의존성 주입
    private final UserService userService; // 사용자 비즈니스 로직 처리 (현재 미사용)

    /**
     * 사용자 목록 페이지 (플레이스홀더)
     * 
     * 기능:
     * - 환영 메시지 표시
     * - 실제 사용자 목록 기능은 미구현
     * 
     * 동작:
     * 1. 고정 메시지를 Model에 추가
     * 2. users/list.jsp 렌더링
     * 
     * URL: GET /users
     * View: /WEB-INF/views/users/list.jsp
     * 
     * Model Attributes:
     * - message: String - 환영 메시지
     * 
     * TODO:
     * - userService를 통해 실제 사용자 목록 조회
     * - 페이징 처리
     * - 검색 기능
     * 
     * @param model Spring MVC Model 객체
     * @return JSP 뷰 이름
     */
    @GetMapping
    public String listUsers(Model model) {
        // 환영 메시지 추가
        model.addAttribute("message", "Welcome to The Salty Spitoon!");

        return "users/list"; // /WEB-INF/views/users/list.jsp
    }

    /**
     * JSP 렌더링 테스트 페이지
     * 
     * 기능:
     * - Spring MVC와 JSP 연동 확인
     * - ViewResolver 설정 검증
     * - 개발 환경 테스트용
     * 
     * 동작:
     * 1. 테스트 메시지를 Model에 추가
     * 2. test.jsp 렌더링
     * 3. JSP에서 ${testMessage} 출력 확인
     * 
     * URL: GET /users/test
     * View: /WEB-INF/views/test.jsp
     * 
     * Model Attributes:
     * - testMessage: String - "JSP is working!"
     * 
     * 사용 시나리오:
     * - 프로젝트 초기 설정 시 JSP 동작 확인
     * - ViewResolver prefix/suffix 검증
     * - Tomcat 내장 서버 확인
     * 
     * ⚠️ 주의:
     * - 프로덕션 배포 시 제거 또는 비활성화 필요
     * - 보안상 테스트 엔드포인트는 외부 노출 금지
     * 
     * @param model Spring MVC Model 객체
     * @return JSP 뷰 이름
     */
    @GetMapping("/test")
    public String test(Model model) {
        // 테스트 메시지 추가
        model.addAttribute("testMessage", "JSP is working!");

        return "test"; // /WEB-INF/views/test.jsp
    }
}