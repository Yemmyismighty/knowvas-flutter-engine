import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/billing_settings_models.dart';
import 'package:knowvas/features/settings/data/repositories/billing_settings_repository_provider.dart';

// State class for billing settings
class BillingSettingsState {
  final CurrentSubscriptionInfo? subscription;
  final SubscriptionUsage? usage;
  final bool isLoadingSubscription;
  final bool isLoadingUsage;
  final String? error;

  BillingSettingsState({
    this.subscription,
    this.usage,
    this.isLoadingSubscription = false,
    this.isLoadingUsage = false,
    this.error,
  });

  BillingSettingsState copyWith({
    CurrentSubscriptionInfo? subscription,
    SubscriptionUsage? usage,
    bool? isLoadingSubscription,
    bool? isLoadingUsage,
    String? error,
  }) {
    return BillingSettingsState(
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
      isLoadingSubscription: isLoadingSubscription ?? this.isLoadingSubscription,
      isLoadingUsage: isLoadingUsage ?? this.isLoadingUsage,
      error: error,
    );
  }
}

// Billing settings provider
class BillingSettingsNotifier extends StateNotifier<BillingSettingsState> {
  final BillingSettingsRepository _repository;

  BillingSettingsNotifier(this._repository) : super(BillingSettingsState());

  /// Load subscription
  Future<void> loadSubscription() async {
    state = state.copyWith(isLoadingSubscription: true, error: null);
    try {
      final subscription = await _repository.getCurrentSubscription();
      state = state.copyWith(
        subscription: subscription,
        isLoadingSubscription: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSubscription: false,
        error: e.toString(),
      );
    }
  }

  /// Load usage
  Future<void> loadUsage() async {
    state = state.copyWith(isLoadingUsage: true, error: null);
    try {
      final usage = await _repository.getSubscriptionUsage();
      state = state.copyWith(
        usage: usage,
        isLoadingUsage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingUsage: false,
        error: e.toString(),
      );
    }
  }

  /// Get manage link
  Future<String> getManageLink() async {
    try {
      return await _repository.getManageLink();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final billingSettingsProvider = StateNotifierProvider<BillingSettingsNotifier, BillingSettingsState>((ref) {
  final repository = ref.watch(billingSettingsRepositoryProvider);
  return BillingSettingsNotifier(repository);
});

