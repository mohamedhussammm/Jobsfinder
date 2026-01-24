import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for logout functionality
final logoutProvider = Provider((ref) => LogoutService(ref));

class LogoutService {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  LogoutService(this.ref);

  /// Logout current user and clear session
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      // The currentUserProvider will automatically update to null
      // and the router will redirect to /auth
    } catch (e) {
      // Handle error silently or log it
      print('Logout error: $e');
    }
  }
}
