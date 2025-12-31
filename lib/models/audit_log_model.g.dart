// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLogModel _$AuditLogModelFromJson(Map<String, dynamic> json) =>
    AuditLogModel(
      id: json['id'] as String,
      adminUserId: json['adminUserId'] as String?,
      action: json['action'] as String,
      targetTable: json['targetTable'] as String?,
      targetId: json['targetId'] as String?,
      oldValues: json['oldValues'] as Map<String, dynamic>?,
      newValues: json['newValues'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AuditLogModelToJson(AuditLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'adminUserId': instance.adminUserId,
      'action': instance.action,
      'targetTable': instance.targetTable,
      'targetId': instance.targetId,
      'oldValues': instance.oldValues,
      'newValues': instance.newValues,
      'ipAddress': instance.ipAddress,
      'createdAt': instance.createdAt.toIso8601String(),
    };
