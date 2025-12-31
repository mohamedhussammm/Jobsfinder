import 'package:json_annotation/json_annotation.dart';

part 'application_model.g.dart';

/// Application model - user's application to an event
@JsonSerializable()
class ApplicationModel {
  final String id;
  final String userId;
  final String eventId;
  final String
  status; // 'applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected'
  final String? cvPath;
  final String? coverLetter;
  final DateTime appliedAt;
  final DateTime updatedAt;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.status = 'applied',
    this.cvPath,
    this.coverLetter,
    required this.appliedAt,
    required this.updatedAt,
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
      'Event'; // TODO: Fetch from events table using eventId

  // Company name - placeholder until we implement proper company joins
  String get companyName =>
      'Company'; // TODO: Fetch from company table via event
}
