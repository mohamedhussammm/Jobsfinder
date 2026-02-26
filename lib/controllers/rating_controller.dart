import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/rating_model.dart';
import '../core/utils/result.dart';

/// User ratings provider
final userRatingsProvider = FutureProvider.autoDispose
    .family<List<RatingModel>, String>((ref, userId) async {
      final controller = ref.watch(ratingControllerProvider);
      final result = await controller.getUserRatings(userId);
      return result.when(success: (ratings) => ratings, error: (e) => throw e);
    });

/// Rating controller provider
final ratingControllerProvider = Provider((ref) => RatingController(ref));

class RatingController {
  final Ref ref;

  RatingController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Rate an applicant (by team leader or company)
  Future<Result<RatingModel>> rateApplicant({
    required String raterUserId,
    required String ratedUserId,
    required String eventId,
    required int score,
    String? textReview,
  }) async {
    try {
      if (score < 1 || score > 5) {
        throw ValidationException(
          message: 'Rating score must be between 1 and 5',
        );
      }

      final response = await _api.post(
        ApiEndpoints.ratings,
        data: {
          'ratedUserId': ratedUserId,
          'eventId': eventId,
          'score': score,
          'textReview': textReview,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final rating = RatingModel.fromJson(
          response.data['data']['rating'] as Map<String, dynamic>,
        );
        return Success(rating);
      }

      return Error(AppException(message: 'Failed to save rating'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to save rating',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to save rating: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get ratings for a user
  Future<Result<List<RatingModel>>> getUserRatings(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.ratingsByUser(userId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['ratings'] ?? []) as List;
        final ratings = list
            .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(ratings);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch ratings',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch ratings: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get ratings given by a user (team leader)
  Future<Result<List<RatingModel>>> getRatingsGivenByUser(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.ratingsGiven);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['ratings'] ?? []) as List;
        final ratings = list
            .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(ratings);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch ratings given',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch ratings given: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event ratings
  Future<Result<List<RatingModel>>> getEventRatings(String eventId) async {
    try {
      final response = await _api.get(ApiEndpoints.ratingsByEvent(eventId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['ratings'] ?? []) as List;
        final ratings = list
            .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(ratings);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch event ratings',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch event ratings: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Check if a rater has already rated an applicant for an event
  Future<bool> hasRatedApplicant({
    required String raterUserId,
    required String ratedUserId,
    required String eventId,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.ratings,
        queryParameters: {
          'raterId': raterUserId,
          'ratedUserId': ratedUserId,
          'eventId': eventId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['ratings'] ?? []) as List;
        return list.isNotEmpty;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
