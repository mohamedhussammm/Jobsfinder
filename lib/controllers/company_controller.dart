import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/company_model.dart';
import '../models/event_model.dart';
import '../models/application_model.dart';
import '../core/utils/result.dart';

/// Company profile provider
final companyProfileProvider = FutureProvider.autoDispose
    .family<CompanyModel, String>((ref, userId) async {
      final controller = ref.watch(companyControllerProvider);
      final result = await controller.getCompanyByUserId(userId);
      return result.when(success: (company) => company, error: (e) => throw e);
    });

/// Company events provider
final companyEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, String>((ref, companyId) async {
      final controller = ref.watch(companyControllerProvider);
      final result = await controller.fetchCompanyEvents(companyId);
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Company controller provider
final companyControllerProvider = Provider((ref) => CompanyController(ref));

class CompanyController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  CompanyController(this.ref);

  /// Get company by user ID
  Future<Result<CompanyModel>> getCompanyByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('user_id', userId)
          .single();

      final company = CompanyModel.fromJson(response);
      return Success(company);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Error(
          NotFoundException(
            message: 'Company profile not found',
            code: 'COMPANY_NOT_FOUND',
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
          message: 'Failed to fetch company: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get company by ID
  Future<Result<CompanyModel>> getCompanyById(String companyId) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('id', companyId)
          .single();

      final company = CompanyModel.fromJson(response);
      return Success(company);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Error(
          NotFoundException(
            message: 'Company not found',
            code: 'COMPANY_NOT_FOUND',
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
          message: 'Failed to fetch company: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Create company profile
  Future<Result<CompanyModel>> createCompanyProfile({
    required String userId,
    required String name,
    String? description,
    String? logoPath,
  }) async {
    try {
      final companyData = {
        'user_id': userId,
        'name': name,
        'description': description,
        'logo_path': logoPath,
        'verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('companies')
          .insert(companyData)
          .select()
          .single();

      final company = CompanyModel.fromJson(response);
      return Success(company);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to create company profile: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update company profile
  Future<Result<CompanyModel>> updateCompanyProfile({
    required String companyId,
    String? name,
    String? description,
    String? logoPath,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (logoPath != null) 'logo_path': logoPath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('companies')
          .update(updateData)
          .eq('id', companyId)
          .select()
          .single();

      final company = CompanyModel.fromJson(response);
      return Success(company);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update company profile: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch company's own events
  Future<Result<List<EventModel>>> fetchCompanyEvents(
    String companyId, {
    String? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('company_id', companyId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);

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
          message: 'Failed to fetch company events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Create event request (pending status)
  Future<Result<EventModel>> createEventRequest({
    required String companyId,
    required String title,
    required String? description,
    required LocationData? location,
    required DateTime startTime,
    required DateTime endTime,
    required int? capacity,
    required String? imagePath,
  }) async {
    try {
      // Validate
      if (title.isEmpty) {
        return Error(ValidationException(message: 'Event title is required'));
      }

      if (endTime.isBefore(startTime)) {
        return Error(
          ValidationException(message: 'End time must be after start time'),
        );
      }

      final eventData = {
        'company_id': companyId,
        'title': title,
        'description': description,
        'location': location?.toJson(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'capacity': capacity,
        'image_path': imagePath,
        'status': 'pending', // Companies create pending events
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.events)
          .insert(eventData)
          .select()
          .single();

      final event = EventModel.fromJson(response);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to create event request: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update pending event
  Future<Result<EventModel>> updatePendingEvent({
    required String eventId,
    String? title,
    String? description,
    LocationData? location,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    String? imagePath,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (location != null) 'location': location.toJson(),
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
        if (capacity != null) 'capacity': capacity,
        if (imagePath != null) 'image_path': imagePath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.events)
          .update(updateData)
          .eq('id', eventId)
          .eq('status', 'pending') // Only update if still pending
          .select()
          .single();

      final event = EventModel.fromJson(response);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to update event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch applicants for company's events
  Future<Result<List<ApplicationModel>>> fetchEventApplicants({
    required String eventId,
    String? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseTables.applications)
          .select()
          .eq('event_id', eventId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
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
          message: 'Failed to fetch applicants: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event statistics for company
  Future<Result<Map<String, int>>> getEventStatistics(String companyId) async {
    try {
      final statuses = ['pending', 'published', 'completed', 'cancelled'];
      final counts = <String, int>{};

      for (final status in statuses) {
        final response = await _supabase
            .from(SupabaseTables.events)
            .select('id')
            .eq('company_id', companyId)
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
