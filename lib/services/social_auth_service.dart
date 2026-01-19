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

  /// Handle the OAuth callback and create user profile if needed
  Future<Result<void>> handleOAuthCallback() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Error(AppException(message: 'No user found after OAuth'));
      }

      // Check if user exists in our users table
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If user doesn't exist, create profile
      if (existingUser == null) {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'full_name':
              user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              'User',
          'role': 'normal', // Default role for social sign-ins
          'phone': user.phone ?? '',
          'national_id': '', // Will need to be filled later
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return Success(null);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to handle OAuth callback: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}

/// Provider for SocialAuthService
final socialAuthServiceProvider = Provider((ref) => SocialAuthService(ref));
