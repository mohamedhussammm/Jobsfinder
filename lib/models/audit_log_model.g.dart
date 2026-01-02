// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLogModel _$AuditLogModelFromJson(Map<String, dynamic> json) =>
    AuditLogModel(
      id: json['id'] as String,
      adminUserId: json['admin_user_id'] as String?,
      action: json['action'] as String,
      targetTable: json['target_table'] as String?,
      targetId: json['target_id'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AuditLogModelToJson(AuditLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_user_id': instance.adminUserId,
      'action': instance.action,
      'target_table': instance.targetTable,
      'target_id': instance.targetId,
      'old_values': instance.oldValues,
      'new_values': instance.newValues,
      'ip_address': instance.ipAddress,
      'created_at': instance.createdAt.toIso8601String(),
    };
