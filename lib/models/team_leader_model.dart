/// Team Leader model - admin assigns team leaders to events
class TeamLeaderModel {
  final String id;
  final String userId;
  final String eventId;
  final String? assignedBy; // Admin ID
  final String status; // 'assigned', 'active', 'completed', 'removed'
  final DateTime assignedAt;
  final DateTime updatedAt;

  TeamLeaderModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.assignedBy,
    this.status = 'assigned',
    required this.assignedAt,
    required this.updatedAt,
  });

  // Status helpers
  bool get isAssigned => status == 'assigned';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isRemoved => status == 'removed';

  factory TeamLeaderModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    String idFrom(dynamic v) {
      if (v is Map) return (v['_id'] ?? v['id'] ?? '').toString();
      return (v ?? '').toString();
    }

    return TeamLeaderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: idFrom(json['userId'] ?? json['user_id']),
      eventId: idFrom(json['eventId'] ?? json['event_id']),
      assignedBy: json['assignedBy'] != null || json['assigned_by'] != null
          ? idFrom(json['assignedBy'] ?? json['assigned_by'])
          : null,
      status: (json['status'] ?? 'assigned').toString(),
      assignedAt: parseDate(
        json['assignedAt'] ?? json['assigned_at'] ?? json['createdAt'],
      ),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventId': eventId,
    'assignedBy': assignedBy,
    'status': status,
    'assignedAt': assignedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  TeamLeaderModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? assignedBy,
    String? status,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return TeamLeaderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      assignedBy: assignedBy ?? this.assignedBy,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TeamLeaderModel($id, userId: $userId, eventId: $eventId, status: $status)';
}
