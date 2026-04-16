import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'follow_repository.dart';

/// Provider for FollowRepository
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return FollowRepository(
    apiClient: apiClient,
    networkInfo: networkInfo,
  );
});
