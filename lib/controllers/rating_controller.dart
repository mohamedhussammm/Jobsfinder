import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/rating_model.dart';
import '../core/utils/result.dart';

/// User ratings provider
final userRatingsProvider = FutureProvider.autoDispose.family<List<RatingModel>, String>(
  (ref, userId) async {
    final controller = ref.watch(ratingControllerProvider);
    final result = await controller.getUserRatings(userId);
    return result.when(
      success: (ratings) => ratings,
      error: (e) => throw e,
    );
  },
);

/// Rating controller provider
final ratingControllerProvider = Provider((ref) => RatingController(ref));

class RatingController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  RatingController(this.ref);

  /// Team leader rates an applicant
  Future<Result<RatingModel>> rateApplicant({
    required String raterUserId, // Team leader
    required String ratedUserId, // Applicant
    required String eventId,
    required int score,
    String? textReview,
  }) async {
    try {
      // Validate score
      if (score < 1 || score > 5) {
        throw ValidationException(message: 'Rating score must be between 1 and 5');
      }

      // Check if rating already exists (immutable)
      final existing = await _supabase
          .from(SupabaseTables.ratings)
          .select()
          .eq('rater_user_id', raterUserId)
          .eq('rated_user_id', ratedUserId)
          .eq('event_id', eventId);

      if (existing.isNotEmpty) {
        throw ValidationException(
          message: 'You have already rated this applicant for this event',
          code: 'DUPLICATE_RATING',
        );
      }

      final ratingData = {
        'rater_user_id': raterUserId,
        'rated_user_id': ratedUserId,
        'event_id': eventId,
        'score': score,
        'text_review': textReview,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.ratings)
          .insert(ratingData)
          .select()
          .single();

      final rating = RatingModel.fromJson(response);

      // Update user's average rating
      await _updateUserAverageRating(ratedUserId);

      return Success(rating);
    } on PostgrestException catch (e) {
      return Error(DatabaseException(
        message: e.message,
        code: e.code,
        originalError: e,
      ));
    } catch (e, st) {
      return Error(AppException(
        message: 'Failed to save rating: $e',
        originalError: e,
        stackTrace: st,
      ));
    }
  }

  /// Get ratings for a user
  Future<Result<List<RatingModel>>> getUserRatings(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.ratings)
          .select()
          .eq('rated_user_id', userId)
          .order('created_at', ascending: false);

      final ratings = (response as List)
          .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(ratings);
    } on PostgrestException catch (e) {
      return Error(DatabaseException(
        message: e.message,
        code: e.code,
        originalError: e,
      ));
    } catch (e, st) {
      return Error(AppException(
        message: 'Failed to fetch ratings: $e',
        originalError: e,
        stackTrace: st,
      ));
    }
  }

  /// Get ratings given by a user (team leader)
  Future<Result<List<RatingModel>>> getRatingsGivenByUser(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.ratings)
          .select()
          .eq('rater_user_id', userId)
          .order('created_at', ascending: false);

      final ratings = (response as List)
          .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(ratings);
    } on PostgrestException catch (e) {
      return Error(DatabaseException(
        message: e.message,
        code: e.code,
        originalError: e,
      ));
    } catch (e, st) {
      return Error(AppException(
        message: 'Failed to fetch ratings given: $e',
        originalError: e,
        stackTrace: st,
      ));
    }
  }

  /// Get event ratings
  Future<Result<List<RatingModel>>> getEventRatings(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.ratings)
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      final ratings = (response as List)
          .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(ratings);
    } on PostgrestException catch (e) {
      return Error(DatabaseException(
        message: e.message,
        code: e.code,
        originalError: e,
      ));
    } catch (e, st) {
      return Error(AppException(
        message: 'Failed to fetch event ratings: $e',
        originalError: e,
        stackTrace: st,
      ));
    }
  }

  /// Update user's average rating
  Future<void> _updateUserAverageRating(String userId) async {
    try {
      // Get all ratings for user
      final ratings = await _supabase
          .from(SupabaseTables.ratings)
          .select('score')
          .eq('rated_user_id', userId);

      if (ratings.isEmpty) {
        return;
      }

      final total = ratings.fold<int>(0, (sum, r) => sum + (r['score'] as int));
      final average = total / ratings.length;

      // Update user record
      await _supabase
          .from(SupabaseTables.users)
          .update({
            'rating_avg': average,
            'rating_count': ratings.length,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Failed to update user average rating: $e');
    }
  }
}
