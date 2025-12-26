package com.weenie_hut_jr.the_salty_spitoon.service;

import com.weenie_hut_jr.the_salty_spitoon.dao.UserDao;
import com.weenie_hut_jr.the_salty_spitoon.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 사용자 비즈니스 로직 서비스
 * 
 * 역할:
 * - 사용자 관련 비즈니스 로직 처리
 * - UserDao와 Controller 사이의 중간 계층
 * - 트랜잭션 관리
 * 
 * 현재 상태:
 * - 기본 구조만 구현 (스켈레톤)
 * - 조회 기능만 제공 (READ)
 * - CUD (Create, Update, Delete) 미구현
 * 
 * 아키텍처:
 * - Controller → Service → DAO → Database
 * - UserController → UserService → UserDao → MySQL
 * 
 * MyBatis 연동:
 * - UserDao: MyBatis @Mapper 인터페이스
 * - SQL 쿼리 실행 및 결과 매핑
 * 
 * 트랜잭션:
 * - @Transactional(readOnly = true): 읽기 전용
 * - 성능 최적화 (DB 락 불필요)
 * - 쓰기 작업 시 메서드별 @Transactional 필요
 * 
 * 향후 확장 계획:
 * 1. 회원가입/로그인 (Spring Security)
 * 2. 사용자 정보 수정
 * 3. 비밀번호 변경 및 암호화
 * 4. 이메일 인증
 * 5. 권한 관리 (USER, ADMIN)
 * 6. 즐겨찾기 종목 관리
 * 7. 포트폴리오 추적
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Service // Spring Service Bean
@RequiredArgsConstructor // final 필드 생성자 주입
@Transactional(readOnly = true) // 클래스 레벨: 모든 메서드 읽기 전용 트랜잭션
public class UserService {

    // 의존성 주입
    private final UserDao userDao; // MyBatis DAO

    /**
     * 전체 사용자 목록 조회
     * 
     * 기능:
     * - users 테이블의 모든 사용자 조회
     * - 관리자 대시보드용
     * 
     * 동작:
     * 1. UserDao.findAll() 호출
     * 2. MyBatis가 SQL 실행: SELECT * FROM users
     * 3. 결과를 List<User>로 매핑
     * 4. 반환
     * 
     * SQL (MyBatis):
     * SELECT * FROM users
     * 
     * 트랜잭션:
     * - readOnly = true (클래스 레벨 설정)
     * - DB 락 불필요
     * - 성능 최적화
     * 
     * 사용 위치:
     * - UserController.listUsers()
     * - 관리자 페이지: 사용자 관리
     * 
     * 제한사항:
     * - 페이징 없음 (전체 조회)
     * - 사용자 많을 경우 성능 이슈
     * 
     * 권장 사항:
     * - 프로덕션: 페이징 처리 필수
     * - 검색/필터링 기능 추가
     * 
     * 반환 예시:
     * [
     * User(id=1, username="john_doe", email="john@example.com"),
     * User(id=2, username="jane_smith", email="jane@example.com"),
     * ...
     * ]
     * 
     * TODO:
     * - 페이징 파라미터 추가 (page, size)
     * - 정렬 옵션 (username, createdAt)
     * - 검색 기능 (username, email)
     * 
     * @return List<User> 전체 사용자 리스트
     */
    public List<User> getAllUsers() {
        return userDao.findAll();
    }

    /**
     * ID로 사용자 단건 조회
     * 
     * 기능:
     * - 특정 ID의 사용자 정보 조회
     * - 사용자 프로필, 권한 확인 등
     * 
     * 동작:
     * 1. UserDao.findById(id) 호출
     * 2. MyBatis가 SQL 실행: SELECT * FROM users WHERE id = #{id}
     * 3. 결과를 User 객체로 매핑
     * 4. 반환 (존재하면 User, 없으면 null)
     * 
     * SQL (MyBatis):
     * SELECT * FROM users WHERE id = #{id}
     * 
     * 트랜잭션:
     * - readOnly = true
     * - Primary Key 조회: 매우 빠름
     * 
     * 사용 시나리오:
     * - 로그인 후 사용자 정보 표시
     * - 프로필 페이지
     * - 권한 검증
     * - 댓글/리뷰 작성자 확인 (향후)
     * 
     * null 처리:
     * - 사용자 없음: null 반환
     * - Controller에서 체크 필요
     * - Optional<User> 반환 고려
     * 
     * 사용 위치:
     * - UserController (향후 구현)
     * - 인증/권한 체크
     * 
     * 반환 예시 (존재):
     * User(id=1, username="john_doe", email="john@example.com")
     * 
     * 반환 예시 (없음):
     * null
     * 
     * TODO:
     * - Optional<User> 반환 타입으로 변경
     * - UserNotFoundException 예외 처리
     * - 캐싱 적용 (@Cacheable)
     * 
     * @param id 조회할 사용자 ID
     * @return User 사용자 객체 또는 null
     */
    public User getUserById(Long id) {
        return userDao.findById(id);
    }

    // ========================================
    // 향후 추가 예정 메서드 (TODO)
    // ========================================

