import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../views/home/event_browse_screen.dart';
import '../views/home/event_details_screen.dart';
import '../views/home/event_search_screen.dart';
import '../views/home/application_form_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/user/user_profile_screen.dart';
import '../views/user/applications_screen.dart';
import '../views/team_leader/team_leader_events_screen.dart';
import '../views/team_leader/rating_form_screen.dart';
import '../views/auth/new_auth_screen.dart';
import '../views/auth/registration_screen.dart'; // Added import
import '../views/company/company_dashboard_screen.dart';
import '../controllers/auth_controller.dart';

/// Provider for GoRouter with auth guard
final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthPage =
          path == '/auth' ||
          path == '/register'; // Updated to include /register

      // If not logged in and not on auth page, redirect to auth
      if (currentUser == null && !isAuthPage) {
        return '/auth';
      }

      // If logged in and on auth page, redirect to role-specific dashboard
      if (currentUser != null && isAuthPage) {
        switch (currentUser.role) {
          case 'admin':
            return '/admin/dashboard';
          case 'team_leader':
            return '/team-leader/events';
          case 'company':
            return '/company/dashboard';
          case 'normal':
          default:
            return '/';
        }
      }

      // Role-based access control
      if (currentUser != null) {
        final role = currentUser.role;

        // Admin restrictions - can ONLY access admin routes
        if (role == 'admin' && !path.startsWith('/admin')) {
          return '/admin/dashboard';
        }

        // Team Leader restrictions
        if (role == 'team_leader') {
          final allowedPaths = ['/team-leader', '/rate/', '/profile'];
          final isAllowed = allowedPaths.any((p) => path.startsWith(p));
          if (!isAllowed) {
            return '/team-leader/events';
          }
        }

        // Company restrictions
        if (role == 'company') {
          final allowedPaths = ['/company/dashboard', '/profile'];
          final isAllowed = allowedPaths.any((p) => path.startsWith(p));
          if (!isAllowed) {
            return '/company/dashboard';
          }
        }

        // Normal user restrictions - cannot access admin/team-leader/company routes
        if (role == 'normal') {
          final restrictedPaths = [
            '/admin',
            '/team-leader',
            '/company/dashboard',
            '/rate/',
          ];
          final isRestricted = restrictedPaths.any((p) => path.startsWith(p));
          if (isRestricted) {
            return '/';
          }
        }
      }

      return null; // Allow access
    },
    routes: [
      // Auth Route
      GoRoute(
        path: '/auth',
        builder: (context, state) => const NewAuthScreen(),
      ),

      // Normal User Routes (Home)
      GoRoute(
        path: '/',
        builder: (context, state) => const EventBrowseScreen(),
      ),
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) =>
            EventDetailsScreen(eventId: state.pathParameters['eventId']!),
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
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationsScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Team Leader Routes
      GoRoute(
        path: '/team-leader/events',
        builder: (context, state) => const TeamLeaderEventsScreen(),
      ),
      GoRoute(
        path: '/rate/:applicantId',
        builder: (context, state) {
          final applicantId = state.pathParameters['applicantId']!;
          final applicantName =
              state.uri.queryParameters['name'] ?? 'Applicant';
          final eventTitle = state.uri.queryParameters['event'] ?? 'Event';
          return RatingFormScreen(
            applicantId: applicantId,
            applicantName: applicantName,
            eventTitle: eventTitle,
          );
        },
      ),

      // Company Routes
      GoRoute(
        path: '/company/dashboard',
        builder: (context, state) => const CompanyDashboardScreen(),
      ),
    ],
  );
});

// Legacy router for backward compatibility (will be removed)
final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const NewAuthScreen()),
    GoRoute(
      path: '/',
      builder: (context, state) => const EventBrowseScreen(),
      routes: [
        GoRoute(
          path: 'event/:eventId',
          builder: (context, state) =>
              EventDetailsScreen(eventId: state.pathParameters['eventId']!),
        ),
        GoRoute(
          path: 'apply/:eventId',
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
          path: 'search',
          builder: (context, state) => const EventSearchScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const UserProfileScreen(),
        ),
        GoRoute(
          path: 'applications',
          builder: (context, state) => const ApplicationsScreen(),
        ),
        GoRoute(
          path: 'admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: 'team-leader/events',
          builder: (context, state) => const TeamLeaderEventsScreen(),
        ),
        GoRoute(
          path: 'rate/:applicantId',
          builder: (context, state) {
            final applicantId = state.pathParameters['applicantId']!;
            final applicantName =
                state.uri.queryParameters['name'] ?? 'Applicant';
            final eventTitle = state.uri.queryParameters['event'] ?? 'Event';
            return RatingFormScreen(
              applicantId: applicantId,
              applicantName: applicantName,
              eventTitle: eventTitle,
            );
          },
        ),
        GoRoute(
          path: 'company/dashboard',
          builder: (context, state) => const CompanyDashboardScreen(),
        ),
      ],
    ),
  ],
);
