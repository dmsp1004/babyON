import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// 비디오 녹화 화면
class VideoRecordingScreen extends StatefulWidget {
  final String title;
  final String description;
  final int maxDurationSeconds;

  const VideoRecordingScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.maxDurationSeconds,
  }) : super(key: key);

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // 녹화 타이머
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = '사용 가능한 카메라가 없습니다';
        });
        return;
      }

      // 전면 카메라 우선, 없으면 후면 카메라 사용
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '카메라 초기화 실패: $e';
      });
    }
  }

  Future<void> _toggleCameraDirection() async {
    if (_cameras == null || _cameras!.length < 2 || _isRecording) {
      return;
    }

    setState(() {
      _isInitialized = false;
    });

    final currentLensDirection = _cameraController!.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != currentLensDirection,
      orElse: () => _cameras!.first,
    );

    await _cameraController?.dispose();
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // 녹화 타이머 시작
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

        // 최대 시간 도달 시 자동 중지
        if (_recordingSeconds >= widget.maxDurationSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '녹화 시작 실패: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    _recordingTimer?.cancel();

    try {
      final videoFile = await _cameraController!.stopVideoRecording();

      // 앱 전용 디렉토리로 파일 이동
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedPath = '${appDir.path}/$fileName';

      await File(videoFile.path).copy(savedPath);

      if (mounted) {
        // 녹화된 비디오 경로를 반환하며 화면 닫기
        Navigator.pop(context, savedPath);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
        _errorMessage = '녹화 중지 실패: $e';
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // 카메라 프리뷰
        _buildCameraPreview(),

        // 상단 설명 오버레이
        _buildTopOverlay(),

        // 하단 컨트롤 오버레이
        _buildBottomOverlay(),

        // 녹화 중 타이머
        if (_isRecording) _buildRecordingTimer(),

        // 처리 중 오버레이
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final cameraRatio = _cameraController!.value.aspectRatio;

    return Center(
      child: AspectRatio(
        aspectRatio: cameraRatio,
        child: ClipRect(
          child: Transform.scale(
            scale: cameraRatio / deviceRatio,
            child: Center(
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '최대 ${widget.maxDurationSeconds}초',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 카메라 전환 버튼
              if (_cameras != null && _cameras!.length > 1)
                IconButton(
                  onPressed: _isRecording ? null : _toggleCameraDirection,
                  icon: const Icon(Icons.flip_camera_ios, size: 32),
                  color: Colors.white,
                  disabledColor: Colors.white.withOpacity(0.3),
                ),

              // 녹화 시작/중지 버튼
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isRecording ? Colors.red : Colors.transparent,
                  ),
                  child: _isRecording
                      ? const Icon(Icons.stop, color: Colors.white, size: 40)
                      : const Icon(Icons.fiber_manual_record,
                          color: Colors.red, size: 40),
                ),
              ),

              // 빈 공간 (대칭을 위해)
              if (_cameras != null && _cameras!.length > 1)
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingTimer() {
    final progress = _recordingSeconds / widget.maxDurationSeconds;
    final remainingSeconds = widget.maxDurationSeconds - _recordingSeconds;

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // 진행 바
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: remainingSeconds <= 10 ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 타이머 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / ${_formatDuration(widget.maxDurationSeconds)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              '비디오 저장 중...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '알 수 없는 오류',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
