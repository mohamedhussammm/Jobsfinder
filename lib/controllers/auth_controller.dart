import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/user_model.dart';
import '../models/login_result.dart';

/// Current user provider
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Authentication controller with business logic
final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthController(this.ref);

  // Static admin credentials
  static const String adminEmail = 'admin@shiftsphere.com';
  static const String adminPassword = 'Admin@123';

  /// HELPER METHOD: Sanitize user data from database
  /// This prevents null values from causing TypeErrors
  Map<String, dynamic> _sanitizeUserData(
    Map<String, dynamic> userData,
    String? fallbackEmail,
  ) {
    final sanitized = <String, dynamic>{};

    // Copy all existing data
    userData.forEach((key, value) {
      sanitized[key] = value;
    });

    // Fix null values with proper defaults
    sanitized['national_id_number'] =
        sanitized['national_id_number'] ?? 'PENDING';
    sanitized['role'] = sanitized['role'] ?? 'normal';
    sanitized['name'] = sanitized['name'] ?? 'User';
    sanitized['email'] =
        sanitized['email'] ?? fallbackEmail ?? 'unknown@example.com';
    sanitized['profile_complete'] = sanitized['profile_complete'] ?? false;

    // Ensure numbers are proper types
    sanitized['rating_avg'] =
        (sanitized['rating_avg'] as num?)?.toDouble() ?? 0.0;
    sanitized['rating_count'] =
        (sanitized['rating_count'] as num?)?.toInt() ?? 0;

    return sanitized;
  }

  /// Login with role-based authentication
  Future<LoginResult> loginWithRole({
    required String email,
    required String password,
  }) async {
    try {
      // Check for static admin credentials first
      if (email.trim().toLowerCase() == adminEmail.toLowerCase() &&
          password == adminPassword) {
        // Admin login - no database record
        ref.read(currentUserProvider.notifier).state = UserModel(
          id: 'admin',
          email: adminEmail,
          name: 'Administrator',
          role: 'admin',
          nationalIdNumber: 'ADMIN',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          profileComplete: true,
        );
        return LoginResult.adminSuccess();
      }

      // Regular user login
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Fetch user profile from database
        try {
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .single();

          // DEBUG: Print raw data from database
          print('=== RAW USER DATA FROM DB ===');
          print(userData);
          print('=== END RAW DATA ===');

          // Use helper to sanitize data
          final sanitizedData = _sanitizeUserData(userData, email.trim());

          // DEBUG: Print sanitized data
          print('=== SANITIZED DATA ===');
          print(sanitizedData);
          print('=== END SANITIZED ===');

          final userModel = UserModel.fromJson(sanitizedData);
          ref.read(currentUserProvider.notifier).state = userModel;
          return LoginResult.success(
            role: userModel.role,
            userId: userModel.id,
          );
        } catch (e) {
          // Fallback: If profile doesn't exist (PGRST116), create it now
          if (e.toString().contains('PGRST116') ||
              e.toString().contains('0 rows')) {
            final role = user.userMetadata?['role'] ?? 'normal';

            await _supabase.from('users').insert({
              'id': user.id,
              'email': user.email ?? email.trim(),
              'name': user.userMetadata?['full_name'] ?? 'Unknown',
              'role': role,
              'phone': user.userMetadata?['phone'],
              'national_id_number':
                  user.userMetadata?['national_id_number'] ?? 'PENDING',
              'profile_complete': false,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            // Return success with the role from metadata
            return LoginResult.success(role: role, userId: user.id);
          }
          rethrow;
        }
      }

      return LoginResult.failure('Login failed. Please try again.');
    } on AuthException catch (e) {
      return LoginResult.failure(e.message);
    } catch (e) {
      return LoginResult.failure('An error occurred: ${e.toString()}');
    }
  }

  /// Register user with role
  Future<LoginResult> registerUserWithRole({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String phone,
    required String nationalId,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty ||
          password.isEmpty ||
          fullName.isEmpty ||
          phone.isEmpty ||
          nationalId.isEmpty) {
        return LoginResult.failure('All required fields must be filled');
      }

      if (password.length < 6) {
        return LoginResult.failure('Password must be at least 6 characters');
      }

      // Validate role
      final validRoles = ['normal', 'user', 'team_leader', 'company'];
      if (!validRoles.contains(role)) {
        return LoginResult.failure('Invalid role selected');
      }

      // Sign up with Supabase Auth including metadata
      final authResponse = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role,
          'phone': phone.trim(),
          'national_id_number': nationalId.trim(),
        },
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        return LoginResult.failure('Registration failed. Please try again.');
      }

      return LoginResult.success(role: role, userId: userId);
    } on AuthException catch (e) {
      return LoginResult.failure(e.message);
    } catch (e) {
      return LoginResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Register new user - returns true on success
  Future<bool> registerUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('All fields are required');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user!.id;

      // Create user profile in Supabase
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
        'national_id_number': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  /// Login user - returns true on success
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Fetch user profile
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        // FIXED: Use sanitization helper
        final sanitizedData = _sanitizeUserData(userData, email);

        final userModel = UserModel.fromJson(sanitizedData);
        ref.read(currentUserProvider.notifier).state = userModel;
        return true;
      }

      return false;
    } on AuthException catch (e) {
      print('Login error: ${e.message}');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      await _supabase.auth.signOut();
      ref.read(currentUserProvider.notifier).state = null;
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // FIXED: Use sanitization helper
      final sanitizedData = _sanitizeUserData(userData, user.email);

      final userModel = UserModel.fromJson(sanitizedData);
      return userModel;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  /// Reset password
  Future<bool> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      print('Reset password error: ${e.message}');
      return false;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != userId) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatar_path'] = avatarUrl;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(updateData).eq('id', userId);

      // Refresh current user
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // FIXED: Use sanitization helper
      final sanitizedData = _sanitizeUserData(userData, user.email);

      final userModel = UserModel.fromJson(sanitizedData);
      ref.read(currentUserProvider.notifier).state = userModel;

      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  /// Fetch user by ID (internal helper)
  Future<UserModel?> _fetchUserById(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // FIXED: Use sanitization helper
      final sanitizedData = _sanitizeUserData(userData, null);

      return UserModel.fromJson(sanitizedData);
    } catch (e) {
      print('Fetch user error: $e');
      return null;
    }
  }
}
