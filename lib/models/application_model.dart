import 'user_model.dart';

/// Application model - user's application to an event
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
  final String? experience;
  final bool isAvailable;
  final bool openToOtherOptions;
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
    this.experience,
    this.isAvailable = false,
    this.openToOtherOptions = false,
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

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    // Backend uses MongoDB _id / camelCase fields
    final userId = (json['userId'] ?? json['user_id'])?.toString();
    final eventId = (json['eventId'] ?? json['event_id'])?.toString();

    // userId / eventId may be nested objects if populated
    final userIdStr =
        userId ??
        (json['userId'] is Map ? json['userId']['_id'] : null)?.toString() ??
        '';
    final eventIdStr =
        eventId ??
        (json['eventId'] is Map ? json['eventId']['_id'] : null)?.toString() ??
        '';

    // Nested user object if populated
    UserModel? user;
    final userJson =
        json['user'] ?? (json['userId'] is Map ? json['userId'] : null);
    if (userJson is Map<String, dynamic>) {
      user = UserModel.fromJson(userJson);
    }

    return ApplicationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: userIdStr,
      eventId: eventIdStr,
      status: (json['status'] ?? 'applied').toString(),
      cvPath: json['cvPath']?.toString() ?? json['cv_path']?.toString(),
      coverLetter:
          json['coverLetter']?.toString() ?? json['cover_letter']?.toString(),
      appliedAt: parseDate(
        json['appliedAt'] ?? json['applied_at'] ?? json['createdAt'],
      ),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      experience: json['experience']?.toString(),
      isAvailable: json['isAvailable'] == true || json['is_available'] == true,
      openToOtherOptions:
          json['openToOtherOptions'] == true ||
          json['open_to_other_options'] == true,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventId': eventId,
    'status': status,
    'cvPath': cvPath,
    'coverLetter': coverLetter,
    'appliedAt': appliedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'experience': experience,
    'isAvailable': isAvailable,
    'openToOtherOptions': openToOtherOptions,
  };

  ApplicationModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? status,
    String? cvPath,
    String? coverLetter,
    DateTime? appliedAt,
    DateTime? updatedAt,
    String? experience,
    bool? isAvailable,
    bool? openToOtherOptions,
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
      experience: experience ?? this.experience,
      isAvailable: isAvailable ?? this.isAvailable,
      openToOtherOptions: openToOtherOptions ?? this.openToOtherOptions,
      user: user ?? this.user,
    );
  }

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
