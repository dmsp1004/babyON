import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/sitter_profile.dart';

class SitterProfileEditScreen extends StatefulWidget {
  const SitterProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<SitterProfileEditScreen> createState() => _SitterProfileEditScreenState();
}

class _SitterProfileEditScreenState extends State<SitterProfileEditScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  SitterProfile? _profile;

  // 프로필 사진
  String? _profileImageUrl;

  final TextEditingController _introductionController = TextEditingController();
  final List<String> _selectedServiceTypes = [];
  final List<String> _selectedAgeGroups = [];
  final List<String> _selectedLanguages = [];
  String? _selectedEducation;

  final List<SitterExperience> _experiences = [];
  final List<SitterCertification> _certifications = [];
  final List<SitterServiceArea> _serviceAreas = [];
  final List<SitterAvailableTime> _availableTimes = [];

  static const List<Map<String, String>> _serviceTypeOptions = [
    {'value': 'SHORT_TERM', 'label': '단기'},
    {'value': 'LONG_TERM', 'label': '장기'},
    {'value': 'LIVE_IN', 'label': '입주'},
    {'value': 'PICKUP_DROPOFF', 'label': '등하원'},
  ];

  static const List<Map<String, String>> _ageGroupOptions = [
    {'value': 'INFANT', 'label': '영아 (0-12개월)'},
    {'value': 'TODDLER', 'label': '유아 (1-3세)'},
    {'value': 'PRESCHOOL', 'label': '미취학 (4-6세)'},
    {'value': 'SCHOOL_AGE', 'label': '학령기 (7세 이상)'},
  ];

  static const List<Map<String, String>> _languageOptions = [
    {'value': 'Korean', 'label': '한국어'},
    {'value': 'English', 'label': '영어'},
    {'value': 'Chinese', 'label': '중국어'},
    {'value': 'Japanese', 'label': '일본어'},
  ];

  static const List<Map<String, String>> _educationOptions = [
    {'value': 'HIGH_SCHOOL', 'label': '고등학교 졸업'},
    {'value': 'ASSOCIATE', 'label': '전문대 졸업'},
    {'value': 'BACHELOR', 'label': '대학교 졸업'},
    {'value': 'MASTER', 'label': '석사'},
    {'value': 'DOCTORATE', 'label': '박사'},
    {'value': 'SPECIALIZED_TRAINING', 'label': '전문 교육 과정'},
  ];

  static const Map<String, String> _dayLabels = {
    'MONDAY': '월',
    'TUESDAY': '화',
    'WEDNESDAY': '수',
    'THURSDAY': '목',
    'FRIDAY': '금',
    'SATURDAY': '토',
    'SUNDAY': '일',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _introductionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sitterId = authProvider.userId;
      if (sitterId == null) throw Exception('사용자 ID를 찾을 수 없습니다');

      final profile = await _apiService.getSitterProfile(sitterId);

      setState(() {
        _profile = profile;
        _profileImageUrl = profile.profileImageUrl;
        _introductionController.text = profile.introduction ?? '';

        _selectedServiceTypes
          ..clear()
          ..addAll(profile.availableServiceTypes ?? []);
        _selectedAgeGroups
          ..clear()
          ..addAll(profile.preferredAgeGroups ?? []);
        _selectedLanguages
          ..clear()
          ..addAll(profile.languagesSpoken ?? []);
        _selectedEducation = profile.educationLevel;

        _experiences
          ..clear()
          ..addAll(profile.experiences ?? []);
        _certifications
          ..clear()
          ..addAll(profile.certifications ?? []);
        _serviceAreas
          ..clear()
          ..addAll(profile.serviceAreas ?? []);
        _availableTimes
          ..clear()
          ..addAll(profile.availableTimes ?? []);

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 불러오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (sitterId == null) throw Exception('사용자 ID를 찾을 수 없습니다');

      await _apiService.updateSitterProfile(
        sitterId: sitterId,
        profileImageUrl: _profileImageUrl,
        introduction: _introductionController.text.trim(),
        availableServiceTypes: _selectedServiceTypes,
        preferredAgeGroups: _selectedAgeGroups,
        languagesSpoken: _selectedLanguages,
        educationLevel: _selectedEducation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePhotoSection(),
                    const SizedBox(height: 24),
                    _buildIntroductionSection(),
                    const SizedBox(height: 24),
                    _buildServiceTypesSection(),
                    const SizedBox(height: 24),
                    _buildAgeGroupsSection(),
                    const SizedBox(height: 24),
                    _buildLanguagesSection(),
                    const SizedBox(height: 24),
                    _buildEducationSection(),
                    const SizedBox(height: 24),
                    _buildExperiencesSection(),
                    const SizedBox(height: 24),
                    _buildCertificationsSection(),
                    const SizedBox(height: 24),
                    _buildServiceAreasSection(),
                    const SizedBox(height: 24),
                    _buildAvailableTimesSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────
  // 섹션 헤더 공통 빌더
  // ─────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ─────────────────────────────────────────
  // 프로필 사진
  // ─────────────────────────────────────────

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('프로필 사진'),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 52, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showEditPhotoUrlDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditPhotoUrlDialog() async {
    final controller = TextEditingController(text: _profileImageUrl);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 사진 URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/photo.jpg',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _profileImageUrl = controller.text.trim().isEmpty ? null : controller.text.trim();
      });
    }
  }

  // ─────────────────────────────────────────
  // 자기소개
  // ─────────────────────────────────────────

  Widget _buildIntroductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('자기소개'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _introductionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '간단한 자기소개를 입력해주세요',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return '자기소개를 입력해주세요';
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 서비스 유형 · 연령대 · 언어
  // ─────────────────────────────────────────

  Widget _buildServiceTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('제공 가능한 서비스'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _serviceTypeOptions.map((opt) {
            final selected = _selectedServiceTypes.contains(opt['value']);
            return FilterChip(
              label: Text(opt['label']!),
              selected: selected,
              onSelected: (v) => setState(() {
                v
                    ? _selectedServiceTypes.add(opt['value']!)
                    : _selectedServiceTypes.remove(opt['value']);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('선호 연령대'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageGroupOptions.map((opt) {
            final selected = _selectedAgeGroups.contains(opt['value']);
            return FilterChip(
              label: Text(opt['label']!),
              selected: selected,
              onSelected: (v) => setState(() {
                v
                    ? _selectedAgeGroups.add(opt['value']!)
                    : _selectedAgeGroups.remove(opt['value']);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('구사 가능 언어'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageOptions.map((opt) {
            final selected = _selectedLanguages.contains(opt['value']);
            return FilterChip(
              label: Text(opt['label']!),
              selected: selected,
              onSelected: (v) => setState(() {
                v
                    ? _selectedLanguages.add(opt['value']!)
                    : _selectedLanguages.remove(opt['value']);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 학력
  // ─────────────────────────────────────────

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('최종 학력'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEducation,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '학력을 선택해주세요',
          ),
          items: _educationOptions
              .map((opt) => DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedEducation = v),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 경력
  // ─────────────────────────────────────────

  Widget _buildExperiencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('경력'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._experiences.map((exp) => Chip(
                  label: Text(_experienceLabel(exp), style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmDelete(
                    label: _experienceLabel(exp),
                    onConfirm: () => _deleteExperience(exp),
                  ),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('경력 추가'),
              onPressed: _showAddExperienceSheet,
            ),
          ],
        ),
      ],
    );
  }

  String _experienceLabel(SitterExperience exp) {
    final parts = <String>[
      if (exp.companyName != null && exp.companyName!.isNotEmpty) exp.companyName!,
      if (exp.position != null && exp.position!.isNotEmpty) exp.position!,
    ];
    final endStr = exp.isCurrent == true
        ? '현재'
        : exp.endDate != null
            ? exp.endDate!.year.toString()
            : '';
    parts.add(endStr.isNotEmpty
        ? '${exp.startDate.year}~$endStr'
        : exp.startDate.year.toString());
    return parts.join(' · ');
  }

  Future<void> _deleteExperience(SitterExperience exp) async {
    if (exp.id == null) {
      setState(() => _experiences.remove(exp));
      return;
    }
    final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (sitterId == null) return;
    try {
      await _apiService.deleteExperience(sitterId: sitterId, experienceId: exp.id!);
      setState(() => _experiences.remove(exp));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('경력 삭제 실패: $e')));
      }
    }
  }

  void _showAddExperienceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExperienceSheet(
        onAdd: (exp) async {
          final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (sitterId == null) return;
          final saved = await _apiService.addExperience(
            sitterId: sitterId,
            companyName: exp.companyName,
            position: exp.position,
            startDate: exp.startDate,
            endDate: exp.endDate,
            isCurrent: exp.isCurrent,
            description: exp.description,
          );
          setState(() => _experiences.add(saved));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('경력이 추가되었습니다')));
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 자격증
  // ─────────────────────────────────────────

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('자격증'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._certifications.map((cert) => Chip(
                  label: Text(_certLabel(cert), style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmDelete(
                    label: _certLabel(cert),
                    onConfirm: () => _deleteCertification(cert),
                  ),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('자격증 추가'),
              onPressed: _showAddCertificationSheet,
            ),
          ],
        ),
      ],
    );
  }

  String _certLabel(SitterCertification cert) {
    final parts = [cert.certificationName];
    if (cert.issuedBy != null && cert.issuedBy!.isNotEmpty) parts.add(cert.issuedBy!);
    if (cert.issueDate != null) parts.add(cert.issueDate!.year.toString());
    return parts.join(' · ');
  }

  Future<void> _deleteCertification(SitterCertification cert) async {
    if (cert.id == null) {
      setState(() => _certifications.remove(cert));
      return;
    }
    final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (sitterId == null) return;
    try {
      await _apiService.deleteCertification(sitterId: sitterId, certificationId: cert.id!);
      setState(() => _certifications.remove(cert));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('자격증 삭제 실패: $e')));
      }
    }
  }

  void _showAddCertificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCertificationSheet(
        onAdd: (cert) async {
          final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (sitterId == null) return;
          final saved = await _apiService.addCertification(
            sitterId: sitterId,
            certificationName: cert.certificationName,
            issuedBy: cert.issuedBy,
            issueDate: cert.issueDate,
            expiryDate: cert.expiryDate,
            description: cert.description,
          );
          setState(() => _certifications.add(saved));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('자격증이 추가되었습니다')));
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 서비스 지역
  // ─────────────────────────────────────────

  Widget _buildServiceAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('서비스 지역'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._serviceAreas.map((area) => Chip(
                  label: Text(_areaLabel(area), style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmDelete(
                    label: _areaLabel(area),
                    onConfirm: () => _deleteServiceArea(area),
                  ),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('지역 추가'),
              onPressed: _showAddServiceAreaSheet,
            ),
          ],
        ),
      ],
    );
  }

  String _areaLabel(SitterServiceArea area) {
    final parts = [area.city];
    if (area.district != null && area.district!.isNotEmpty) parts.add(area.district!);
    if (area.travelDistanceKm != null) parts.add('${area.travelDistanceKm}km 이내');
    return parts.join(' · ');
  }

  Future<void> _deleteServiceArea(SitterServiceArea area) async {
    if (area.id == null) {
      setState(() => _serviceAreas.remove(area));
      return;
    }
    final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (sitterId == null) return;
    try {
      await _apiService.deleteServiceArea(sitterId: sitterId, serviceAreaId: area.id!);
      setState(() => _serviceAreas.remove(area));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('서비스 지역 삭제 실패: $e')));
      }
    }
  }

  void _showAddServiceAreaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddServiceAreaSheet(
        onAdd: (area) async {
          final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (sitterId == null) return;
          final saved = await _apiService.addServiceArea(
            sitterId: sitterId,
            city: area.city,
            district: area.district,
            detailedArea: area.detailedArea,
            travelDistanceKm: area.travelDistanceKm,
            isPrimary: area.isPrimary,
          );
          setState(() => _serviceAreas.add(saved));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('서비스 지역이 추가되었습니다')));
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 근무 가능 시간
  // ─────────────────────────────────────────

  Widget _buildAvailableTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('근무 가능 시간'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._availableTimes.map((time) => Chip(
                  label: Text(_timeLabel(time), style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmDelete(
                    label: _timeLabel(time),
                    onConfirm: () => _deleteAvailableTime(time),
                  ),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('시간 추가'),
              onPressed: _showAddAvailableTimeSheet,
            ),
          ],
        ),
      ],
    );
  }

  String _timeLabel(SitterAvailableTime time) {
    final day = (_dayLabels[time.dayOfWeek] ?? time.dayOfWeek) + '요일';
    final flexible = time.isFlexible == true ? ' (유연)' : '';
    return '$day ${time.startTime}~${time.endTime}$flexible';
  }

  Future<void> _deleteAvailableTime(SitterAvailableTime time) async {
    if (time.id == null) {
      setState(() => _availableTimes.remove(time));
      return;
    }
    final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (sitterId == null) return;
    try {
      await _apiService.deleteAvailableTime(
          sitterId: sitterId, availableTimeId: time.id!);
      setState(() => _availableTimes.remove(time));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('시간 삭제 실패: $e')));
      }
    }
  }

  void _showAddAvailableTimeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAvailableTimeSheet(
        onAdd: (time) async {
          final sitterId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (sitterId == null) return;
          final saved = await _apiService.addAvailableTime(
            sitterId: sitterId,
            dayOfWeek: time.dayOfWeek,
            startTime: time.startTime,
            endTime: time.endTime,
            isFlexible: time.isFlexible,
          );
          setState(() => _availableTimes.add(saved));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('근무 가능 시간이 추가되었습니다')));
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 공통 삭제 확인 다이얼로그
  // ─────────────────────────────────────────

  void _confirmDelete({required String label, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"$label"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BottomSheet: 경력 추가
// ─────────────────────────────────────────

class _AddExperienceSheet extends StatefulWidget {
  final Future<void> Function(SitterExperience exp) onAdd;
  const _AddExperienceSheet({required this.onAdd});

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime(now.year - 1)) : (_endDate ?? now),
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('ko', 'KR'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _fmt(DateTime? dt) => dt == null ? '선택' : '${dt.year}.${dt.month.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }
    setState(() => _isSaving = true);
    final exp = SitterExperience(
      companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      position: _positionCtrl.text.trim().isEmpty ? null : _positionCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    try {
      await widget.onAdd(exp);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('경력 추가 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: '경력 추가',
      isSaving: _isSaving,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                  labelText: '회사명 / 기관명', hintText: '예: OO어린이집', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _positionCtrl,
              decoration: const InputDecoration(
                  labelText: '역할 / 직책', hintText: '예: 보육교사', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? '역할을 입력해주세요' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _DateButton(label: '시작일', value: _fmt(_startDate), onTap: () => _pickDate(isStart: true))),
              const SizedBox(width: 12),
              Expanded(child: _DateButton(
                  label: '종료일',
                  value: _isCurrent ? '현재' : _fmt(_endDate),
                  onTap: _isCurrent ? null : () => _pickDate(isStart: false))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Checkbox(
                  value: _isCurrent,
                  onChanged: (v) => setState(() {
                        _isCurrent = v ?? false;
                        if (_isCurrent) _endDate = null;
                      }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('현재 재직 중'),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: '업무 설명 (선택)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BottomSheet: 자격증 추가
// ─────────────────────────────────────────

class _AddCertificationSheet extends StatefulWidget {
  final Future<void> Function(SitterCertification cert) onAdd;
  const _AddCertificationSheet({required this.onAdd});

  @override
  State<_AddCertificationSheet> createState() => _AddCertificationSheetState();
}

class _AddCertificationSheetState extends State<_AddCertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _issuedByCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _issuedByCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isIssue}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssue ? (_issueDate ?? DateTime(now.year - 1)) : (_expiryDate ?? now),
      firstDate: DateTime(2000),
      lastDate: isIssue ? now : DateTime(now.year + 20),
      locale: const Locale('ko', 'KR'),
    );
    if (picked == null) return;
    setState(() => isIssue ? _issueDate = picked : _expiryDate = picked);
  }

  String _fmt(DateTime? dt) =>
      dt == null ? '선택' : '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issueDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('발급일을 선택해주세요')));
      return;
    }
    setState(() => _isSaving = true);
    final cert = SitterCertification(
      certificationName: _nameCtrl.text.trim(),
      issuedBy: _issuedByCtrl.text.trim().isEmpty ? null : _issuedByCtrl.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    try {
      await widget.onAdd(cert);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('자격증 추가 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: '자격증 추가',
      isSaving: _isSaving,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: '자격증 이름', hintText: '예: 보육교사 2급', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? '자격증 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issuedByCtrl,
              decoration: const InputDecoration(
                  labelText: '발급 기관 (선택)', hintText: '예: 보건복지부', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _DateButton(label: '발급일', value: _fmt(_issueDate), onTap: () => _pickDate(isIssue: true))),
              const SizedBox(width: 12),
              Expanded(child: _DateButton(label: '만료일 (선택)', value: _fmt(_expiryDate), onTap: () => _pickDate(isIssue: false))),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: '설명 (선택)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BottomSheet: 서비스 지역 추가
// ─────────────────────────────────────────

class _AddServiceAreaSheet extends StatefulWidget {
  final Future<void> Function(SitterServiceArea area) onAdd;
  const _AddServiceAreaSheet({required this.onAdd});

  @override
  State<_AddServiceAreaSheet> createState() => _AddServiceAreaSheetState();
}

class _AddServiceAreaSheetState extends State<_AddServiceAreaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _detailCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final area = SitterServiceArea(
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
      detailedArea: _detailCtrl.text.trim().isEmpty ? null : _detailCtrl.text.trim(),
      travelDistanceKm: _distanceCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_distanceCtrl.text.trim()),
      isPrimary: _isPrimary,
    );
    try {
      await widget.onAdd(area);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('서비스 지역 추가 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: '서비스 지역 추가',
      isSaving: _isSaving,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(
                  labelText: '시/도', hintText: '예: 서울특별시', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? '시/도를 입력해주세요' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _districtCtrl,
              decoration: const InputDecoration(
                  labelText: '구/군 (선택)', hintText: '예: 강남구', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _detailCtrl,
              decoration: const InputDecoration(
                  labelText: '상세 지역 (선택)', hintText: '예: 역삼동 일대', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _distanceCtrl,
              decoration: const InputDecoration(
                  labelText: '이동 가능 거리 km (선택)', hintText: '예: 10', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (int.tryParse(v.trim()) == null) return '숫자만 입력해주세요';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Checkbox(
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('주요 활동 지역으로 설정'),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BottomSheet: 근무 가능 시간 추가
// ─────────────────────────────────────────

class _AddAvailableTimeSheet extends StatefulWidget {
  final Future<void> Function(SitterAvailableTime time) onAdd;
  const _AddAvailableTimeSheet({required this.onAdd});

  @override
  State<_AddAvailableTimeSheet> createState() => _AddAvailableTimeSheetState();
}

class _AddAvailableTimeSheetState extends State<_AddAvailableTimeSheet> {
  static const List<Map<String, String>> _days = [
    {'value': 'MONDAY', 'label': '월요일'},
    {'value': 'TUESDAY', 'label': '화요일'},
    {'value': 'WEDNESDAY', 'label': '수요일'},
    {'value': 'THURSDAY', 'label': '목요일'},
    {'value': 'FRIDAY', 'label': '금요일'},
    {'value': 'SATURDAY', 'label': '토요일'},
    {'value': 'SUNDAY', 'label': '일요일'},
  ];

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFlexible = false;
  bool _isSaving = false;

  Future<void> _pickTime({required bool isStart}) async {
    final initial = (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  String _fmtTime(TimeOfDay? t) =>
      t == null ? '선택' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('요일을 선택해주세요')));
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시작/종료 시간을 모두 선택해주세요')));
      return;
    }
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다')));
      return;
    }

    setState(() => _isSaving = true);
    final time = SitterAvailableTime(
      dayOfWeek: _selectedDay!,
      startTime: _fmtTime(_startTime),
      endTime: _fmtTime(_endTime),
      isFlexible: _isFlexible,
    );
    try {
      await widget.onAdd(time);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('시간 추가 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: '근무 가능 시간 추가',
      isSaving: _isSaving,
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDay,
            decoration: const InputDecoration(
                labelText: '요일', border: OutlineInputBorder()),
            items: _days
                .map((d) => DropdownMenuItem(value: d['value'], child: Text(d['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDay = v),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _DateButton(label: '시작 시간', value: _fmtTime(_startTime), onTap: () => _pickTime(isStart: true))),
            const SizedBox(width: 12),
            Expanded(child: _DateButton(label: '종료 시간', value: _fmtTime(_endTime), onTap: () => _pickTime(isStart: false))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Checkbox(
              value: _isFlexible,
              onChanged: (v) => setState(() => _isFlexible = v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Text('시간 유연 협의 가능'),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 공통 BottomSheet 컨테이너
// ─────────────────────────────────────────

class _SheetContainer extends StatelessWidget {
  final String title;
  final bool isSaving;
  final VoidCallback onSubmit;
  final Widget child;

  const _SheetContainer({
    required this.title,
    required this.isSaving,
    required this.onSubmit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            child,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSubmit,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 날짜/시간 선택 버튼
// ─────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DateButton({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onTap == null
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
