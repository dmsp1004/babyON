package com.babyon.childcare.controller;

import com.babyon.childcare.dto.AuthResponse;
import com.babyon.childcare.dto.OAuthRegisterRequest;
import com.babyon.childcare.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class OAuthRegisterController {

    private final UserService userService;

    @Autowired
    public OAuthRegisterController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/oauth2/callback/{provider}")
    public ResponseEntity<AuthResponse> oauthCallback(
            @PathVariable String provider,
            @Valid @RequestBody OAuthRegisterRequest request) {

        request.setProvider(provider);
        AuthResponse response = userService.completeOAuthRegistration(request);
        return ResponseEntity.ok(response);
    }
}
