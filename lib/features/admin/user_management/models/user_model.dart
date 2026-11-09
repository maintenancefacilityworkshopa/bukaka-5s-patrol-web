// ignore_for_file: constant_identifier_names

enum AppRole {
  ADMIN,
  PIC_AREA,
  STAFF_AHLI,
  STAFF_INTERNSHIP;

  static AppRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return AppRole.ADMIN;
      case 'PIC_AREA':
      case 'PIC AREA':
      case 'PIC':
        return AppRole.PIC_AREA;
      case 'STAFF_AHLI':
      case 'STAFF AHLI':
        return AppRole.STAFF_AHLI;
      case 'STAFF_INTERNSHIP':
      case 'STAFF INTERNSHIP':
      case 'INTERN':
        return AppRole.STAFF_INTERNSHIP;
      default:
        return AppRole.STAFF_AHLI;
    }
  }

  String toShortString() => name;
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? nik;
  final AppRole role;
  final String? areaResponsibility;
  final String? departmentId;
  final String? phoneNumber;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.nik,
    required this.role,
    this.areaResponsibility,
    this.departmentId,
    this.phoneNumber,
    required this.isActive,
    this.updatedAt,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      nik: json['nik'],
      role: AppRole.fromString(json['role']),
      areaResponsibility: json['area_responsibility'],
      departmentId: json['department_id'],
      phoneNumber: json['phone_number'],
      isActive: json['is_active'] ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'nik': nik,
      'role': role.toShortString(),
      'area_responsibility': areaResponsibility,
      'department_id': departmentId,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Helper konversi Enum DB ke Label UI
  String get displayRole {
    switch (role) {
      case AppRole.ADMIN:
        return 'Admin';
      case AppRole.PIC_AREA:
        return 'PIC Area';
      case AppRole.STAFF_INTERNSHIP:
        return 'Staff Internship';
      case AppRole.STAFF_AHLI:
        return 'Staff Ahli';
    }
  }

  // Helper konversi Label UI ke Enum DB
  static AppRole roleToEnum(String displayRole) {
    switch (displayRole) {
      case 'Admin':
        return AppRole.ADMIN;
      case 'PIC Area':
        return AppRole.PIC_AREA;
      case 'Staff Internship':
      case 'Intern':
        return AppRole.STAFF_INTERNSHIP;
      case 'Staff Ahli':
      default:
        return AppRole.STAFF_AHLI;
    }
  }

  // Helper pembuat inisial 2 huruf nama (Misal: Pandu Muhammad Akbar -> PA)
  String get initials {
    if (fullName.trim().isEmpty) return 'U';
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}