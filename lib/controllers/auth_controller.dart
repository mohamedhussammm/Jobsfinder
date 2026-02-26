import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/login_result.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/api/token_storage.dart';

/// Current user provider
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Auth status provider — true if tokens exist (replaces old authStateProvider)
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Rating controller provider
final authControllerProvider = Provider((ref) => AuthController(ref));

/// Fetch specific user user profile provider
final fetchUserByIdProvider = FutureProvider.autoDispose
    .family<UserModel, String>((ref, userId) async {
      final controller = ref.watch(authControllerProvider);
      return await controller.fetchUserById(userId);
    });

class AuthController {
  final Ref ref;

  AuthController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  /// HELPER METHOD: Sanitize user data from API response
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
        sanitized['national_id_number'] ??
        sanitized['nationalIdNumber'] ??
        'PENDING';
    sanitized['role'] = sanitized['role'] ?? 'normal';
    sanitized['name'] = sanitized['name'] ?? 'User';
    sanitized['email'] =
        sanitized['email'] ?? fallbackEmail ?? 'unknown@example.com';
    sanitized['profile_complete'] =
        sanitized['profile_complete'] ?? sanitized['profileComplete'] ?? false;

    // Ensure numbers are proper types
    sanitized['rating_avg'] =
        (sanitized['rating_avg'] ?? sanitized['ratingAvg'] as num?)
            ?.toDouble() ??
        0.0;
    sanitized['rating_count'] =
        (sanitized['rating_count'] ?? sanitized['ratingCount'] as num?)
            ?.toInt() ??
        0;

    // Ensure dates exist
    sanitized['created_at'] =
        sanitized['created_at'] ??
        sanitized['createdAt'] ??
        DateTime.now().toIso8601String();
    sanitized['updated_at'] =
        sanitized['updated_at'] ??
        sanitized['updatedAt'] ??
        DateTime.now().toIso8601String();

    // Normalize _id → id (MongoDB)
    sanitized['id'] = sanitized['id'] ?? sanitized['_id'] ?? '';

