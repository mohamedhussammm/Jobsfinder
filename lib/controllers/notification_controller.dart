import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/notification_model.dart';
import '../core/utils/result.dart';

/// User notifications provider
final userNotificationsProvider = FutureProvider.autoDispose
    .family<List<NotificationModel>, String>((ref, userId) async {
      final controller = ref.watch(notificationControllerProvider);
      final result = await controller.fetchUserNotifications(userId);
      return result.when(success: (n) => n, error: (e) => throw e);
    });

/// Unread notification count provider
final unreadCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  userId,
) async {
  final controller = ref.watch(notificationControllerProvider);
  final result = await controller.getUnreadCount(userId);
  return result.when(success: (c) => c, error: (e) => throw e);
});

/// Notification controller provider
final notificationControllerProvider = Provider(
  (ref) => NotificationController(ref),
);

class NotificationController {
  final Ref ref;

  NotificationController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Fetch user notifications with pagination
  Future<Result<List<NotificationModel>>> fetchUserNotifications(
    String userId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page + 1, 'limit': pageSize},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['notifications'] ?? []) as List;
        final notifications = list
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(notifications);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch notifications',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch notifications: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get unread notification count
  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final response = await _api.get(ApiEndpoints.notificationsUnreadCount);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final count = (data['count'] as num?)?.toInt() ?? 0;
        return Success(count);
      }

      return Success(0);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to get unread count',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get unread count: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Mark a single notification as read
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _api.patch(ApiEndpoints.notificationById(notificationId));
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to mark notification as read',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to mark notification as read: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Mark all notifications as read for a user
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _api.patch(ApiEndpoints.notificationsReadAll);
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to mark all as read',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to mark all as read: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Delete a notification
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _api.delete(ApiEndpoints.notificationById(notificationId));
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to delete notification',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to delete notification: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Send a notification (typically called from other controllers)
  Future<Result<NotificationModel>> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.notifications,
        data: {
          'userId': userId,
          'type': type,
          'title': title,
          'message': message,
          'relatedId': relatedId,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Success(
          NotificationModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }

      return Error(AppException(message: 'Failed to send notification'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to send notification',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to send notification: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
