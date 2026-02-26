/// Analytics KPI model - dashboard metrics
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
  int get declinedApplications =>
      totalApplications - acceptedApplications - rejectedApplications;
  double get acceptanceRate {
    if (totalApplications == 0) return 0;
    return (acceptedApplications / totalApplications) * 100;
  }

  factory AnalyticsKPI.fromJson(Map<String, dynamic> json) {
    int i(String key, [int fallback = 0]) =>
        ((json[key] ?? fallback) as num).toInt();
    double d(String key, [double fallback = 0.0]) =>
        ((json[key] ?? fallback) as num).toDouble();

    return AnalyticsKPI(
      // Backend key: totalUsers  (camelCase from service)
      totalUsers: i('totalUsers'),
      // Backend doesn't break down by role in KPI — use 0 as fallback
      totalCompanies: i('totalCompanies'),
      totalTeamLeaders: i('totalTeamLeaders'),
      totalEvents: i('totalEvents'),
      pendingEventRequests: i('pendingEvents'),
      publishedEvents: i('publishedEvents'),
      activeEvents: i('activeEvents'),
      totalApplications: i('totalApplications'),
      acceptedApplications: i('acceptedApplications'),
      rejectedApplications: i('rejectedApplications'),
      averageRating: d('averageRating'),
      ratingsCount: i('totalRatings'),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'totalCompanies': totalCompanies,
    'totalTeamLeaders': totalTeamLeaders,
    'totalEvents': totalEvents,
    'pendingEvents': pendingEventRequests,
    'publishedEvents': publishedEvents,
    'activeEvents': activeEvents,
    'totalApplications': totalApplications,
    'acceptedApplications': acceptedApplications,
    'rejectedApplications': rejectedApplications,
    'averageRating': averageRating,
    'totalRatings': ratingsCount,
  };
}

/// Monthly statistics for charts
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

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    int i(String key, [int fb = 0]) => ((json[key] ?? fb) as num).toInt();
    // Backend aggregates may return {_id: {year, month}, count}
    final id = json['_id'];
    String month;
    if (id is Map) {
      final y = (id['year'] ?? 0).toString();
      final m = (id['month'] ?? 1).toString().padLeft(2, '0');
      month = '$y-$m';
    } else {
      month = (json['month'] ?? '').toString();
    }
    return MonthlyStats(
      month: month,
      eventsCreated: i('eventsCreated', i('count')),
      applicationsReceived: i('applicationsReceived'),
      eventsCompleted: i('eventsCompleted'),
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'eventsCreated': eventsCreated,
    'applicationsReceived': applicationsReceived,
    'eventsCompleted': eventsCompleted,
  };
}

/// Top events data for charts
class TopEvent {
  final String eventId;
  final String eventTitle;
  final int applicationCount;

  TopEvent({
    required this.eventId,
    required this.eventTitle,
    required this.applicationCount,
  });

  factory TopEvent.fromJson(Map<String, dynamic> json) {
    return TopEvent(
      eventId: (json['eventId'] ?? json['event_id'] ?? '').toString(),
      eventTitle: (json['title'] ?? json['event_title'] ?? '').toString(),
      applicationCount:
          ((json['applicationCount'] ?? json['application_count'] ?? 0) as num)
              .toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventTitle': eventTitle,
    'applicationCount': applicationCount,
  };
}

/// User role distribution
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

  factory RoleDistribution.fromJson(Map<String, dynamic> json) {
    int i(String key, [int fb = 0]) => ((json[key] ?? fb) as num).toInt();
    return RoleDistribution(
      // Backend returns { normal: N, company: N, team_leader: N, admin: N }
      normalUsers: i('normal'),
      companies: i('company'),
      teamLeaders: i('team_leader'),
      admins: i('admin'),
    );
  }

  Map<String, dynamic> toJson() => {
    'normal': normalUsers,
    'company': companies,
    'team_leader': teamLeaders,
    'admin': admins,
  };
}
