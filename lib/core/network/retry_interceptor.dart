import 'dart:math';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Interceptor for automatic retry with exponential backoff
/// Retries failed requests up to a maximum number of attempts
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 10000,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Initial delay in milliseconds before first retry
  final int initialDelayMs;

  /// Maximum delay in milliseconds between retries
  final int maxDelayMs;

  final Logger _logger;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry on specific error types
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    // Get current retry count from request options
    final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;

    if (retryCount >= maxRetries) {
      _logger.w(
        'Max retries ($maxRetries) reached for ${err.requestOptions.path}',
      );
      return handler.next(err);
    }

    // Calculate delay with exponential backoff
    final delay = _calculateDelay(retryCount);

    _logger.i(
      'Retrying request (attempt ${retryCount + 1}/$maxRetries) '
      'after ${delay}ms delay: ${err.requestOptions.path}',
    );

    // Wait before retrying
    await Future<void>.delayed(Duration(milliseconds: delay));

    // Increment retry count
    err.requestOptions.extra['retry_count'] = retryCount + 1;

    try {
      // Retry the request
      final dio = Dio();
      final response = await dio.fetch<dynamic>(err.requestOptions);

      return handler.resolve(response);
    } on DioException catch (e) {
      // If retry fails, pass the error to the next handler
      return handler.next(e);
    }
  }

  /// Determine if the request should be retried based on error type
  bool _shouldRetry(DioException err) {
    // Don't retry on client errors (4xx) except 408, 429
    if (err.response?.statusCode != null) {
      final statusCode = err.response!.statusCode!;

      // Retry on server errors (5xx)
      if (statusCode >= 500) {
        return true;
      }

      // Retry on specific client errors
      if (statusCode == 408 || statusCode == 429) {
        // 408 Request Timeout, 429 Too Many Requests
        return true;
      }

      // Don't retry other 4xx errors
      if (statusCode >= 400 && statusCode < 500) {
        return false;
      }
    }

    // Retry on network-related errors
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        // Already handled above
        return false;

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Calculate delay with exponential backoff and jitter
  int _calculateDelay(int retryCount) {
    // Exponential backoff: delay = initialDelay * 2^retryCount
    final exponentialDelay = initialDelayMs * pow(2, retryCount);

    // Add jitter (random value between 0 and 1000ms) to prevent thundering herd
    final jitter = Random().nextInt(1000);

    // Cap at maximum delay
    final totalDelay = min(exponentialDelay.toInt() + jitter, maxDelayMs);

    return totalDelay;
  }
}
