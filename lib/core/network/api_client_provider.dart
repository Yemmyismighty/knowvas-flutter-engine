import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/auth/data/repositories/auth_repository_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';
import 'retry_interceptor.dart';

/// Provider for SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Provider for Logger
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      errorMethodCount: 5,
      lineLength: 50,
    ),
  );
});

/// Provider for NetworkInfo
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

/// Provider for AuthInterceptor with token refresh + session-expired callbacks
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final logger = ref.watch(loggerProvider);

  return AuthInterceptor(
    secureStorage: secureStorage,
    logger: logger,
    onTokenRefresh: () async {
      final authRepository = ref.read(authRepositoryProvider);
      try {
        final tokenResponse = await authRepository.refreshToken();
        return tokenResponse.accessToken;
      } catch (e) {
        logger.e('Token refresh failed in interceptor: $e');
        return null;
      }
    },
    // Mirror the web's auth:session-expired event — tell the auth provider
    // the session is dead so it can update state and show the right message.
    onSessionExpired: () {
      ref.read(authProvider.notifier).handleSessionExpired();
    },
  );
});

/// Provider for RetryInterceptor
final retryInterceptorProvider = Provider<RetryInterceptor>((ref) {
  final logger = ref.watch(loggerProvider);

  return RetryInterceptor(
    maxRetries: 3,
    initialDelayMs: 1000,
    maxDelayMs: 10000,
    logger: logger,
  );
});

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  final retryInterceptor = ref.watch(retryInterceptorProvider);
  final logger = ref.watch(loggerProvider);

  return ApiClient(
    baseUrl: ApiConstants.baseUrl,
    authInterceptor: authInterceptor,
    retryInterceptor: retryInterceptor,
    logger: logger,
  );
});
