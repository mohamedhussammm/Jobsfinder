// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    ApplicationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      status: json['status'] as String? ?? 'applied',
      cvPath: json['cv_path'] as String?,
      coverLetter: json['cover_letter'] as String?,
      appliedAt: DateTime.parse(json['applied_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ApplicationModelToJson(ApplicationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'event_id': instance.eventId,
      'status': instance.status,
      'cv_path': instance.cvPath,
      'cover_letter': instance.coverLetter,
      'applied_at': instance.appliedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
