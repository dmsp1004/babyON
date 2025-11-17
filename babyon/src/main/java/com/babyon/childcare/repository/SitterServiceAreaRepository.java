package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterServiceArea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SitterServiceAreaRepository extends JpaRepository<SitterServiceArea, Long> {

    List<SitterServiceArea> findBySitterId(Long sitterId);

    List<SitterServiceArea> findByCity(String city);

    List<SitterServiceArea> findByCityAndDistrict(String city, String district);

    Optional<SitterServiceArea> findBySitterIdAndIsPrimaryTrue(Long sitterId);

    void deleteBySitterId(Long sitterId);
}
