import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';

/// Provider for logout functionality
final logoutProvider = Provider((ref) => LogoutService(ref));

class LogoutService {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  LogoutService(this.ref);

  /// Logout current user, clear session and provider state
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Sign-out failed silently — still clear local state
    }
    // Always clear the in-memory user so the router redirects to /auth
    ref.read(currentUserProvider.notifier).state = null;
  }
}
