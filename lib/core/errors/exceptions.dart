/// Base exception class
class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
  });

  final String message;
  final String? code;

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Server exception
class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
  });

  final int? statusCode;
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
  });
}

/// Platform exception wrapper
class PlatformException extends AppException {
  const PlatformException(
    super.message, {
    super.code,
  });
}
