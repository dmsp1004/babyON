package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterExperience;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SitterExperienceRepository extends JpaRepository<SitterExperience, Long> {

    List<SitterExperience> findBySitterIdOrderByStartDateDesc(Long sitterId);

    List<SitterExperience> findBySitterIdAndIsCurrentTrue(Long sitterId);

    void deleteBySitterId(Long sitterId);
}
