// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsKPI _$AnalyticsKPIFromJson(Map<String, dynamic> json) => AnalyticsKPI(
      totalUsers: (json['total_users'] as num).toInt(),
      totalCompanies: (json['total_companies'] as num).toInt(),
      totalTeamLeaders: (json['total_team_leaders'] as num).toInt(),
      totalEvents: (json['total_events'] as num).toInt(),
      pendingEventRequests: (json['pending_event_requests'] as num).toInt(),
      publishedEvents: (json['published_events'] as num).toInt(),
      activeEvents: (json['active_events'] as num).toInt(),
      totalApplications: (json['total_applications'] as num).toInt(),
      acceptedApplications: (json['accepted_applications'] as num).toInt(),
      rejectedApplications: (json['rejected_applications'] as num).toInt(),
      averageRating: (json['average_rating'] as num).toDouble(),
      ratingsCount: (json['ratings_count'] as num).toInt(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$AnalyticsKPIToJson(AnalyticsKPI instance) =>
    <String, dynamic>{
      'total_users': instance.totalUsers,
      'total_companies': instance.totalCompanies,
      'total_team_leaders': instance.totalTeamLeaders,
      'total_events': instance.totalEvents,
      'pending_event_requests': instance.pendingEventRequests,
      'published_events': instance.publishedEvents,
      'active_events': instance.activeEvents,
      'total_applications': instance.totalApplications,
      'accepted_applications': instance.acceptedApplications,
      'rejected_applications': instance.rejectedApplications,
      'average_rating': instance.averageRating,
      'ratings_count': instance.ratingsCount,
      'last_updated': instance.lastUpdated.toIso8601String(),
    };

MonthlyStats _$MonthlyStatsFromJson(Map<String, dynamic> json) => MonthlyStats(
      month: json['month'] as String,
      eventsCreated: (json['events_created'] as num).toInt(),
      applicationsReceived: (json['applications_received'] as num).toInt(),
      eventsCompleted: (json['events_completed'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyStatsToJson(MonthlyStats instance) =>
    <String, dynamic>{
      'month': instance.month,
      'events_created': instance.eventsCreated,
      'applications_received': instance.applicationsReceived,
      'events_completed': instance.eventsCompleted,
    };

TopEvent _$TopEventFromJson(Map<String, dynamic> json) => TopEvent(
      eventId: json['event_id'] as String,
      eventTitle: json['event_title'] as String,
      applicationCount: (json['application_count'] as num).toInt(),
    );

Map<String, dynamic> _$TopEventToJson(TopEvent instance) => <String, dynamic>{
      'event_id': instance.eventId,
      'event_title': instance.eventTitle,
      'application_count': instance.applicationCount,
    };

RoleDistribution _$RoleDistributionFromJson(Map<String, dynamic> json) =>
    RoleDistribution(
      normalUsers: (json['normal_users'] as num).toInt(),
      companies: (json['companies'] as num).toInt(),
      teamLeaders: (json['team_leaders'] as num).toInt(),
      admins: (json['admins'] as num).toInt(),
    );

Map<String, dynamic> _$RoleDistributionToJson(RoleDistribution instance) =>
    <String, dynamic>{
      'normal_users': instance.normalUsers,
      'companies': instance.companies,
      'team_leaders': instance.teamLeaders,
      'admins': instance.admins,
    };
