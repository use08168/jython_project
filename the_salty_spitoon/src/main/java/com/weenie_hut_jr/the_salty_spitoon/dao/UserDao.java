package com.weenie_hut_jr.the_salty_spitoon.dao;

import com.weenie_hut_jr.the_salty_spitoon.model.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 사용자 데이터 접근 객체 (DAO - Data Access Object)
 * 
 * 역할:
 * - MyBatis를 사용한 users 테이블 CRUD 작업
 * - SQL 쿼리와 Java 객체 간 매핑
 * - UserService와 데이터베이스 사이의 중간 계층
 * 
 * 기술 스택:
 * - MyBatis 3.x
 * - Annotation 기반 SQL 매핑 (현재)
 * - XML 기반 매핑으로 전환 가능 (향후)
 * 
 * 현재 상태:
 * - 기본 조회 기능만 구현 (findAll, findById)
 * - 테스트용 간단한 구조
 * - CUD(Create, Update, Delete) 미구현
 * 
 * 향후 확장:
 * 1. XML 매퍼로 전환 (복잡한 쿼리 관리)
 * 2. 회원가입/수정/탈퇴 기능 추가
 * 3. 동적 쿼리 (검색, 필터링)
 * 4. 페이징 처리
 * 
 * 사용 예시:
 * {@code
 * @Service
 * public class UserService {
 * 
 * @Autowired
 *            private UserDao userDao;
 * 
 *            public List<User> getAllUsers() {
 *            return userDao.findAll();
 *            }
 *            }
 *            }
 * 
 * @author The Salty Spitoon Team
 * @since 2025-12-21
 */
@Mapper // MyBatis Mapper 인터페이스 - Spring이 자동으로 구현체 생성
public interface UserDao {

    /**
     * 모든 사용자 조회
     * 
     * 기능:
     * - users 테이블의 전체 레코드 조회
     * - User 객체 리스트로 반환
     * 
     * SQL:
     * SELECT * FROM users
     * 
     * 매핑:
     * - 컬럼명과 User 클래스의 필드명이 일치해야 함
     * - snake_case(DB) → camelCase(Java) 자동 변환 (설정 필요)
     * 
     * 사용 시나리오:
     * - 관리자 페이지에서 전체 사용자 목록 표시
     * - 통계 데이터 생성
     * 
     * ⚠️ 주의:
     * - 데이터가 많을 경우 성능 문제 발생 가능
     * - 프로덕션에서는 페이징 처리 필수
     * 
     * TODO:
     * - 페이징 파라미터 추가 (offset, limit)
     * - 정렬 옵션 추가
     * 
     * @return List<User> 전체 사용자 리스트
     */
    // 일단 테스트용 - 나중에 MyBatis XML로 변경 가능
    @Select("SELECT * FROM users")
    List<User> findAll();

    /**
     * ID로 사용자 조회
     * 
     * 기능:
     * - 특정 ID의 사용자 단건 조회
     * - Primary Key 기반 검색
     * 
     * SQL:
     * SELECT * FROM users WHERE id = #{id}
     * 
     * 파라미터 바인딩:
     * - #{id}: MyBatis가 PreparedStatement로 처리 (SQL Injection 방지)
     * - Java의 Long 타입이 MySQL의 BIGINT로 매핑
     * 
     * 사용 시나리오:
     * - 사용자 프로필 조회
     * - 로그인 후 사용자 정보 표시
     * - 권한 검증
     * 
     * 반환값:
     * - 사용자 존재: User 객체 반환
     * - 사용자 없음: null 반환
     * 
     * ⚠️ 주의:
     * - null 체크 필수 (Service 계층에서 처리)
     * - Optional<User>로 변경 고려
     * 
     * TODO:
     * - Optional<User> 반환 타입으로 변경
     * - 예외 처리 추가 (UserNotFoundException)
     * 
     * @param id 조회할 사용자 ID (Primary Key)
     * @return User 사용자 객체 또는 null
     */
    @Select("SELECT * FROM users WHERE id = #{id}")
    User findById(Long id);

    // ========================================
    // 향후 추가 예정 메서드 (TODO)
    // ========================================

    /**
     * TODO: 사용자 추가
     * 
     * @param user 추가할 사용자 정보
     * @return int 삽입된 행 개수 (1: 성공, 0: 실패)
     */
    // @Insert("INSERT INTO users (username, email, password) VALUES (#{username},
    // #{email}, #{password})")
    // int insert(User user);

    /**
     * TODO: 사용자 수정
     * 
     * @param user 수정할 사용자 정보 (id 포함)
     * @return int 수정된 행 개수
     */
    // @Update("UPDATE users SET username=#{username}, email=#{email} WHERE
    // id=#{id}")
    // int update(User user);

    /**
     * TODO: 사용자 삭제
     * 
     * @param id 삭제할 사용자 ID
     * @return int 삭제된 행 개수
     */
    // @Delete("DELETE FROM users WHERE id=#{id}")
    // int deleteById(Long id);

    /**
     * TODO: 이메일로 사용자 조회 (로그인용)
     * 
     * @param email 사용자 이메일
     * @return User 사용자 객체 또는 null
     */
    // @Select("SELECT * FROM users WHERE email = #{email}")
    // User findByEmail(String email);
}