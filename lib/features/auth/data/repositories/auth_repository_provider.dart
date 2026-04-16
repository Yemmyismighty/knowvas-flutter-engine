import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/retry_interceptor.dart';
import 'auth_repository.dart';

/// Provider for AuthRepository with a separate API client (no auth interceptor to avoid circular dependency)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final retryInterceptor = ref.watch(retryInterceptorProvider);
  final logger = ref.watch(loggerProvider);

  // Create a separate API client without auth interceptor for auth operations
  final authApiClient = ApiClient(
    baseUrl: ApiConstants.baseUrl,
    retryInterceptor: retryInterceptor,
    logger: logger,
    // No auth interceptor to avoid circular dependency
  );

  return AuthRepository(
    apiClient: authApiClient,
    secureStorage: secureStorage,
  );
});

/// Provider for regular API client with auth interceptor
final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(apiClientProvider);
});
