import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'subscription_repository.dart';

part 'subscription_repository_provider.g.dart';

/// Provider for SubscriptionRepository
@riverpod
SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
  return SubscriptionRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}
