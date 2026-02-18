import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime service provider
final realtimeServiceProvider = Provider((ref) => RealtimeService(ref));

/// Stream provider for realtime notifications
final realtimeNotificationsProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) {
      final service = ref.watch(realtimeServiceProvider);
      return service.subscribeToNotifications(userId);
    });

/// Stream provider for realtime messages
final realtimeMessagesProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) {
      final service = ref.watch(realtimeServiceProvider);
      return service.subscribeToMessages(userId);
    });

/// Stream provider for event status changes
final realtimeEventUpdatesProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
      final service = ref.watch(realtimeServiceProvider);
      return service.subscribeToEventUpdates();
    });

class RealtimeService {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeService(this.ref);

  /// Subscribe to new notifications for a user
  Stream<Map<String, dynamic>> subscribeToNotifications(String userId) {
    final controller = StreamController<Map<String, dynamic>>();

    final channel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            controller.add(payload.newRecord);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Subscribe to new messages for a user
  Stream<Map<String, dynamic>> subscribeToMessages(String userId) {
    final controller = StreamController<Map<String, dynamic>>();

    final channel = _supabase
        .channel('messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            controller.add(payload.newRecord);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Subscribe to event status changes (all events)
  Stream<Map<String, dynamic>> subscribeToEventUpdates() {
    final controller = StreamController<Map<String, dynamic>>();

    final channel = _supabase
        .channel('events:updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            controller.add(payload.newRecord);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Subscribe to application status changes for a user
  Stream<Map<String, dynamic>> subscribeToApplicationUpdates(String userId) {
    final controller = StreamController<Map<String, dynamic>>();

    final channel = _supabase
        .channel('applications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            controller.add(payload.newRecord);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }
}
