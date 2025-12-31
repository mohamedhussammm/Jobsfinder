import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// User model - represents all user types (normal, company, team_leader, admin)
@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String role; // 'normal', 'company', 'team_leader', 'admin'
  final String? phone;

  @JsonKey(name: 'national_id_number')
  final String nationalIdNumber;

  @JsonKey(name: 'avatar_path')
  final String? avatarPath;

  @JsonKey(name: 'profile_complete')
  final bool profileComplete;

  @JsonKey(name: 'rating_avg')
  final double ratingAvg;

  @JsonKey(name: 'rating_count')
  final int ratingCount;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.role = 'normal',
    this.phone,
    required this.nationalIdNumber,
    this.avatarPath,
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

  // Copy with method for immutable updates
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? nationalIdNumber,
    String? avatarPath,
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
      profileComplete: profileComplete ?? this.profileComplete,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  String toString() => 'UserModel($id, $email, $role)';
}
