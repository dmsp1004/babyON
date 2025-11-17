class SitterProfile {
  final int? id;
  final int? sitterId;
  final String? sitterEmail;
  final String? profileImageUrl;
  final String? introduction;
  final List<String>? availableServiceTypes;
  final List<String>? preferredAgeGroups;
  final List<String>? languagesSpoken;
  final String? educationLevel;
  final double? rating;
  final int? totalReviews;
  final bool? profileCompleted;
  final bool? isActive;

  // From Sitter entity
  final String? sitterType;
  final int? experienceYears;
  final double? hourlyRate;
  final String? bio;
  final bool? isVerified;

  // Related data
  final List<SitterCertification>? certifications;
  final List<SitterExperience>? experiences;
  final List<SitterAvailableTime>? availableTimes;
  final List<SitterServiceArea>? serviceAreas;
  final SitterVideoResume? primaryVideoResume;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterProfile({
    this.id,
    this.sitterId,
    this.sitterEmail,
    this.profileImageUrl,
    this.introduction,
    this.availableServiceTypes,
    this.preferredAgeGroups,
    this.languagesSpoken,
    this.educationLevel,
    this.rating,
    this.totalReviews,
    this.profileCompleted,
    this.isActive,
    this.sitterType,
    this.experienceYears,
    this.hourlyRate,
    this.bio,
    this.isVerified,
    this.certifications,
    this.experiences,
    this.availableTimes,
    this.serviceAreas,
    this.primaryVideoResume,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterProfile.fromJson(Map<String, dynamic> json) {
    return SitterProfile(
      id: json['id'],
      sitterId: json['sitterId'],
      sitterEmail: json['sitterEmail'],
      profileImageUrl: json['profileImageUrl'],
      introduction: json['introduction'],
      availableServiceTypes: json['availableServiceTypes'] != null
          ? List<String>.from(json['availableServiceTypes'])
          : null,
      preferredAgeGroups: json['preferredAgeGroups'] != null
          ? List<String>.from(json['preferredAgeGroups'])
          : null,
      languagesSpoken: json['languagesSpoken'] != null
          ? List<String>.from(json['languagesSpoken'])
          : null,
      educationLevel: json['educationLevel'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalReviews: json['totalReviews'],
      profileCompleted: json['profileCompleted'],
      isActive: json['isActive'],
      sitterType: json['sitterType'],
      experienceYears: json['experienceYears'],
      hourlyRate: json['hourlyRate'] != null ? (json['hourlyRate'] as num).toDouble() : null,
      bio: json['bio'],
      isVerified: json['isVerified'],
      certifications: json['certifications'] != null
          ? (json['certifications'] as List)
              .map((e) => SitterCertification.fromJson(e))
              .toList()
          : null,
      experiences: json['experiences'] != null
          ? (json['experiences'] as List)
              .map((e) => SitterExperience.fromJson(e))
              .toList()
          : null,
      availableTimes: json['availableTimes'] != null
          ? (json['availableTimes'] as List)
              .map((e) => SitterAvailableTime.fromJson(e))
              .toList()
          : null,
      serviceAreas: json['serviceAreas'] != null
          ? (json['serviceAreas'] as List)
              .map((e) => SitterServiceArea.fromJson(e))
              .toList()
          : null,
      primaryVideoResume: json['primaryVideoResume'] != null
          ? SitterVideoResume.fromJson(json['primaryVideoResume'])
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'sitterEmail': sitterEmail,
      'profileImageUrl': profileImageUrl,
      'introduction': introduction,
      'availableServiceTypes': availableServiceTypes,
      'preferredAgeGroups': preferredAgeGroups,
      'languagesSpoken': languagesSpoken,
      'educationLevel': educationLevel,
      'rating': rating,
      'totalReviews': totalReviews,
      'profileCompleted': profileCompleted,
      'isActive': isActive,
      'sitterType': sitterType,
      'experienceYears': experienceYears,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SitterCertification {
  final int? id;
  final int? sitterId;
  final String certificationName;
  final String? issuedBy;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? certificateImageUrl;
  final String? description;
  final bool? isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterCertification({
    this.id,
    this.sitterId,
    required this.certificationName,
    this.issuedBy,
    this.issueDate,
    this.expiryDate,
    this.certificateImageUrl,
    this.description,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterCertification.fromJson(Map<String, dynamic> json) {
    return SitterCertification(
      id: json['id'],
      sitterId: json['sitterId'],
      certificationName: json['certificationName'] ?? '',
      issuedBy: json['issuedBy'],
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      certificateImageUrl: json['certificateImageUrl'],
      description: json['description'],
      isVerified: json['isVerified'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'certificationName': certificationName,
      'issuedBy': issuedBy,
      'issueDate': issueDate?.toIso8601String().split('T')[0],
      'expiryDate': expiryDate?.toIso8601String().split('T')[0],
      'certificateImageUrl': certificateImageUrl,
      'description': description,
      'isVerified': isVerified,
    };
  }
}

class SitterExperience {
  final int? id;
  final int? sitterId;
  final String? companyName;
  final String? position;
  final DateTime startDate;
  final DateTime? endDate;
  final bool? isCurrent;
  final String? description;
  final String? childrenAgeGroup;
  final int? numberOfChildren;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterExperience({
    this.id,
    this.sitterId,
    this.companyName,
    this.position,
    required this.startDate,
    this.endDate,
    this.isCurrent,
    this.description,
    this.childrenAgeGroup,
    this.numberOfChildren,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterExperience.fromJson(Map<String, dynamic> json) {
    return SitterExperience(
      id: json['id'],
      sitterId: json['sitterId'],
      companyName: json['companyName'],
      position: json['position'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCurrent: json['isCurrent'],
      description: json['description'],
      childrenAgeGroup: json['childrenAgeGroup'],
      numberOfChildren: json['numberOfChildren'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'companyName': companyName,
      'position': position,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'isCurrent': isCurrent,
      'description': description,
      'childrenAgeGroup': childrenAgeGroup,
      'numberOfChildren': numberOfChildren,
    };
  }
}

class SitterAvailableTime {
  final int? id;
  final int? sitterId;
  final String dayOfWeek;
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final bool? isFlexible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterAvailableTime({
    this.id,
    this.sitterId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isFlexible,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterAvailableTime.fromJson(Map<String, dynamic> json) {
    return SitterAvailableTime(
      id: json['id'],
      sitterId: json['sitterId'],
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isFlexible: json['isFlexible'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isFlexible': isFlexible,
    };
  }
}

class SitterServiceArea {
  final int? id;
  final int? sitterId;
  final String city;
  final String? district;
  final String? detailedArea;
  final int? travelDistanceKm;
  final bool? isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterServiceArea({
    this.id,
    this.sitterId,
    required this.city,
    this.district,
    this.detailedArea,
    this.travelDistanceKm,
    this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterServiceArea.fromJson(Map<String, dynamic> json) {
    return SitterServiceArea(
      id: json['id'],
      sitterId: json['sitterId'],
      city: json['city'] ?? '',
      district: json['district'],
      detailedArea: json['detailedArea'],
      travelDistanceKm: json['travelDistanceKm'],
      isPrimary: json['isPrimary'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'city': city,
      'district': district,
      'detailedArea': detailedArea,
      'travelDistanceKm': travelDistanceKm,
      'isPrimary': isPrimary,
    };
  }
}

class SitterVideoResume {
  final int? id;
  final int? sitterId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? title;
  final int? durationSeconds;
  final double? fileSizeMb;
  final String? aiAnalysisResult;
  final DateTime? aiAnalyzedAt;
  final bool? isPrimary;
  final int? viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SitterVideoResume({
    this.id,
    this.sitterId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.durationSeconds,
    this.fileSizeMb,
    this.aiAnalysisResult,
    this.aiAnalyzedAt,
    this.isPrimary,
    this.viewCount,
    this.createdAt,
    this.updatedAt,
  });

  factory SitterVideoResume.fromJson(Map<String, dynamic> json) {
    return SitterVideoResume(
      id: json['id'],
      sitterId: json['sitterId'],
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      title: json['title'],
      durationSeconds: json['durationSeconds'],
      fileSizeMb: json['fileSizeMb'] != null ? (json['fileSizeMb'] as num).toDouble() : null,
      aiAnalysisResult: json['aiAnalysisResult'],
      aiAnalyzedAt: json['aiAnalyzedAt'] != null ? DateTime.parse(json['aiAnalyzedAt']) : null,
      isPrimary: json['isPrimary'],
      viewCount: json['viewCount'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'durationSeconds': durationSeconds,
      'fileSizeMb': fileSizeMb,
      'isPrimary': isPrimary,
    };
  }
}
