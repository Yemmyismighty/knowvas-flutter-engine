import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/subscription.dart';
import '../../data/repositories/subscription_repository_provider.dart';

part 'subscription_provider.g.dart';

/// Provider for fetching subscription plans
@riverpod
Future<List<SubscriptionPlan>> subscriptionPlans(
  SubscriptionPlansRef ref,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getSubscriptionPlans();
}

/// Provider for fetching active subscription
@riverpod
Future<ActiveSubscription?> activeSubscription(
  ActiveSubscriptionRef ref,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getActiveSubscription();
}

/// State for subscription operations
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Subscribe to a plan
  Future<void> subscribe({
    required String planId,
    required String billingCycle,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.subscribe(
        planId: planId,
        billingCycle: billingCycle,
        paymentMethod: paymentMethod,
      );
      
      // Invalidate active subscription to refresh
      ref.invalidate(activeSubscriptionProvider);
    });
  }

  /// Cancel active subscription
  Future<void> cancelSubscription() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.cancelSubscription();
      
      // Invalidate active subscription to refresh
      ref.invalidate(activeSubscriptionProvider);
    });
  }
}
