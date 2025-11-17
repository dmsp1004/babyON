package com.babyon.childcare.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "sitter_video_resumes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SitterVideoResume {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter;

    @Column(name = "video_url", nullable = false, length = 500)
    private String videoUrl;

    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;

    @Column(name = "title")
    private String title;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "file_size_mb", precision = 10, scale = 2)
    private BigDecimal fileSizeMb;

    @Column(name = "ai_analysis_result", columnDefinition = "JSON")
    private String aiAnalysisResult; // AI-generated insights (keywords, sentiment, etc)

    @Column(name = "ai_analyzed_at")
    private LocalDateTime aiAnalyzedAt;

    @Column(name = "is_primary")
    private Boolean isPrimary = false; // Primary video resume

    @Column(name = "view_count")
    private Integer viewCount = 0;

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
