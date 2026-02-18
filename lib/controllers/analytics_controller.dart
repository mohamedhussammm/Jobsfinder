import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/analytics_model.dart';
import '../core/utils/result.dart';

/// Analytics KPI provider
final analyticsKPIProvider = FutureProvider.autoDispose((ref) async {
  final controller = ref.watch(analyticsControllerProvider);
  final result = await controller.getAnalyticsKPI();
  return result.when(success: (kpi) => kpi, error: (e) => throw e);
});

/// Analytics controller provider
final analyticsControllerProvider = Provider((ref) => AnalyticsController(ref));

class AnalyticsController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  AnalyticsController(this.ref);

  /// Get main KPI metrics
  Future<Result<AnalyticsKPI>> getAnalyticsKPI() async {
    try {
      // Get user counts
      final users = await _supabase.from(SupabaseTables.users).select('id');
      final teamLeaders = users.where((u) => u['role'] == 'team_leader').length;

      // Get event stats
      final events = await _supabase
          .from(SupabaseTables.events)
          .select('id, status');
      final totalEvents = events.length;
      final publishedEvents = events
          .where((e) => e['status'] == 'published')
          .length;

      // Get application stats
      final applications = await _supabase
          .from(SupabaseTables.applications)
          .select('id, status');
      final totalApplications = applications.length;
      final acceptedApplications = applications
          .where((a) => a['status'] == 'accepted')
          .length;

      // Get ratings
      final ratings = await _supabase
          .from(SupabaseTables.ratings)
          .select('score');
      double avgRating = 0;
      if (ratings.isNotEmpty) {
        final totalScore = ratings.fold<int>(
          0,
          (sum, r) => sum + (r['score'] as int),
        );
        avgRating = totalScore / ratings.length;
      }

      final kpi = AnalyticsKPI(
        totalUsers: users.length,
        totalCompanies: users.where((u) => u['role'] == 'company').length,
        totalTeamLeaders: teamLeaders,
        totalEvents: totalEvents,
        pendingEventRequests: events
            .where((e) => e['status'] == 'pending')
            .length,
        publishedEvents: publishedEvents,
        activeEvents: publishedEvents,
        totalApplications: totalApplications,
        acceptedApplications: acceptedApplications,
        rejectedApplications: 0,
        averageRating: avgRating,
        ratingsCount: ratings.length,
        lastUpdated: DateTime.now(),
      );

      return Success(kpi);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get analytics KPI: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get monthly statistics (last 12 months)
  Future<Result<List<MonthlyStats>>> getMonthlyStatistics({
    int months = 12,
  }) async {
    try {
      final stats = <MonthlyStats>[];
      final now = DateTime.now();

      for (var i = months - 1; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = i == 0
            ? now
            : DateTime(now.year, now.month - i + 1, 0);

        // Get events created in month
        final eventsData = await _supabase
            .from(SupabaseTables.events)
            .select('id')
            .gte('created_at', monthStart.toIso8601String())
            .lte('created_at', monthEnd.toIso8601String());

        // Get applications in month
        final applicationsData = await _supabase
            .from(SupabaseTables.applications)
            .select('id')
            .gte('applied_at', monthStart.toIso8601String())
            .lte('applied_at', monthEnd.toIso8601String());

        // Get completed events in month
        final completedData = await _supabase
            .from(SupabaseTables.events)
            .select('id')
            .eq('status', 'completed')
            .gte('updated_at', monthStart.toIso8601String())
            .lte('updated_at', monthEnd.toIso8601String());

        final monthStr =
            '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

        stats.add(
          MonthlyStats(
            month: monthStr,
            eventsCreated: eventsData.length,
            applicationsReceived: applicationsData.length,
            eventsCompleted: completedData.length,
          ),
        );
      }

      return Success(stats);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get monthly statistics: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get role distribution
  Future<Result<RoleDistribution>> getRoleDistribution() async {
    try {
      final users = await _supabase.from(SupabaseTables.users).select('role');

      final distribution = RoleDistribution(
        normalUsers: users.where((u) => u['role'] == 'normal').length,
        companies: users.where((u) => u['role'] == 'company').length,
        teamLeaders: users.where((u) => u['role'] == 'team_leader').length,
        admins: users.where((u) => u['role'] == 'admin').length,
      );

      return Success(distribution);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get role distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get top 10 events by application count
  Future<Result<List<TopEvent>>> getTopEvents({int limit = 10}) async {
    try {
      // Get all events
      final events = await _supabase
          .from(SupabaseTables.events)
          .select('id, title');

      // Get application counts
      final appCounts = <String, int>{};
      for (final event in events) {
        final eventId = event['id'] as String;
        final apps = await _supabase
            .from(SupabaseTables.applications)
            .select('id')
            .eq('event_id', eventId);
        appCounts[eventId] = apps.length;
      }

      // Sort and take top limit
      final sorted = events
          .map((e) => MapEntry(e, appCounts[e['id']] ?? 0))
          .toList();
      sorted.sort((a, b) => b.value.compareTo(a.value));

      final topEvents = sorted
          .take(limit)
          .map(
            (entry) => TopEvent(
              eventId: entry.key['id'] as String,
              eventTitle: entry.key['title'] as String,
              applicationCount: entry.value,
            ),
          )
          .toList();

      return Success(topEvents);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get top events: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get application status distribution
  Future<Result<Map<String, int>>> getApplicationStatusDistribution() async {
    try {
      final statuses = [
        'applied',
        'shortlisted',
        'invited',
        'accepted',
        'declined',
        'rejected',
      ];
      final distribution = <String, int>{};

      for (final status in statuses) {
        final applications = await _supabase
            .from(SupabaseTables.applications)
            .select('id')
            .eq('status', status);
        distribution[status] = applications.length;
      }

      return Success(distribution);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get application distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get event status distribution
  Future<Result<Map<String, int>>> getEventStatusDistribution() async {
    try {
      final statuses = [
        'draft',
        'pending',
        'published',
        'completed',
        'cancelled',
      ];
      final distribution = <String, int>{};

      for (final status in statuses) {
        final events = await _supabase
            .from(SupabaseTables.events)
            .select('id')
            .eq('status', status);
        distribution[status] = events.length;
      }

      return Success(distribution);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get event distribution: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
