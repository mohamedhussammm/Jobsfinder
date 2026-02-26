import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/user_model.dart';
import '../models/team_leader_model.dart';
import '../models/event_model.dart';
import '../models/application_model.dart';
import '../core/utils/result.dart';

/// All users provider
final allUsersProvider = FutureProvider.autoDispose
    .family<List<UserModel>, int>((ref, page) async {
      final controller = ref.watch(adminControllerProvider);
      final result = await controller.fetchAllUsers(page: page);
      return result.when(success: (users) => users, error: (e) => throw e);
    });

/// Team leaders for event provider
final teamLeadersForEventProvider = FutureProvider.autoDispose
    .family<List<TeamLeaderModel>, String>((ref, eventId) async {
      final controller = ref.watch(adminControllerProvider);
      final result = await controller.fetchTeamLeadersForEvent(eventId);
      return result.when(success: (tl) => tl, error: (e) => throw e);
    });

/// All applications provider (admin view)
final allApplicationsAdminProvider = FutureProvider.autoDispose
    .family<List<ApplicationModel>, int>((ref, page) async {
      final controller = ref.watch(adminControllerProvider);
      final result = await controller.fetchAllApplications(page: page);
      return result.when(success: (apps) => apps, error: (e) => throw e);
    });

/// All companies provider
final allCompaniesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final response = await api.get(ApiEndpoints.companies);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['companies'] as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    });

/// Admin controller provider
final adminControllerProvider = Provider((ref) => AdminController(ref));

class AdminController {
  final Ref ref;
  static const int pageSize = 10;

  AdminController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Fetch pending event requests
  Future<Result<List<EventModel>>> fetchPendingEventRequests({
    int page = 0,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.eventsPending,
        queryParameters: {'page': page + 1, 'limit': pageSize},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['events'] ?? []) as List;
        final events = list
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(events);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch pending events',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch pending events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch all users with pagination
  Future<Result<List<UserModel>>> fetchAllUsers({
    int page = 0,
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page + 1,
        'limit': pageSize,
      };
      if (roleFilter != null) queryParams['role'] = roleFilter;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _api.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['users'] ?? []) as List;
        final users = list
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(users);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch users',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch users: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Block/Unblock user
  Future<Result<UserModel>> toggleUserStatus(String userId, bool block) async {
    try {
      final endpoint = block
          ? ApiEndpoints.blockUser(userId)
          : ApiEndpoints.unblockUser(userId);

      final response = await _api.patch(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = UserModel.fromJson(
          response.data['data']['user'] as Map<String, dynamic>,
        );
        return Success(user);
      }

      return Error(AppException(message: 'Failed to update user status'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to update user status',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to toggle user status: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update user role
  Future<Result<UserModel>> updateUserRole(
    String userId,
    String newRole,
  ) async {
    try {
      final response = await _api.patch(
        ApiEndpoints.changeRole(userId),
        data: {'role': newRole},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = UserModel.fromJson(
          response.data['data']['user'] as Map<String, dynamic>,
        );
        return Success(user);
      }

      return Error(AppException(message: 'Failed to update role'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to update role',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update user role: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Assign team leader to event
  Future<Result<TeamLeaderModel>> assignTeamLeaderToEvent({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.teamLeaders,
        data: {'userId': userId, 'eventId': eventId},
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final tl = TeamLeaderModel.fromJson(
          response.data['data']['assignment'] as Map<String, dynamic>,
        );
        return Success(tl);
      }

      return Error(AppException(message: 'Failed to assign team leader'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to assign team leader',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to assign team leader: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch team leaders assigned to event
  Future<Result<List<TeamLeaderModel>>> fetchTeamLeadersForEvent(
    String eventId,
  ) async {
    try {
      final response = await _api.get(ApiEndpoints.teamLeadersByEvent(eventId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['leaders'] ?? []) as List;
        final tls = list
            .map(
              (json) => TeamLeaderModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(tls);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch team leaders',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch team leaders: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Remove team leader from event
  Future<Result<void>> removeTeamLeaderFromEvent(String teamLeaderId) async {
    try {
      await _api.delete(ApiEndpoints.teamLeaderById(teamLeaderId));
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to remove team leader',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to remove team leader: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch audit logs
  Future<Result<List<Map<String, dynamic>>>> fetchAuditLogs({
    int page = 0,
    String? adminUserId,
    String? targetTable,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page + 1,
        'limit': pageSize,
      };
      if (adminUserId != null) queryParams['adminId'] = adminUserId;
      if (targetTable != null) queryParams['targetTable'] = targetTable;

      final response = await _api.get(
        ApiEndpoints.auditLogs,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final logs = list.map((json) => json as Map<String, dynamic>).toList();
        return Success(logs);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch audit logs',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch audit logs: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get user count by role
  Future<Result<Map<String, int>>> getUserCountByRole() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsRoles);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final counts = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(counts);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to get user counts',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get user count by role: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event statistics
  Future<Result<Map<String, int>>> getEventStatistics() async {
    try {
      final response = await _api.get(ApiEndpoints.analyticsEventStatus);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final stats = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        return Success(stats);
      }

      return Success({});
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to get event stats',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get event statistics: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch all applications for admin view
  Future<Result<List<ApplicationModel>>> fetchAllApplications({
    int page = 0,
    String? statusFilter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page + 1,
        'limit': pageSize,
      };
      if (statusFilter != null) queryParams['status'] = statusFilter;

      final response = await _api.get(
        ApiEndpoints.applications,
        queryParameters: queryParams,
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
          message: 'Failed to fetch all applications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
