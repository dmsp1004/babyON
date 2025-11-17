package com.babyon.childcare.repository;

import com.babyon.childcare.entity.JobApplication;
import com.babyon.childcare.entity.Sitter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {

    // 특정 구인글에 대한 모든 지원서 검색
    List<JobApplication> findByJobPostingId(Long jobPostingId);

    // 특정 시터가 제출한 모든 지원서 검색
    List<JobApplication> findBySitter(Sitter sitter);

    // 특정 시터가 특정 구인글에 제출한 지원서 검색
    Optional<JobApplication> findByJobPostingIdAndSitterId(Long jobPostingId, Long sitterId);

    // 특정 상태의 지원서 검색
    List<JobApplication> findByStatus(JobApplication.ApplicationStatus status);

    // 특정 부모의 구인글에 대한 모든 지원서 검색
    List<JobApplication> findByJobPosting_Parent_Id(Long parentId);

    // 특정 지원서가 이미 존재하는지 확인
    boolean existsByJobPostingIdAndSitterId(Long jobPostingId, Long sitterId);

    // 특정 구인글의 지원자 수 조회 (JobPostingRepository에서 이동)
    @Query("SELECT COUNT(ja) FROM JobApplication ja WHERE ja.jobPosting.id = :postingId")
    int countApplicationsByJobPostingId(@Param("postingId") Long postingId);

    // 구인글 ID 목록으로 지원 수 조회 (Batch 조회용 - jp.id와 count를 Object[] 형태로 반환)
    @Query("SELECT ja.jobPosting.id, COUNT(ja) FROM JobApplication ja " +
            "WHERE ja.jobPosting.id IN :ids " +
            "GROUP BY ja.jobPosting.id")
    List<Object[]> countApplicationsByJobPostingIds(@Param("ids") List<Long> ids);

}