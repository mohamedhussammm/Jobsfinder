import 'package:json_annotation/json_annotation.dart';

part 'company_model.g.dart';

/// Company model - represents a company that submits event requests
@JsonSerializable()
class CompanyModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'logo_path')
  final String? logoPath;

  @JsonKey(name: 'verified')
  final bool verified;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.description,
    this.logoPath,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  CompanyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoPath,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoPath: logoPath ?? this.logoPath,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);

  @override
  String toString() => 'CompanyModel($id, $name, verified: $verified)';
}
