import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/team_leader_model.dart';
import '../models/event_model.dart';
import '../core/utils/result.dart';

/// Team leader events provider
final teamLeaderEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, String>((ref, userId) async {
      final controller = ref.watch(teamLeaderControllerProvider);
      final result = await controller.getTeamLeaderEvents(userId);
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Team leader controller provider
final teamLeaderControllerProvider = Provider(
  (ref) => TeamLeaderController(ref),
);

class TeamLeaderController {
  final Ref ref;

  TeamLeaderController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Get events assigned to team leader
  Future<Result<List<EventModel>>> getTeamLeaderEvents(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.teamLeadersMyEvents);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['assignments'] ?? []) as List;
        // Extract events from team leader assignments
        final events = <EventModel>[];
        for (final item in list) {
          final eventData = (item as Map<String, dynamic>)['eventId'];
          if (eventData is Map<String, dynamic>) {
            events.add(EventModel.fromJson(eventData));
          }
        }
        return Success(events);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to fetch team leader events',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch team leader events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get team leader assignment
  Future<Result<TeamLeaderModel>> getTeamLeaderAssignment(
    String userId,
    String eventId,
  ) async {
    try {
      final response = await _api.get(ApiEndpoints.teamLeadersByEvent(eventId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['leaders'] ?? []) as List;
        if (list.isNotEmpty) {
          final tl = TeamLeaderModel.fromJson(
            list.first as Map<String, dynamic>,
          );
          return Success(tl);
        }
        return Error(NotFoundException(message: 'Assignment not found'));
      }

      return Error(AppException(message: 'Failed to fetch assignment'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch assignment',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch assignment: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update assignment status
  Future<Result<TeamLeaderModel>> updateAssignmentStatus({
    required String assignmentId,
    required String newStatus,
  }) async {
    try {
      final response = await _api.patch(
        ApiEndpoints.teamLeaderById(assignmentId),
        data: {'status': newStatus},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final tl = TeamLeaderModel.fromJson(
          response.data['data']['assignment'] as Map<String, dynamic>,
        );
        return Success(tl);
      }

      return Error(AppException(message: 'Failed to update status'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to update status',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update assignment status: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get active assignments count
  Future<Result<int>> getActiveAssignmentsCount(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.teamLeadersMyEvents);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['assignments'] ?? []) as List;
        return Success(list.length);
      }

      return Success(0);
    } catch (_) {
      return Success(0);
    }
  }

  /// Get completed assignments count
  Future<Result<int>> getCompletedAssignmentsCount(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.teamLeadersMyEvents);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['assignments'] ?? []) as List;
        return Success(list.where((a) => a['status'] == 'completed').length);
      }

      return Success(0);
    } catch (_) {
      return Success(0);
    }
  }

  /// Mark user attendance for event
  Future<Result<Map<String, dynamic>>> markAttendance({
    required String userId,
    required String eventId,
    required bool present,
    String? notes,
  }) async {
    try {
      // This uses a custom endpoint — may need backend extension
      final response = await _api.post(
        '${ApiEndpoints.teamLeaders}/attendance',
        data: {
          'userId': userId,
          'eventId': eventId,
          'present': present,
          'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(response.data['data'] as Map<String, dynamic>);
      }

      return Error(AppException(message: 'Failed to mark attendance'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to mark attendance',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to mark attendance: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get attendance for event
  Future<Result<List<Map<String, dynamic>>>> getEventAttendance(
    String eventId,
  ) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.teamLeaders}/attendance',
        queryParameters: {'eventId': eventId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List;
        return Success(list.map((e) => e as Map<String, dynamic>).toList());
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch attendance',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch event attendance: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get user's attendance history
  Future<Result<List<Map<String, dynamic>>>> getUserAttendance(
    String userId,
  ) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.teamLeaders}/attendance',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List;
        return Success(list.map((e) => e as Map<String, dynamic>).toList());
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch attendance',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch user attendance: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
