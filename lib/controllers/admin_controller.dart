import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/user_model.dart';
import '../models/team_leader_model.dart';
import '../models/company_model.dart';
import '../models/audit_log_model.dart';
import '../models/event_model.dart';
import '../core/utils/result.dart';

/// Admin controller provider
final adminControllerProvider = Provider((ref) => AdminController(ref));

/// Pending events admin view provider
final pendingEventsAdminProvider = FutureProvider.autoDispose((ref) async {
  final controller = ref.watch(adminControllerProvider);
  final result = await controller.fetchPendingEventRequests();
  return result.when(success: (events) => events, error: (e) => throw e);
});

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
      return result.when(success: (leaders) => leaders, error: (e) => throw e);
    });

/// Audit logs provider
final auditLogsProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, int>((ref, page) async {
      final controller = ref.watch(adminControllerProvider);
      final result = await controller.fetchAuditLogs(page: page);
      return result.when(success: (logs) => logs, error: (e) => throw e);
    });

class AdminController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const int pageSize = 10;

  AdminController(this.ref);

  /// Fetch pending event requests
  Future<Result<List<EventModel>>> fetchPendingEventRequests({
    int page = 0,
  }) async {
    try {
      int offset = page * pageSize;

      final response = await _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .range(offset, offset + pageSize - 1);

      final events = (response as List)
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(events);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      int offset = page * pageSize;

      var query = _supabase.from(SupabaseTables.users).select();

      if (roleFilter != null) {
        query = query.eq('role', roleFilter);
      }

      // Client-side search filtering since Supabase doesn't have full-text search on free tier
      final response = await query.order('created_at', ascending: false);

      List users = response;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerSearch = searchQuery.toLowerCase();
        users = users.where((u) {
          final json = u as Map<String, dynamic>;
          final name = (json['name'] ?? '').toString().toLowerCase();
          final email = (json['email'] ?? '').toString().toLowerCase();
          return name.contains(lowerSearch) || email.contains(lowerSearch);
        }).toList();
      }

      // Manual pagination
      final paginatedUsers = users.skip(offset).take(pageSize).toList();

      final mapped = (paginatedUsers)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(mapped);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.users)
          .update({
            'deleted_at': block ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      final user = UserModel.fromJson(response);

      // Log audit
      await _logAuditAction(
        action: block ? 'user_blocked' : 'user_unblocked',
        targetTable: SupabaseTables.users,
        targetId: userId,
      );

      return Success(user);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.users)
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      final user = UserModel.fromJson(response);

      // Log audit
      await _logAuditAction(
        action: 'user_role_update',
        targetTable: SupabaseTables.users,
        targetId: userId,
        newValues: {'role': newRole},
      );

      return Success(user);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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

  /// Fetch all companies (for dropdowns)
  Future<Result<List<CompanyModel>>> fetchAllCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('name', ascending: true);

      final companies = (response as List)
          .map((json) => CompanyModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(companies);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch companies: $e',
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
      // Check if already assigned
      final existing = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId);

      if (existing.isNotEmpty) {
        throw ValidationException(
          message: 'This team leader is already assigned to this event',
          code: 'DUPLICATE_ASSIGNMENT',
        );
      }

      final adminId = _supabase.auth.currentUser?.id;

      final leaderData = {
        'user_id': userId,
        'event_id': eventId,
        'assigned_by': adminId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .insert(leaderData)
          .select()
          .single();

      final leader = TeamLeaderModel.fromJson(response);

      // Log audit
      await _logAuditAction(
        action: 'team_leader_assigned',
        targetTable: SupabaseTables.teamLeaders,
        targetId: leader.id,
        newValues: leader.toJson(),
      );

      return Success(leader);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.teamLeaders)
          .select()
          .eq('event_id', eventId)
          .neq('status', 'removed');

      final leaders = (response as List)
          .map((json) => TeamLeaderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(leaders);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(SupabaseTables.teamLeaders)
          .update({
            'status': 'removed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', teamLeaderId);

      // Log audit
      await _logAuditAction(
        action: 'team_leader_removed',
        targetTable: SupabaseTables.teamLeaders,
        targetId: teamLeaderId,
      );

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
  Future<Result<List<AuditLogModel>>> fetchAuditLogs({
    int page = 0,
    String? adminUserId,
    String? targetTable,
  }) async {
    try {
      int offset = page * pageSize;

      var query = _supabase.from(SupabaseTables.auditLogs).select();

      final response = await query.order('created_at', ascending: false);

      List filteredResponse = response;

      if (adminUserId != null) {
        filteredResponse = filteredResponse.where((log) {
          final json = log as Map<String, dynamic>;
          return json['admin_user_id'] == adminUserId;
        }).toList();
      }

      if (targetTable != null) {
        filteredResponse = filteredResponse.where((log) {
          final json = log as Map<String, dynamic>;
          return json['target_table'] == targetTable;
        }).toList();
      }

      // Manual pagination
      final paginatedLogs = filteredResponse
          .skip(offset)
          .take(pageSize)
          .toList();

      final logs = (paginatedLogs)
          .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(logs);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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

  /// Log admin action to audit_logs
  Future<void> _logAuditAction({
    required String action,
    String? targetTable,
    String? targetId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase.from(SupabaseTables.auditLogs).insert({
        'admin_user_id': adminId,
        'action': action,
        'target_table': targetTable,
        'target_id': targetId,
        'old_values': oldValues,
        'new_values': newValues,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log silently - audit failure shouldn't block operations
      print('Failed to log audit: $e');
    }
  }

  /// Get user count by role
  Future<Result<Map<String, int>>> getUserCountByRole() async {
    try {
      final roles = ['normal', 'company', 'team_leader', 'admin'];
      final counts = <String, int>{};

      for (final role in roles) {
        final response = await _supabase
            .from(SupabaseTables.users)
            .select('id')
            .eq('role', role);

        counts[role] = response.length;
      }

      return Success(counts);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to count users by role: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event statistics
  Future<Result<Map<String, int>>> getEventStatistics() async {
    try {
      final statuses = [
        'draft',
        'pending',
        'published',
        'completed',
        'cancelled',
      ];
      final counts = <String, int>{};

      for (final status in statuses) {
        final response = await _supabase
            .from(SupabaseTables.events)
            .select('id')
            .eq('status', status);

        counts[status] = response.length;
      }

      return Success(counts);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
}
