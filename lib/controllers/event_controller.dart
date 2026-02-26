import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';
import '../core/utils/result.dart';
import 'admin_controller.dart';

/// Published events provider (for homepage)
final publishedEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, int>((ref, page) async {
      final controller = ref.watch(eventControllerProvider);
      final result = await controller.fetchPublishedEvents(page: page);
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Pending events provider (for admin dashboard)
final pendingEventsAdminProvider = FutureProvider.autoDispose<List<EventModel>>(
  (ref) async {
    final adminController = ref.watch(adminControllerProvider);
    final result = await adminController.fetchPendingEventRequests();
    return result.when(success: (events) => events, error: (e) => throw e);
  },
);

/// Published events filtered by category
final publishedEventsByCategoryProvider = FutureProvider.autoDispose
    .family<List<EventModel>, String?>((ref, categoryId) async {
      final controller = ref.watch(eventControllerProvider);
      final result = await controller.fetchPublishedEvents(
        categoryId: categoryId,
      );
      return result.when(success: (events) => events, error: (e) => throw e);
    });

/// Categories provider
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((
  ref,
) async {
  final controller = ref.watch(eventControllerProvider);
  final result = await controller.fetchCategories();
  return result.when(success: (cats) => cats, error: (e) => throw e);
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
  static const int pageSize = 10;

  EventController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Fetch published events (with pagination and optional category filter)
  Future<Result<List<EventModel>>> fetchPublishedEvents({
    int page = 0,
    String? searchQuery,
    List<String>? filters,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': 'published',
        'page': page + 1, // Backend uses 1-based pages
        'limit': pageSize,
      };

      if (categoryId != null) queryParams['category'] = categoryId;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _api.get(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        // Backend returns { events: [...], pagination: {...} }
        final List list;
        if (responseData is List) {
          list = responseData;
        } else if (responseData is Map && responseData['events'] != null) {
          list = responseData['events'] as List;
        } else {
          list = [];
        }
        final events = list
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(events);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch events',
          originalError: e,
        ),
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

  /// Fetch all categories
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _api.get(ApiEndpoints.categories);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['categories'] ?? []) as List;
        final categories = list
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(categories);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch categories',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch categories: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Admin creates and publishes an event directly
  Future<Result<EventModel>> adminCreateEvent({
    required String companyId,
    required String title,
    String? description,
    LocationData? location,
    required DateTime startTime,
    required DateTime endTime,
    int? capacity,
    String? imagePath,
    String? categoryId,
    double? salary,
    String? requirements,
    String? benefits,
    String? contactEmail,
    String? contactPhone,
    List<String>? tags,
    bool isUrgent = false,
  }) async {
    try {
      if (title.isEmpty) {
        return Error(ValidationException(message: 'Event title is required'));
      }
      if (endTime.isBefore(startTime)) {
        return Error(
          ValidationException(message: 'End time must be after start time'),
        );
      }
      if (companyId.isEmpty) {
        return Error(ValidationException(message: 'Company is required'));
      }

      final eventData = <String, dynamic>{
        'companyId': companyId,
        'title': title,
        'description': description,
        'location': location?.toJson(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'capacity': capacity,
        'imagePath': imagePath,
        'status': 'published',
        'isUrgent': isUrgent,
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        eventData['categoryId'] = categoryId;
      }
      if (salary != null) eventData['salary'] = salary;
      if (requirements != null && requirements.isNotEmpty) {
        eventData['requirements'] = requirements;
      }
      if (benefits != null && benefits.isNotEmpty) {
        eventData['benefits'] = benefits;
      }
      if (contactEmail != null && contactEmail.isNotEmpty) {
        eventData['contactEmail'] = contactEmail;
      }
      if (contactPhone != null && contactPhone.isNotEmpty) {
        eventData['contactPhone'] = contactPhone;
      }
      if (tags != null && tags.isNotEmpty) {
        eventData['tags'] = tags;
      }

      final response = await _api.post(ApiEndpoints.events, data: eventData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(AppException(message: 'Failed to create event'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to create event',
          originalError: e,
        ),
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

  /// Get event by ID
  Future<Result<EventModel>> getEventById(String eventId) async {
    try {
      final response = await _api.get(ApiEndpoints.eventById(eventId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(
        NotFoundException(message: 'Event not found', code: 'EVENT_NOT_FOUND'),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Error(
          NotFoundException(
            message: 'Event not found',
            code: 'EVENT_NOT_FOUND',
            originalError: e,
          ),
        );
      }
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch event',
          originalError: e,
        ),
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
      if (title.isEmpty) {
        return Error(ValidationException(message: 'Event title is required'));
      }

      if (endTime.isBefore(startTime)) {
        return Error(
          ValidationException(message: 'End time must be after start time'),
        );
      }

      final eventData = {
        'companyId': companyId,
        'title': title,
        'description': description,
        'location': location?.toJson(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'capacity': capacity,
        'imagePath': imagePath,
        'status': 'pending',
      };

      final response = await _api.post(ApiEndpoints.events, data: eventData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(AppException(message: 'Failed to create event'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to create event',
          originalError: e,
        ),
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
      final response = await _api.get(
        ApiEndpoints.events,
        queryParameters: {
          'companyId': companyId,
          'page': page + 1,
          'limit': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final List list;
        if (responseData is List) {
          list = responseData;
        } else if (responseData is Map && responseData['events'] != null) {
          list = responseData['events'] as List;
        } else {
          list = [];
        }
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
              e.response?.data?['message'] ?? 'Failed to fetch company events',
          originalError: e,
        ),
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
      final response = await _api.get(
        ApiEndpoints.events,
        queryParameters: {
          'status': 'pending',
          'page': page + 1,
          'limit': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final List list;
        if (responseData is List) {
          list = responseData;
        } else if (responseData is Map && responseData['events'] != null) {
          list = responseData['events'] as List;
        } else {
          list = [];
        }
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

  /// Admin approves/publishes event
  Future<Result<EventModel>> approveEvent(String eventId) async {
    try {
      final response = await _api.patch(ApiEndpoints.approveEvent(eventId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(AppException(message: 'Failed to approve event'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to approve event',
          originalError: e,
        ),
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
      final response = await _api.patch(
        ApiEndpoints.rejectEvent(eventId),
        data: {'rejectionReason': reason},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(AppException(message: 'Failed to reject event'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to reject event',
          originalError: e,
        ),
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
    String? categoryId,
    double? salary,
    String? requirements,
    String? benefits,
    String? contactEmail,
    String? contactPhone,
    List<String>? tags,
    bool? isUrgent,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (location != null) 'location': location.toJson(),
        if (startTime != null) 'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime.toIso8601String(),
        if (capacity != null) 'capacity': capacity,
        if (imagePath != null) 'imagePath': imagePath,
        if (status != null) 'status': status,
        if (categoryId != null) 'categoryId': categoryId,
        if (salary != null) 'salary': salary,
        if (requirements != null) 'requirements': requirements,
        if (benefits != null) 'benefits': benefits,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (tags != null) 'tags': tags,
        if (isUrgent != null) 'isUrgent': isUrgent,
      };

      final response = await _api.put(
        ApiEndpoints.eventById(eventId),
        data: updateData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final event = EventModel.fromJson(
          response.data['data']['event'] as Map<String, dynamic>,
        );
        return Success(event);
      }

      return Error(AppException(message: 'Failed to update event'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to update event',
          originalError: e,
        ),
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
      final response = await _api.get(
        ApiEndpoints.events,
        queryParameters: {'search': query, 'status': 'published'},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final List list;
        if (responseData is List) {
          list = responseData;
        } else if (responseData is Map && responseData['events'] != null) {
          list = responseData['events'] as List;
        } else {
          list = [];
        }
        final events = list
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(events);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Search failed',
          originalError: e,
        ),
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
      await _api.delete(ApiEndpoints.eventById(eventId));
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to delete event',
          originalError: e,
        ),
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
}
