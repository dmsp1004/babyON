import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'video_preview_screen.dart';
import 'video_recording_screen.dart';

// ── 업로드 상태 ──────────────────────────────────────────
enum _UploadState { idle, uploading, rollingBack, failed, success }

// 에러 종류별 메시지 매핑
enum _UploadError { network, timeout, fileNotFound, serverError, clientError, unknown }

extension _UploadErrorExt on _UploadError {
  String get title {
    switch (this) {
      case _UploadError.network:      return '네트워크 연결 오류';
      case _UploadError.timeout:      return '업로드 시간 초과';
      case _UploadError.fileNotFound: return '영상 파일 오류';
      case _UploadError.serverError:  return '서버 오류';
      case _UploadError.clientError:  return '요청 오류';
      case _UploadError.unknown:      return '업로드 실패';
    }
  }

  String get description {
    switch (this) {
      case _UploadError.network:
        return 'Wi-Fi 또는 모바일 데이터 연결을 확인한 뒤 다시 시도해주세요.';
      case _UploadError.timeout:
        return '영상 파일이 크거나 네트워크가 느립니다. 더 빠른 연결로 재시도해주세요.';
      case _UploadError.fileNotFound:
        return '녹화된 영상 파일을 찾을 수 없습니다. 영상을 다시 녹화해주세요.';
      case _UploadError.serverError:
        return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case _UploadError.clientError:
        return '업로드 요청이 올바르지 않습니다. 영상을 다시 녹화한 후 시도해주세요.';
      case _UploadError.unknown:
        return '알 수 없는 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  IconData get icon {
    switch (this) {
      case _UploadError.network:      return Icons.wifi_off;
      case _UploadError.timeout:      return Icons.timer_off;
      case _UploadError.fileNotFound: return Icons.videocam_off;
      case _UploadError.serverError:  return Icons.cloud_off;
      case _UploadError.clientError:  return Icons.error_outline;
      case _UploadError.unknown:      return Icons.warning_amber;
    }
  }

  // 파일이 손상된 경우에는 재시도 대신 재녹화 유도
  bool get canRetryWithSameFiles =>
      this != _UploadError.fileNotFound && this != _UploadError.clientError;
}

/// AI 화상 이력서 등록 전체 플로우 화면
class AiVideoResumeFlowScreen extends StatefulWidget {
  const AiVideoResumeFlowScreen({Key? key}) : super(key: key);

  @override
  State<AiVideoResumeFlowScreen> createState() => _AiVideoResumeFlowScreenState();
}

class _AiVideoResumeFlowScreenState extends State<AiVideoResumeFlowScreen> {
  final ApiService _apiService = ApiService();

  int _currentStep = 0;
  _UploadState _uploadState = _UploadState.idle;
  _UploadError? _uploadError;
  String _uploadErrorDetail = '';

