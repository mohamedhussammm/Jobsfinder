// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    ApplicationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      status: json['status'] as String? ?? 'applied',
      cvPath: json['cvPath'] as String?,
      coverLetter: json['coverLetter'] as String?,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ApplicationModelToJson(ApplicationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'eventId': instance.eventId,
      'status': instance.status,
      'cvPath': instance.cvPath,
      'coverLetter': instance.coverLetter,
      'appliedAt': instance.appliedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
