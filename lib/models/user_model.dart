/// User model - represents all user types (normal, company, team_leader, admin)
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String role; // 'normal', 'company', 'team_leader', 'admin'
  final String? phone;
  final String? nationalIdNumber;
  final String? avatarPath;
  final String? cvPath;
  final bool profileComplete;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.role = 'normal',
    this.phone,
    this.nationalIdNumber,
    this.avatarPath,
    this.cvPath,
    this.profileComplete = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Getters for role checking
  bool get isAdmin => role == 'admin';
  bool get isCompany => role == 'company';
  bool get isTeamLeader => role == 'team_leader';
  bool get isNormalUser => role == 'normal';

  /// Calculate real profile completion percentage based on filled fields (20% each)
  double get profileCompletion {
    int count = 0;
    if (name != null && name!.isNotEmpty) count++;
    if (phone != null && phone!.isNotEmpty) count++;
    if (nationalIdNumber != null &&
        nationalIdNumber!.isNotEmpty &&
        nationalIdNumber != 'PENDING') {
      count++;
    }
    if (avatarPath != null && avatarPath!.isNotEmpty) count++;
    if (cvPath != null && cvPath!.isNotEmpty) count++;

    return count / 5.0;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return UserModel(
      // MongoDB uses _id; REST may map it to 'id'
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      role: (json['role'] ?? 'normal').toString(),
      phone: json['phone']?.toString(),
      // nationalIdNumber may be null for new/incomplete profiles
      nationalIdNumber:
          json['nationalIdNumber']?.toString() ??
          json['national_id_number']?.toString(),
      avatarPath:
          json['avatarPath']?.toString() ?? json['avatar_path']?.toString(),
      cvPath: json['cvPath']?.toString() ?? json['cv_path']?.toString(),
      profileComplete:
          (json['profileComplete'] ?? json['profile_complete'] ?? false) ==
          true,
      ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0) as num)
          .toDouble(),
      ratingCount: ((json['ratingCount'] ?? json['rating_count'] ?? 0) as num)
          .toInt(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      deletedAt: json['deletedAt'] != null || json['deleted_at'] != null
          ? parseDate(json['deletedAt'] ?? json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'phone': phone,
    'nationalIdNumber': nationalIdNumber,
    'avatarPath': avatarPath,
    'cvPath': cvPath,
    'profileComplete': profileComplete,
    'ratingAvg': ratingAvg,
    'ratingCount': ratingCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  // Copy with method for immutable updates
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? nationalIdNumber,
    String? avatarPath,
    String? cvPath,
    bool? profileComplete,
    double? ratingAvg,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      cvPath: cvPath ?? this.cvPath,
      profileComplete: profileComplete ?? this.profileComplete,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'UserModel($id, $email, $role)';
}
