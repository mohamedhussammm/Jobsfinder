/// Notification model - push notifications to users
class NotificationModel {
  final String id;
  final String userId;
  final String
  type; // 'invite', 'accepted', 'declined', 'message', 'rating', 'application_status'
  final String? relatedId;
  final String? title;
  final String? message;
  final bool isRead;
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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    // userId may be a populated object
    final userRaw = json['userId'] ?? json['user_id'];
    final String userId;
    if (userRaw is Map) {
      userId = (userRaw['_id'] ?? userRaw['id'] ?? '').toString();
    } else {
      userId = (userRaw ?? '').toString();
    }

    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: userId,
      type: (json['type'] ?? 'message').toString(),
      relatedId:
          json['relatedId']?.toString() ?? json['related_id']?.toString(),
      title: json['title']?.toString(),
      message: json['message']?.toString(),
      isRead: (json['isRead'] ?? json['is_read'] ?? false) == true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type,
    'relatedId': relatedId,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

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

  @override
  String toString() => 'NotificationModel($id, type: $type, isRead: $isRead)';
}
