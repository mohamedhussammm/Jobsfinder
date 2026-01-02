import 'package:json_annotation/json_annotation.dart';

part 'team_leader_model.g.dart';

/// Team Leader model - admin assigns team leaders to events
@JsonSerializable()
class TeamLeaderModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'event_id')
  final String eventId;

  @JsonKey(name: 'assigned_by')
  final String? assignedBy; // Admin ID

  @JsonKey(name: 'status')
  final String status; // 'assigned', 'active', 'completed', 'removed'

  @JsonKey(name: 'assigned_at')
  final DateTime assignedAt;

  @JsonKey(name: 'updated_at')
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

  factory TeamLeaderModel.fromJson(Map<String, dynamic> json) =>
      _$TeamLeaderModelFromJson(json);
  Map<String, dynamic> toJson() => _$TeamLeaderModelToJson(this);

  @override
  String toString() =>
      'TeamLeaderModel($id, userId: $userId, eventId: $eventId, status: $status)';
}
