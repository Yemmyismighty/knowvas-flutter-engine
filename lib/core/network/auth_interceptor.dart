import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/storage_keys.dart';
import '../security/secure_storage.dart';
import '../services/device_service.dart';

/// Interceptor for automatic JWT token injection and device identification.
/// Adds access token + X-Device-ID to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    Logger? logger,
    Future<String?> Function()? onTokenRefresh,
    VoidCallback? onSessionExpired,
  })  : _secureStorage = secureStorage,
        _logger = logger ?? Logger(),
        _onTokenRefresh = onTokenRefresh,
        _onSessionExpired = onSessionExpired;

  final SecureStorage _secureStorage;
  final Logger _logger;
  final Future<String?> Function()? _onTokenRefresh;
  final VoidCallback? _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Always attach the stable device ID so the backend can track this device.
      // We set a temporary value first so it's present even if getDeviceId() throws.
      options.headers['X-Device-ID'] = 'mobile-unknown';
      final deviceId = await DeviceService.instance.getDeviceId();
      options.headers['X-Device-ID'] = deviceId;

      // Also send the human-readable device name so the backend doesn't have
      // to parse the Dart User-Agent string (which returns "Other").
      final deviceName = await DeviceService.instance.getDeviceName();
      options.headers['X-Device-Name'] = deviceName;

      // Skip token injection for public auth endpoints
      if (_isAuthEndpoint(options.path)) {
        return handler.next(options);
      }

      // Get access token from secure storage
      final accessToken = await _secureStorage.read(
        key: StorageKeys.accessToken,
      );

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      handler.next(options);
    } catch (e) {
      _logger.e('Error in AuthInterceptor.onRequest: $e');
      // Ensure X-Device-ID is always present even on error
      if (options.headers['X-Device-ID'] == null) {
        options.headers['X-Device-ID'] = 'mobile-unknown';
      }
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 — attempt silent token refresh then retry, exactly like the web's apiFetch
    if (err.response?.statusCode == 401 && _onTokenRefresh != null) {
      // Don't retry refresh or /api/auth/me itself to avoid infinite loops
      final path = err.requestOptions.path;
      if (path.contains('/api/auth/refresh') || path.contains('/api/auth/me')) {
        // Refresh token is invalid/expired — session is over
        _logger.e('Session expired — refresh or /me returned 401');
        if (_onSessionExpired != null) _onSessionExpired!();
        return handler.next(err);
      }

      _logger.w('Received 401, attempting token refresh for: $path');

      try {
        final newAccessToken = await _onTokenRefresh!();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _logger.i('Token refresh successful, retrying: $path');

          // Reuse the original request options — keeps X-Device-ID and all other headers.
          // Just swap in the new access token.
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          // Fetch using the same Dio instance so interceptors run again
          final dio = Dio();
          final response = await dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } else {
          _logger.e('Token refresh returned null — session expired');
          if (_onSessionExpired != null) _onSessionExpired!();
          return handler.next(err);
        }
      } catch (e) {
        _logger.e('Token refresh threw: $e — session expired');
        if (_onSessionExpired != null) _onSessionExpired!();
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  /// Check if the endpoint is an auth endpoint that doesn't need token
  bool _isAuthEndpoint(String path) {
    // Only skip token injection for endpoints that don't require authentication.
    // /api/auth/me is intentionally excluded — it requires a Bearer token.
    final authPaths = [
      '/api/auth/login',
      '/api/auth/signup',
      '/api/auth/refresh',
      '/api/auth/forgot-password',
      '/api/auth/reset-password',
      '/api/auth/google-login',
      '/api/auth/verify-email',
      '/api/auth/resend-verification-email',
    ];

    return authPaths.any((p) => path.contains(p));
  }
}
