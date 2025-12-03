import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;
import 'dart:math';
import '../models/job_posting.dart';
import '../models/job_application.dart';
import '../models/sitter_profile.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // OAuth2 관련 설정
  final String _clientId = 'childcare-client';
  final String _redirectUri =
      kIsWeb
          ? 'http://localhost:3000/oauth/callback'
          : 'com.ida.childcare:/oauth/callback';

  // 플랫폼별 기본 URL 설정
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8085/api';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8085/api';
      } else {
        return 'http://localhost:8085/api';
      }
    }
  }

  // OAuth2 서버 URL
  String get _oauth2BaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8085';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8085';
      } else {
        return 'http://localhost:8085';
      }
    }
  }

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 요청 인터셉터 추가 (토큰 자동 첨부)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('요청: ${options.method} ${options.path}');
            print('헤더: ${options.headers}');
            if (options.data != null) {
              print('데이터: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('응답: ${response.statusCode}');
            print('응답 데이터: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('오류: ${error.message}');
            if (error.response != null) {
              print('오류 응답: ${error.response?.data}');
            }
          }
          // 401 에러 처리 (토큰 만료 등)
          if (error.response?.statusCode == 401) {
            // 토큰 삭제
            _secureStorage.delete(key: 'auth_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // _dio 객체에 접근할 수 있는 getter 메서드 추가
  Dio getDio() {
    return _dio;
  }

  // baseUrl 접근을 위한 getter 추가
  String getBaseUrl() {
    return _baseUrl;
  }

  // 로그인 메서드
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('로그인 오류: $e');
      }
      rethrow;
    }
  }

  // 소셜 로그인 URL 생성
  String getOAuth2AuthUrl(String provider) {
    final state = _generateRandomString(30); // CSRF 방지용 상태값
    _secureStorage.write(key: 'oauth2_state', value: state);

    // 제공자별 URL 생성
    switch (provider.toLowerCase()) {
      case 'google':
        return '$_oauth2BaseUrl/oauth2/authorization/google?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      case 'kakao':
        return '$_oauth2BaseUrl/oauth2/authorization/kakao?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      case 'naver':
        return '$_oauth2BaseUrl/oauth2/authorization/naver?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      default:
        throw Exception('지원하지 않는 소셜 로그인 제공자: $provider');
    }
  }

  // 소셜 로그인 처리
  Future<Map<String, dynamic>> processSocialLogin(
    String code,
    String provider,
  ) async {
    try {
      final response = await _dio.post(
        '/v1/auth/oauth2/callback/$provider',
        data: {'code': code, 'redirect_uri': _redirectUri},
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('소셜 로그인 처리 오류: $e');
      }
      rethrow;
    }
  }

  bool _isValidating = false;
  // 토큰 유효성 검증
  Future<bool> validateToken(String token) async {
    if (_isValidating) return true; // 중복 방지
    _isValidating = true;

    try {
      final response = await _dio.get('/v1/auth/validate-token');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      _isValidating = false;
    }
  }

  // 회원가입 메서드
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String phoneNumber,
    String userType,
  ) async {
    try {
      final response = await _dio.post(
        '/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'userType': userType, // PARENT 또는 SITTER
        },
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('회원가입 오류: $e');
      }
      rethrow;
    }
  }

  // 로그아웃 메서드
  Future<void> logout() async {
    try {
      await _dio.post('/v1/auth/logout');
    } catch (e) {
      if (kDebugMode) {
        print('로그아웃 API 오류: $e');
      }
    } finally {
      await _secureStorage.delete(key: 'auth_token');
    }
  }

  // CSRF 방지용 랜덤 문자열 생성
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ==================== 구인구직 게시판 API ====================

  // 게시글 목록 조회 (페이지네이션)
  Future<Map<String, dynamic>> fetchJobPostings({
    int page = 0,
    int size = 10,
    String? keyword,
    String? location,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (location != null && location.isNotEmpty) 'location': location,
      };

      String endpoint = '/job-postings';
      if (keyword != null && keyword.isNotEmpty) {
        endpoint = '/job-postings/search';
      } else if (location != null && location.isNotEmpty) {
        endpoint = '/job-postings/search/location';
      }

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      return {
        'content': (response.data['content'] as List)
            .map((json) => JobPosting.fromJson(json))
            .toList(),
        'totalPages': response.data['totalPages'],
        'totalElements': response.data['totalElements'],
        'number': response.data['number'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('게시글 목록 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 게시글 상세 조회
  Future<JobPosting> fetchJobPostingDetail(int id) async {
    try {
      final response = await _dio.get('/job-postings/$id');
      return JobPosting.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('게시글 상세 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 게시글 작성 (부모만 가능)
  Future<JobPosting> createJobPosting({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required double hourlyRate,
    required int requiredExperienceYears,
    required String jobType,
    required String ageOfChildren,
    required int numberOfChildren,
    String? payType,
  }) async {
    try {
      final response = await _dio.post(
        '/job-postings',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'hourlyRate': hourlyRate,
          'requiredExperienceYears': requiredExperienceYears,
          'jobType': jobType,
          'ageOfChildren': ageOfChildren,
          if (payType != null) 'payType': payType,
          'numberOfChildren': numberOfChildren,
        },
      );
      return JobPosting.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('게시글 작성 오류: $e');
      }
      rethrow;
    }
  }

  // 게시글 수정
  Future<JobPosting> updateJobPosting({
    required int id,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required double hourlyRate,
    required int requiredExperienceYears,
    required String jobType,
    String? payType,
    required String ageOfChildren,
    required int numberOfChildren,
  }) async {
    try {
      final response = await _dio.put(
        '/job-postings/$id',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'hourlyRate': hourlyRate,
          'requiredExperienceYears': requiredExperienceYears,
          'jobType': jobType,
          if (payType != null) 'payType': payType,
          'ageOfChildren': ageOfChildren,
          'numberOfChildren': numberOfChildren,
        },
      );
      return JobPosting.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('게시글 수정 오류: $e');
      }
      rethrow;
    }
  }

  // 게시글 삭제 (비활성화)
  Future<void> deleteJobPosting(int id) async {
    try {
      await _dio.delete('/job-postings/$id');
    } catch (e) {
      if (kDebugMode) {
        print('게시글 삭제 오류: $e');
      }
      rethrow;
    }
  }

  // 내 게시글 목록 조회
  Future<Map<String, dynamic>> getMyJobPostings({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/job-postings/my-postings',
        queryParameters: {'page': page, 'size': size},
      );

      return {
        'content': (response.data['content'] as List)
            .map((json) => JobPosting.fromJson(json))
            .toList(),
        'totalPages': response.data['totalPages'],
        'totalElements': response.data['totalElements'],
        'number': response.data['number'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('내 게시글 목록 조회 오류: $e');
      }
      rethrow;
    }
  }

  // ==================== 지원서 API ====================

  // 지원서 제출 (시터만 가능)
  Future<JobApplication> submitApplication({
    required int jobPostingId,
    required String coverLetter,
    required double proposedHourlyRate,
  }) async {
    try {
      final response = await _dio.post(
        '/job-applications',
        data: {
          'jobPostingId': jobPostingId,
          'coverLetter': coverLetter,
          'proposedHourlyRate': proposedHourlyRate,
        },
      );
      return JobApplication.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('지원서 제출 오류: $e');
      }
      rethrow;
    }
  }

  // 내 지원 내역 조회 (시터)
  Future<List<JobApplication>> getMyApplications() async {
    try {
      final response = await _dio.get('/job-applications/my-applications');
      return (response.data as List)
          .map((json) => JobApplication.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('내 지원 내역 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 특정 게시글의 지원 내역 조회 (부모)
  Future<List<JobApplication>> getApplicationsForPosting(int postingId) async {
    try {
      final response =
          await _dio.get('/job-applications/by-posting/$postingId');
      return (response.data as List)
          .map((json) => JobApplication.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('게시글 지원 내역 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 내 게시글에 대한 모든 지원 내역 조회 (부모)
  Future<List<JobApplication>> getAllApplicationsForParent() async {
    try {
      final response = await _dio.get('/job-applications/all-for-parent');
      return (response.data as List)
          .map((json) => JobApplication.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('내 게시글 지원 내역 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 지원 상태 업데이트 (부모: 승인/거절)
  Future<JobApplication> updateApplicationStatus({
    required int applicationId,
    required String status, // ACCEPTED, REJECTED
  }) async {
    try {
      final response = await _dio.patch(
        '/job-applications/$applicationId/status',
        data: {'status': status},
      );
      return JobApplication.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('지원 상태 업데이트 오류: $e');
      }
      rethrow;
    }
  }

  // 지원 철회 (시터)
  Future<void> withdrawApplication(int applicationId) async {
    try {
      await _dio.delete('/job-applications/$applicationId');
    } catch (e) {
      if (kDebugMode) {
        print('지원 철회 오류: $e');
      }
      rethrow;
    }
  }

  // ==================== 시터 프로필 API ====================

  // 시터 프로필 조회
  Future<SitterProfile> getSitterProfile(int sitterId) async {
    try {
      final response = await _dio.get('/sitter-profiles/$sitterId');
      return SitterProfile.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('시터 프로필 조회 오류: $e');
      }
      rethrow;
    }
  }

  // 시터 프로필 수정
  Future<SitterProfile> updateSitterProfile({
    required int sitterId,
    String? profileImageUrl,
    String? introduction,
    List<String>? availableServiceTypes,
    List<String>? preferredAgeGroups,
    List<String>? languagesSpoken,
    String? educationLevel,
  }) async {
    try {
      final response = await _dio.put(
        '/sitter-profiles/$sitterId',
        data: {
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (introduction != null) 'introduction': introduction,
          if (availableServiceTypes != null) 'availableServiceTypes': availableServiceTypes,
          if (preferredAgeGroups != null) 'preferredAgeGroups': preferredAgeGroups,
          if (languagesSpoken != null) 'languagesSpoken': languagesSpoken,
          if (educationLevel != null) 'educationLevel': educationLevel,
        },
      );
      return SitterProfile.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('시터 프로필 수정 오류: $e');
      }
      rethrow;
    }
  }

  // 시터 검색
  Future<Map<String, dynamic>> searchSitterProfiles({
    String? city,
    String? district,
    String? serviceType,
    String? ageGroup,
    double? minRating,
    int? minExperienceYears,
    double? maxHourlyRate,
    String? dayOfWeek,
    String sortBy = 'rating',
    String sortDirection = 'desc',
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (serviceType != null) 'serviceType': serviceType,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (minRating != null) 'minRating': minRating,
        if (minExperienceYears != null) 'minExperienceYears': minExperienceYears,
        if (maxHourlyRate != null) 'maxHourlyRate': maxHourlyRate,
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page,
        'size': size,
      };

      final response = await _dio.get('/sitter-profiles/search', queryParameters: queryParams);

      return {
        'content': (response.data['content'] as List).map((json) => SitterProfile.fromJson(json)).toList(),
        'totalPages': response.data['totalPages'],
        'totalElements': response.data['totalElements'],
        'number': response.data['number'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('시터 검색 오류: $e');
      }
      rethrow;
    }
  }

  // 자격증 추가
  Future<SitterCertification> addCertification({
    required int sitterId,
    required String certificationName,
    String? issuedBy,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? certificateImageUrl,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/sitter-profiles/$sitterId/certifications',
        data: {
          'certificationName': certificationName,
          if (issuedBy != null) 'issuedBy': issuedBy,
          if (issueDate != null) 'issueDate': issueDate.toIso8601String().split('T')[0],
          if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String().split('T')[0],
          if (certificateImageUrl != null) 'certificateImageUrl': certificateImageUrl,
          if (description != null) 'description': description,
        },
      );
      return SitterCertification.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('자격증 추가 오류: $e');
      }
      rethrow;
    }
  }

  // 경력 추가
  Future<SitterExperience> addExperience({
    required int sitterId,
    String? companyName,
    String? position,
    required DateTime startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? description,
    String? childrenAgeGroup,
    int? numberOfChildren,
  }) async {
    try {
      final response = await _dio.post(
        '/sitter-profiles/$sitterId/experiences',
        data: {
          if (companyName != null) 'companyName': companyName,
          if (position != null) 'position': position,
          'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'endDate': endDate.toIso8601String().split('T')[0],
          if (isCurrent != null) 'isCurrent': isCurrent,
          if (description != null) 'description': description,
          if (childrenAgeGroup != null) 'childrenAgeGroup': childrenAgeGroup,
          if (numberOfChildren != null) 'numberOfChildren': numberOfChildren,
        },
      );
      return SitterExperience.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('경력 추가 오류: $e');
      }
      rethrow;
    }
  }

  // 가능 시간대 추가
  Future<SitterAvailableTime> addAvailableTime({
    required int sitterId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    bool? isFlexible,
  }) async {
    try {
      final response = await _dio.post(
        '/sitter-profiles/$sitterId/available-times',
        data: {
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          if (isFlexible != null) 'isFlexible': isFlexible,
        },
      );
      return SitterAvailableTime.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('가능 시간대 추가 오류: $e');
      }
      rethrow;
    }
  }

  // 서비스 지역 추가
  Future<SitterServiceArea> addServiceArea({
    required int sitterId,
    required String city,
    String? district,
    String? detailedArea,
    int? travelDistanceKm,
    bool? isPrimary,
  }) async {
    try {
      final response = await _dio.post(
        '/sitter-profiles/$sitterId/service-areas',
        data: {
          'city': city,
          if (district != null) 'district': district,
          if (detailedArea != null) 'detailedArea': detailedArea,
          if (travelDistanceKm != null) 'travelDistanceKm': travelDistanceKm,
          if (isPrimary != null) 'isPrimary': isPrimary,
        },
      );
      return SitterServiceArea.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('서비스 지역 추가 오류: $e');
      }
      rethrow;
    }
  }
}
