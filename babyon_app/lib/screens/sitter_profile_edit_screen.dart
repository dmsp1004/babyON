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

  final TextEditingController _introductionController = TextEditingController();
  final List<String> _selectedServiceTypes = [];
  final List<String> _selectedAgeGroups = [];
  final List<String> _selectedLanguages = [];
  String? _selectedEducation;

  final List<Map<String, String>> _serviceTypeOptions = [
    {'value': 'SHORT_TERM', 'label': '단기'},
    {'value': 'LONG_TERM', 'label': '장기'},
    {'value': 'LIVE_IN', 'label': '입주'},
    {'value': 'PICKUP_DROPOFF', 'label': '등하원'},
  ];

  final List<Map<String, String>> _ageGroupOptions = [
    {'value': 'INFANT', 'label': '영아 (0-12개월)'},
    {'value': 'TODDLER', 'label': '유아 (1-3세)'},
    {'value': 'PRESCHOOL', 'label': '미취학 (4-6세)'},
    {'value': 'SCHOOL_AGE', 'label': '학령기 (7세 이상)'},
  ];

  final List<Map<String, String>> _languageOptions = [
    {'value': 'Korean', 'label': '한국어'},
    {'value': 'English', 'label': '영어'},
    {'value': 'Chinese', 'label': '중국어'},
    {'value': 'Japanese', 'label': '일본어'},
  ];

  final List<Map<String, String>> _educationOptions = [
    {'value': 'HIGH_SCHOOL', 'label': '고등학교 졸업'},
    {'value': 'ASSOCIATE', 'label': '전문대 졸업'},
    {'value': 'BACHELOR', 'label': '대학교 졸업'},
    {'value': 'MASTER', 'label': '석사'},
    {'value': 'DOCTORATE', 'label': '박사'},
    {'value': 'SPECIALIZED_TRAINING', 'label': '전문 교육 과정'},
  ];

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

      if (sitterId == null) {
        throw Exception('사용자 ID를 찾을 수 없습니다');
      }

      final profile = await _apiService.getSitterProfile(sitterId);

      setState(() {
        _profile = profile;
        _introductionController.text = profile.introduction ?? '';

        if (profile.availableServiceTypes != null) {
          _selectedServiceTypes.addAll(profile.availableServiceTypes!);
        }
        if (profile.preferredAgeGroups != null) {
          _selectedAgeGroups.addAll(profile.preferredAgeGroups!);
        }
        if (profile.languagesSpoken != null) {
          _selectedLanguages.addAll(profile.languagesSpoken!);
        }
        _selectedEducation = profile.educationLevel;

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sitterId = authProvider.userId;

      if (sitterId == null) {
        throw Exception('사용자 ID를 찾을 수 없습니다');
      }

      await _apiService.updateSitterProfile(
        sitterId: sitterId,
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
                    _buildIntroductionSection(),
                    const SizedBox(height: 24),
                    _buildServiceTypesSection(),
                    const SizedBox(height: 24),
                    _buildAgeGroupsSection(),
                    const SizedBox(height: 24),
                    _buildLanguagesSection(),
                    const SizedBox(height: 24),
                    _buildEducationSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIntroductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자기소개',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _introductionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '간단한 자기소개를 입력해주세요',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '자기소개를 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildServiceTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제공 가능한 서비스',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _serviceTypeOptions.map((option) {
            final isSelected = _selectedServiceTypes.contains(option['value']);
            return FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedServiceTypes.add(option['value']!);
                  } else {
                    _selectedServiceTypes.remove(option['value']);
                  }
                });
              },
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
        Text(
          '선호 연령대',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageGroupOptions.map((option) {
            final isSelected = _selectedAgeGroups.contains(option['value']);
            return FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAgeGroups.add(option['value']!);
                  } else {
                    _selectedAgeGroups.remove(option['value']);
                  }
                });
              },
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
        Text(
          '구사 가능 언어',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageOptions.map((option) {
            final isSelected = _selectedLanguages.contains(option['value']);
            return FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(option['value']!);
                  } else {
                    _selectedLanguages.remove(option['value']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최종 학력',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEducation,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '학력을 선택해주세요',
          ),
          items: _educationOptions.map((option) {
            return DropdownMenuItem(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEducation = value;
            });
          },
        ),
      ],
    );
  }
}
