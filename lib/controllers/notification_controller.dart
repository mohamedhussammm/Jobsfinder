import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  NotificationController(this.ref);

  /// Fetch user notifications with pagination
  Future<Result<List<NotificationModel>>> fetchUserNotifications(
    String userId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from(SupabaseTables.notifications)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      final notifications = (response as List)
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(notifications);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final response = await _supabase
          .from(SupabaseTables.notifications)
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return Success((response as List).length);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('id', notificationId);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(SupabaseTables.notifications)
          .delete()
          .eq('id', notificationId);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final data = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'related_id': relatedId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseTables.notifications)
          .insert(data)
          .select()
          .single();

      return Success(NotificationModel.fromJson(response));
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
