import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';

/// Stub provider for pending events in admin dashboard
/// TODO: Implement proper admin event filtering
final pendingEventsAdminProvider = FutureProvider<List<EventModel>>((
  ref,
) async {
  // Placeholder - return empty list until proper implementation
  return [];
});

/// Stub provider for active assignments count (team leader)
/// TODO: Implement proper assignment counting
final activeAssignmentsCountProvider = FutureProvider<int>((ref) async {
  // Placeholder - return 0 until proper implementation
  return 0;
});

/// Stub provider for completed assignments count (team leader)
/// TODO: Implement proper assignment counting
final completedAssignmentsCountProvider = FutureProvider<int>((ref) async {
  // Placeholder - return 0 until proper implementation
  return 0;
});