    return sanitized;
  }

  /// Login with role-based authentication
  Future<LoginResult> loginWithRole({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        // Store tokens
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        // Parse user from response
        final userData = data['user'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, email.trim());
        final userModel = UserModel.fromJson(sanitizedData);

        ref.read(currentUserProvider.notifier).state = userModel;
        ref.read(isAuthenticatedProvider.notifier).state = true;

        return LoginResult.success(role: userModel.role, userId: userModel.id);
      }

      return LoginResult.failure('Login failed. Please try again.');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Login failed';
      return LoginResult.failure(message);
    } catch (e) {
      return LoginResult.failure('An error occurred: ${e.toString()}');
    }
  }

  /// Try to restore session from stored tokens on app startup
  Future<void> tryAutoLogin() async {
    try {
      await _tokenStorage.init();
      if (!_tokenStorage.hasTokens) return;

      // Try to fetch current user profile with stored token
      final response = await _api.get(ApiEndpoints.me);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, null);
        final userModel = UserModel.fromJson(sanitizedData);

        ref.read(currentUserProvider.notifier).state = userModel;
        ref.read(isAuthenticatedProvider.notifier).state = true;
      } else {
        await _tokenStorage.clearTokens();
      }
    } catch (_) {
      // Token expired or invalid — user needs to re-login
      await _tokenStorage.clearTokens();
    }
  }

  /// Synchronize user profile — alias for tryAutoLogin
  Future<void> syncUser() async {
    await tryAutoLogin();
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

      final response = await _api.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          'name': fullName.trim(),
          'role': role,
          'phone': phone.trim(),
          'nationalIdNumber': nationalId.trim(),
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];

        // Store tokens
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final userData = data['user'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, email.trim());
        final userModel = UserModel.fromJson(sanitizedData);

        ref.read(currentUserProvider.notifier).state = userModel;
        ref.read(isAuthenticatedProvider.notifier).state = true;

        return LoginResult.success(role: role, userId: userModel.id);
      }

      return LoginResult.failure('Registration failed. Please try again.');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Registration failed';
      return LoginResult.failure(message);
    } catch (e) {
      return LoginResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Google Sign-In — triggers native flow, sends token to backend
  Future<LoginResult> signInWithGoogle() async {
    try {
      // On Web: use clientId. On Android: use serverClientId to get an idToken.
      final googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId:
                  '537432724341-knp7n02inu5t7lt5jt96q7dmr07nj8ri.apps.googleusercontent.com',
              scopes: ['email', 'profile'],
            )
          : GoogleSignIn(
              serverClientId:
                  '537432724341-knp7n02inu5t7lt5jt96q7dmr07nj8ri.apps.googleusercontent.com',
              scopes: ['email', 'profile'],
            );

      // Trigger the Google sign-in flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return LoginResult.failure('Google sign-in cancelled');
      }

      // Get the auth details
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      // Web can't reliably get idToken — send accessToken instead
      String? token = idToken ?? accessToken;
      String tokenType = idToken != null ? 'idToken' : 'accessToken';

      if (token == null) {
        return LoginResult.failure('Failed to get Google credentials');
      }

      // Send token to our backend
      final response = await _api.post(
        ApiEndpoints.googleSignIn,
        data: {'token': token, 'tokenType': tokenType},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        // Store tokens
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final userData = data['user'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, googleUser.email);
        final userModel = UserModel.fromJson(sanitizedData);

        ref.read(currentUserProvider.notifier).state = userModel;
        ref.read(isAuthenticatedProvider.notifier).state = true;

        return LoginResult.success(role: userModel.role, userId: userModel.id);
      }

      return LoginResult.failure('Google sign-in failed on server');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Google sign-in failed';
      return LoginResult.failure(message);
    } catch (e) {
      return LoginResult.failure('Google sign-in error: ${e.toString()}');
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
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('All fields are required');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final response = await _api.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          'name': fullName.trim(),
          'phone': phone?.trim(),
          'role': 'normal',
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        ref.read(isAuthenticatedProvider.notifier).state = true;
        return true;
      }

      return false;
    } catch (_) {
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

      final response = await _api.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final userData = data['user'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, email);
        final userModel = UserModel.fromJson(sanitizedData);

        ref.read(currentUserProvider.notifier).state = userModel;
        ref.read(isAuthenticatedProvider.notifier).state = true;
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      final rt = _tokenStorage.refreshToken;
      if (rt != null) {
        await _api.post(ApiEndpoints.logout, data: {'refreshToken': rt});
      }
    } catch (_) {
      // Logout API call failed — still clear local state
    }
    await _tokenStorage.clearTokens();
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(isAuthenticatedProvider.notifier).state = false;
    return true;
  }

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      if (!_tokenStorage.hasTokens) return null;

      final response = await _api.get(ApiEndpoints.me);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, null);
        return UserModel.fromJson(sanitizedData);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch anyone's profile by ID (subject to server-side auth)
  Future<UserModel> fetchUserById(String userId) async {
    final response = await _api.get(ApiEndpoints.userById(userId));

    if (response.statusCode == 200 && response.data['success'] == true) {
      final userData = response.data['data']['user'] as Map<String, dynamic>;
      final sanitizedData = _sanitizeUserData(userData, null);
      return UserModel.fromJson(sanitizedData);
    }

    throw Exception(response.data['message'] ?? 'Failed to fetch user profile');
  }

  /// Reset password
  Future<bool> resetPassword({required String email}) async {
    try {
      final response = await _api.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
      return response.statusCode == 200;
    } catch (_) {
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
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatarPath'] = avatarUrl;

      final response = await _api.put(
        ApiEndpoints.userById(userId),
        data: updateData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Refresh current user
        final userData = response.data['data'] as Map<String, dynamic>;
        final sanitizedData = _sanitizeUserData(userData, null);
        final userModel = UserModel.fromJson(sanitizedData);
        ref.read(currentUserProvider.notifier).state = userModel;
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({required String newPassword}) async {
    try {
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final response = await _api.post(
        ApiEndpoints.resetPassword,
        data: {'password': newPassword},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Delete account (soft-delete: mark as deleted, then sign out)
  Future<bool> deleteAccount() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return false;

      await _api.delete(ApiEndpoints.userById(user.id));

      // Sign out
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }
}