    /**
     * TODO: 회원가입
     * 
     * @Transactional // 쓰기 작업: readOnly = false (기본값)
     *                public User registerUser(User user) {
     *                // 1. 중복 체크 (username, email)
     *                if (userDao.existsByUsername(user.getUsername())) {
     *                throw new DuplicateUsernameException();
     *                }
     * 
     *                // 2. 비밀번호 암호화 (BCrypt)
     *                String encodedPassword =
     *                passwordEncoder.encode(user.getPassword());
     *                user.setPassword(encodedPassword);
     * 
     *                // 3. 기본값 설정
     *                user.setRole("USER");
     *                user.setCreatedAt(LocalDateTime.now());
     *                user.setIsActive(true);
     * 
     *                // 4. DB 저장
     *                userDao.insert(user);
     * 
     *                // 5. 이메일 인증 메일 발송 (비동기)
     *                emailService.sendVerificationEmail(user.getEmail());
     * 
     *                return user;
     *                }
     */

    /**
     * TODO: 로그인 (인증)
     * 
     * public User login(String username, String password) {
     * // 1. 사용자 조회
     * User user = userDao.findByUsername(username);
     * if (user == null) {
     * throw new UsernameNotFoundException();
     * }
     * 
     * // 2. 비밀번호 검증
     * if (!passwordEncoder.matches(password, user.getPassword())) {
     * throw new BadCredentialsException();
     * }
     * 
     * // 3. 계정 활성 상태 확인
     * if (!user.getIsActive()) {
     * throw new AccountDisabledException();
     * }
     * 
     * // 4. 마지막 로그인 시각 업데이트
     * updateLastLogin(user.getId());
     * 
     * return user;
     * }
     */

    /**
     * TODO: 사용자 정보 수정
     * 
     * @Transactional
     *                public User updateUser(Long id, User updateData) {
     *                // 1. 기존 사용자 조회
     *                User user = userDao.findById(id);
     *                if (user == null) {
     *                throw new UserNotFoundException();
     *                }
     * 
     *                // 2. 수정 가능한 필드만 업데이트
     *                if (updateData.getUsername() != null) {
     *                user.setUsername(updateData.getUsername());
     *                }
     *                if (updateData.getEmail() != null) {
     *                user.setEmail(updateData.getEmail());
     *                }
     * 
     *                // 3. DB 업데이트
     *                userDao.update(user);
     * 
     *                return user;
     *                }
     */

    /**
     * TODO: 비밀번호 변경
     * 
     * @Transactional
     *                public void changePassword(Long id, String oldPassword, String
     *                newPassword) {
     *                // 1. 사용자 조회
     *                User user = userDao.findById(id);
     * 
     *                // 2. 현재 비밀번호 확인
     *                if (!passwordEncoder.matches(oldPassword, user.getPassword()))
     *                {
     *                throw new BadCredentialsException("Current password is
     *                incorrect");
     *                }
     * 
     *                // 3. 새 비밀번호 암호화
     *                String encodedPassword = passwordEncoder.encode(newPassword);
     * 
     *                // 4. 업데이트
     *                userDao.updatePassword(id, encodedPassword);
     *                }
     */

    /**
     * TODO: 사용자 삭제 (탈퇴)
     * 
     * @Transactional
     *                public void deleteUser(Long id) {
     *                // 1. 사용자 존재 확인
     *                User user = userDao.findById(id);
     *                if (user == null) {
     *                throw new UserNotFoundException();
     *                }
     * 
     *                // 2. 연관 데이터 정리 (즐겨찾기, 포트폴리오 등)
     *                favoriteDao.deleteByUserId(id);
     *                portfolioDao.deleteByUserId(id);
     * 
     *                // 3. 사용자 삭제 (또는 비활성화)
     *                userDao.deleteById(id);
     *                // 또는: userDao.deactivate(id); // soft delete
     *                }
     */

    /**
     * TODO: 이메일로 사용자 조회 (로그인용)
     * 
     * public User getUserByEmail(String email) {
     * return userDao.findByEmail(email);
     * }
     */

    /**
     * TODO: 사용자명으로 조회
     * 
     * public User getUserByUsername(String username) {
     * return userDao.findByUsername(username);
     * }
     */

    /**
     * TODO: 중복 체크
     * 
     * public boolean isUsernameAvailable(String username) {
     * return !userDao.existsByUsername(username);
     * }
     * 
     * public boolean isEmailAvailable(String email) {
     * return !userDao.existsByEmail(email);
     * }
     */

    /**
     * TODO: 마지막 로그인 시각 업데이트
     * 
     * @Transactional
     *                private void updateLastLogin(Long id) {
     *                userDao.updateLastLogin(id, LocalDateTime.now());
     *                }
     */

    /**
     * TODO: 이메일 인증
     * 
     * @Transactional
     *                public void verifyEmail(Long userId, String token) {
     *                // 1. 토큰 검증
     *                if (!emailVerificationService.verifyToken(userId, token)) {
     *                throw new InvalidTokenException();
     *                }
     * 
     *                // 2. 사용자 이메일 인증 상태 업데이트
     *                userDao.markEmailVerified(userId);
     *                }
     */

    /**
     * TODO: 사용자 검색 (관리자용)
     * 
     * public List<User> searchUsers(String keyword) {
     * // username 또는 email로 검색
     * return userDao.searchByKeyword(keyword);
     * }
     */

    /**
     * TODO: 페이징 처리
     * 
     * public Page<User> getUsersWithPaging(int page, int size) {
     * int offset = page * size;
     * List<User> users = userDao.findWithPaging(offset, size);
     * long total = userDao.count();
     * 
     * return new PageImpl<>(users, PageRequest.of(page, size), total);
     * }
     */
}