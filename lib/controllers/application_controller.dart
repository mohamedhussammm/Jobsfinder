import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/application_model.dart';
import '../core/utils/result.dart';

/// User applications provider
final userApplicationsProvider = FutureProvider.autoDispose
    .family<List<ApplicationModel>, String>((ref, userId) async {
      final controller = ref.watch(applicationControllerProvider);
      final result = await controller.fetchUserApplications(userId);
      return result.when(success: (apps) => apps, error: (e) => throw e);
    });

/// Event applications provider
final eventApplicationsProvider = FutureProvider.autoDispose
    .family<List<ApplicationModel>, String>((ref, eventId) async {
      final controller = ref.watch(applicationControllerProvider);
      final result = await controller.fetchEventApplications(eventId);
      return result.when(success: (apps) => apps, error: (e) => throw e);
    });

/// Application controller provider
final applicationControllerProvider = Provider(
  (ref) => ApplicationController(ref),
);

class ApplicationController {
  final Ref ref;
  ApplicationController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// User applies to an event
  Future<Result<ApplicationModel>> applyToEvent({
    required String userId,
    required String eventId,
    String? cvPath,
    String? coverLetter,
    String? experience,
    bool isAvailable = false,
    bool openToOtherOptions = false,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.applications,
        data: {
          'eventId': eventId,
          'cvPath': cvPath,
          'coverLetter': coverLetter,
          'experience': experience,
          'isAvailable': isAvailable,
          'openToOtherOptions': openToOtherOptions,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final app = ApplicationModel.fromJson(
          response.data['data']['application'] as Map<String, dynamic>,
        );
        return Success(app);
      }

      return Error(AppException(message: 'Failed to apply'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to apply to event',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to apply: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Withdraw application
  Future<Result<void>> withdrawApplication(String applicationId) async {
    try {
      await _api.delete(ApiEndpoints.applicationById(applicationId));
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to withdraw application',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to withdraw: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch user's applications
  Future<Result<List<ApplicationModel>>> fetchUserApplications(
    String userId,
  ) async {
    try {
      final response = await _api.get(ApiEndpoints.myApplications);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['applications'] ?? []) as List;
        final apps = list
            .map(
              (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(apps);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch applications',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch applications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch applications for an event (team leader view)
  Future<Result<List<ApplicationModel>>> fetchEventApplications(
    String eventId, {
    String? filterStatus,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.eventApplications(eventId),
        queryParameters: filterStatus != null ? {'status': filterStatus} : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['applications'] ?? []) as List;
        final apps = list
            .map(
              (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(apps);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to fetch event applications',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch event applications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Team leader updates application status
  Future<Result<ApplicationModel>> updateApplicationStatus({
    required String applicationId,
    required String newStatus,
  }) async {
    try {
      final response = await _api.patch(
        ApiEndpoints.applicationStatus(applicationId),
        data: {'status': newStatus},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final app = ApplicationModel.fromJson(
          response.data['data']['application'] as Map<String, dynamic>,
        );
        return Success(app);
      }

      return Error(AppException(message: 'Failed to update application'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to update application',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update application: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get application with related event/user info
  Future<Result<ApplicationModel>> getApplicationById(
    String applicationId,
  ) async {
    try {
      final response = await _api.get(
        ApiEndpoints.applicationById(applicationId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final app = ApplicationModel.fromJson(
          response.data['data']['application'] as Map<String, dynamic>,
        );
        return Success(app);
      }

      return Error(AppException(message: 'Application not found'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch application',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch application: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch applications by status
  Future<Result<List<ApplicationModel>>> fetchApplicationsByStatus(
    String status, {
    int page = 0,
    int pageSize = 10,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.applications,
        queryParameters: {
          'status': status,
          'page': page + 1,
          'limit': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['applications'] ?? []) as List;
        final apps = list
            .map(
              (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(apps);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch applications',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch applications by status: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Count applications per status
  Future<Result<Map<String, int>>> countApplicationsByStatus() async {
    try {
      final response = await _api.get(
        ApiEndpoints.applications,
        queryParameters: {'countByStatus': true},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final counts = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(counts);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to count',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to count applications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
