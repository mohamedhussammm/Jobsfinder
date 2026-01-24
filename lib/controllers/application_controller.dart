import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/application_model.dart';
import '../core/utils/result.dart';

/// User applications provider
final userApplicationsProvider = FutureProvider.autoDispose
    .family<List<ApplicationModel>, String>((ref, userId) async {
      final controller = ref.watch(applicationControllerProvider);
      final result = await controller.fetchUserApplications(userId);
      return result.when(success: (apps) => apps, error: (e) => throw e);
    });

/// Event applications provider (for team leaders)
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
  final SupabaseClient _supabase = Supabase.instance.client;

  ApplicationController(this.ref);

  /// User applies to an event
  Future<Result<ApplicationModel>> applyToEvent({
    required String userId,
    required String eventId,
    String? cvPath,
    String? coverLetter,
  }) async {
    try {
      // Check if user already applied
      final existing = await _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId);

      if (existing.isNotEmpty) {
        throw ValidationException(
          message: 'You have already applied to this event',
          code: 'DUPLICATE_APPLICATION',
        );
      }

      final applicationData = {
        'user_id': userId,
        'event_id': eventId,
        'status': 'applied',
        'cv_path': cvPath,
        'cover_letter': coverLetter,
        'applied_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.applications)
          .insert(applicationData)
          .select()
          .single();

      final application = ApplicationModel.fromJson(response);
      return Success(application);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(SupabaseTables.applications)
          .delete()
          .eq('id', applicationId);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to withdraw application: $e',
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
      final response = await _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      final applications = (response as List)
          .map(
            (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(applications);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      var query = _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('event_id', eventId);

      if (filterStatus != null) {
        query = query.eq('status', filterStatus);
      }

      final response = await query.order('applied_at', ascending: false);

      final applications = (response as List)
          .map(
            (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(applications);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final validStatuses = [
        'applied',
        'shortlisted',
        'invited',
        'accepted',
        'declined',
        'rejected',
      ];
      if (!validStatuses.contains(newStatus)) {
        throw ValidationException(message: 'Invalid status');
      }

      final response = await _supabase
          .from(SupabaseTables.applications)
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId)
          .select()
          .single();

      final application = ApplicationModel.fromJson(response);
      return Success(application);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update application status: $e',
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
      final response = await _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('id', applicationId)
          .single();

      final application = ApplicationModel.fromJson(response);
      return Success(application);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Error(
          NotFoundException(
            message: 'Application not found',
            code: 'APPLICATION_NOT_FOUND',
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
      int offset = page * pageSize;

      final response = await _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('status', status)
          .order('applied_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      final applications = (response as List)
          .map(
            (json) => ApplicationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(applications);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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

  /// Count applications per status
  Future<Result<Map<String, int>>> countApplicationsByStatus() async {
    try {
      final statuses = [
        'applied',
        'shortlisted',
        'invited',
        'accepted',
        'declined',
        'rejected',
      ];
      final counts = <String, int>{};

      for (final status in statuses) {
        final response = await _supabase
            .from(SupabaseTables.applications)
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
          message: 'Failed to count applications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
