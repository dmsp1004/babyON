package com.babyon.childcare.repository;

import com.babyon.childcare.entity.AiQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * AI 질문 Repository
 * 랜덤 질문 선택 및 관리를 위한 데이터 접근 레이어
 */
@Repository
public interface AiQuestionRepository extends JpaRepository<AiQuestion, Long> {

    /**
     * 활성화된 질문 중 랜덤으로 하나 선택
     * ORDER BY RAND()는 MySQL/MariaDB 전용이므로, 서비스 레이어에서 처리 권장
     */
    List<AiQuestion> findByIsActiveTrue();

    /**
     * 특정 카테고리의 활성화된 질문 목록 조회
     */
    List<AiQuestion> findByIsActiveTrueAndQuestionCategory(AiQuestion.QuestionCategory questionCategory);

    /**
     * 난이도별 활성화된 질문 목록 조회
     */
    List<AiQuestion> findByIsActiveTrueAndDifficultyLevel(AiQuestion.DifficultyLevel difficultyLevel);

    /**
     * 질문 ID로 활성화된 질문 조회
     */
    Optional<AiQuestion> findByIdAndIsActiveTrue(Long id);

    /**
     * 사용 횟수가 적은 순으로 활성화된 질문 조회 (질문 균등 분배)
     */
    @Query("SELECT aq FROM AiQuestion aq WHERE aq.isActive = true ORDER BY aq.usageCount ASC")
    List<AiQuestion> findActiveQuestionsOrderByUsageCount();
}
