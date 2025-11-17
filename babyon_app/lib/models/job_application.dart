import 'package:intl/intl.dart';

class JobApplication {
  final int? id;
  final int jobPostingId;
  final String? jobTitle;
  final int? sitterId;
  final String? sitterEmail;
  final String coverLetter;
  final double proposedHourlyRate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobApplication({
    this.id,
    required this.jobPostingId,
    this.jobTitle,
    this.sitterId,
    this.sitterEmail,
    required this.coverLetter,
    required this.proposedHourlyRate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // JSON → JobApplication 객체
  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'],
      jobPostingId: json['jobPostingId'],
      jobTitle: json['jobTitle'],
      sitterId: json['sitterId'],
      sitterEmail: json['sitterEmail'],
      coverLetter: json['coverLetter'] ?? '',
      proposedHourlyRate: (json['proposedHourlyRate'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // JobApplication 객체 → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobPostingId': jobPostingId,
      'jobTitle': jobTitle,
      'sitterId': sitterId,
      'sitterEmail': sitterEmail,
      'coverLetter': coverLetter,
      'proposedHourlyRate': proposedHourlyRate,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // 지원 상태 한글 변환
  String get statusKorean {
    switch (status) {
      case 'PENDING':
        return '대기중';
      case 'ACCEPTED':
        return '수락됨';
      case 'REJECTED':
        return '거절됨';
      case 'WITHDRAWN':
        return '철회됨';
      default:
        return status;
    }
  }

  // 상태별 색상
  int get statusColor {
    switch (status) {
      case 'PENDING':
        return 0xFFFF9800; // Orange
      case 'ACCEPTED':
        return 0xFF4CAF50; // Green
      case 'REJECTED':
        return 0xFFF44336; // Red
      case 'WITHDRAWN':
        return 0xFF9E9E9E; // Grey
      default:
        return 0xFF757575;
    }
  }

  // 제안 시급 포맷팅
  String get proposedHourlyRateFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(proposedHourlyRate.toInt())}원/시간';
  }

  // 지원일 포맷팅
  String get createdAtFormatted {
    if (createdAt == null) return '-';
    return '${createdAt!.year}.${createdAt!.month.toString().padLeft(2, '0')}.${createdAt!.day.toString().padLeft(2, '0')}';
  }
}
