package com.babyon.childcare.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * 시터 AI 화상 이력서 엔티티
 * 시터의 자유 소개 영상 및 AI 질문 답변 영상을 관리합니다.
 */
@Entity
@Table(name = "sitter_ai_video_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"sitter", "aiQuestion"})  // 순환 참조 방지
@EqualsAndHashCode(exclude = {"sitter", "aiQuestion"})
public class SitterAiVideoProfile {

    @Id
    @Column(name = "sitter_id")
    private Long sitterId; // PK이자 FK (Sitter ID)

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter;

    @Column(name = "intro_video_url", length = 500)
    private String introVideoUrl; // 자유 소개 영상 S3 URL

    @Column(name = "intro_video_duration_seconds")
    private Integer introVideoDurationSeconds; // 인트로 영상 길이 (최대 120초)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ai_question_id")
    private AiQuestion aiQuestion; // 답변한 AI 질문

    @Column(name = "answer_video_url", length = 500)
    private String answerVideoUrl; // AI 질문 답변 영상 S3 URL

    @Column(name = "answer_video_duration_seconds")
    private Integer answerVideoDurationSeconds; // 답변 영상 길이 (최대 120초)

    @Column(name = "status")
    @Enumerated(EnumType.STRING)
    private ProfileStatus status = ProfileStatus.PENDING; // 이력서 상태

    @Column(name = "view_count")
    private Integer viewCount = 0; // 조회수

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Enum for profile status
    public enum ProfileStatus {
        PENDING,    // 대기 중 (업로드 진행 중)
        ACTIVE,     // 활성화 (공개)
        INACTIVE,   // 비활성화 (비공개)
        REVIEWING   // 검토 중 (관리자 승인 대기)
    }
}
