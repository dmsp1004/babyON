import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sitter_profile.dart';

class ParentSearchSitterScreen extends StatefulWidget {
  const ParentSearchSitterScreen({Key? key}) : super(key: key);

  @override
  State<ParentSearchSitterScreen> createState() =>
      _ParentSearchSitterScreenState();
}

class _ParentSearchSitterScreenState extends State<ParentSearchSitterScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<SitterProfile> _sitters = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 10;

  // 필터 상태
  String? _selectedServiceType;
  String? _selectedAgeGroup;
  String? _selectedLanguage;
  String _sortBy = 'rating';

  // 필터 옵션
  static const Map<String, String> _serviceTypeOptions = {
    'SHORT_TERM': '단기 돌봄',
    'LONG_TERM': '장기 돌봄',
    'LIVE_IN': '입주 돌봄',
    'PICKUP_DROPOFF': '등하원 동행',
  };

  static const Map<String, String> _ageGroupOptions = {
    'INFANT': '영아 (0~12개월)',
    'TODDLER': '걸음마기 (1~3세)',
    'PRESCHOOL': '유아 (3~6세)',
    'SCHOOL_AGE': '초등 (7세~)',
  };

  static const Map<String, String> _languageOptions = {
    'Korean': '한국어',
    'English': '영어',
    'Chinese': '중국어',
  };

  static const Map<String, String> _sortOptions = {
    'rating': '평점순',
    'experienceYears': '경력순',
    'hourlyRate': '시급순',
  };

  @override
  void initState() {
    super.initState();
    _fetchSitters(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchSitters();
    }
  }

  Future<void> _fetchSitters({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _hasError = false;
        _isLoading = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _apiService.searchSitterProfiles(
        serviceType: _selectedServiceType,
        ageGroup: _selectedAgeGroup,
        sortBy: _sortBy,
        sortDirection: 'desc',
        page: _currentPage,
        size: _pageSize,
      );

      final newSitters = (result['content'] as List? ?? [])
          .map((e) => SitterProfile.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        if (refresh) {
          _sitters = newSitters;
        } else {
          _sitters.addAll(newSitters);
        }
        _currentPage++;
        _hasMore = newSitters.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _hasError = refresh;
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilter() => _fetchSitters(refresh: true);

  void _clearFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedAgeGroup = null;
      _selectedLanguage = null;
      _sortBy = 'rating';
    });
    _fetchSitters(refresh: true);
  }

  bool get _hasActiveFilter =>
      _selectedServiceType != null ||
      _selectedAgeGroup != null ||
      _selectedLanguage != null ||
      _sortBy != 'rating';

  // ── 한글 변환 ──────────────────────────────────────────

  String _serviceTypeLabel(String? key) =>
      key != null ? (_serviceTypeOptions[key] ?? key) : '';

  String _ageGroupLabel(String? key) =>
      key != null ? (_ageGroupOptions[key] ?? key) : '';

  String _languageLabel(String? key) =>
      key != null ? (_languageOptions[key] ?? key) : '';

  String _educationLabel(String? key) {
    const map = {
      'HIGH_SCHOOL': '고졸',
      'ASSOCIATE': '전문대졸',
      'BACHELOR': '대졸',
      'MASTER': '석사',
      'DOCTORATE': '박사',
      'SPECIALIZED_TRAINING': '전문교육',
    };
    return key != null ? (map[key] ?? key) : '';
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('시터 찾기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          if (_hasActiveFilter)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('초기화', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          const SizedBox(height: 4),
          _buildSortBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── 필터 패널 ────────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(
            label: '서비스',
            options: _serviceTypeOptions,
            selected: _selectedServiceType,
            onSelect: (v) {
              setState(() => _selectedServiceType =
                  _selectedServiceType == v ? null : v);
              _applyFilter();
            },
          ),
          const SizedBox(height: 8),
          _buildFilterRow(
            label: '연령대',
            options: _ageGroupOptions,
            selected: _selectedAgeGroup,
            onSelect: (v) {
              setState(
                  () => _selectedAgeGroup = _selectedAgeGroup == v ? null : v);
              _applyFilter();
            },
          ),
          const SizedBox(height: 8),
          _buildFilterRow(
            label: '언어',
            options: _languageOptions,
            selected: _selectedLanguage,
            onSelect: (v) {
              setState(() =>
                  _selectedLanguage = _selectedLanguage == v ? null : v);
              _applyFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required Map<String, String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.entries.map((entry) {
                final isSelected = selected == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onSelect(entry.key),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── 정렬 바 ─────────────────────────────────────────────

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '시터 목록',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: _sortOptions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _sortBy = v);
                  _applyFilter();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 본문 ─────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류가 발생했습니다',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchSitters(refresh: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_sitters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('조건에 맞는 시터가 없습니다',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('필터를 조정해보세요',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchSitters(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _sitters.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _sitters.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildSitterCard(_sitters[index]);
        },
      ),
    );
  }

  // ── 시터 카드 ────────────────────────────────────────────

  Widget _buildSitterCard(SitterProfile sitter) {
    final email = sitter.sitterEmail ?? '';
    final initial =
        email.isNotEmpty ? email[0].toUpperCase() : '?';
    final rating = sitter.rating ?? 0.0;
    final reviewCount = sitter.totalReviews ?? 0;
    final hourlyRate = sitter.hourlyRate;
    final experienceYears = sitter.experienceYears ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/sitter_profile_detail',
          arguments: sitter.sitterId,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단: 아바타 + 기본정보 ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(
                    initial: initial,
                    imageUrl: sitter.profileImageUrl,
                    isVerified: sitter.isVerified ?? false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sitter.isVerified == true)
                              const _VerifiedBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildRatingRow(rating, reviewCount),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.work_outline,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              '경력 $experienceYears년',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            if (hourlyRate != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.attach_money,
                                  size: 13, color: Colors.green),
                              Text(
                                '${hourlyRate.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원/시',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── 자기소개 ──
              if (sitter.introduction != null &&
                  sitter.introduction!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  sitter.introduction!,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // ── 서비스 유형 칩 ──
              if (sitter.availableServiceTypes != null &&
                  sitter.availableServiceTypes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: sitter.availableServiceTypes!
                      .map((t) => _TagChip(
                            label: _serviceTypeLabel(t),
                            color: Colors.blue,
                          ))
                      .toList(),
                ),
              ],

              // ── 연령대 + 언어 + 학력 ──
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...?sitter.preferredAgeGroups?.map((a) => _TagChip(
                        label: _ageGroupLabel(a),
                        color: Colors.orange,
                      )),
                  ...?sitter.languagesSpoken?.map((l) => _TagChip(
                        label: _languageLabel(l),
                        color: Colors.purple,
                      )),
                  if (sitter.educationLevel != null)
                    _TagChip(
                      label: _educationLabel(sitter.educationLevel),
                      color: Colors.teal,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String initial,
    String? imageUrl,
    required bool isVerified,
  }) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                )
              : null,
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified,
                  size: 14, color: Colors.blue),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow(double rating, int reviewCount) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return const Icon(Icons.star, size: 14, color: Colors.amber);
          } else if (i < rating) {
            return const Icon(Icons.star_half,
                size: 14, color: Colors.amber);
          } else {
            return const Icon(Icons.star_border,
                size: 14, color: Colors.amber);
          }
        }),
        const SizedBox(width: 4),
        Text(
          rating > 0
              ? '${rating.toStringAsFixed(1)} ($reviewCount)'
              : '평가 없음',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 11, color: Colors.blue.shade600),
          const SizedBox(width: 2),
          Text(
            '인증',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
