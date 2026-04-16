import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/checkout_models.dart';
import 'package:knowvas/features/checkout/data/repositories/checkout_repository.dart';
import 'package:knowvas/features/checkout/data/repositories/checkout_repository_provider.dart';

// State class for checkout
class CheckoutState {
  final CheckoutData? checkoutData;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  CheckoutState({
    this.checkoutData,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  CheckoutState copyWith({
    CheckoutData? checkoutData,
    bool? isLoading,
    bool? isProcessing,
    String? error,
  }) {
    return CheckoutState(
      checkoutData: checkoutData ?? this.checkoutData,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

// Checkout provider
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final CheckoutRepository _repository;

  CheckoutNotifier(this._repository) : super(CheckoutState());

  /// Fetch checkout data
  Future<void> fetchCheckoutData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final checkoutData = await _repository.getCheckoutData();
      state = state.copyWith(
        checkoutData: checkoutData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Initiate payment
  Future<PaymentInitiateResponse> initiatePayment() async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final response = await _repository.initiatePayment();
      state = state.copyWith(isProcessing: false);
      return response;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Verify payment
  Future<PaymentVerificationData> verifyPayment(String reference) async {
    try {
      return await _repository.verifyPayment(reference);
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
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final repository = ref.watch(checkoutRepositoryProvider);
  return CheckoutNotifier(repository);
});

