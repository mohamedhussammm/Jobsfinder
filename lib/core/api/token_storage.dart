import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for token storage
final tokenStorageProvider = Provider((ref) => TokenStorage());

/// Hive-based JWT token storage for access and refresh tokens
class TokenStorage {
  static const String _boxName = 'auth_tokens';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Box? _box;

  /// Initialize the token storage box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Get the current access token
  String? get accessToken {
    if (_box == null || !_box!.isOpen) {
      // Try to get already-opened box synchronously
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      }
    }
    return _box?.get(_accessTokenKey);
  }

  /// Get the current refresh token
  String? get refreshToken {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      }
    }
    return _box?.get(_refreshTokenKey);
  }

  /// Store both tokens after login/refresh
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await init();
    await _box?.put(_accessTokenKey, accessToken);
    await _box?.put(_refreshTokenKey, refreshToken);
  }

  /// Update only the access token (after refresh)
  Future<void> updateAccessToken(String accessToken) async {
    await init();
    await _box?.put(_accessTokenKey, accessToken);
  }

  /// Clear all tokens (on logout)
  Future<void> clearTokens() async {
    await init();
    await _box?.delete(_accessTokenKey);
    await _box?.delete(_refreshTokenKey);
  }

  /// Check if user has stored tokens (potentially logged in)
  bool get hasTokens {
    return accessToken != null && refreshToken != null;
  }
}
