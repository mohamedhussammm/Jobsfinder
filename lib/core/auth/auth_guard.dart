import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';

/// Auth guard that checks if user is authenticated and has correct role
class AuthGuard {
  final Ref ref;

  AuthGuard(this.ref);

  /// Check if user can access a route based on their role
  Future<String?> checkAccess(BuildContext context, GoRouterState state) async {
    final currentUser = ref.read(currentUserProvider);
    final path = state.uri.path;

    // If not logged in, redirect to auth
    if (currentUser == null) {
      return '/auth';
    }

    final role = currentUser.role;

    // Admin role restrictions
    if (role == 'admin') {
      // Admin can ONLY access admin dashboard
      if (!path.startsWith('/admin')) {
        return '/admin/dashboard';
      }
      return null; // Allow access
    }

    // Team Leader role restrictions
    if (role == 'team_leader') {
      // Team leader can access: team-leader routes and profile
      final allowedPaths = ['/team-leader/events', '/rate/', '/profile'];

      final isAllowed = allowedPaths.any((allowed) => path.startsWith(allowed));

      if (!isAllowed) {
        return '/team-leader/events'; // Redirect to their dashboard
      }
      return null; // Allow access
    }

    // Company role restrictions
    if (role == 'company') {
      // Company can access: company dashboard and profile
      final allowedPaths = ['/company/dashboard', '/profile'];

      final isAllowed = allowedPaths.any((allowed) => path.startsWith(allowed));

      if (!isAllowed) {
        return '/company/dashboard'; // Redirect to their dashboard
      }
      return null; // Allow access
    }

    // Normal user restrictions
    if (role == 'normal') {
      // Normal users can access:
      // - Home routes (/, /event/, /apply/, /search)
      // - User routes (/profile, /applications)

      final restrictedPaths = [
        '/admin',
        '/team-leader',
        '/company/dashboard',
        '/rate/',
      ];

      final isRestricted = restrictedPaths.any(
        (restricted) => path.startsWith(restricted),
      );

      if (isRestricted) {
        return '/'; // Redirect to homepage
      }
      return null; // Allow access
    }

    // Unknown role, redirect to auth
    return '/auth';
  }

  /// Get initial route based on user role
  static String getInitialRouteForRole(String role) {
    switch (role) {
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
}

/// Provider for auth guard
final authGuardProvider = Provider((ref) => AuthGuard(ref));
