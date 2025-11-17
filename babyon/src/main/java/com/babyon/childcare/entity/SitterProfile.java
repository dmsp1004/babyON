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
@Table(name = "sitter_profiles")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SitterProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "sitter_id", nullable = false, unique = true)
    private Sitter sitter;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @Column(name = "introduction", columnDefinition = "TEXT")
    private String introduction;

    @Column(name = "available_service_types", length = 500)
    private String availableServiceTypes; // Comma-separated: SHORT_TERM,LONG_TERM,LIVE_IN,PICKUP_DROPOFF

    @Column(name = "preferred_age_groups")
    private String preferredAgeGroups; // Comma-separated: INFANT,TODDLER,PRESCHOOL,SCHOOL_AGE

    @Column(name = "languages_spoken")
    private String languagesSpoken; // Comma-separated: Korean,English,Chinese,etc

    @Column(name = "education_level", length = 50)
    private String educationLevel; // HIGH_SCHOOL,BACHELOR,MASTER,DOCTORATE,etc

    @Column(name = "rating", precision = 3, scale = 2)
    private BigDecimal rating = BigDecimal.ZERO;

    @Column(name = "total_reviews")
    private Integer totalReviews = 0;

    @Column(name = "profile_completed")
    private Boolean profileCompleted = false;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Enum for service types
    public enum ServiceType {
        SHORT_TERM,      // 단기
        LONG_TERM,       // 장기
        LIVE_IN,         // 입주
        PICKUP_DROPOFF   // 등하원
    }

    // Enum for age groups
    public enum AgeGroup {
        INFANT,          // 영아 (0-12개월)
        TODDLER,         // 유아 (1-3세)
        PRESCHOOL,       // 미취학 (4-6세)
        SCHOOL_AGE       // 학령기 (7세 이상)
    }

    // Enum for education level
    public enum EducationLevel {
        HIGH_SCHOOL,
        ASSOCIATE,
        BACHELOR,
        MASTER,
        DOCTORATE,
        SPECIALIZED_TRAINING // 전문교육과정
    }
}
