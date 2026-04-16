import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/subscription_models.dart';
import 'package:knowvas/features/subscription/data/repositories/subscription_repository.dart';
import 'package:knowvas/features/subscription/data/repositories/subscription_repository_provider.dart';

// State class for subscription
class SubscriptionState {
  final List<SubscriptionPlan> plans;
  final CurrentSubscription? currentSubscription;
  final bool isLoading;
  final String? error;
  final String currency;

  SubscriptionState({
    this.plans = const [],
    this.currentSubscription,
    this.isLoading = false,
    this.error,
    this.currency = 'USD',
  });

  SubscriptionState copyWith({
    List<SubscriptionPlan>? plans,
    CurrentSubscription? currentSubscription,
    bool? isLoading,
    String? error,
    String? currency,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currency: currency ?? this.currency,
    );
  }
}

// Subscription provider
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionRepository _repository;

  SubscriptionNotifier(this._repository) : super(SubscriptionState());

  /// Fetch subscription plans
  Future<void> fetchPlans({String currency = 'USD'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.getPlans(currency: currency);
      state = state.copyWith(
        plans: plans,
        currency: currency,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch current subscription
  Future<void> fetchCurrentSubscription() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subscription = await _repository.getCurrentSubscription();
      state = state.copyWith(
        currentSubscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Initiate subscription
  Future<SubscriptionInitiateResponse> initiateSubscription(String planCode) async {
    try {
      return await _repository.initiateSubscription(planCode);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Verify payment
  Future<bool> verifyPayment(String reference) async {
    try {
      return await _repository.verifyPayment(reference);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get management link
  Future<String> getManageLink() async {
    try {
      return await _repository.getManageLink();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository);
});

