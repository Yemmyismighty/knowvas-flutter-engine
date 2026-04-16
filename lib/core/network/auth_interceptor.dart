import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/storage_keys.dart';
import '../security/secure_storage.dart';

/// Interceptor for automatic JWT token injection
/// Adds access token to request headers and handles token refresh on 401
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    Logger? logger,
    Future<String?> Function()? onTokenRefresh,
  })  : _secureStorage = secureStorage,
        _logger = logger ?? Logger(),
        _onTokenRefresh = onTokenRefresh;

  final SecureStorage _secureStorage;
  final Logger _logger;
  final Future<String?> Function()? _onTokenRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Skip token injection for auth endpoints
      if (_isAuthEndpoint(options.path)) {
        return handler.next(options);
      }

      // Get access token from secure storage
      final accessToken = await _secureStorage.read(
        key: StorageKeys.accessToken,
      );

      if (accessToken != null && accessToken.isNotEmpty) {
        // Add Bearer token to Authorization header
        options.headers['Authorization'] = 'Bearer $accessToken';
        _logger.d('Added access token to request: ${options.path}');
      } else {
        _logger.w('No access token found for request: ${options.path}');
      }

      handler.next(options);
    } catch (e) {
      _logger.e('Error in AuthInterceptor.onRequest: $e');
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - attempt token refresh
    if (err.response?.statusCode == 401 && _onTokenRefresh != null) {
      _logger.w('Received 401, attempting token refresh');

      try {
        // Attempt to refresh the token
        final newAccessToken = await _onTokenRefresh!();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _logger.i('Token refresh successful, retrying request');

          // Update the failed request with new token
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';

          // Retry the request with new token
          final dio = Dio();
          final response = await dio.fetch<dynamic>(err.requestOptions);

          return handler.resolve(response);
        } else {
          _logger.e('Token refresh failed - no new token received');
          return handler.next(err);
        }
      } catch (e) {
        _logger.e('Token refresh error: $e');
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  /// Check if the endpoint is an auth endpoint that doesn't need token
  bool _isAuthEndpoint(String path) {
    final authPaths = [
      '/api/auth/login',
      '/api/auth/signup',
      '/api/auth/refresh',
      '/api/auth/forgot-password',
      '/api/auth/reset-password',
    ];

    return authPaths.any(path.contains);
  }
}
