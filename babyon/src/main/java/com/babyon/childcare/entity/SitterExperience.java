package com.babyon.childcare.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "sitter_experiences")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SitterExperience {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "position")
    private String position;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "is_current")
    private Boolean isCurrent = false; // Currently working here

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "children_age_group", length = 100)
    private String childrenAgeGroup; // Age group cared for

    @Column(name = "number_of_children")
    private Integer numberOfChildren;

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
