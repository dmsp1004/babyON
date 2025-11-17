import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/job_posting.dart';
import '../providers/auth_provider.dart';

class JobPostingDetailScreen extends StatefulWidget {
  final int jobPostingId;

  const JobPostingDetailScreen({
    Key? key,
    required this.jobPostingId,
  }) : super(key: key);

  @override
  State<JobPostingDetailScreen> createState() =>
      _JobPostingDetailScreenState();
}

class _JobPostingDetailScreenState extends State<JobPostingDetailScreen> {
  JobPosting? _jobPosting;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadJobPostingDetails();
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
          _errorMessage = '게시글 정보를 불러올 수 없습니다';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteJobPosting() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _apiService.deleteJobPosting(widget.jobPostingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 삭제 성공 신호와 함께 돌아가기
      }
    } catch (e) {
      print('게시글 삭제 오류: $e');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 삭제에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToApply() {
    Navigator.pushNamed(
      context,
      '/create_job_application',
      arguments: widget.jobPostingId,
    );
  }

  void _navigateToEdit() {
    // TODO: 게시글 수정 화면으로 이동
    Navigator.pushNamed(
      context,
      '/edit_job_posting',
      arguments: _jobPosting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isParentOwner =
        authProvider.userId == _jobPosting?.parentId && authProvider.userType == 'PARENT';
    final isSitter = authProvider.userType == 'SITTER';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('게시글 상세'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _jobPosting == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('게시글 상세'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? '게시글을 불러올 수 없습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadJobPostingDetails,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 섹션
                Text(
                  _jobPosting!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // 기본 정보 - 부모 이름
                if (_jobPosting!.parentName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '부모: ${_jobPosting!.parentName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),

                // 주요 정보 카드
                _buildInfoCard(
                  context,
                  title: '주요 정보',
                  children: [
                    _buildInfoRow('직종', _jobPosting!.jobTypeKorean),
                    const Divider(),
                    _buildInfoRow('지역', _jobPosting!.location),
                    const Divider(),
                    _buildInfoRow('시급', _jobPosting!.hourlyRateFormatted),
                    const Divider(),
                    _buildInfoRow('기간', _jobPosting!.dateRangeFormatted),
                  ],
                ),
                const SizedBox(height: 16),

                // 아이 정보 카드
                _buildInfoCard(
                  context,
                  title: '아이 정보',
                  children: [
                    _buildInfoRow('나이', _jobPosting!.ageOfChildren),
                    const Divider(),
                    _buildInfoRow('인원', '${_jobPosting!.numberOfChildren}명'),
                    const Divider(),
                    _buildInfoRow(
                      '필요 경력',
                      '${_jobPosting!.requiredExperienceYears}년 이상',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 상세 설명 카드
                _buildInfoCard(
                  context,
                  title: '상세 설명',
                  children: [
                    Text(
                      _jobPosting!.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 지원자 정보 카드
                _buildInfoCard(
                  context,
                  title: '지원 현황',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '지원자 수',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_jobPosting!.applicationCount ?? 0}명',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 생성/수정 날짜
                if (_jobPosting!.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '작성일: ${_formatDate(_jobPosting!.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),

                if (_jobPosting!.updatedAt != null &&
                    _jobPosting!.updatedAt != _jobPosting!.createdAt)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '수정일: ${_formatDate(_jobPosting!.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),

                const SizedBox(height: 100), // 하단 버튼 공간 확보
              ],
            ),
          ),

          // 하단 버튼 영역
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: _buildActionButtons(context, isParentOwner, isSitter),
            ),
          ),
        ],
      ),
    );
  }

  // 정보 카드 빌드
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // 정보 행 빌드
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // 액션 버튼 빌드
  Widget _buildActionButtons(
    BuildContext context,
    bool isParentOwner,
    bool isSitter,
  ) {
    if (isParentOwner) {
      // 부모 - Edit, Delete 버튼
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isDeleting ? null : _deleteJobPosting,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isDeleting ? null : _navigateToEdit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('수정'),
            ),
          ),
        ],
      );
    } else if (isSitter) {
      // 시터 - Apply 버튼
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _navigateToApply,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.blue,
          ),
          child: const Text(
            '지원하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      // 로그인하지 않은 사용자 또는 다른 부모
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('로그인 후 지원 가능'),
        ),
      );
    }
  }

  // 날짜 포맷팅 함수
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
