/// Custom exception class for app errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// Authentication-specific exception
class AuthException extends AppException {
  AuthException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'AUTH_ERROR',
  );
}

/// Network-related exception
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'NETWORK_ERROR',
  );
}

/// Supabase/Database exception
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'DATABASE_ERROR',
  );
}

/// Permission/Authorization exception
class PermissionException extends AppException {
  PermissionException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'PERMISSION_DENIED',
  );
}

/// Validation exception
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required super.message,
    this.errors,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'VALIDATION_ERROR',
  );
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
    code: code ?? 'NOT_FOUND',
  );
}

/// Generic result class for success/failure handling
sealed class Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) error,
  });

  Result<U> map<U>(U Function(T) mapper) => when(
    success: (data) => Success(mapper(data)),
    error: (error) => Error(error),
  );

  Future<Result<U>> asyncMap<U>(Future<U> Function(T) mapper) async => when(
    success: (data) async {
      try {
        return Success(await mapper(data));
      } on AppException catch (e) {
        return Error(e);
      }
    },
    error: (error) async => Error(error),
  ) as Result<U>;
}

final class Success<T> extends Result<T> {
  final T data;

  Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) error,
  }) =>
    success(data);
}

final class Error<T> extends Result<T> {
  final AppException error;

  Error(this.error);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) error,
  }) =>
    error(this.error);
}

/// Extension to unwrap Result
extension ResultX<T> on Result<T> {
  T? getOrNull() => when(
    success: (data) => data,
    error: (_) => null,
  );

  AppException? getErrorOrNull() => when(
    success: (_) => null,
    error: (error) => error,
  );

  bool get isSuccess => this is Success;
  bool get isError => this is Error;
}
