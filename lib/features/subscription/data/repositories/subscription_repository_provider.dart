import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/network/api_client_provider.dart';
import 'subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});
