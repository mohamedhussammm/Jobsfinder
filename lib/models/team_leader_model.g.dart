// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_leader_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamLeaderModel _$TeamLeaderModelFromJson(Map<String, dynamic> json) =>
    TeamLeaderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      assignedBy: json['assignedBy'] as String?,
      status: json['status'] as String? ?? 'assigned',
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TeamLeaderModelToJson(TeamLeaderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'eventId': instance.eventId,
      'assignedBy': instance.assignedBy,
      'status': instance.status,
      'assignedAt': instance.assignedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
