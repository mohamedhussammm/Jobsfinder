// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_leader_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamLeaderModel _$TeamLeaderModelFromJson(Map<String, dynamic> json) =>
    TeamLeaderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      assignedBy: json['assigned_by'] as String?,
      status: json['status'] as String? ?? 'assigned',
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeamLeaderModelToJson(TeamLeaderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'event_id': instance.eventId,
      'assigned_by': instance.assignedBy,
      'status': instance.status,
      'assigned_at': instance.assignedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
