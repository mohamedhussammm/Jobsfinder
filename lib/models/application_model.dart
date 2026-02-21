import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'application_model.g.dart';

/// Application model - user's application to an event
@JsonSerializable()
class ApplicationModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'event_id')
  final String eventId;

  @JsonKey(name: 'status')
  final String status; // 'applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected'

  @JsonKey(name: 'cv_path')
  final String? cvPath;

  @JsonKey(name: 'cover_letter')
  final String? coverLetter;

  @JsonKey(name: 'applied_at')
  final DateTime appliedAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(includeFromJson: true, includeToJson: false)
  final UserModel? user;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.status = 'applied',
    this.cvPath,
    this.coverLetter,
    required this.appliedAt,
    required this.updatedAt,
    this.user,
  });

  // Status helpers
  bool get isApplied => status == 'applied';
  bool get isShortlisted => status == 'shortlisted';
  bool get isInvited => status == 'invited';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isRejected => status == 'rejected';

  // Status groups
  bool get isPending => isApplied || isShortlisted || isInvited;
  bool get isFinal => isAccepted || isDeclined || isRejected;

  ApplicationModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? status,
    String? cvPath,
    String? coverLetter,
    DateTime? appliedAt,
    DateTime? updatedAt,
    UserModel? user,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      cvPath: cvPath ?? this.cvPath,
      coverLetter: coverLetter ?? this.coverLetter,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  @override
  String toString() =>
      'ApplicationModel($id, userId: $userId, eventId: $eventId, status: $status)';
}

/// Extension to provide UI-expected properties
extension ApplicationModelExtensions on ApplicationModel {
  // Event title - placeholder until we implement proper event joins
  String get eventTitle =>
      'Event'; // Placeholder — populated via event join when available

  // Company name - placeholder until we implement proper company joins
  String get companyName =>
      'Company'; // Placeholder — populated via company join when available
}
