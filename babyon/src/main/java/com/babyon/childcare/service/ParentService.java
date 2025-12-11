package com.babyon.childcare.service;

import com.babyon.childcare.dto.ParentProfileResponse;
import com.babyon.childcare.dto.ParentProfileUpdateRequest;
import com.babyon.childcare.entity.Parent;
import com.babyon.childcare.exception.ParentNotFoundException;
import com.babyon.childcare.repository.ParentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ParentService {

    private final ParentRepository parentRepository;

    /**
     * 부모 프로필 조회
     * @param parentId 부모 ID
     * @return 부모 프로필 정보
     */
    @Transactional(readOnly = true)
    public ParentProfileResponse getProfile(Long parentId) {
        Parent parent = parentRepository.findById(parentId)
                .orElseThrow(() -> new ParentNotFoundException(parentId));

        return ParentProfileResponse.from(parent);
    }

    /**
     * 부모 프로필 수정
     * @param parentId 부모 ID
     * @param request 수정 요청 정보
     * @return 수정된 프로필 정보
     */
    @Transactional
    public ParentProfileResponse updateProfile(Long parentId, ParentProfileUpdateRequest request) {
        Parent parent = parentRepository.findById(parentId)
                .orElseThrow(() -> new ParentNotFoundException(parentId));

        // 자녀 수 수정
        if (request.getNumberOfChildren() != null) {
            parent.setNumberOfChildren(request.getNumberOfChildren());
        }

        // 주소 수정
        if (request.getAddress() != null) {
            parent.setAddress(request.getAddress());
        }

        // 추가 정보 수정
        if (request.getAdditionalInfo() != null) {
            parent.setAdditionalInfo(request.getAdditionalInfo());
        }

        // 전화번호 수정
        if (request.getPhoneNumber() != null) {
            parent.setPhoneNumber(request.getPhoneNumber());
        }

        Parent updatedParent = parentRepository.save(parent);
        log.info("부모 프로필 수정 완료: parentId={}", parentId);

        return ParentProfileResponse.from(updatedParent);
    }

    /**
     * 부모 존재 여부 확인
     * @param parentId 부모 ID
     * @return 존재 여부
     */
    @Transactional(readOnly = true)
    public boolean exists(Long parentId) {
        return parentRepository.existsById(parentId);
    }
}
