import 'package:intl/intl.dart';

class JobPosting {
  final int? id;
  final String title;
  final String description;
  final int? parentId;
  final String? parentName;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final double hourlyRate;
  final int requiredExperienceYears;
  final String jobType;
  final String ageOfChildren;
  final int numberOfChildren;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? applicationCount;

  JobPosting({
    this.id,
    required this.title,
    required this.description,
    this.parentId,
    this.parentName,
    required this.location,
    this.startDate,
    this.endDate,
    required this.hourlyRate,
    required this.requiredExperienceYears,
    required this.jobType,
    required this.ageOfChildren,
    required this.numberOfChildren,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.applicationCount,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    try {
      return JobPosting(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        parentId: json['parentId'],
        parentName: json['parentName'],
        location: json['location'] ?? '',
        startDate: _parseDateTime(json['startDate']),
        endDate: _parseDateTime(json['endDate']),
        hourlyRate: _parseDouble(json['hourlyRate']),
        requiredExperienceYears: json['requiredExperienceYears'] ?? 0,
        jobType: json['jobType'] ?? '',
        ageOfChildren: json['ageOfChildren'] ?? '',
        numberOfChildren: json['numberOfChildren'] ?? 0,
        isActive: json['isActive'],
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        applicationCount: json['applicationCount'] ?? 0,
      );
    } catch (e) {
      print('JobPosting.fromJson 오류: $e');
      print('JSON 데이터: $json');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is List && value.length >= 3) {
        return DateTime(
          value[0],
          value[1],
          value[2],
          value.length > 3 ? value[3] : 0,
          value.length > 4 ? value[4] : 0,
          value.length > 5 ? value[5] : 0,
        );
      }
      return null;
    } catch (e) {
      print('DateTime 파싱 오류: $e, value: $value');
      return null;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'parentId': parentId,
      'parentName': parentName,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'hourlyRate': hourlyRate,
      'requiredExperienceYears': requiredExperienceYears,
      'jobType': jobType,
      'ageOfChildren': ageOfChildren,
      'numberOfChildren': numberOfChildren,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'applicationCount': applicationCount,
    };
  }

  String get jobTypeKorean {
    switch (jobType) {
      case 'REGULAR_CARE':
        return '정기 돌봄';
      case 'SCHOOL_ESCORT':
        return '등하원 도우미';
      case 'ONE_TIME':
        return '일회성 돌봄';
      case 'EMERGENCY':
        return '긴급 돌봄';
      case 'TEMPORARY':
        return '임시 돌봄';
      default:
        return jobType;
    }
  }

  String get dateRangeFormatted {
    if (startDate == null || endDate == null) return '날짜 미정';
    final start = '${startDate!.year}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.day.toString().padLeft(2, '0')}';
    final end = '${endDate!.year}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')}';
    return '$start ~ $end';
  }

  String get hourlyRateFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(hourlyRate.toInt())}원/시간';
  }
}
