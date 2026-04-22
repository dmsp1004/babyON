package com.babyon.childcare.service;

import com.babyon.childcare.dto.AuthResponse;
import com.babyon.childcare.dto.LoginRequest;
import com.babyon.childcare.dto.OAuthRegisterRequest;
import com.babyon.childcare.dto.RegisterRequest;
import com.babyon.childcare.entity.Admin;
import com.babyon.childcare.entity.Parent;
import com.babyon.childcare.entity.RefreshToken;
import com.babyon.childcare.entity.Sitter;
import com.babyon.childcare.entity.User;
import com.babyon.childcare.repository.RefreshTokenRepository;
import com.babyon.childcare.repository.UserRepository;
import com.babyon.childcare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.lang.reflect.Field;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    @Autowired
    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil, RefreshTokenRepository refreshTokenRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.refreshTokenRepository = refreshTokenRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

        List<GrantedAuthority> authorities = new ArrayList<>();
        if (user.getUserType() != null) {
            authorities.add(new SimpleGrantedAuthority("ROLE_" + user.getUserType().name()));
        }

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                authorities
        );
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // 이메일 중복 확인
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("이미 등록된 이메일입니다");
        }

        // 회원 유형에 따라 엔티티 생성
        User user;
        User.UserType userType;

        if (request.getUserType().equals("PARENT")) {
            user = new Parent();
            userType = User.UserType.PARENT;
        } else if (request.getUserType().equals("SITTER")) {
            user = new Sitter();
            userType = User.UserType.SITTER;
        } else if (request.getUserType().equals("ADMIN")) {
            user = new Admin();
            userType = User.UserType.ADMIN;
        } else {
            throw new RuntimeException("잘못된 회원 유형입니다");
        }

        // 사용자 정보 설정
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(request.getPhoneNumber());

        // 수동으로 userType 값 설정 (리플렉션 사용)
        try {
            Field userTypeField = User.class.getDeclaredField("userType");
            userTypeField.setAccessible(true);
            userTypeField.set(user, userType);
        } catch (Exception e) {
            throw new RuntimeException("사용자 유형 설정 실패", e);
        }

        // 저장
        user = userRepository.save(user);

        // 토큰 생성
        UserDetails userDetails = loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);
        String refreshToken = createRefreshToken(user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getUserType() != null ? user.getUserType().toString() : request.getUserType())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // 직접 인증 처리
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + request.getEmail()));

        // 비밀번호 검증
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid password");
        }

        // 토큰 생성 (기존 refresh token 폐기 후 새로 발급)
        refreshTokenRepository.deleteByEmail(user.getEmail());
        UserDetails userDetails = loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);
        String refreshToken = createRefreshToken(user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getUserType().toString())
                .build();
    }

    // Admin 계정 생성을 위한 메서드
    @Transactional
    public AuthResponse createAdminAccount(String email, String password, String phoneNumber) {
        // 이메일 중복 확인
        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("이미 등록된 이메일입니다");
        }

        // Admin 엔티티 생성
        Admin admin = new Admin();
        admin.setEmail(email);
        admin.setPassword(passwordEncoder.encode(password));
        admin.setPhoneNumber(phoneNumber);
        admin.setDepartment("System");
        admin.setAdminLevel(1);
        admin.setAccessAllRecords(true);

        // 저장
        admin = userRepository.save(admin);

        // JWT 토큰 생성
        UserDetails userDetails = loadUserByUsername(admin.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .userId(admin.getId())
                .email(admin.getEmail())
                .role(admin.getUserType().toString())
                .build();
    }

    /**
     * 소셜 로그인 사용자의 회원가입 완료 메서드
     */
    @Transactional
    public AuthResponse completeOAuthRegistration(OAuthRegisterRequest request) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UsernameNotFoundException("소셜 인증 정보가 없습니다. 이메일: " + request.getEmail()));

        // 소셜 로그인 정보 검증
        if (user.getProvider() == null || !user.getProvider().equals(request.getProvider())) {
            throw new RuntimeException("소셜 로그인 정보가 일치하지 않습니다");
        }

        // 사용자 유형 변경 (PARENT/SITTER)
        User.UserType userType;

        if (request.getUserType().equals("PARENT")) {
            // 기존 사용자가 Parent가 아니면 새로 생성
            if (!(user instanceof Parent)) {
                Parent parent = new Parent();
                copyBaseUserProperties(user, parent);
                updateParentInfo(parent, request);
                user = parent;
            } else {
                // 이미 Parent인 경우 정보 업데이트
                updateParentInfo((Parent) user, request);
            }
            userType = User.UserType.PARENT;
        } else if (request.getUserType().equals("SITTER")) {
            // 기존 사용자가 Sitter가 아니면 새로 생성
            if (!(user instanceof Sitter)) {
                Sitter sitter = new Sitter();
                copyBaseUserProperties(user, sitter);
                updateSitterInfo(sitter, request);
                user = sitter;
            } else {
                // 이미 Sitter인 경우 정보 업데이트
                updateSitterInfo((Sitter) user, request);
            }
            userType = User.UserType.SITTER;
        } else {
            throw new RuntimeException("잘못된 회원 유형입니다");
        }

        // 전화번호 업데이트
        user.setPhoneNumber(request.getPhoneNumber());

        // userType 설정 (리플렉션 사용)
        try {
            Field userTypeField = User.class.getDeclaredField("userType");
            userTypeField.setAccessible(true);
            userTypeField.set(user, userType);
        } catch (Exception e) {
            throw new RuntimeException("사용자 유형 설정 실패", e);
        }

        // 저장
        user = userRepository.save(user);

        // 토큰 생성
        refreshTokenRepository.deleteByEmail(user.getEmail());
        UserDetails userDetails = loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);
        String refreshToken = createRefreshToken(user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getUserType() != null ? user.getUserType().toString() : request.getUserType())
                .build();
    }

    /**
     * Refresh Token으로 새 Access Token 발급 (토큰 로테이션)
     */
    @Transactional
    public AuthResponse refreshAccessToken(String refreshTokenValue) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
                .orElseThrow(() -> new RuntimeException("유효하지 않은 Refresh Token입니다"));

        if (refreshToken.isExpired()) {
            refreshTokenRepository.deleteByToken(refreshTokenValue);
            throw new RuntimeException("Refresh Token이 만료되었습니다. 다시 로그인해주세요");
        }

        // 기존 refresh token 삭제 (rotation)
        refreshTokenRepository.deleteByToken(refreshTokenValue);

        String email = refreshToken.getEmail();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));

        UserDetails userDetails = loadUserByUsername(email);
        String newAccessToken = jwtUtil.generateToken(userDetails);
        String newRefreshToken = createRefreshToken(email);

        return AuthResponse.builder()
                .token(newAccessToken)
                .refreshToken(newRefreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getUserType().toString())
                .build();
    }

    /**
     * 로그아웃 처리 — Refresh Token 소유권 검증 후 폐기
     *
     * JWT가 유효한 상태(email 제공)에서는 토큰이 해당 계정 소유인지 확인 후 삭제한다.
     * logoutAllDevices=true이면 해당 계정의 모든 Refresh Token을 일괄 폐기한다.
     */
    @Transactional
    public void logout(String email, String refreshToken, boolean logoutAllDevices) {
        if (logoutAllDevices) {
            refreshTokenRepository.deleteByEmail(email);
            return;
        }
        if (StringUtils.hasText(refreshToken)) {
            refreshTokenRepository.findByToken(refreshToken)
                    .filter(rt -> rt.getEmail().equals(email))
                    .ifPresent(rt -> refreshTokenRepository.deleteByToken(refreshToken));
        }
    }

    /**
     * Refresh Token 단독 폐기 — JWT 없이 refresh token 값만으로 로그아웃할 때 사용
     * (JWT 만료 상태에서 로그아웃 요청 시 fallback)
     */
    @Transactional
    public void revokeRefreshToken(String refreshTokenValue) {
        refreshTokenRepository.deleteByToken(refreshTokenValue);
    }

    /**
     * Refresh Token 생성 및 저장
     */
    @Transactional
    public String createRefreshToken(String email) {
        String tokenValue = UUID.randomUUID().toString();
        RefreshToken refreshToken = RefreshToken.builder()
                .token(tokenValue)
                .email(email)
                .expiresAt(LocalDateTime.now().plusSeconds(refreshExpiration / 1000))
                .build();
        refreshTokenRepository.save(refreshToken);
        return tokenValue;
    }

    /**
     * 기본 사용자 속성 복사 메서드
     */
    private void copyBaseUserProperties(User source, User target) {
        target.setId(source.getId());
        target.setEmail(source.getEmail());
        target.setPassword(source.getPassword());
        target.setProvider(source.getProvider());
        target.setProviderId(source.getProviderId());
    }

    /**
     * Parent 정보 업데이트 메서드
     */
    private void updateParentInfo(Parent parent, OAuthRegisterRequest request) {
        if (request.getNumberOfChildren() != null) {
            parent.setNumberOfChildren(request.getNumberOfChildren());
        }
        if (request.getAddress() != null) {
            parent.setAddress(request.getAddress());
        }
        if (request.getAdditionalInfo() != null) {
            parent.setAdditionalInfo(request.getAdditionalInfo());
        }
    }

    /**
     * Sitter 정보 업데이트 메서드
     */
    private void updateSitterInfo(Sitter sitter, OAuthRegisterRequest request) {
        if (request.getSitterType() != null) {
            try {
                Sitter.SitterType sitterType = Sitter.SitterType.valueOf(request.getSitterType());
                sitter.setSitterType(sitterType);
            } catch (IllegalArgumentException e) {
                // 유효하지 않은 SitterType 값이면 무시
            }
        }
        if (request.getExperienceYears() != null) {
            sitter.setExperienceYears(request.getExperienceYears());
        }
        if (request.getHourlyRate() != null) {
            sitter.setHourlyRate(request.getHourlyRate());
        }
        if (request.getBio() != null) {
            sitter.setBio(request.getBio());
        }

        // 기본 검증 상태 설정
        sitter.setIsVerified(false);
        sitter.setBackgroundCheckCompleted(false);
        sitter.setInterviewCompleted(false);
    }
}