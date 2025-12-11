import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'video_recording_screen.dart';
import 'video_preview_screen.dart';

/// AI 화상 이력서 등록 전체 플로우 화면
class AiVideoResumeFlowScreen extends StatefulWidget {
  const AiVideoResumeFlowScreen({Key? key}) : super(key: key);

  @override
  State<AiVideoResumeFlowScreen> createState() => _AiVideoResumeFlowScreenState();
}

class _AiVideoResumeFlowScreenState extends State<AiVideoResumeFlowScreen> {
  final ApiService _apiService = ApiService();

  int _currentStep = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  // 녹화된 비디오 파일 경로
  String? _introVideoPath;
  String? _answerVideoPath;

  // AI 질문 정보
  Map<String, dynamic>? _aiQuestion;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    try {
      final exists = await _apiService.aiVideoProfileExists();
      if (exists && mounted) {
        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('기존 화상 이력서가 있습니다'),
            content: const Text('기존 화상 이력서를 덮어쓰시겠습니까?\n새로 녹화하면 이전 이력서는 삭제됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('덮어쓰기', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldOverwrite != true && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // 존재 여부 확인 실패는 무시 (프로필이 없을 수 있음)
    }
  }

  Future<void> _loadRandomQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final question = await _apiService.getRandomAiQuestion();
      setState(() {
        _aiQuestion = question;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'AI 질문을 불러오는데 실패했습니다: $e';
      });
    }
  }

  void _onIntroVideoRecorded(String videoPath) {
    setState(() {
      _introVideoPath = videoPath;
    });
    _nextStep();
  }

  void _onAnswerVideoRecorded(String videoPath) {
    setState(() {
      _answerVideoPath = videoPath;
    });
    _nextStep();
  }

  void _nextStep() {
    if (_currentStep == 1 && _aiQuestion == null) {
      // AI 질문이 아직 없으면 로드
      _loadRandomQuestion();
    }
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _uploadVideos() async {
    if (_introVideoPath == null || _answerVideoPath == null || _aiQuestion == null) {
      setState(() {
        _errorMessage = '모든 영상을 녹화해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _apiService.uploadAiVideoProfile(
        introVideoPath: _introVideoPath!,
        answerVideoPath: _answerVideoPath!,
        aiQuestionId: _aiQuestion!['questionId'],
        status: 'ACTIVE',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 화상 이력서가 성공적으로 등록되었습니다')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '업로드에 실패했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 화상 이력서 등록'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildIntroRecordingStep();
      case 2:
        return _buildQuestionStep();
      case 3:
        return _buildAnswerRecordingStep();
      case 4:
        return _buildPreviewStep();
      default:
        return _buildWelcomeStep();
    }
  }

  // 환영 화면
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
            child: const Text(
              '시작하기',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 자유 소개 녹화 단계
  Widget _buildIntroRecordingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 100, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              '자유 소개 영상',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '자신을 자유롭게 소개해주세요.\n최대 120초까지 녹화할 수 있습니다.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final videoPath = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoRecordingScreen(
                      title: '자유 소개 영상',
                      description: '자신을 자유롭게 소개해주세요',
                      maxDurationSeconds: 120,
                    ),
                  ),
                );

                if (videoPath != null) {
                  _onIntroVideoRecorded(videoPath);
                }
              },
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label: const Text(
                '녹화 시작',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI 질문 표시 단계
  Widget _buildQuestionStep() {
    if (_aiQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 80, color: Colors.orange),
          const SizedBox(height: 32),
          const Text(
            'AI 질문',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              '답변 녹화 시작',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
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

  String _translateCategory(String? category) {
    const categories = {
      'EXPERIENCE': '경험',
      'PERSONALITY': '성격',
      'SITUATION': '상황 대처',
      'MOTIVATION': '동기',
      'CHILDCARE': '아이 돌봄',
    };
    return categories[category] ?? category ?? '';
  }

  String _translateDifficulty(String? difficulty) {
    const difficulties = {
      'EASY': '쉬움',
      'MEDIUM': '보통',
      'HARD': '어려움',
    };
    return difficulties[difficulty] ?? difficulty ?? '';
  }

  // AI 질문 답변 녹화 단계
  Widget _buildAnswerRecordingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 100, color: Colors.orange),
            const SizedBox(height: 32),
            const Text(
              'AI 질문 답변',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
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
                final videoPath = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoRecordingScreen(
                      title: 'AI 질문 답변',
                      description: _aiQuestion!['questionText'] ?? '',
                      maxDurationSeconds: _aiQuestion!['timeLimitSeconds'] ?? 120,
                    ),
                  ),
                );

                if (videoPath != null) {
                  _onAnswerVideoRecorded(videoPath);
                }
              },
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label: const Text(
                '녹화 시작',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 미리보기 및 업로드 단계
  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            '녹화 완료!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '모든 영상이 녹화되었습니다.\n업로드하시겠습니까?',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _buildVideoInfo('자유 소개 영상', _introVideoPath),
          const SizedBox(height: 16),
          _buildVideoInfo('AI 질문 답변 영상', _answerVideoPath),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _uploadVideos,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '업로드',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo(String title, String? path) {
    return InkWell(
      onTap: path != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPreviewScreen(
                    videoPath: path,
                    title: title,
                  ),
                ),
              );
            }
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline, color: Colors.blue, size: 32),
          ],
        ),
      ),
    );
  }
}
