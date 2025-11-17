package com.babyon.childcare.repository;

import com.babyon.childcare.entity.JobPosting;
import com.babyon.childcare.entity.Parent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

import java.time.LocalDateTime;

@Repository
public interface JobPostingRepository extends JpaRepository<JobPosting, Long> {

    // 활성화된 모든 구인글 검색 (페이징) - JOIN FETCH로 Parent 함께 조회
    @Query("SELECT jp FROM JobPosting jp JOIN FETCH jp.parent WHERE jp.isActive = true")
    Page<JobPosting> findByIsActiveTrueWithParent(Pageable pageable);

    // 특정 부모가 작성한 구인글 검색 - JOIN FETCH로 Parent 함께 조회
    @Query("SELECT jp FROM JobPosting jp JOIN FETCH jp.parent p WHERE p = :parent")
    Page<JobPosting> findByParentWithParent(@Param("parent") Parent parent, Pageable pageable);

    // 제목 또는 설명에 특정 키워드가 포함된 구인글 검색 - 수정된 쿼리
    @Query("SELECT jp FROM JobPosting jp JOIN FETCH jp.parent WHERE jp.isActive = true AND " +
            "(jp.title LIKE %:keyword% OR jp.description LIKE %:keyword%)")
    Page<JobPosting> searchByKeywordWithParent(@Param("keyword") String keyword, Pageable pageable);

    // 특정 위치에 있는 구인글 검색 - JOIN FETCH 추가
    @Query("SELECT jp FROM JobPosting jp JOIN FETCH jp.parent WHERE jp.isActive = true AND jp.location LIKE %:location%")
    Page<JobPosting> findByLocationWithParent(@Param("location") String location, Pageable pageable);

    // 구인글 ID로 상세 조회 (활성화 여부 무관) - JOIN FETCH
    @Query("SELECT jp FROM JobPosting jp JOIN FETCH jp.parent WHERE jp.id = :id")
    JobPosting findByIdWithParent(@Param("id") Long id);

    // 구인글 ID 목록으로 지원 수 조회 (Batch 조회용)
    @Query("SELECT jp.id, COUNT(ja) FROM JobPosting jp " +
            "LEFT JOIN jp.applications ja " +
            "WHERE jp.id IN :ids " +
            "GROUP BY jp.id")
    List<Object[]> countApplicationsByJobPostingIds(@Param("ids") List<Long> ids);
}