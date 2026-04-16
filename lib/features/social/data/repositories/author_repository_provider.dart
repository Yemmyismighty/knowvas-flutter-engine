import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'author_repository.dart';

/// Provider for AuthorRepository
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return AuthorRepository(
    apiClient: apiClient,
    networkInfo: networkInfo,
  );
});
