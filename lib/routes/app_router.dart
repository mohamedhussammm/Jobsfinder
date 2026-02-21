import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../views/home/event_browse_screen.dart';
import '../views/home/event_details_screen.dart';
import '../models/event_model.dart';
import '../views/home/event_search_screen.dart';
import '../views/home/application_form_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/user/user_profile_screen.dart';
import '../views/user/applications_screen.dart';
import '../views/user/user_dashboard_screen.dart';
import '../views/user/calendar_screen.dart';
import '../views/user/user_ratings_screen.dart';
import '../views/user/user_history_screen.dart';
import '../views/user/edit_profile_screen.dart';
import '../views/team_leader/team_leader_events_screen.dart';
import '../views/team_leader/rating_form_screen.dart';
import '../views/team_leader/attendance_screen.dart';
import '../views/auth/new_auth_screen.dart';
import '../views/auth/registration_screen.dart';
import '../views/shared/notifications_screen.dart';
import '../views/shared/settings_screen.dart';
import '../views/shared/messaging_screen.dart';
import '../views/shared/splash_screen.dart';
import '../views/shared/main_shell.dart';
import '../controllers/auth_controller.dart';

/// Provider for GoRouter with auth guard, splash screen, and ShellRoute
final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthPage = path == '/auth' || path == '/register';
      final isSplash = path == '/splash';

      // Show splash while auth state is loading
      if (authState.isLoading && isSplash) return null;
      if (authState.isLoading) return '/splash';

      // If not logged in
      if (currentUser == null) {
        if (isSplash || isAuthPage) return isAuthPage ? null : '/auth';
        return '/auth';
      }

      // If logged in and on splash/auth, redirect to role dashboard
      if (isSplash || isAuthPage) {
        switch (currentUser.role) {
          case 'admin':
            return '/admin/dashboard';
          case 'team_leader':
            return '/team-leader/events';
          case 'normal':
          default:
            return '/';
        }
      }

      // Role-based access control
      final role = currentUser.role;

      // Admin — ONLY admin routes
      if (role == 'admin' && !path.startsWith('/admin')) {
        return '/admin/dashboard';
      }

      // Team Leader — expanded access
      if (role == 'team_leader') {
        final allowedPaths = [
          '/team-leader',
          '/rate/',
          '/profile',
          '/notifications',
          '/settings',
          '/messages',
        ];
        final isAllowed = allowedPaths.any((p) => path.startsWith(p));
        if (!isAllowed) return '/team-leader/events';
      }

      // Normal user — cannot access admin/team-leader routes
      if (role == 'normal') {
        final restrictedPaths = ['/admin', '/team-leader', '/rate/'];
        final isRestricted = restrictedPaths.any((p) => path.startsWith(p));
        if (isRestricted) return '/';
      }

      return null; // Allow access
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const NewAuthScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),

      // === Normal User Routes (inside MainShell bottom nav) ===
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const EventBrowseScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const UserProfileScreen(),
          ),
        ],
      ),

      // Normal User — Pages without bottom nav
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final initialEvent = state.extra as EventModel?;
          return EventDetailsScreen(
            eventId: eventId,
            initialEvent: initialEvent,
          );
        },
      ),
      GoRoute(
        path: '/apply/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventTitle = state.extra as String? ?? 'Event';
          return ApplicationFormScreen(
            eventId: eventId,
            eventTitle: eventTitle,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const EventSearchScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const UserDashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/ratings',
        builder: (context, state) => const UserRatingsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const UserHistoryScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationsScreen(),
      ),

      // === Admin Routes ===
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // === Team Leader Routes ===
      GoRoute(
        path: '/team-leader/events',
        builder: (context, state) => const TeamLeaderEventsScreen(),
      ),
      GoRoute(
        path: '/team-leader/attendance/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventTitle = state.uri.queryParameters['title'] ?? 'Event';
          return AttendanceScreen(eventId: eventId, eventTitle: eventTitle);
        },
      ),
      GoRoute(
        path: '/rate/:applicantId',
        builder: (context, state) {
          final applicantId = state.pathParameters['applicantId']!;
          final applicantName =
              state.uri.queryParameters['name'] ?? 'Applicant';
          final eventTitle = state.uri.queryParameters['event'] ?? 'Event';
          final eventId = state.uri.queryParameters['eventId'] ?? '';
          return RatingFormScreen(
            applicantId: applicantId,
            applicantName: applicantName,
            eventTitle: eventTitle,
            eventId: eventId,
          );
        },
      ),
    ],
  );
});
