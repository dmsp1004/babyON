package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterVideoResume;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SitterVideoResumeRepository extends JpaRepository<SitterVideoResume, Long> {

    List<SitterVideoResume> findBySitterIdOrderByCreatedAtDesc(Long sitterId);

    Optional<SitterVideoResume> findBySitterIdAndIsPrimaryTrue(Long sitterId);

    void deleteBySitterId(Long sitterId);
}
