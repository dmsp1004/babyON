package com.babyon.childcare.repository;

import com.babyon.childcare.entity.Sitter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SitterRepository extends JpaRepository<Sitter, Long> {
}