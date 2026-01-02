import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

/// Notification model - push notifications to users
@JsonSerializable()
class NotificationModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'type')
  final String type; // 'invite', 'accepted', 'declined', 'message', 'rating', 'application_status'

  @JsonKey(name: 'related_id')
  final String? relatedId; // Link to related resource (event, application, etc)

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'is_read')
  final bool isRead;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.type = 'message',
    this.relatedId,
    this.title,
    this.message,
    this.isRead = false,
    required this.createdAt,
  });

  // Type helpers
  bool get isInvite => type == 'invite';
  bool get isAccepted => type == 'accepted';
  bool get isDeclined => type == 'declined';
  bool get isRating => type == 'rating';
  bool get isApplicationStatus => type == 'application_status';

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? relatedId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  String toString() => 'NotificationModel($id, type: $type, isRead: $isRead)';
}
