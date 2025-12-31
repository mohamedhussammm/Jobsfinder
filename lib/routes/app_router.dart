import 'package:go_router/go_router.dart';
import '../views/home/event_browse_screen.dart';
import '../views/home/event_details_screen.dart';
import '../views/home/event_search_screen.dart';
import '../views/home/application_form_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/user/user_profile_screen.dart';
import '../views/team_leader/team_leader_events_screen.dart';
import '../views/team_leader/rating_form_screen.dart';
import '../views/auth/new_auth_screen.dart';
import '../views/company/company_dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    // Auth Route
    GoRoute(path: '/auth', builder: (context, state) => const NewAuthScreen()),
    // Main Routes
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
