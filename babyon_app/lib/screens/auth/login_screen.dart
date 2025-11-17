import 'package:flutter/material.dart';
import 'package:babyon_app/screens/job_posting_list_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) 'dart:ui' show window;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  StreamSubscription? _linkSubscription;
  bool _processingLogin = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _initDeepLinkListener() async {
    if (kIsWeb) {
      try {
        final href = Uri.base.toString();
        print('현재 웹 URL: $href');
        final currentUri = Uri.parse(href);

        if (currentUri.path.contains('/oauth/callback') ||
            currentUri.queryParameters.containsKey('code')) {
          print('웹 환경에서 OAuth 콜백 감지: ${currentUri.toString()}');
          _handleIncomingLink(currentUri);
        }
      } catch (e) {
        print('웹 딥링크 처리 오류: $e');
      }
      return;
    }

    try {
      _linkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null && mounted) {
            print('모바일 딥링크 수신: $uri');
            _handleIncomingLink(uri);
          }
        },
        onError: (err) {
          print('딥링크 에러: $err');
        },
      );

      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        print('초기 딥링크 수신: $initialUri');
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('초기 딥링크 에러: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    print('딥링크 처리 시작: $uri');

    if (_processingLogin) {
      print('이미 로그인 처리 중입니다.');
      return;
    }
    _processingLogin = true;

    if (uri.path.contains('/oauth/callback') ||
        uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      final provider =
          uri.queryParameters['provider'] ?? _getProviderFromPath(uri.path);

      if (code != null && provider != null) {
        print('OAuth 콜백 감지 - 코드: $code, 제공자: $provider');
        _processSocialLogin(code, provider);
      } else {
        print('OAuth 콜백 파라미터 누락 - 코드: $code, 제공자: $provider');
        _processingLogin = false;
      }
    } else {
      print('OAuth 콜백 URL이 아닙니다: $uri');
      _processingLogin = false;
    }
  }

  String? _getProviderFromPath(String path) {
    print('URL 경로에서 제공자 추출 시도: $path');
    final parts = path.split('/');
    for (final provider in ['google', 'kakao', 'naver']) {
      if (parts.contains(provider)) {
        print('제공자 감지: $provider');
        return provider;
      }
    }

    if (path.contains('google')) return 'google';
    if (path.contains('kakao')) return 'kakao';
    if (path.contains('naver')) return 'naver';

    print('제공자를 찾을 수 없습니다');
    return null;
  }

  Future<void> _processSocialLogin(String code, String provider) async {
    print('소셜 로그인 처리 시작 - 코드: $code, 제공자: $provider');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.handleSocialLoginCallback(
        code,
        provider,
      );

      if (success && mounted) {
        print('소셜 로그인 성공: ${authProvider.userType}');
        _navigateBasedOnUserType(authProvider.userType ?? 'PARENT');
      } else if (mounted) {
        print('소셜 로그인 실패: ${authProvider.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? '소셜 로그인 처리 실패')),
        );
      }
    } catch (e) {
      print('소셜 로그인 처리 예외: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 처리 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingLogin = false;
        });
      } else {
        _processingLogin = false;
      }
      print('소셜 로그인 처리 완료');
    }
  }

  @override
  void dispose() {
    print('LoginScreen dispose');
    _emailController.dispose();
    _passwordController.dispose();
    _linkSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateBasedOnUserType(String userType) {
    if (!mounted) return;
    print('유형에 따른 화면 이동 시작: $userType');

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/job_postings',
      (route) => false,
    );

    print('사용자 유형: $userType - 구인구직 게시판으로 이동 완료');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF8B7FFF),
              Color(0xFFFF6584),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 로고 섹션
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.child_care,
                                  size: 60,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'babyON',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '아이 돌봄 매칭 플랫폼',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 로그인 폼 카드
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              // 이메일 입력
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: '이메일',
                                  hintText: 'example@email.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이메일을 입력해주세요';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return '유효한 이메일 주소를 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 비밀번호 입력
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: '비밀번호',
                                  hintText: '6자 이상 입력',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '비밀번호를 입력해주세요';
                                  }
                                  if (value.length < 6) {
                                    return '비밀번호는 최소 6자 이상이어야 합니다';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // 비밀번호 찾기
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot_password');
                                  },
                                  child: const Text(
                                    '비밀번호 찾기',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 로그인 버튼
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF8B7FFF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading || _processingLogin
                                      ? null
                                      : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            _processingLogin = true;
                                          });
                                          try {
                                            print('이메일 로그인 시도: ${_emailController.text.trim()}');
                                            final success = await authProvider.login(
                                              _emailController.text.trim(),
                                              _passwordController.text,
                                            );

                                            if (success && mounted) {
                                              print('로그인 성공: ${authProvider.userType}');
                                              _navigateBasedOnUserType(
                                                authProvider.userType ?? 'PARENT',
                                              );
                                            } else if (mounted) {
                                              print('로그인 실패: ${authProvider.errorMessage}');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    authProvider.errorMessage ?? '로그인에 실패했습니다.',
                                                  ),
                                                  backgroundColor: Colors.red.shade400,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print('로그인 예외 발생: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('로그인 처리 중 오류: $e')),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _processingLogin = false;
                                              });
                                            } else {
                                              _processingLogin = false;
                                            }
                                          }
                                        }
                                      },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: authProvider.isLoading || _processingLogin
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          '로그인',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // 구분선
                              Row(
                                children: [
                                  const Expanded(child: Divider(thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '소셜 로그인',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 소셜 로그인 버튼들
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialLoginButton(
                                    icon: Icons.chat_bubble,
                                    color: const Color(0xFFFEE500),
                                    label: '카카오',
                                    provider: 'kakao',
                                    isLoading: authProvider.isLoading || _processingLogin,
                                    iconColor: Colors.black87,
                                  ),
                                  _buildSocialLoginButton(
                                    icon: Icons.edit,
                                    color: const Color(0xFF03C75A),
                                    label: '네이버',
                                    provider: 'naver',
                                    isLoading: authProvider.isLoading || _processingLogin,
                                    iconColor: Colors.white,
                                  ),
                                  _buildSocialLoginButton(
                                    icon: Icons.g_mobiledata,
                                    color: Colors.white,
                                    label: '구글',
                                    provider: 'google',
                                    isLoading: authProvider.isLoading || _processingLogin,
                                    iconColor: const Color(0xFF6C63FF),
                                    hasBorder: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 회원가입 안내
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '계정이 없으신가요?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required String label,
    required String provider,
    required bool isLoading,
    required Color iconColor,
    bool hasBorder = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () async {
                    if (_processingLogin) return;

                    setState(() {
                      _processingLogin = true;
                    });

                    try {
                      print('소셜 로그인 시도: $provider');
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.socialLogin(provider);
                    } catch (e) {
                      print('소셜 로그인 요청 오류: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('소셜 로그인 오류: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _processingLogin = false;
                        });
                      } else {
                        _processingLogin = false;
                      }
                    }
                  },
              customBorder: const CircleBorder(),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasBorder
                      ? Border.all(color: Colors.grey.shade300, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
