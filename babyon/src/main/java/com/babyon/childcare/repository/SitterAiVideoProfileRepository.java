package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterAiVideoProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * 시터 AI 화상 이력서 Repository
 * 시터의 AI 화상 이력서 데이터 접근 레이어
 */
@Repository
public interface SitterAiVideoProfileRepository extends JpaRepository<SitterAiVideoProfile, Long> {

    /**
     * 시터 ID로 AI 화상 이력서 조회
     */
    Optional<SitterAiVideoProfile> findBySitterId(Long sitterId);

    /**
     * 시터 ID와 상태로 AI 화상 이력서 조회
     */
    Optional<SitterAiVideoProfile> findBySitterIdAndStatus(Long sitterId, SitterAiVideoProfile.ProfileStatus status);

    /**
     * 시터 ID로 AI 화상 이력서 존재 여부 확인
     */
    boolean existsBySitterId(Long sitterId);

    /**
     * 조회수 증가
     */
    @Modifying
    @Transactional
    @Query("UPDATE SitterAiVideoProfile sap SET sap.viewCount = sap.viewCount + 1 WHERE sap.sitterId = :sitterId")
    void incrementViewCount(@Param("sitterId") Long sitterId);
}
