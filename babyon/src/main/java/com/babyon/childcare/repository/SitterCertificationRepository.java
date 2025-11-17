package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterCertification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SitterCertificationRepository extends JpaRepository<SitterCertification, Long> {

    List<SitterCertification> findBySitterId(Long sitterId);

    List<SitterCertification> findBySitterIdAndIsVerifiedTrue(Long sitterId);

    void deleteBySitterId(Long sitterId);
}
