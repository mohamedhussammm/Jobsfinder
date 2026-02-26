/// Audit Log model - tracks admin actions
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

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    String? idFrom(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['_id'] ?? v['id'])?.toString();
      return v.toString();
    }

    return AuditLogModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      adminUserId: idFrom(json['adminUserId'] ?? json['admin_user_id']),
      action: (json['action'] ?? '').toString(),
      targetTable:
          json['targetTable']?.toString() ?? json['target_table']?.toString(),
      targetId: idFrom(json['targetId'] ?? json['target_id']),
      oldValues:
          json['oldValues'] as Map<String, dynamic>? ??
          json['old_values'] as Map<String, dynamic>?,
      newValues:
          json['newValues'] as Map<String, dynamic>? ??
          json['new_values'] as Map<String, dynamic>?,
      ipAddress:
          json['ipAddress']?.toString() ?? json['ip_address']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'adminUserId': adminUserId,
    'action': action,
    'targetTable': targetTable,
    'targetId': targetId,
    'oldValues': oldValues,
    'newValues': newValues,
    'ipAddress': ipAddress,
    'createdAt': createdAt.toIso8601String(),
  };

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

  @override
  String toString() => 'AuditLogModel($id, action: $action)';
}
