// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingModel _$RatingModelFromJson(Map<String, dynamic> json) => RatingModel(
      id: json['id'] as String,
      raterUserId: json['raterUserId'] as String,
      ratedUserId: json['ratedUserId'] as String,
      eventId: json['eventId'] as String?,
      score: (json['score'] as num).toInt(),
      textReview: json['textReview'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$RatingModelToJson(RatingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'raterUserId': instance.raterUserId,
      'ratedUserId': instance.ratedUserId,
      'eventId': instance.eventId,
      'score': instance.score,
      'textReview': instance.textReview,
      'createdAt': instance.createdAt.toIso8601String(),
    };
