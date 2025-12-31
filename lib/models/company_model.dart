import 'package:json_annotation/json_annotation.dart';

part 'company_model.g.dart';

/// Company model - represents a company that submits event requests
@JsonSerializable()
class CompanyModel {
  final String id;
  final String name;
  final String? description;
  final String? logoPath;
  final bool verified;
  final DateTime createdAt;
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

  factory CompanyModel.fromJson(Map<String, dynamic> json) => _$CompanyModelFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);

  @override
  String toString() => 'CompanyModel($id, $name, verified: $verified)';
}
