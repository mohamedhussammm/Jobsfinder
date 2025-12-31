import 'package:json_annotation/json_annotation.dart';

part 'analytics_model.g.dart';

/// Analytics KPI model - dashboard metrics
@JsonSerializable()
class AnalyticsKPI {
  final int totalUsers;
  final int totalCompanies;
  final int totalTeamLeaders;
  final int totalEvents;
  final int pendingEventRequests;
  final int publishedEvents;
  final int activeEvents;
  final int totalApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final double averageRating;
  final int ratingsCount;
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
  int get declinedApplications => totalApplications - acceptedApplications - rejectedApplications;
  double get acceptanceRate {
    if (totalApplications == 0) return 0;
    return (acceptedApplications / totalApplications) * 100;
  }

  factory AnalyticsKPI.fromJson(Map<String, dynamic> json) => _$AnalyticsKPIFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyticsKPIToJson(this);
}

/// Monthly statistics for charts
@JsonSerializable()
class MonthlyStats {
  final String month; // Format: "2025-01"
  final int eventsCreated;
  final int applicationsReceived;
  final int eventsCompleted;

  MonthlyStats({
    required this.month,
    required this.eventsCreated,
    required this.applicationsReceived,
    required this.eventsCompleted,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) => _$MonthlyStatsFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyStatsToJson(this);
}

/// Top events data for charts
@JsonSerializable()
class TopEvent {
  final String eventId;
  final String eventTitle;
  final int applicationCount;

  TopEvent({
    required this.eventId,
    required this.eventTitle,
    required this.applicationCount,
  });

  factory TopEvent.fromJson(Map<String, dynamic> json) => _$TopEventFromJson(json);
  Map<String, dynamic> toJson() => _$TopEventToJson(this);
}

/// User role distribution
@JsonSerializable()
class RoleDistribution {
  final int normalUsers;
  final int companies;
  final int teamLeaders;
  final int admins;

  RoleDistribution({
    required this.normalUsers,
    required this.companies,
    required this.teamLeaders,
    required this.admins,
  });

  int get total => normalUsers + companies + teamLeaders + admins;

  factory RoleDistribution.fromJson(Map<String, dynamic> json) => _$RoleDistributionFromJson(json);
  Map<String, dynamic> toJson() => _$RoleDistributionToJson(this);
}