  String? _introVideoPath;
  String? _answerVideoPath;
  Map<String, dynamic>? _aiQuestion;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  // ── 기존 프로필 덮어쓰기 확인 ────────────────────────────────
  Future<void> _checkExistingProfile() async {
    try {
      final exists = await _apiService.aiVideoProfileExists();
      if (!exists || !mounted) return;

      final shouldOverwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('기존 화상 이력서가 있습니다'),
          content: const Text(
            '기존 화상 이력서를 덮어쓰시겠습니까?\n새로 녹화하면 이전 이력서는 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('덮어쓰기',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (shouldOverwrite != true && mounted) Navigator.pop(context);
    } catch (_) {
      // 존재 여부 확인 실패는 진행
    }
  }

  // ── 질문 로드 ────────────────────────────────────────────────
  Future<void> _loadRandomQuestion() async {
    setState(() => _uploadState = _UploadState.uploading);
    try {
      final question = await _apiService.getRandomAiQuestion();
      if (mounted) {
        setState(() {
          _aiQuestion = question;
          _uploadState = _UploadState.idle;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadState = _UploadState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 질문을 불러오지 못했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  // ── 단계 이동 ────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 1 && _aiQuestion == null) _loadRandomQuestion();
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_uploadState == _UploadState.uploading) return; // 업로드 중 뒤로 막기
    setState(() {
      _currentStep--;
      _uploadState = _UploadState.idle;
      _uploadError = null;
    });
  }

  void _onIntroVideoRecorded(String path) {
    setState(() => _introVideoPath = path);
    _nextStep();
  }

  void _onAnswerVideoRecorded(String path) {
    setState(() => _answerVideoPath = path);
    _nextStep();
  }

  // ── 업로드 ──────────────────────────────────────────────────
  Future<void> _uploadVideos() async {
    // 파일 존재 여부 사전 검증
    if (!_validateFiles()) return;

    setState(() {
      _uploadState = _UploadState.uploading;
      _uploadError = null;
      _uploadErrorDetail = '';
    });

    try {
      await _apiService.uploadAiVideoProfile(
        introVideoPath: _introVideoPath!,
        answerVideoPath: _answerVideoPath!,
        aiQuestionId: _aiQuestion!['questionId'],
        status: 'ACTIVE',
      );

      if (!mounted) return;
      setState(() => _uploadState = _UploadState.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 화상 이력서가 성공적으로 등록되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final kind = _classifyError(e);
      setState(() {
        _uploadState = _UploadState.failed;
        _uploadError = kind;
        _uploadErrorDetail = _extractDetail(e);
      });
      // 서버에 부분 저장된 데이터가 있을 수 있으면 롤백 시도
      if (kind == _UploadError.serverError || kind == _UploadError.unknown) {
        _rollback();
      }
    }
  }

  bool _validateFiles() {
    if (_introVideoPath == null || !File(_introVideoPath!).existsSync()) {
      _showFileError('자유 소개 영상 파일을 찾을 수 없습니다. 다시 녹화해주세요.');
      setState(() {
        _introVideoPath = null;
        _currentStep = 1; // 인트로 녹화 단계로 복귀
      });
      return false;
    }
    if (_answerVideoPath == null || !File(_answerVideoPath!).existsSync()) {
      _showFileError('AI 질문 답변 영상 파일을 찾을 수 없습니다. 다시 녹화해주세요.');
      setState(() {
        _answerVideoPath = null;
        _currentStep = 3; // 답변 녹화 단계로 복귀
      });
      return false;
    }
    return true;
  }

  void _showFileError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _rollback() async {
    if (!mounted) return;
    setState(() => _uploadState = _UploadState.rollingBack);
    try {
      await _apiService.rollbackAiVideoProfile();
    } catch (_) {
      // 롤백 실패는 로그만 남기고 사용자에게는 별도 안내 없음
    } finally {
      if (mounted) setState(() => _uploadState = _UploadState.failed);
    }
  }

  // ── 재시도 ──────────────────────────────────────────────────
  void _retry() {
    final canRetry = _uploadError?.canRetryWithSameFiles ?? false;
    if (canRetry) {
      _uploadVideos();
    } else {
      // 파일 문제 → 해당 단계로 돌아가 재녹화
      setState(() {
        _introVideoPath = null;
        _answerVideoPath = null;
        _uploadState = _UploadState.idle;
        _uploadError = null;
        _currentStep = 1;
      });
    }
  }

  // ── 오류 분류 ────────────────────────────────────────────────
  _UploadError _classifyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return _UploadError.network;
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return _UploadError.timeout;
        default:
          final status = e.response?.statusCode;
          if (status == null) return _UploadError.network;
          if (status >= 500) return _UploadError.serverError;
          if (status >= 400) return _UploadError.clientError;
          return _UploadError.unknown;
      }
    }
    if (e is FileSystemException) return _UploadError.fileNotFound;
    return _UploadError.unknown;
  }

  String _extractDetail(Object e) {
    if (e is DioException) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] as String?
          : null;
      return msg ?? e.message ?? '';
    }
    return e.toString();
  }

  // ── 빌드 ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 화상 이력서 등록'),
        leading: (_currentStep > 0 && _uploadState != _UploadState.uploading)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Stack(
        children: [
          _buildCurrentStep(),
          if (_uploadState == _UploadState.uploading ||
              _uploadState == _UploadState.rollingBack)
            _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildWelcomeStep();
      case 1: return _buildIntroRecordingStep();
      case 2: return _buildQuestionStep();
      case 3: return _buildAnswerRecordingStep();
      case 4: return _buildPreviewStep();
      default: return _buildWelcomeStep();
    }
  }

