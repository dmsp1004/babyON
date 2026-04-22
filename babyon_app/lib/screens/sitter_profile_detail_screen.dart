import 'package:flutter/material.dart';
import '../models/sitter_profile.dart';
import '../services/api_service.dart';

class SitterProfileDetailScreen extends StatefulWidget {
  final int sitterId;
  final String? sitterEmail;

  const SitterProfileDetailScreen({
    Key? key,
    required this.sitterId,
    this.sitterEmail,
  }) : super(key: key);

  @override
  State<SitterProfileDetailScreen> createState() =>
      _SitterProfileDetailScreenState();
}

class _SitterProfileDetailScreenState
    extends State<SitterProfileDetailScreen> {
  late Future<SitterProfile> _profileFuture;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getSitterProfile(widget.sitterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<SitterProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError();
          }
          return _buildProfile(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(title: const Text('시터 프로필')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('프로필을 불러올 수 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {
                _profileFuture =
                    _apiService.getSitterProfile(widget.sitterId);
              }),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(SitterProfile profile) {
    final name = profile.sitterEmail?.split('@').first ?? '시터';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildAvatar(profile, initials, 56),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.sitterEmail != null)
                      Text(
                        profile.sitterEmail!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (profile.isVerified == true)
                          _buildBadge(
                            Icons.verified,
                            '인증 완료',
                            Colors.white,
                          ),
                        if (profile.rating != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            Icons.star,
                            '${profile.rating!.toStringAsFixed(1)}점',
                            Colors.amber,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoCards(profile),
              const SizedBox(height: 16),
              if (profile.bio != null && profile.bio!.isNotEmpty)
                _buildSection(
                  '소개',
                  Icons.info_outline,
                  [_buildBioText(profile.bio!)],
                ),
              if (profile.experiences != null &&
                  profile.experiences!.isNotEmpty)
                _buildSection(
                  '경력 (${profile.experiences!.length}건)',
                  Icons.work_outline,
                  profile.experiences!
                      .map((e) => _buildExperienceItem(e))
                      .toList(),
                ),
              if (profile.certifications != null &&
                  profile.certifications!.isNotEmpty)
                _buildSection(
                  '자격증 (${profile.certifications!.length}개)',
                  Icons.card_membership_outlined,
                  profile.certifications!
                      .map((c) => _buildCertificationItem(c))
                      .toList(),
                ),
              if (profile.availableServiceTypes != null &&
                  profile.availableServiceTypes!.isNotEmpty)
                _buildSection(
                  '제공 서비스',
                  Icons.child_care_outlined,
                  [_buildChipRow(profile.availableServiceTypes!)],
                ),
              if (profile.preferredAgeGroups != null &&
                  profile.preferredAgeGroups!.isNotEmpty)
                _buildSection(
                  '선호 연령대',
                  Icons.cake_outlined,
                  [_buildChipRow(profile.preferredAgeGroups!)],
                ),
              if (profile.languagesSpoken != null &&
                  profile.languagesSpoken!.isNotEmpty)
                _buildSection(
                  '구사 언어',
                  Icons.language,
                  [_buildChipRow(profile.languagesSpoken!)],
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(SitterProfile profile, String initials, double radius) {
    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profile.profileImageUrl!),
        backgroundColor: Colors.white.withOpacity(0.3),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(SitterProfile profile) {
    return Row(
      children: [
        _buildInfoCard(
          '경력',
          profile.experienceYears != null
              ? '${profile.experienceYears}년'
              : '-',
          Icons.work,
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          '자격증',
          '${profile.certifications?.length ?? 0}개',
          Icons.card_membership,
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          '시급',
          profile.hourlyRate != null
              ? '${profile.hourlyRate!.toStringAsFixed(0)}원'
              : '-',
          Icons.attach_money,
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          '리뷰',
          '${profile.totalReviews ?? 0}개',
          Icons.rate_review_outlined,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioText(String bio) {
    return Text(
      bio,
      style: const TextStyle(fontSize: 14, color: Color(0xFF4F5D75), height: 1.5),
    );
  }

  Widget _buildExperienceItem(SitterExperience exp) {
    final period = [
      exp.startDate != null
          ? '${exp.startDate!.year}.${exp.startDate!.month.toString().padLeft(2, '0')}'
          : null,
      exp.endDate != null
          ? '${exp.endDate!.year}.${exp.endDate!.month.toString().padLeft(2, '0')}'
          : (exp.isCurrent == true ? '현재' : null),
    ].whereType<String>().join(' ~ ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.companyName ?? exp.position ?? '경력',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (exp.position != null && exp.companyName != null)
                  Text(
                    exp.position!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4F5D75),
                    ),
                  ),
                if (period.isNotEmpty)
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(SitterCertification cert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_membership,
              color: Color(0xFF6C63FF),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.certificationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (cert.issuedBy != null)
                  Text(
                    cert.issuedBy!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          if (cert.isVerified == true)
            const Icon(Icons.verified, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  Widget _buildChipRow(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items
          .map(
            (item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.08),
              side: const BorderSide(color: Color(0xFF6C63FF), width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }
}
