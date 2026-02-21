import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../core/utils/result.dart';

/// Service for handling social authentication (Google, Facebook, etc.)
class SocialAuthService {
  final Ref ref;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  SocialAuthService(this.ref);

  /// Sign in with Google using Supabase OAuth
  ///
  /// This uses Supabase's built-in OAuth flow.
  /// You need to configure Google OAuth in your Supabase dashboard:
  /// 1. Go to Authentication > Providers
  /// 2. Enable Google
  /// 3. Add your Google Client ID and Secret
  Future<Result<supabase.AuthResponse>> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo:
            'io.supabase.shiftsphere://login-callback/', // Your app's deep link
      );

      if (response) {
        // OAuth flow initiated successfully
        // The actual auth response will come through the deep link
        return Success(
          supabase.AuthResponse(
            session: _supabase.auth.currentSession,
            user: _supabase.auth.currentUser,
          ),
        );
      } else {
        return Error(
          AppException(message: 'Failed to initiate Google sign in'),
        );
      }
    } on supabase.AuthException catch (e) {
      return Error(
        AppException(
          message: 'Google sign in failed: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Unexpected error during Google sign in: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Sign in with Facebook using Supabase OAuth
  ///
  /// Configure Facebook OAuth in Supabase dashboard:
  /// 1. Go to Authentication > Providers
  /// 2. Enable Facebook
  /// 3. Add your Facebook App ID and Secret
  Future<Result<supabase.AuthResponse>> signInWithFacebook() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        supabase.OAuthProvider.facebook,
        redirectTo: 'io.supabase.shiftsphere://login-callback/',
      );

      if (response) {
        return Success(
          supabase.AuthResponse(
            session: _supabase.auth.currentSession,
            user: _supabase.auth.currentUser,
          ),
        );
      } else {
        return Error(
          AppException(message: 'Failed to initiate Facebook sign in'),
        );
      }
    } on supabase.AuthException catch (e) {
      return Error(
        AppException(
          message: 'Facebook sign in failed: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Unexpected error during Facebook sign in: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}

/// Provider for SocialAuthService
final socialAuthServiceProvider = Provider((ref) => SocialAuthService(ref));
