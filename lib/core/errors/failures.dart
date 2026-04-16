/// Base failure class for error handling
abstract class Failure implements Exception {
  const Failure(
    this.message, {
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
  });
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    this.statusCode,
    super.code,
  });

  final int? statusCode;
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    super.code,
  });
}

/// Device limit reached - user must sign out another device first
class DeviceLimitFailure extends AuthFailure {
  const DeviceLimitFailure(this.deviceManagementToken)
      : super('Device limit reached', code: 'DEVICE_LIMIT_REACHED');

  final String deviceManagementToken;
}

/// Reader-related failures
class ReaderFailure extends Failure {
  const ReaderFailure(
    super.message, {
    super.code,
    super.details,
  });
}

/// File not found failure
class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message)
      : super(code: 'FILE_NOT_FOUND');
}

/// Encryption-related failures
class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message)
      : super(code: 'ENCRYPTION_ERROR');
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure(
    super.message, {
    super.code,
  });
}

/// Insufficient storage failure
class InsufficientStorageFailure extends StorageFailure {
  const InsufficientStorageFailure()
      : super(
          'Insufficient storage space',
          code: 'INSUFFICIENT_STORAGE',
        );
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(
    super.message, {
    super.code,
  });
}

/// Payment-related failures
class PaymentFailure extends Failure {
  const PaymentFailure(
    super.message, {
    this.statusCode,
    super.code,
  });

  final int? statusCode;
}
