package com.babyon.childcare.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * AI 화상 이력서용 랜덤 질문 엔티티
 * 시터가 화상 이력서 녹화 시 답변할 AI 질문을 관리합니다.
 */
@Entity
@Table(name = "ai_questions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "question_text", nullable = false, columnDefinition = "TEXT")
    private String questionText;

    @Column(name = "question_category", length = 50)
    @Enumerated(EnumType.STRING)
    private QuestionCategory questionCategory;

    @Column(name = "difficulty_level")
    @Enumerated(EnumType.STRING)
    private DifficultyLevel difficultyLevel;

    @Column(name = "time_limit_seconds", nullable = false)
    private Integer timeLimitSeconds = 120; // 기본값: 120초

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "usage_count")
    private Integer usageCount = 0; // 이 질문이 사용된 횟수

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Enum for difficulty level
    public enum DifficultyLevel {
        EASY,       // 쉬운 질문
        MEDIUM,     // 보통 질문
        HARD        // 어려운 질문
    }

    // Enum for question category
    public enum QuestionCategory {
        EXPERIENCE,     // 경험 관련
        PERSONALITY,    // 성격 관련
        SITUATION,      // 상황 대처
        MOTIVATION,     // 동기 및 열정
        CHILDCARE       // 육아 철학
    }
}
