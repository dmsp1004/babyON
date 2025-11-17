package com.babyon.childcare.service;

import com.babyon.childcare.dto.*;
import com.babyon.childcare.entity.*;
import com.babyon.childcare.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SitterProfileService {

    private final SitterProfileRepository sitterProfileRepository;
    private final SitterRepository sitterRepository;
    private final SitterCertificationRepository certificationRepository;
    private final SitterExperienceRepository experienceRepository;
    private final SitterAvailableTimeRepository availableTimeRepository;
    private final SitterServiceAreaRepository serviceAreaRepository;
    private final SitterVideoResumeRepository videoResumeRepository;

    /**
     * Get or create sitter profile by sitter ID
     */
    @Transactional
    public SitterProfileResponse getOrCreateProfile(Long sitterId) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterProfile profile = sitterProfileRepository.findBySitterId(sitterId)
                .orElseGet(() -> createDefaultProfile(sitter));

        return toProfileResponse(profile);
    }

    /**
     * Update sitter profile
     */
    @Transactional
    public SitterProfileResponse updateProfile(Long sitterId, SitterProfileRequest request) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterProfile profile = sitterProfileRepository.findBySitterId(sitterId)
                .orElseGet(() -> createDefaultProfile(sitter));

        // Update profile fields
        profile.setProfileImageUrl(request.getProfileImageUrl());
        profile.setIntroduction(request.getIntroduction());
        profile.setAvailableServiceTypes(joinList(request.getAvailableServiceTypes()));
        profile.setPreferredAgeGroups(joinList(request.getPreferredAgeGroups()));
        profile.setLanguagesSpoken(joinList(request.getLanguagesSpoken()));
        profile.setEducationLevel(request.getEducationLevel());

        // Check if profile is completed
        profile.setProfileCompleted(isProfileCompleted(profile));

        SitterProfile savedProfile = sitterProfileRepository.save(profile);
        return toProfileResponse(savedProfile);
    }

    /**
     * Search sitter profiles with filters
     */
    public Page<SitterProfileResponse> searchProfiles(SitterSearchRequest searchRequest) {
        int page = searchRequest.getPage() != null ? searchRequest.getPage() : 0;
        int size = searchRequest.getSize() != null ? searchRequest.getSize() : 10;

        String sortBy = searchRequest.getSortBy() != null ? searchRequest.getSortBy() : "createdAt";
        String sortDirection = searchRequest.getSortDirection() != null ? searchRequest.getSortDirection() : "desc";

        Sort sort = Sort.by(Sort.Direction.fromString(sortDirection), sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<SitterProfile> profiles;

        if (searchRequest.getCity() != null || searchRequest.getServiceType() != null) {
            profiles = sitterProfileRepository.searchProfiles(
                    searchRequest.getCity(),
                    searchRequest.getServiceType(),
                    pageable
            );
        } else {
            profiles = sitterProfileRepository.findByIsActiveTrue(pageable);
        }

        return profiles.map(this::toProfileResponse);
    }

    /**
     * Add certification to sitter
     */
    @Transactional
    public SitterCertificationResponse addCertification(Long sitterId, SitterCertificationRequest request) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterCertification certification = new SitterCertification();
        certification.setSitter(sitter);
        certification.setCertificationName(request.getCertificationName());
        certification.setIssuedBy(request.getIssuedBy());
        certification.setIssueDate(request.getIssueDate());
        certification.setExpiryDate(request.getExpiryDate());
        certification.setCertificateImageUrl(request.getCertificateImageUrl());
        certification.setDescription(request.getDescription());

        SitterCertification saved = certificationRepository.save(certification);
        return toCertificationResponse(saved);
    }

    /**
     * Add experience to sitter
     */
    @Transactional
    public SitterExperienceResponse addExperience(Long sitterId, SitterExperienceRequest request) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterExperience experience = new SitterExperience();
        experience.setSitter(sitter);
        experience.setCompanyName(request.getCompanyName());
        experience.setPosition(request.getPosition());
        experience.setStartDate(request.getStartDate());
        experience.setEndDate(request.getEndDate());
        experience.setIsCurrent(request.getIsCurrent());
        experience.setDescription(request.getDescription());
        experience.setChildrenAgeGroup(request.getChildrenAgeGroup());
        experience.setNumberOfChildren(request.getNumberOfChildren());

        SitterExperience saved = experienceRepository.save(experience);
        return toExperienceResponse(saved);
    }

    /**
     * Add available time to sitter
     */
    @Transactional
    public SitterAvailableTimeResponse addAvailableTime(Long sitterId, SitterAvailableTimeRequest request) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterAvailableTime availableTime = new SitterAvailableTime();
        availableTime.setSitter(sitter);
        availableTime.setDayOfWeek(SitterAvailableTime.DayOfWeek.valueOf(request.getDayOfWeek()));
        availableTime.setStartTime(request.getStartTime());
        availableTime.setEndTime(request.getEndTime());
        availableTime.setIsFlexible(request.getIsFlexible());

        SitterAvailableTime saved = availableTimeRepository.save(availableTime);
        return toAvailableTimeResponse(saved);
    }

    /**
     * Add service area to sitter
     */
    @Transactional
    public SitterServiceAreaResponse addServiceArea(Long sitterId, SitterServiceAreaRequest request) {
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));

        SitterServiceArea serviceArea = new SitterServiceArea();
        serviceArea.setSitter(sitter);
        serviceArea.setCity(request.getCity());
        serviceArea.setDistrict(request.getDistrict());
        serviceArea.setDetailedArea(request.getDetailedArea());
        serviceArea.setTravelDistanceKm(request.getTravelDistanceKm());
        serviceArea.setIsPrimary(request.getIsPrimary());

        SitterServiceArea saved = serviceAreaRepository.save(serviceArea);
        return toServiceAreaResponse(saved);
    }

    // Helper methods

    private SitterProfile createDefaultProfile(Sitter sitter) {
        SitterProfile profile = new SitterProfile();
        profile.setSitter(sitter);
        profile.setProfileCompleted(false);
        profile.setIsActive(true);
        return sitterProfileRepository.save(profile);
    }

    private boolean isProfileCompleted(SitterProfile profile) {
        return profile.getIntroduction() != null && !profile.getIntroduction().isEmpty()
                && profile.getAvailableServiceTypes() != null && !profile.getAvailableServiceTypes().isEmpty()
                && profile.getLanguagesSpoken() != null && !profile.getLanguagesSpoken().isEmpty();
    }

    private String joinList(List<String> list) {
        return list != null ? String.join(",", list) : null;
    }

    private List<String> splitString(String str) {
        return str != null && !str.isEmpty()
                ? Arrays.asList(str.split(","))
                : List.of();
    }

    private SitterProfileResponse toProfileResponse(SitterProfile profile) {
        Sitter sitter = profile.getSitter();

        return SitterProfileResponse.builder()
                .id(profile.getId())
                .sitterId(sitter.getId())
                .sitterEmail(sitter.getEmail())
                .profileImageUrl(profile.getProfileImageUrl())
                .introduction(profile.getIntroduction())
                .availableServiceTypes(splitString(profile.getAvailableServiceTypes()))
                .preferredAgeGroups(splitString(profile.getPreferredAgeGroups()))
                .languagesSpoken(splitString(profile.getLanguagesSpoken()))
                .educationLevel(profile.getEducationLevel())
                .rating(profile.getRating())
                .totalReviews(profile.getTotalReviews())
                .profileCompleted(profile.getProfileCompleted())
                .isActive(profile.getIsActive())
                .sitterType(sitter.getSitterType() != null ? sitter.getSitterType().name() : null)
                .experienceYears(sitter.getExperienceYears())
                .hourlyRate(sitter.getHourlyRate())
                .bio(sitter.getBio())
                .isVerified(sitter.getIsVerified())
                .certifications(getCertifications(sitter.getId()))
                .experiences(getExperiences(sitter.getId()))
                .availableTimes(getAvailableTimes(sitter.getId()))
                .serviceAreas(getServiceAreas(sitter.getId()))
                .primaryVideoResume(getPrimaryVideoResume(sitter.getId()))
                .createdAt(profile.getCreatedAt())
                .updatedAt(profile.getUpdatedAt())
                .build();
    }

    private List<SitterCertificationResponse> getCertifications(Long sitterId) {
        return certificationRepository.findBySitterId(sitterId).stream()
                .map(this::toCertificationResponse)
                .collect(Collectors.toList());
    }

    private List<SitterExperienceResponse> getExperiences(Long sitterId) {
        return experienceRepository.findBySitterIdOrderByStartDateDesc(sitterId).stream()
                .map(this::toExperienceResponse)
                .collect(Collectors.toList());
    }

    private List<SitterAvailableTimeResponse> getAvailableTimes(Long sitterId) {
        return availableTimeRepository.findBySitterIdOrderByDayOfWeek(sitterId).stream()
                .map(this::toAvailableTimeResponse)
                .collect(Collectors.toList());
    }

    private List<SitterServiceAreaResponse> getServiceAreas(Long sitterId) {
        return serviceAreaRepository.findBySitterId(sitterId).stream()
                .map(this::toServiceAreaResponse)
                .collect(Collectors.toList());
    }

    private SitterVideoResumeResponse getPrimaryVideoResume(Long sitterId) {
        return videoResumeRepository.findBySitterIdAndIsPrimaryTrue(sitterId)
                .map(this::toVideoResumeResponse)
                .orElse(null);
    }

    private SitterCertificationResponse toCertificationResponse(SitterCertification cert) {
        return SitterCertificationResponse.builder()
                .id(cert.getId())
                .sitterId(cert.getSitter().getId())
                .certificationName(cert.getCertificationName())
                .issuedBy(cert.getIssuedBy())
                .issueDate(cert.getIssueDate())
                .expiryDate(cert.getExpiryDate())
                .certificateImageUrl(cert.getCertificateImageUrl())
                .description(cert.getDescription())
                .isVerified(cert.getIsVerified())
                .createdAt(cert.getCreatedAt())
                .updatedAt(cert.getUpdatedAt())
                .build();
    }

    private SitterExperienceResponse toExperienceResponse(SitterExperience exp) {
        return SitterExperienceResponse.builder()
                .id(exp.getId())
                .sitterId(exp.getSitter().getId())
                .companyName(exp.getCompanyName())
                .position(exp.getPosition())
                .startDate(exp.getStartDate())
                .endDate(exp.getEndDate())
                .isCurrent(exp.getIsCurrent())
                .description(exp.getDescription())
                .childrenAgeGroup(exp.getChildrenAgeGroup())
                .numberOfChildren(exp.getNumberOfChildren())
                .createdAt(exp.getCreatedAt())
                .updatedAt(exp.getUpdatedAt())
                .build();
    }

    private SitterAvailableTimeResponse toAvailableTimeResponse(SitterAvailableTime time) {
        return SitterAvailableTimeResponse.builder()
                .id(time.getId())
                .sitterId(time.getSitter().getId())
                .dayOfWeek(time.getDayOfWeek().name())
                .startTime(time.getStartTime())
                .endTime(time.getEndTime())
                .isFlexible(time.getIsFlexible())
                .createdAt(time.getCreatedAt())
                .updatedAt(time.getUpdatedAt())
                .build();
    }

    private SitterServiceAreaResponse toServiceAreaResponse(SitterServiceArea area) {
        return SitterServiceAreaResponse.builder()
                .id(area.getId())
                .sitterId(area.getSitter().getId())
                .city(area.getCity())
                .district(area.getDistrict())
                .detailedArea(area.getDetailedArea())
                .travelDistanceKm(area.getTravelDistanceKm())
                .isPrimary(area.getIsPrimary())
                .createdAt(area.getCreatedAt())
                .updatedAt(area.getUpdatedAt())
                .build();
    }

    private SitterVideoResumeResponse toVideoResumeResponse(SitterVideoResume video) {
        return SitterVideoResumeResponse.builder()
                .id(video.getId())
                .sitterId(video.getSitter().getId())
                .videoUrl(video.getVideoUrl())
                .thumbnailUrl(video.getThumbnailUrl())
                .title(video.getTitle())
                .durationSeconds(video.getDurationSeconds())
                .fileSizeMb(video.getFileSizeMb())
                .aiAnalysisResult(video.getAiAnalysisResult())
                .aiAnalyzedAt(video.getAiAnalyzedAt())
                .isPrimary(video.getIsPrimary())
                .viewCount(video.getViewCount())
                .createdAt(video.getCreatedAt())
                .updatedAt(video.getUpdatedAt())
                .build();
    }
}
