import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/job_application.dart';
import '../providers/auth_provider.dart';

class JobApplicationListScreen extends StatefulWidget {
  final bool myApplications;
  final int? jobPostingId;

  const JobApplicationListScreen({
    Key? key,
    this.myApplications = false,
    this.jobPostingId,
  }) : super(key: key);

  @override
  State<JobApplicationListScreen> createState() =>
      _JobApplicationListScreenState();
}

class _JobApplicationListScreenState extends State<JobApplicationListScreen> {
  late ApiService _apiService;
  late Future<List<JobApplication>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadApplications();
  }

  void _loadApplications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _applicationsFuture = _loadApplicationsBasedOnContext(authProvider.userType);
  }

  Future<List<JobApplication>> _loadApplicationsBasedOnContext(
      String? userType) async {
    // If jobPostingId is provided, fetch applications for that specific posting
    if (widget.jobPostingId != null) {
      return _apiService.getApplicationsForPosting(widget.jobPostingId!);
    }

    // If myApplications flag is true, fetch only user's applications
    if (widget.myApplications) {
      return _apiService.getMyApplications();
    }

    // Otherwise, use the default logic based on user type
    if (userType == 'PARENT') {
      return _apiService.getAllApplicationsForParent();
    } else {
      return _apiService.getMyApplications();
    }
  }

  Future<void> _updateApplicationStatus(
    int applicationId,
    String newStatus,
  ) async {
    try {
      await _apiService.updateApplicationStatus(
        applicationId: applicationId,
        status: newStatus,
      );

      // 새로운 데이터 로드
      setState(() {
        _loadApplications();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지원 상태가 ${newStatus == 'ACCEPTED' ? '승인' : '거절'}되었습니다.'),
          backgroundColor: newStatus == 'ACCEPTED' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지원 상태 업데이트 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _withdrawApplication(int applicationId) async {
    try {
      await _apiService.withdrawApplication(applicationId);

      // 새로운 데이터 로드
      setState(() {
        _loadApplications();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('지원이 철회되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지원 철회 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApplicationDetails(JobApplication application) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(application.jobTitle ?? '공고 정보'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('지원일', application.createdAtFormatted),
                const SizedBox(height: 12),
                _buildDetailRow(
                  '제안 시급',
                  application.proposedHourlyRateFormatted,
                ),
                const SizedBox(height: 12),
                _buildDetailRow('상태', application.statusKorean),
                const SizedBox(height: 12),
                const Text(
                  '자기소개',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  application.coverLetter,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isParent = authProvider.userType == 'PARENT';

    // Determine the appropriate title based on the context
    String title;
    if (widget.jobPostingId != null) {
      title = '구인글 지원 목록';
    } else if (widget.myApplications) {
      title = '내 지원 목록';
    } else {
      title = isParent ? '받은 지원 목록' : '내 지원 목록';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: FutureBuilder<List<JobApplication>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          // 로딩 상태
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 에러 상태
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '지원 목록 로드 실패',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadApplications();
                      });
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 데이터가 없을 경우
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isParent ? Icons.inbox_outlined : Icons.assignment_outlined,
                    color: Colors.grey[400],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isParent ? '받은 지원이 없습니다' : '지원한 공고가 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isParent
                        ? '공고를 등록하면 시터로부터 지원을 받을 수 있습니다'
                        : '공고를 검색하여 지원해 보세요',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          // 데이터 표시
          final applications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadApplications();
              });
              await _applicationsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                return _buildApplicationCard(
                  application,
                  isParent,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(
    JobApplication application,
    bool isParent,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showApplicationDetails(application),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 제목과 상태 배지
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle ?? '공고 정보',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isParent)
                          Text(
                            '지원자: ${application.sitterEmail ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 상태 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(application.statusColor).withOpacity(0.2),
                      border: Border.all(
                        color: Color(application.statusColor),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      application.statusKorean,
                      style: TextStyle(
                        color: Color(application.statusColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 커버레터 미리보기
              Text(
                '자기소개',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                application.coverLetter,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // 제안 시급 및 지원일
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '제안 시급',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        application.proposedHourlyRateFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '지원일',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        application.createdAtFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 액션 버튼
              if (isParent)
                _buildParentActionButtons(application)
              else
                _buildSitterActionButtons(application),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentActionButtons(JobApplication application) {
    final isActionable =
        application.status == 'PENDING'; // PENDING 상태만 액션 가능

    return Row(
      children: [
        if (isActionable)
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateApplicationStatus(
                application.id!,
                'REJECTED',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('거절'),
            ),
          ),
        if (isActionable) const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: isActionable
                ? () => _updateApplicationStatus(
                      application.id!,
                      'ACCEPTED',
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              isActionable ? '승인' : '완료됨',
              style: TextStyle(
                color: isActionable ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSitterActionButtons(JobApplication application) {
    final isWithdrawable = application.status == 'PENDING';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showApplicationDetails(application),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('상세보기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: isWithdrawable
                ? () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('지원 철회'),
                          content: const Text('이 지원을 철회하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _withdrawApplication(application.id!);
                              },
                              child: const Text(
                                '철회',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: isWithdrawable ? Colors.red : Colors.grey[300]!,
              ),
            ),
            child: Text(
              isWithdrawable ? '철회' : '철회 불가',
              style: TextStyle(
                color: isWithdrawable ? Colors.red : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
