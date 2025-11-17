import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/job_posting.dart';

class CreateJobApplicationScreen extends StatefulWidget {
  final int jobPostingId;

  const CreateJobApplicationScreen({
    Key? key,
    required this.jobPostingId,
  }) : super(key: key);

  @override
  State<CreateJobApplicationScreen> createState() =>
      _CreateJobApplicationScreenState();
}

class _CreateJobApplicationScreenState
    extends State<CreateJobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _proposedRateController = TextEditingController();

  JobPosting? _jobPosting;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadJobPostingDetails();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _proposedRateController.dispose();
    super.dispose();
  }

  Future<void> _loadJobPostingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final jobPosting =
          await _apiService.fetchJobPostingDetail(widget.jobPostingId);

      if (mounted) {
        setState(() {
          _jobPosting = jobPosting;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('게시글 상세 조회 오류: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '게시글 정보를 불러올 수 없습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final coverLetter = _coverLetterController.text.trim();
      final proposedRate =
          double.parse(_proposedRateController.text.replaceAll(',', '').trim());

      await _apiService.submitApplication(
        jobPostingId: widget.jobPostingId,
        coverLetter: coverLetter,
        proposedHourlyRate: proposedRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('지원서가 성공적으로 제출되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 지원 완료 후 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('지원서 제출 오류: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '지원서 제출 중 오류가 발생했습니다: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? '지원서 제출 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일자리 지원'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _jobPosting == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? '게시글을 찾을 수 없습니다',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('뒤로가기'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 게시글 정보 카드
                      _buildJobPostingCard(),
                      const SizedBox(height: 24),

                      // 지원 폼
                      _buildApplicationForm(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJobPostingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              _jobPosting!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 기본 정보
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _jobPosting!.location,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 일자리 유형 및 시급
            Row(
              children: [
                Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _jobPosting!.jobTypeKorean,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money,
                    size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  _jobPosting!.hourlyRateFormatted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 기간
            if (_jobPosting!.startDate != null &&
                _jobPosting!.endDate != null)
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _jobPosting!.dateRangeFormatted,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 폼 제목
          const Text(
            '지원 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 자기소개 필드
          TextFormField(
            controller: _coverLetterController,
            decoration: InputDecoration(
              labelText: '자기소개 / 커버레터',
              labelStyle: const TextStyle(color: Colors.black54),
              hintText: '왜 이 일자리에 지원하는지, 자신의 경험을 설명해주세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.description, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            minLines: 5,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '자기소개를 입력해주세요';
              }
              if (value.trim().length < 10) {
                return '자기소개는 최소 10자 이상이어야 합니다';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 제안 시급 필드
          TextFormField(
            controller: _proposedRateController,
            decoration: InputDecoration(
              labelText: '제안 시급 (원/시간)',
              labelStyle: const TextStyle(color: Colors.black54),
              hintText: '예: 10,000',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
              suffixText: '원/시간',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final number = int.tryParse(newValue.text);
                if (number == null) return oldValue;
                final formatted = NumberFormat('#,###').format(number);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제안 시급을 입력해주세요';
              }
              try {
                final rate = double.parse(value.replaceAll(',', '').trim());
                if (rate <= 0) {
                  return '시급은 0보다 커야 합니다';
                }
                if (rate < 5000) {
                  return '시급은 5,000원 이상이어야 합니다';
                }
                if (rate > 100000) {
                  return '시급이 너무 높습니다 (최대 100,000원)';
                }
                return null;
              } catch (e) {
                return '유효한 숫자를 입력해주세요';
              }
            },
          ),
          const SizedBox(height: 24),

          // 원본 시급 정보 표시
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '공고 시급: ${_jobPosting!.hourlyRateFormatted}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '지원하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          // 취소 버튼
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
