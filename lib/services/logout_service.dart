import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/api/token_storage.dart';

/// Provider for logout functionality
final logoutProvider = Provider((ref) => LogoutService(ref));

class LogoutService {
  final Ref ref;

  LogoutService(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  /// Logout current user, clear session and provider state
  Future<void> logout() async {
    try {
      final rt = _tokenStorage.refreshToken;
      if (rt != null) {
        await _api.post(ApiEndpoints.logout, data: {'refreshToken': rt});
      }
    } catch (_) {
      // Sign-out failed silently — still clear local state
    }
    await _tokenStorage.clearTokens();
    // Always clear the in-memory user so the router redirects to /auth
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(isAuthenticatedProvider.notifier).state = false;
  }
}
