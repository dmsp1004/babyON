package com.babyon.childcare.exception;

/**
 * 부모를 찾을 수 없을 때 발생하는 예외
 */
public class ParentNotFoundException extends BusinessException {
    public ParentNotFoundException(Long parentId) {
        super("PARENT_NOT_FOUND", "Parent not found with ID: " + parentId);
    }

    public ParentNotFoundException(String email) {
        super("PARENT_NOT_FOUND", "Parent not found with email: " + email);
    }

    public ParentNotFoundException(String message, boolean custom) {
        super("PARENT_NOT_FOUND", message);
    }
}
