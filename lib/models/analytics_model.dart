import 'package:json_annotation/json_annotation.dart';

part 'analytics_model.g.dart';

/// Analytics KPI model - dashboard metrics
@JsonSerializable()
class AnalyticsKPI {
  @JsonKey(name: 'total_users')
  final int totalUsers;

  @JsonKey(name: 'total_companies')
  final int totalCompanies;

  @JsonKey(name: 'total_team_leaders')
  final int totalTeamLeaders;

  @JsonKey(name: 'total_events')
  final int totalEvents;

  @JsonKey(name: 'pending_event_requests')
  final int pendingEventRequests;

  @JsonKey(name: 'published_events')
  final int publishedEvents;

  @JsonKey(name: 'active_events')
  final int activeEvents;

  @JsonKey(name: 'total_applications')
  final int totalApplications;

  @JsonKey(name: 'accepted_applications')
  final int acceptedApplications;

  @JsonKey(name: 'rejected_applications')
  final int rejectedApplications;

  @JsonKey(name: 'average_rating')
  final double averageRating;

  @JsonKey(name: 'ratings_count')
  final int ratingsCount;

  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;

  AnalyticsKPI({
    required this.totalUsers,
    required this.totalCompanies,
    required this.totalTeamLeaders,
    required this.totalEvents,
    required this.pendingEventRequests,
    required this.publishedEvents,
    required this.activeEvents,
    required this.totalApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.averageRating,
    required this.ratingsCount,
    required this.lastUpdated,
  });

  // Calculated properties
  int get declinedApplications =>
      totalApplications - acceptedApplications - rejectedApplications;
  double get acceptanceRate {
    if (totalApplications == 0) return 0;
    return (acceptedApplications / totalApplications) * 100;
  }

  factory AnalyticsKPI.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsKPIFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyticsKPIToJson(this);
}

/// Monthly statistics for charts
@JsonSerializable()
class MonthlyStats {
  @JsonKey(name: 'month')
  final String month; // Format: "2025-01"

  @JsonKey(name: 'events_created')
  final int eventsCreated;

  @JsonKey(name: 'applications_received')
  final int applicationsReceived;

  @JsonKey(name: 'events_completed')
  final int eventsCompleted;

  MonthlyStats({
    required this.month,
    required this.eventsCreated,
    required this.applicationsReceived,
    required this.eventsCompleted,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatsFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyStatsToJson(this);
}

/// Top events data for charts
@JsonSerializable()
class TopEvent {
  @JsonKey(name: 'event_id')
  final String eventId;

  @JsonKey(name: 'event_title')
  final String eventTitle;

  @JsonKey(name: 'application_count')
  final int applicationCount;

  TopEvent({
    required this.eventId,
    required this.eventTitle,
    required this.applicationCount,
  });

  factory TopEvent.fromJson(Map<String, dynamic> json) =>
      _$TopEventFromJson(json);
  Map<String, dynamic> toJson() => _$TopEventToJson(this);
}

/// User role distribution
@JsonSerializable()
class RoleDistribution {
  @JsonKey(name: 'normal_users')
  final int normalUsers;

  @JsonKey(name: 'companies')
  final int companies;

  @JsonKey(name: 'team_leaders')
  final int teamLeaders;

  @JsonKey(name: 'admins')
  final int admins;

  RoleDistribution({
    required this.normalUsers,
    required this.companies,
    required this.teamLeaders,
    required this.admins,
  });

  int get total => normalUsers + companies + teamLeaders + admins;

  factory RoleDistribution.fromJson(Map<String, dynamic> json) =>
      _$RoleDistributionFromJson(json);
  Map<String, dynamic> toJson() => _$RoleDistributionToJson(this);
}
