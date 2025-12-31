import 'package:json_annotation/json_annotation.dart';

part 'rating_model.g.dart';

/// Rating model - team leader rates applicants
@JsonSerializable()
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

  factory RatingModel.fromJson(Map<String, dynamic> json) => _$RatingModelFromJson(json);
  Map<String, dynamic> toJson() => _$RatingModelToJson(this);

  @override
  String toString() => 'RatingModel($id, score: $score/5)';
}
