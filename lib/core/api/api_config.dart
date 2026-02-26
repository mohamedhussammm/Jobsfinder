import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API configuration and endpoint constants
class ApiConfig {
  /// Your PC's local network IP (for physical device access over WiFi)
  static const String _localNetworkIp = '172.20.10.2';

  /// Base URL for the backend API — auto-detects platform
  static String get baseUrl {
    // If .env has an explicit override, use it
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    String url;
    // Auto-detect: web → localhost, mobile → local IP
    if (kIsWeb) {
      url = 'http://localhost:5000/api';
    } else {
      url = 'http://$_localNetworkIp:5000/api';
      // For android emulators, 10.0.2.2 is usually required
      // You can manually change _localNetworkIp above or add a platform check here
    }

    if (kDebugMode) {
      print('📡 [ApiConfig] Using Base URL: $url');
    }
    return url;
  }

  /// Request timeout in milliseconds
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int sendTimeout = 30000;
}

/// All API endpoint paths
class ApiEndpoints {
  // ─── Auth ─────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String me = '/auth/me';
  static const String googleSignIn = '/auth/google';

  // ─── Users ────────────────────────────────────
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String updateProfile = '/users/profile';
  static String blockUser(String id) => '/users/$id/block';
  static String unblockUser(String id) => '/users/$id/unblock';
  static String changeRole(String id) => '/users/$id/change-role';

  // ─── Companies ────────────────────────────────
  static const String companies = '/companies';
  static String companyById(String id) => '/companies/$id';
  static String verifyCompany(String id) => '/companies/$id/verify';

  // ─── Categories ───────────────────────────────
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // ─── Events ───────────────────────────────────
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';
  static String approveEvent(String id) => '/events/$id/approve';
  static String rejectEvent(String id) => '/events/$id/reject';
  static const String eventSearch = '/events/search';
  static const String eventStats = '/events/stats';
  static const String eventsPending = '/events/status/pending';

  // ─── Applications ─────────────────────────────
  static const String applications = '/applications';
  static String applicationById(String id) => '/applications/$id';
  static String applicationStatus(String id) => '/applications/$id/status';
  static String eventApplications(String eventId) =>
      '/applications/event/$eventId';
  static const String myApplications = '/applications/my';

  // ─── Team Leaders ─────────────────────────────
  static const String teamLeaders = '/team-leaders';
  static const String teamLeadersMyEvents = '/team-leaders/my-events';
  static String teamLeaderById(String id) => '/team-leaders/$id';
  static String teamLeadersByEvent(String eventId) =>
      '/team-leaders/event/$eventId';

  // ─── Ratings ──────────────────────────────────
  static const String ratings = '/ratings';
  static const String ratingsGiven = '/ratings/given';
  static String ratingsByUser(String userId) => '/ratings/user/$userId';
  static String ratingsByEvent(String eventId) => '/ratings/event/$eventId';

  // ─── Notifications ────────────────────────────
  static const String notifications = '/notifications';
  static String notificationById(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  // ─── Audit Logs ───────────────────────────────
  static const String auditLogs = '/audit-logs';

  // ─── Analytics ────────────────────────────────
  static const String analyticsKpi = '/analytics/kpis';
  static const String analyticsMonthly = '/analytics/monthly';
  static const String analyticsRoles = '/analytics/roles';
  static const String analyticsTopEvents = '/analytics/top-events';
  static const String analyticsApplicationStatus = '/analytics/app-status';
  static const String analyticsEventStatus = '/analytics/event-status';

  // ─── Upload ───────────────────────────────────
  static const String uploadAvatar = '/upload/avatar';
  static const String uploadCv = '/upload/cv';
  static const String uploadEventImage = '/upload/event-image';
  static const String uploadCompanyLogo = '/upload/company-logo';
}

/// Common API error messages
class ApiErrors {
  static const String unauthorized =
      'You do not have permission to perform this action';
  static const String notFound = 'Resource not found';
  static const String conflict = 'This resource already exists';
  static const String serverError =
      'Server error occurred. Please try again later';
  static const String networkError =
      'Network error. Please check your connection';
  static const String timeout = 'Request timed out. Please try again';
}
