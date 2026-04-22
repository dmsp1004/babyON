package com.babyon.childcare.exception;

public class DuplicateApplicationException extends BusinessException {

    public DuplicateApplicationException(Long jobPostingId) {
        super("DUPLICATE_APPLICATION", "이미 해당 구인글에 지원하셨습니다. (구인글 ID: " + jobPostingId + ")");
    }
}
