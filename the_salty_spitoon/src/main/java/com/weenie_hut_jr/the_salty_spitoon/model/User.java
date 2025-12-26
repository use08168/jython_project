package com.weenie_hut_jr.the_salty_spitoon.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 사용자 모델 클래스
 * 
 * 역할:
 * - 사용자 기본 정보 저장
 * - MyBatis 매핑용 POJO (Plain Old Java Object)
 * - 향후 인증/권한 시스템 확장 예정
 * 
 * 현재 상태:
 * - 기본 구조만 정의 (스켈레톤)
 * - 실제 사용자 관리 기능 미구현
 * - 테스트 및 프로토타입 용도
 * 
 * 데이터베이스:
 * - 테이블명: users (예상)
 * - ORM: MyBatis (UserDao와 연동)
 * - Primary Key: id
 * 
 * JPA vs MyBatis:
 * - Stock, StockCandle1m: JPA (@Entity 사용)
 * - User: MyBatis (일반 POJO, @Mapper와 매핑)
 * 
 * 향후 확장 계획:
 * 1. 인증 시스템 (Spring Security)
 * 2. 비밀번호 암호화 (BCrypt)
 * 3. 사용자 권한 (Role: USER, ADMIN)
 * 4. 즐겨찾기 종목 관리
 * 5. 포트폴리오 추적
 * 6. 알림 설정
 * 7. 거래 시뮬레이션
 * 
 * 확장 필드 예시:
 * - password: String (암호화된 비밀번호)
 * - role: String (USER, ADMIN, PREMIUM)
 * - createdAt: LocalDateTime
 * - lastLoginAt: LocalDateTime
 * - isActive: Boolean
 * - emailVerified: Boolean
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Data // Lombok: getter, setter, toString, equals, hashCode 자동 생성
@NoArgsConstructor // Lombok: 기본 생성자 (MyBatis 매핑 필수)
@AllArgsConstructor // Lombok: 모든 필드 생성자
public class User {

    /**
     * 사용자 ID (Primary Key)
     * 
     * 역할:
     * - 사용자를 식별하는 고유 번호
     * - MySQL AUTO_INCREMENT
     * 
     * 타입:
     * - Long (MySQL BIGINT)
     * - null 가능 (INSERT 전에는 null)
     * 
     * 생성:
     * - 회원가입 시 자동 생성
     * - DB가 자동으로 할당
     * 
     * 사용:
     * - 사용자 조회: userDao.findById(1L)
     * - 세션 관리: 로그인 시 ID 저장
     * - 외래키: 다른 테이블과 연결 (즐겨찾기, 포트폴리오 등)
     * 
     * 보안:
     * - 외부 노출 최소화
     * - API 응답 시 UUID 사용 고려
     */
    private Long id;

    /**
     * 사용자명 (Username)
     * 
     * 역할:
     * - 로그인 ID 또는 닉네임
     * - 시스템 내 사용자 식별
     * 
     * 특징:
     * - 유니크 제약조건 권장 (중복 방지)
     * - 3-20자 길이 제한 권장
     * - 영문, 숫자, 언더스코어 허용
     * 
     * 예시:
     * - "john_doe"
     * - "investor2025"
     * - "stock_trader"
     * 
     * 사용 시나리오:
     * - 로그인 화면
     * - 사용자 프로필 표시
     * - 댓글/리뷰 작성자 표시 (향후)
     * 
     * 제약조건 (권장):
     * - NOT NULL
     * - UNIQUE
     * - LENGTH(3, 20)
     * 
     * TODO:
     * - 유효성 검증 (@Pattern, @Size)
     * - 중복 체크 로직
     */
    private String username;

    /**
     * 이메일 주소 (Email)
     * 
     * 역할:
     * - 사용자 연락처
     * - 로그인 ID (username 대신 사용 가능)
     * - 이메일 인증 및 알림
     * 
     * 특징:
     * - 이메일 형식 검증 필요
     * - 유니크 제약조건 권장
     * - 대소문자 구분 없음 (저장 시 소문자 변환 권장)
     * 
     * 예시:
     * - "user@example.com"
     * - "investor@gmail.com"
     * - "trader@nasdaq.com"
     * 
     * 사용 시나리오:
     * - 회원가입 인증 메일
     * - 비밀번호 재설정
     * - 주가 알림 전송 (향후)
     * - 뉴스레터 구독 (향후)
     * 
     * 제약조건 (권장):
     * - NOT NULL
     * - UNIQUE
     * - 이메일 형식 (@Email 어노테이션)
     * 
     * TODO:
     * - 이메일 유효성 검증 (@Email)
     * - 중복 체크 로직
     * - 이메일 인증 기능 (emailVerified 필드 추가)
     */
    private String email;

    // ========================================
    // 향후 추가 예정 필드 (TODO)
    // ========================================

    /**
     * TODO: 비밀번호 (암호화됨)
     * 
     * private String password;
     * 
     * - BCryptPasswordEncoder로 암호화
     * - 최소 8자, 영문+숫자+특수문자 조합 권장
     * - DB에는 해시값만 저장 (평문 저장 절대 금지)
     */

    /**
     * TODO: 사용자 권한
     * 
     * private String role;
     * 
     * 가능한 값:
     * - "USER": 일반 사용자
     * - "PREMIUM": 프리미엄 회원 (추가 기능)
     * - "ADMIN": 관리자
     */

    /**
     * TODO: 계정 생성 시각
     * 
     * private LocalDateTime createdAt;
     * 
     * - 회원가입 일시
     * - 불변 값
     */

    /**
     * TODO: 마지막 로그인 시각
     * 
     * private LocalDateTime lastLoginAt;
     * 
     * - 로그인 시마다 업데이트
     * - 활동성 추적
     */

    /**
     * TODO: 계정 활성 상태
     * 
     * private Boolean isActive;
     * 
     * - true: 활성 (로그인 가능)
     * - false: 비활성 (정지, 탈퇴)
     */

    /**
     * TODO: 이메일 인증 여부
     * 
     * private Boolean emailVerified;
     * 
     * - true: 인증 완료
     * - false: 미인증 (기능 제한)
     */

    /**
     * TODO: 프로필 이미지 URL
     * 
     * private String profileImageUrl;
     * 
     * - S3, CDN 등에 저장된 이미지 경로
     */

    /**
     * TODO: 즐겨찾기 종목 (관계)
     * 
     * private List<String> favoriteSymbols;
     * 
     * - 별도 테이블: user_favorites (user_id, symbol)
     * - N:N 관계
     */

    // ========================================
    // 비즈니스 로직 (향후 추가 가능)
    // ========================================

    /**
     * TODO: 비밀번호 검증
     * 
     * public boolean checkPassword(String rawPassword, PasswordEncoder encoder) {
     * return encoder.matches(rawPassword, this.password);
     * }
     */

    /**
     * TODO: 관리자 권한 체크
     * 
     * public boolean isAdmin() {
     * return "ADMIN".equals(this.role);
     * }
     */

    /**
     * TODO: 이메일 인증 완료 처리
     * 
     * public void verifyEmail() {
     * this.emailVerified = true;
     * }
     */

    /**
     * TODO: 마지막 로그인 시각 업데이트
     * 
     * public void updateLastLogin() {
     * this.lastLoginAt = LocalDateTime.now();
     * }
     */
}