package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterAvailableTime;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SitterAvailableTimeRepository extends JpaRepository<SitterAvailableTime, Long> {

    List<SitterAvailableTime> findBySitterIdOrderByDayOfWeek(Long sitterId);

    List<SitterAvailableTime> findBySitterIdAndDayOfWeek(Long sitterId, SitterAvailableTime.DayOfWeek dayOfWeek);

    void deleteBySitterId(Long sitterId);
}
