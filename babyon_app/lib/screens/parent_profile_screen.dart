import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({Key? key}) : super(key: key);

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isEditing = false;
  String _errorMessage = '';

  // 프로필 데이터
  Map<String, dynamic>? _profileData;

  // 폼 컨트롤러
  final TextEditingController _numberOfChildrenController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _numberOfChildrenController.dispose();
    _addressController.dispose();
    _additionalInfoController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final profile = await _apiService.getMyParentProfile();
      setState(() {
        _profileData = profile;
        _numberOfChildrenController.text = profile['numberOfChildren']?.toString() ?? '';
        _addressController.text = profile['address'] ?? '';
        _additionalInfoController.text = profile['additionalInfo'] ?? '';
        _phoneNumberController.text = profile['phoneNumber'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '프로필을 불러오는데 실패했습니다: $e';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final updatedProfile = await _apiService.updateMyParentProfile(
        numberOfChildren: _numberOfChildrenController.text.isEmpty
            ? null
            : int.parse(_numberOfChildrenController.text),
        address: _addressController.text.isEmpty ? null : _addressController.text,
        additionalInfo: _additionalInfoController.text.isEmpty
            ? null
            : _additionalInfoController.text,
        phoneNumber: _phoneNumberController.text.isEmpty
            ? null
            : _phoneNumberController.text,
      );

      setState(() {
        _profileData = updatedProfile;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 수정되었습니다')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '프로필 수정에 실패했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // 원래 데이터로 되돌리기
                  if (_profileData != null) {
                    _numberOfChildrenController.text =
                        _profileData!['numberOfChildren']?.toString() ?? '';
                    _addressController.text = _profileData!['address'] ?? '';
                    _additionalInfoController.text = _profileData!['additionalInfo'] ?? '';
                    _phoneNumberController.text = _profileData!['phoneNumber'] ?? '';
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이메일 (읽기 전용)
                        _buildReadOnlyField(
                          label: '이메일',
                          value: _profileData?['email'] ?? '',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),

                        // 전화번호
                        _buildTextField(
                          controller: _phoneNumberController,
                          label: '전화번호',
                          icon: Icons.phone,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^01[0-9]-\d{3,4}-\d{4}$').hasMatch(value)) {
                                return '올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 자녀 수
                        _buildTextField(
                          controller: _numberOfChildrenController,
                          label: '자녀 수',
                          icon: Icons.child_care,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final number = int.tryParse(value);
                              if (number == null || number < 0) {
                                return '올바른 자녀 수를 입력해주세요';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 주소
                        _buildTextField(
                          controller: _addressController,
                          label: '주소',
                          icon: Icons.location_on,
                          enabled: _isEditing,
                          maxLines: 2,
                          validator: (value) {
                            if (value != null && value.length > 255) {
                              return '주소는 255자 이하이어야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 추가 정보
                        _buildTextField(
                          controller: _additionalInfoController,
                          label: '추가 정보',
                          icon: Icons.info,
                          enabled: _isEditing,
                          maxLines: 5,
                          validator: (value) {
                            if (value != null && value.length > 1000) {
                              return '추가 정보는 1000자 이하이어야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 가입 일시 (읽기 전용)
                        _buildReadOnlyField(
                          label: '가입 일시',
                          value: _formatDateTime(_profileData?['createdAt']),
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),

                        // 수정 일시 (읽기 전용)
                        _buildReadOnlyField(
                          label: '마지막 수정',
                          value: _formatDateTime(_profileData?['updatedAt']),
                          icon: Icons.update,
                        ),
                        const SizedBox(height: 32),

                        // 저장 버튼
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text(
                                '저장',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return '정보 없음';
    }
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
