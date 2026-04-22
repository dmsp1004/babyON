import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/job_application.dart';
import '../models/sitter_profile.dart';
import '../providers/auth_provider.dart';
import 'sitter_profile_detail_screen.dart';

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
  // 카드별 프로필 캐시 (sitterId → SitterProfile)
  final Map<int, SitterProfile?> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadApplications();
  }

  void _loadApplications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _applicationsFuture =
        _loadApplicationsBasedOnContext(authProvider.userType);
  }

  Future<List<JobApplication>> _loadApplicationsBasedOnContext(
      String? userType) async {
    if (widget.jobPostingId != null) {
      return _apiService.getApplicationsForPosting(widget.jobPostingId!);
    }
    if (widget.myApplications) {
      return _apiService.getMyApplications();
    }
    if (userType == 'PARENT') {
      return _apiService.getAllApplicationsForParent();
    } else {
      return _apiService.getMyApplications();
    }
  }

  Future<SitterProfile?> _fetchProfile(int sitterId) async {
    if (_profileCache.containsKey(sitterId)) return _profileCache[sitterId];
    try {
      final profile = await _apiService.getSitterProfile(sitterId);
      _profileCache[sitterId] = profile;
      return profile;
    } catch (_) {
      _profileCache[sitterId] = null;
      return null;
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
      setState(() {
        _loadApplications();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지원 상태가 ${newStatus == 'ACCEPTED' ? '승인' : '거절'}되었습니다.'),
          backgroundColor: newStatus == 'ACCEPTED' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
      setState(() {
        _loadApplications();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('지원이 철회되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
                    '제안 시급', application.proposedHourlyRateFormatted),
                const SizedBox(height: 12),
                _buildDetailRow('상태', application.statusKorean),
                const SizedBox(height: 12),
                const Text(
                  '자기소개',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(application.coverLetter,
                    style: const TextStyle(fontSize: 13)),
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
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
          child:
              Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isParent = authProvider.userType == 'PARENT';

    String title;
    if (widget.jobPostingId != null) {
      title = '구인글 지원 목록';
    } else if (widget.myApplications) {
      title = '내 지원 목록';
    } else {
      title = isParent ? '받은 지원 목록' : '내 지원 목록';
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: FutureBuilder<List<JobApplication>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('지원 목록 로드 실패',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(_loadApplications),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isParent
                        ? Icons.inbox_outlined
                        : Icons.assignment_outlined,
                    color: Colors.grey[400],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isParent
                        ? '받은 지원이 없습니다'
                        : '지원한 공고가 없습니다',
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

          final applications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadApplications);
              await _applicationsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                return isParent
                    ? _buildParentCard(application)
                    : _buildSitterCard(application);
              },
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PARENT: 시터 프로필 로드 후 강화된 카드 표시
  // ──────────────────────────────────────────────
  Widget _buildParentCard(JobApplication application) {
    final sitterId = application.sitterId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: sitterId != null
          ? FutureBuilder<SitterProfile?>(
              future: _fetchProfile(sitterId),
              builder: (context, snap) {
                final profile =
                    snap.connectionState == ConnectionState.done
                        ? snap.data
                        : null;
                return _buildParentCardContent(
                    application, profile, snap.connectionState);
              },
            )
          : _buildParentCardContent(application, null,
              ConnectionState.done),
    );
  }

  Widget _buildParentCardContent(
    JobApplication application,
    SitterProfile? profile,
    ConnectionState state,
  ) {
    final name = profile?.sitterEmail?.split('@').first ??
        application.sitterEmail?.split('@').first ??
        '지원자';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: application.sitterId != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SitterProfileDetailScreen(
                    sitterId: application.sitterId!,
                    sitterEmail: application.sitterEmail,
                  ),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아바타 + 이름/뱃지 + 상태
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarWidget(profile, initials, state),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile?.isVerified == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified,
                                  color: Colors.blue, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 경력·자격증·평점 요약
                      _buildProfileSummaryRow(profile, state),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(application),
              ],
            ),

            // 공고 제목
            if (application.jobTitle != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline,
                        size: 13, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        application.jobTitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 자기소개 미리보기
            const SizedBox(height: 10),
            Text(
              application.coverLetter,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4F5D75)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // 자격증 태그 (프로필 로드 완료 시)
            if (profile?.certifications != null &&
                profile!.certifications!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: profile.certifications!
                    .take(3)
                    .map((c) => _buildMiniChip(
                          c.certificationName,
                          Icons.card_membership,
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            // 하단: 시급 + 지원일 + 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMeta(
                  '제안 시급',
                  application.proposedHourlyRateFormatted,
                ),
                _buildMeta('지원일', application.createdAtFormatted),
              ],
            ),
            const SizedBox(height: 12),
            _buildParentActionButtons(application),

            // 상세보기 힌트
            const SizedBox(height: 6),
            Center(
              child: Text(
                '카드를 탭하면 시터 프로필을 볼 수 있습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(
      SitterProfile? profile, String initials, ConnectionState state) {
    if (state == ConnectionState.waiting) {
      return const SizedBox(
        width: 52,
        height: 52,
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (profile?.profileImageUrl != null &&
        profile!.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(profile.profileImageUrl!),
        backgroundColor: const Color(0xFFECEAFF),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF6C63FF),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
    );
  }

  Widget _buildProfileSummaryRow(
      SitterProfile? profile, ConnectionState state) {
    if (state == ConnectionState.waiting) {
      return Container(
        height: 14,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    final parts = <String>[];
    if (profile?.experienceYears != null) {
      parts.add('경력 ${profile!.experienceYears}년');
    }
    if (profile?.certifications != null) {
      parts.add('자격증 ${profile!.certifications!.length}개');
    }
    if (profile?.rating != null) {
      parts.add('★ ${profile!.rating!.toStringAsFixed(1)}');
    }
    if (parts.isEmpty) {
      parts.add(profile?.sitterEmail ?? '');
    }
    return Text(
      parts.join('  ·  '),
      style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
    );
  }

  Widget _buildStatusBadge(JobApplication application) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color(application.statusColor).withOpacity(0.12),
        border: Border.all(color: Color(application.statusColor)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        application.statusKorean,
        style: TextStyle(
          color: Color(application.statusColor),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF6C63FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // SITTER: 기존 카드 (내 지원 목록)
  // ──────────────────────────────────────────────
  Widget _buildSitterCard(JobApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showApplicationDetails(application),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      application.jobTitle ?? '공고 정보',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(application),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                application.coverLetter,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4F5D75)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMeta(
                      '제안 시급', application.proposedHourlyRateFormatted),
                  _buildMeta('지원일', application.createdAtFormatted),
                ],
              ),
              const SizedBox(height: 12),
              _buildSitterActionButtons(application),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentActionButtons(JobApplication application) {
    final isActionable = application.status == 'PENDING';
    return Row(
      children: [
        if (isActionable)
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateApplicationStatus(
                  application.id!, 'REJECTED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('거절'),
            ),
          ),
        if (isActionable) const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: isActionable
                ? () => _updateApplicationStatus(
                    application.id!, 'ACCEPTED')
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('상세보기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: isWithdrawable
                ? () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('지원 철회'),
                        content: const Text('이 지원을 철회하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _withdrawApplication(application.id!);
                            },
                            child: const Text('철회',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    )
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color:
                    isWithdrawable ? Colors.red : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isWithdrawable ? '철회' : '철회 불가',
              style: TextStyle(
                color:
                    isWithdrawable ? Colors.red : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