  // ── 업로드 진행 오버레이 ─────────────────────────────────────
  Widget _buildUploadOverlay() {
    final isRollingBack = _uploadState == _UploadState.rollingBack;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                isRollingBack ? '업로드 취소 중…' : '업로드 중…',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isRollingBack
                    ? '서버에 저장된 데이터를 정리하고 있습니다.'
                    : '두 영상을 서버에 전송하고 있습니다.\n화면을 닫지 마세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 에러 배너 (미리보기 단계 상단) ──────────────────────────
  Widget _buildErrorBanner() {
    final err = _uploadError;
    if (_uploadState != _UploadState.failed || err == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(err.icon, color: Colors.red.shade700, size: 22),
              const SizedBox(width: 10),
              Text(
                err.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            err.description,
            style: TextStyle(fontSize: 13, color: Colors.red.shade700),
          ),
          if (_uploadErrorDetail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _uploadErrorDetail,
              style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retry,
                  icon: Icon(
                    err.canRetryWithSameFiles
                        ? Icons.refresh
                        : Icons.videocam,
                    size: 18,
                  ),
                  label: Text(
                    err.canRetryWithSameFiles ? '다시 시도' : '다시 녹화',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 개별 단계 위젯들 ─────────────────────────────────────────

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.video_camera_front, size: 100, color: Colors.blue),
          const SizedBox(height: 32),
          const Text(
            'AI 화상 이력서 등록',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'AI 화상 이력서는 두 부분으로 구성됩니다:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.person,
            title: '1. 자유 소개 (최대 120초)',
            description: '자신을 자유롭게 소개하는 영상을 녹화합니다.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.question_answer,
            title: '2. AI 질문 답변 (최대 120초)',
            description: 'AI가 제시하는 질문에 답변하는 영상을 녹화합니다.',
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
            ),
            child: const Text('시작하기',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroRecordingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 100, color: Colors.blue),
            const SizedBox(height: 32),
            const Text('자유 소개 영상',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              '자신을 자유롭게 소개해주세요.\n최대 120초까지 녹화할 수 있습니다.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final path = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoRecordingScreen(
                      title: '자유 소개 영상',
                      description: '자신을 자유롭게 소개해주세요',
                      maxDurationSeconds: 120,
                    ),
                  ),
                );
                if (path != null) _onIntroVideoRecorded(path);
              },
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label:
                  const Text('녹화 시작', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 32),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStep() {
    if (_aiQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 80, color: Colors.orange),
          const SizedBox(height: 32),
          const Text('AI 질문',
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Text(
                  _aiQuestion!['questionText'] ?? '',
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChip(
                      '카테고리: ${_translateCategory(_aiQuestion!['questionCategory'])}',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      '난이도: ${_translateDifficulty(_aiQuestion!['difficultyLevel'])}',
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildChip(
                    '시간 제한: ${_aiQuestion!['timeLimitSeconds']}초',
                    Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 32),
              backgroundColor: Colors.orange,
            ),
            child: const Text('답변 녹화 시작',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  String _translateCategory(String? c) {
    const m = {
      'EXPERIENCE': '경험',
      'PERSONALITY': '성격',
      'SITUATION': '상황 대처',
      'MOTIVATION': '동기',
      'CHILDCARE': '아이 돌봄',
    };
    return m[c] ?? c ?? '';
  }

  String _translateDifficulty(String? d) {
    const m = {'EASY': '쉬움', 'MEDIUM': '보통', 'HARD': '어려움'};
    return m[d] ?? d ?? '';
  }

  Widget _buildAnswerRecordingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 100, color: Colors.orange),
            const SizedBox(height: 32),
            const Text('AI 질문 답변',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                _aiQuestion!['questionText'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final path = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoRecordingScreen(
                      title: 'AI 질문 답변',
                      description: _aiQuestion!['questionText'] ?? '',
                      maxDurationSeconds:
                          _aiQuestion!['timeLimitSeconds'] ?? 120,
                    ),
                  ),
                );
                if (path != null) _onAnswerVideoRecorded(path);
              },
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label:
                  const Text('녹화 시작', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 32),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStep() {
    final isUploading = _uploadState == _UploadState.uploading ||
        _uploadState == _UploadState.rollingBack;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('녹화 완료!',
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '모든 영상이 녹화되었습니다.\n업로드하시겠습니까?',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 에러 배너
          _buildErrorBanner(),

          _buildVideoInfo('자유 소개 영상', _introVideoPath),
          const SizedBox(height: 16),
          _buildVideoInfo('AI 질문 답변 영상', _answerVideoPath),

          const Spacer(),

          // 업로드 버튼 (실패 후 재시도는 에러 배너 버튼에서 담당)
          if (_uploadState != _UploadState.failed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : _uploadVideos,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text('업로드',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo(String title, String? path) {
    return InkWell(
      onTap: path != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VideoPreviewScreen(videoPath: path, title: title),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    path ?? '',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline,
                color: Colors.blue, size: 32),
          ],
        ),
      ),
    );
  }
}
