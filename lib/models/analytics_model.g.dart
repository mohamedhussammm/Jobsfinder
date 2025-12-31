// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsKPI _$AnalyticsKPIFromJson(Map<String, dynamic> json) => AnalyticsKPI(
      totalUsers: (json['totalUsers'] as num).toInt(),
      totalCompanies: (json['totalCompanies'] as num).toInt(),
      totalTeamLeaders: (json['totalTeamLeaders'] as num).toInt(),
      totalEvents: (json['totalEvents'] as num).toInt(),
      pendingEventRequests: (json['pendingEventRequests'] as num).toInt(),
      publishedEvents: (json['publishedEvents'] as num).toInt(),
      activeEvents: (json['activeEvents'] as num).toInt(),
      totalApplications: (json['totalApplications'] as num).toInt(),
      acceptedApplications: (json['acceptedApplications'] as num).toInt(),
      rejectedApplications: (json['rejectedApplications'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingsCount: (json['ratingsCount'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AnalyticsKPIToJson(AnalyticsKPI instance) =>
    <String, dynamic>{
      'totalUsers': instance.totalUsers,
      'totalCompanies': instance.totalCompanies,
      'totalTeamLeaders': instance.totalTeamLeaders,
      'totalEvents': instance.totalEvents,
      'pendingEventRequests': instance.pendingEventRequests,
      'publishedEvents': instance.publishedEvents,
      'activeEvents': instance.activeEvents,
      'totalApplications': instance.totalApplications,
      'acceptedApplications': instance.acceptedApplications,
      'rejectedApplications': instance.rejectedApplications,
      'averageRating': instance.averageRating,
      'ratingsCount': instance.ratingsCount,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

MonthlyStats _$MonthlyStatsFromJson(Map<String, dynamic> json) => MonthlyStats(
      month: json['month'] as String,
      eventsCreated: (json['eventsCreated'] as num).toInt(),
      applicationsReceived: (json['applicationsReceived'] as num).toInt(),
      eventsCompleted: (json['eventsCompleted'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyStatsToJson(MonthlyStats instance) =>
    <String, dynamic>{
      'month': instance.month,
      'eventsCreated': instance.eventsCreated,
      'applicationsReceived': instance.applicationsReceived,
      'eventsCompleted': instance.eventsCompleted,
    };

TopEvent _$TopEventFromJson(Map<String, dynamic> json) => TopEvent(
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String,
      applicationCount: (json['applicationCount'] as num).toInt(),
    );

Map<String, dynamic> _$TopEventToJson(TopEvent instance) => <String, dynamic>{
      'eventId': instance.eventId,
      'eventTitle': instance.eventTitle,
      'applicationCount': instance.applicationCount,
    };

RoleDistribution _$RoleDistributionFromJson(Map<String, dynamic> json) =>
    RoleDistribution(
      normalUsers: (json['normalUsers'] as num).toInt(),
      companies: (json['companies'] as num).toInt(),
      teamLeaders: (json['teamLeaders'] as num).toInt(),
      admins: (json['admins'] as num).toInt(),
    );

Map<String, dynamic> _$RoleDistributionToJson(RoleDistribution instance) =>
    <String, dynamic>{
      'normalUsers': instance.normalUsers,
      'companies': instance.companies,
      'teamLeaders': instance.teamLeaders,
      'admins': instance.admins,
    };
