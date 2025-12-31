import 'package:json_annotation/json_annotation.dart';

part 'audit_log_model.g.dart';

/// Audit Log model - tracks admin actions
@JsonSerializable()
class AuditLogModel {
  final String id;
  final String? adminUserId;
  final String action;
  final String? targetTable;
  final String? targetId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    this.adminUserId,
    required this.action,
    this.targetTable,
    this.targetId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    required this.createdAt,
  });

  // Action helpers
  bool get isEventApproval => action.contains('event_approve');
  bool get isEventRejection => action.contains('event_reject');
  bool get isUserManagement => action.contains('user_');
  bool get isTeamLeaderAssignment => action.contains('team_leader_assign');

  AuditLogModel copyWith({
    String? id,
    String? adminUserId,
    String? action,
    String? targetTable,
    String? targetId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? ipAddress,
    DateTime? createdAt,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      adminUserId: adminUserId ?? this.adminUserId,
      action: action ?? this.action,
      targetTable: targetTable ?? this.targetTable,
      targetId: targetId ?? this.targetId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => _$AuditLogModelFromJson(json);
  Map<String, dynamic> toJson() => _$AuditLogModelToJson(this);

  @override
  String toString() => 'AuditLogModel($id, action: $action)';
}
