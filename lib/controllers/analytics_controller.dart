import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/analytics_model.dart';
import '../core/utils/result.dart';

/// Analytics KPI provider
final analyticsKPIProvider = FutureProvider.autoDispose<AnalyticsKPI>((
  ref,
) async {
  final controller = ref.watch(analyticsControllerProvider);
  final result = await controller.getAnalyticsKPI();
  return result.when(success: (kpi) => kpi, error: (e) => throw e);
});

/// Analytics controller provider
final analyticsControllerProvider = Provider((ref) => AnalyticsController(ref));

class AnalyticsController {
  final Ref ref;

  AnalyticsController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Get main KPI metrics
  Future<Result<AnalyticsKPI>> getAnalyticsKPI() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsKpi);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final wrapper = response.data['data'] as Map<String, dynamic>;
        final kpiData = wrapper['kpis'] as Map<String, dynamic>;
        return Success(AnalyticsKPI.fromJson(kpiData));
      }

      return Error(AppException(message: 'Failed to fetch KPI'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch analytics',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch analytics KPI: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get monthly statistics (last 12 months)
  Future<Result<List<Map<String, dynamic>>>> getMonthlyStatistics({
    int months = 12,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.analyticsMonthly,
        queryParameters: {'months': months},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['stats'] as List;
        return Success(list.map((e) => e as Map<String, dynamic>).toList());
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch monthly stats',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch monthly statistics: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get role distribution
  Future<Result<Map<String, int>>> getRoleDistribution() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsRoles);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data =
            response.data['data']['distribution'] as Map<String, dynamic>;
        final dist = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(dist);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to fetch role distribution',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch role distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get top 10 events by application count
  Future<Result<List<Map<String, dynamic>>>> getTopEvents({
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.analyticsTopEvents,
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['events'] as List;
        return Success(list.map((e) => e as Map<String, dynamic>).toList());
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch top events',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch top events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get application status distribution
  Future<Result<Map<String, int>>> getApplicationStatusDistribution() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsApplicationStatus);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data =
            response.data['data']['distribution'] as Map<String, dynamic>;
        final dist = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(dist);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to fetch application status',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch application status distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event status distribution
  Future<Result<Map<String, int>>> getEventStatusDistribution() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsEventStatus);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data =
            response.data['data']['distribution'] as Map<String, dynamic>;
        final dist = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(dist);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch event status',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch event status distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
