import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import 'event_controller.dart';
import 'team_leader_controller.dart';
import 'auth_controller.dart';

/// Pending events for admin dashboard (real implementation)
final pendingEventsAdminProvider = FutureProvider<List<EventModel>>((
  ref,
) async {
  final controller = ref.watch(eventControllerProvider);
  final result = await controller.fetchPendingEventRequests();
  return result.when(success: (events) => events, error: (e) => throw e);
});

/// Active assignments count for team leader (real implementation)
final activeAssignmentsCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;

  final controller = ref.watch(teamLeaderControllerProvider);
  final result = await controller.getActiveAssignmentsCount(currentUser.id);
  return result.when(success: (count) => count, error: (_) => 0);
});

/// Completed assignments count for team leader (real implementation)
final completedAssignmentsCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;

  final controller = ref.watch(teamLeaderControllerProvider);
  final result = await controller.getCompletedAssignmentsCount(currentUser.id);
  return result.when(success: (count) => count, error: (_) => 0);
});
