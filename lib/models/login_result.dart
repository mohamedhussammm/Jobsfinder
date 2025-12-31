/// Result model for login operations
class LoginResult {
  final bool success;
  final String? role;
  final String? errorMessage;
  final String? userId;

  LoginResult({
    required this.success,
    this.role,
    this.errorMessage,
    this.userId,
  });

  factory LoginResult.success({required String role, required String userId}) {
    return LoginResult(success: true, role: role, userId: userId);
  }

  factory LoginResult.failure(String errorMessage) {
    return LoginResult(success: false, errorMessage: errorMessage);
  }

  factory LoginResult.adminSuccess() {
    return LoginResult(success: true, role: 'admin', userId: 'admin');
  }
}
