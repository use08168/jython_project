package com.weenie_hut_jr.the_salty_spitoon.repository;

import com.weenie_hut_jr.the_salty_spitoon.entity.EmailVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 이메일 인증 Repository
 */
@Repository
public interface EmailVerificationRepository extends JpaRepository<EmailVerification, Long> {

    /**
     * 이메일로 가장 최근 인증 코드 조회 (미인증, 만료되지 않은)
     */
    @Query("SELECT e FROM EmailVerification e WHERE e.email = :email AND e.verified = false AND e.expiresAt > :now ORDER BY e.createdAt DESC")
    Optional<EmailVerification> findLatestValidByEmail(@Param("email") String email, @Param("now") LocalDateTime now);

    /**
     * 최근 1분간 해당 이메일로 발송된 인증 코드 개수
     */
    @Query("SELECT COUNT(e) FROM EmailVerification e WHERE e.email = :email AND e.createdAt > :since")
    long countRecentByEmail(@Param("email") String email, @Param("since") LocalDateTime since);

    /**
     * 이메일로 모든 미인증 코드 조회
     */
    List<EmailVerification> findByEmailAndVerifiedFalse(String email);

    /**
     * 만료된 인증 코드 삭제
     */
    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}
