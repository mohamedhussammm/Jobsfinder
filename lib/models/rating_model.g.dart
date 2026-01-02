// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingModel _$RatingModelFromJson(Map<String, dynamic> json) => RatingModel(
      id: json['id'] as String,
      raterUserId: json['rater_user_id'] as String,
      ratedUserId: json['rated_user_id'] as String,
      eventId: json['event_id'] as String?,
      score: (json['score'] as num).toInt(),
      textReview: json['text_review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RatingModelToJson(RatingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rater_user_id': instance.raterUserId,
      'rated_user_id': instance.ratedUserId,
      'event_id': instance.eventId,
      'score': instance.score,
      'text_review': instance.textReview,
      'created_at': instance.createdAt.toIso8601String(),
    };
