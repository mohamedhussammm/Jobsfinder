import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/event_model.dart';
import '../core/utils/result.dart';

/// Published events provider (for homepage)
final publishedEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, int>((ref, page) async {
      final controller = ref.watch(eventControllerProvider);
      final result = await controller.fetchPublishedEvents(page: page);
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Event details provider
final eventDetailsProvider = FutureProvider.autoDispose
    .family<EventModel, String>((ref, eventId) async {
      final controller = ref.watch(eventControllerProvider);
      final result = await controller.getEventById(eventId);
      return result.when(success: (event) => event, error: (e) => throw e);
    });

/// Event controller provider
final eventControllerProvider = Provider((ref) => EventController(ref));

class EventController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const int pageSize = 10;

  EventController(this.ref);

  /// Fetch published events (homepage, with pagination)
  Future<Result<List<EventModel>>> fetchPublishedEvents({
    int page = 0,
    String? searchQuery,
    List<String>? filters,
  }) async {
    try {
      int offset = page * pageSize;

      var query = _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('status', 'published')
          .order('start_time', ascending: true)
          .range(offset, offset + pageSize - 1);

      final response = await query;

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
          message: 'Failed to fetch published events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event by ID
  Future<Result<EventModel>> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('id', eventId)
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Error(
          NotFoundException(
            message: 'Event not found',
            code: 'EVENT_NOT_FOUND',
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
          message: 'Failed to fetch event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Company creates event request (status = pending)
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
        'status': 'pending', // Always pending initially
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.events)
          .insert(eventData)
          .select()
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to create event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch company's own events
  Future<Result<List<EventModel>>> fetchCompanyEvents(
    String companyId, {
    int page = 0,
  }) async {
    try {
      int offset = page * pageSize;

      final response = await _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
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
          message: 'Failed to fetch company events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch pending event requests (admin only)
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

  /// Admin approves/publishes event
  Future<Result<EventModel>> approveEvent(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.events)
          .update({
            'status': 'published',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to approve event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Admin rejects event
  Future<Result<EventModel>> rejectEvent(
    String eventId, {
    String? reason,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.events)
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to reject event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update event details (admin or company)
  Future<Result<EventModel>> updateEvent({
    required String eventId,
    String? title,
    String? description,
    LocationData? location,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    String? imagePath,
    String? status,
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
        if (status != null) 'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.events)
          .update(updateData)
          .eq('id', eventId)
          .select()
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
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

  /// Search events
  Future<Result<List<EventModel>>> searchEvents(String query) async {
    try {
      // Client-side filtering since Supabase doesn't support full-text search on free tier
      final response = await _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('status', 'published')
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .where(
            (event) => event.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      return Success(events);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Search failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Admin deletes event
  Future<Result<void>> deleteEvent(String eventId) async {
    try {
      await _supabase.from(SupabaseTables.events).delete().eq('id', eventId);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to delete event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Admin creates event (published directly)
  Future<Result<EventModel>> adminCreateEvent({
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
        'status': 'published', // Admin events are published immediately
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.events)
          .insert(eventData)
          .select()
          .single();

      final event = EventModel.fromJson(response as Map<String, dynamic>);
      return Success(event);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to create admin event: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
