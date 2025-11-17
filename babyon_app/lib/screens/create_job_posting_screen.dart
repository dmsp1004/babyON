import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/job_posting.dart';

class CreateJobPostingScreen extends StatefulWidget {
  const CreateJobPostingScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobPostingScreen> createState() => _CreateJobPostingScreenState();
}

class _CreateJobPostingScreenState extends State<CreateJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _dongController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _ageOfChildrenController = TextEditingController();
  final TextEditingController _numberOfChildrenController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _jobType = 'REGULAR_CARE';
  String _payType = 'HOURLY';
  int _requiredExperienceYears = 0;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _jobTypes = [
    {'value': 'REGULAR_CARE', 'label': '정기 돌봄'},
    {'value': 'PART_TIME', 'label': '파트타임'},
    {'value': 'SCHOOL_ESCORT', 'label': '등하원'},
    {'value': 'ONE_TIME', 'label': '일회성'},
    {'value': 'EMERGENCY', 'label': '긴급'},
    {'value': 'TEMPORARY', 'label': '임시'},
  ];

  final List<Map<String, dynamic>> _payTypes = [
    {'value': 'HOURLY', 'label': '시급'},
    {'value': 'DAILY', 'label': '일급'},
    {'value': 'MONTHLY', 'label': '월급'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _dongController.dispose();
    _hourlyRateController.dispose();
    _ageOfChildrenController.dispose();
    _numberOfChildrenController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return '';
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6F00),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF6F00),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = combined;
          } else {
            _endDate = combined;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '선택하기';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (dateToCheck == today) {
      dateStr = '오늘';
    } else if (dateToCheck == today.add(const Duration(days: 1))) {
      dateStr = '내일';
    } else {
      dateStr = DateFormat('M월 d일').format(dateTime);
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$dateStr $period $displayHour:$minute';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작 시간과 종료 시간을 모두 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('종료 시간은 시작 시간 이후여야 합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final hourlyRate = double.parse(_hourlyRateController.text.replaceAll(',', ''));
      final location = '${_cityController.text.trim()} ${_districtController.text.trim()} ${_dongController.text.trim()}'.trim();

      final jobPosting = await _apiService.createJobPosting(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: location.isEmpty ? '미입력' : location,
        startDate: _startDate!,
        endDate: _endDate!,
        hourlyRate: hourlyRate,
        payType: _payType,
        requiredExperienceYears: _requiredExperienceYears,
        jobType: _jobType,
        ageOfChildren: _ageOfChildrenController.text.trim(),
        numberOfChildren: int.parse(_numberOfChildrenController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구인글이 성공적으로 등록되었습니다.'),
            backgroundColor: Color(0xFFFF6F00),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('구인글 작성 오류: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구인글 작성에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('구인글 작성'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSection(
                '제목',
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('예) 평일 오후 시터 구합니다'),
                  validator: (v) => v == null || v.trim().length < 5 ? '제목은 최소 5자 이상' : null,
                  maxLength: 100,
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '구인 유형',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _jobTypes.map((type) {
                    final isSelected = _jobType == type['value'];
                    return ChoiceChip(
                      label: Text(type['label']),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _jobType = type['value']);
                      },
                      selectedColor: const Color(0xFFFFE0B2),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '급여 타입',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _payTypes.map((type) {
                    final isSelected = _payType == type['value'];
                    return ChoiceChip(
                      label: Text(type['label']),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _payType = type['value']);
                      },
                      selectedColor: const Color(0xFFFFE0B2),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                _payType == 'HOURLY' ? '시급' : _payType == 'DAILY' ? '일급' : '월급',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _hourlyRateController,
                      decoration: _inputDecoration('0').copyWith(
                        suffix: const Text('원', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) return newValue;
                          final formatted = _formatCurrency(newValue.text);
                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '급여를 입력해주세요';
                        final rate = double.tryParse(v.replaceAll(',', ''));
                        return (rate == null || rate <= 0) ? '올바른 급여를 입력해주세요' : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('2025년 최저시급: 10,030원', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '근무 시간',
                Row(
                  children: [
                    Expanded(child: _buildTimeSelector('시작', _startDate, true)),
                    Padding(
                      padding: const EdgeInsets.only(top: 28, left: 8, right: 8),
                      child: Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
                    ),
                    Expanded(child: _buildTimeSelector('종료', _endDate, false)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '위치',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration('시').copyWith(
                              prefixIcon: const Icon(Icons.location_city, color: Color(0xFFFF6F00), size: 20),
                            ),
                            maxLength: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _districtController,
                            decoration: _inputDecoration('구'),
                            maxLength: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _dongController,
                            decoration: _inputDecoration('동'),
                            maxLength: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('예) 서울시 / 강남구 / 역삼동', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '필요 경력',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [0, 1, 2, 3, 5].map((years) {
                    final isSelected = _requiredExperienceYears == years;
                    return ChoiceChip(
                      label: Text(years == 0 ? '경력 무관' : '${years}년 이상'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _requiredExperienceYears = years);
                      },
                      selectedColor: const Color(0xFFFFE0B2),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF6F00) : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '아이 정보',
                Column(
                  children: [
                    TextFormField(
                      controller: _ageOfChildrenController,
                      decoration: _inputDecoration('예) 3세, 5세').copyWith(labelText: '아이 나이'),
                      validator: (v) => v == null || v.trim().isEmpty ? '아이 나이를 입력해주세요' : null,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numberOfChildrenController,
                      decoration: _inputDecoration('예) 2').copyWith(labelText: '아이 수'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '아이 수를 입력해주세요';
                        final count = int.tryParse(v);
                        return (count == null || count <= 0) ? '올바른 아이 수를 입력해주세요' : null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _buildSection(
                '상세 설명',
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration('예) 평일 오후 2시부터 6시까지 아이 돌봄'),
                  maxLines: 8,
                  validator: (v) => v == null || v.trim().length < 10 ? '상세 설명은 최소 10자 이상' : null,
                  maxLength: 1000,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('작성 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, DateTime? date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _formatDateTime(date),
                    style: TextStyle(fontSize: 14, color: date == null ? Colors.grey[400] : Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
