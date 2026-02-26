/// Rating model - team leader rates applicants
class RatingModel {
  final String id;
  final String raterUserId; // Team leader
  final String ratedUserId; // Applicant
  final String? eventId;
  final int score; // 1-5
  final String? textReview;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.raterUserId,
    required this.ratedUserId,
    this.eventId,
    required this.score,
    this.textReview,
    required this.createdAt,
  });

  // Score helpers
  bool get isExcellent => score == 5;
  bool get isGood => score == 4;
  bool get isAverage => score == 3;
  bool get isPoor => score == 2;
  bool get isBad => score == 1;

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    String idFrom(dynamic v) {
      if (v is Map) return (v['_id'] ?? v['id'] ?? '').toString();
      return (v ?? '').toString();
    }

    return RatingModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      raterUserId: idFrom(
        json['raterId'] ?? json['rater_user_id'] ?? json['raterUserId'],
      ),
      ratedUserId: idFrom(json['ratedUserId'] ?? json['rated_user_id']),
      eventId: (json['eventId'] ?? json['event_id']) != null
          ? idFrom(json['eventId'] ?? json['event_id'])
          : null,
      score: ((json['score'] ?? 0) as num).toInt(),
      textReview:
          json['textReview']?.toString() ?? json['text_review']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'raterUserId': raterUserId,
    'ratedUserId': ratedUserId,
    'eventId': eventId,
    'score': score,
    'textReview': textReview,
    'createdAt': createdAt.toIso8601String(),
  };

  RatingModel copyWith({
    String? id,
    String? raterUserId,
    String? ratedUserId,
    String? eventId,
    int? score,
    String? textReview,
    DateTime? createdAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      raterUserId: raterUserId ?? this.raterUserId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      eventId: eventId ?? this.eventId,
      score: score ?? this.score,
      textReview: textReview ?? this.textReview,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'RatingModel($id, score: $score/5)';
}
