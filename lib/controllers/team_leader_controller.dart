import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/team_leader_model.dart';
import '../models/event_model.dart';
import '../core/utils/result.dart';

/// Team leader's events provider
final teamLeaderEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, String>((ref, teamLeaderId) async {
      final controller = ref.watch(teamLeaderControllerProvider);
      final result = await controller.getTeamLeaderEvents(teamLeaderId);
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Team leader controller provider
final teamLeaderControllerProvider = Provider(
  (ref) => TeamLeaderController(ref),
);

class TeamLeaderController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  TeamLeaderController(this.ref);

  /// Get events assigned to team leader
  Future<Result<List<EventModel>>> getTeamLeaderEvents(String userId) async {
    try {
      // Get team leader assignments
      final assignments = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select('event_id')
          .eq('user_id', userId)
          .neq('status', 'removed');

      if (assignments.isEmpty) {
        return Success([]);
      }

      // Get event details for each assignment
      final eventIds = (assignments as List)
          .map((a) => a['event_id'] as String)
          .toList();

      final events = <EventModel>[];
      for (final eventId in eventIds) {
        final eventResponse = await _supabase
            .from(SupabaseTables.events)
            .select()
            .eq('id', eventId)
            .single();

        events.add(EventModel.fromJson(eventResponse as Map<String, dynamic>));
      }

      return Success(events);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .single();

      final assignment = TeamLeaderModel.fromJson(
        response as Map<String, dynamic>,
      );
      return Success(assignment);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Error(
          NotFoundException(
            message: 'Team leader assignment not found',
            code: 'ASSIGNMENT_NOT_FOUND',
            originalError: e,
          ),
        );
      }
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final validStatuses = ['assigned', 'active', 'completed', 'removed'];
      if (!validStatuses.contains(newStatus)) {
        throw ValidationException(message: 'Invalid status');
      }

      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId)
          .select()
          .single();

      final assignment = TeamLeaderModel.fromJson(
        response as Map<String, dynamic>,
      );
      return Success(assignment);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active');

      return Success(response.length);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to count active assignments: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get completed assignments count
  Future<Result<int>> getCompletedAssignmentsCount(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'completed');

      return Success(response.length);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to count completed assignments: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Mark user attendance for event
  Future<Result<void>> markAttendance({
    required String userId,
    required String eventId,
    required bool present,
    String? notes,
  }) async {
    try {
      // Check if attendance record exists
      final existing = await _supabase
          .from('attendance') // Assuming attendance table exists
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId);

      if (existing.isNotEmpty) {
        // Update existing
        await _supabase
            .from('attendance')
            .update({
              'present': present,
              'notes': notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('event_id', eventId);
      } else {
        // Create new
        await _supabase.from('attendance').insert({
          'user_id': userId,
          'event_id': eventId,
          'present': present,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return Success(response as List<Map<String, dynamic>>);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch attendance: $e',
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
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return Success(response as List<Map<String, dynamic>>);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
