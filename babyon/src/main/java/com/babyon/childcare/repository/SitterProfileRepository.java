package com.babyon.childcare.repository;

import com.babyon.childcare.entity.SitterProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SitterProfileRepository extends JpaRepository<SitterProfile, Long> {

    Optional<SitterProfile> findBySitterId(Long sitterId);

    boolean existsBySitterId(Long sitterId);

    // Find all active profiles
    Page<SitterProfile> findByIsActiveTrue(Pageable pageable);

    // Find profiles by rating
    @Query("SELECT sp FROM SitterProfile sp WHERE sp.isActive = true AND sp.rating >= :minRating ORDER BY sp.rating DESC")
    Page<SitterProfile> findByMinRating(@Param("minRating") Double minRating, Pageable pageable);

    // Search profiles with filters
    @Query("SELECT sp FROM SitterProfile sp WHERE sp.isActive = true " +
           "AND (:city IS NULL OR EXISTS (SELECT ssa FROM SitterServiceArea ssa WHERE ssa.sitter.id = sp.sitter.id AND ssa.city LIKE %:city%)) " +
           "AND (:serviceType IS NULL OR sp.availableServiceTypes LIKE %:serviceType%)")
    Page<SitterProfile> searchProfiles(@Param("city") String city,
                                       @Param("serviceType") String serviceType,
                                       Pageable pageable);
}
