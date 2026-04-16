import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/library_item.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/repositories/purchase_repository_provider.dart';
import 'cart_provider.dart';

part 'purchase_provider.g.dart';

/// State for purchase operations
class PurchaseState {
  final bool isProcessing;
  final String? error;
  final String? successMessage;
  final List<LibraryItem>? purchasedItems;

  const PurchaseState({
    this.isProcessing = false,
    this.error,
    this.successMessage,
    this.purchasedItems,
  });

  PurchaseState copyWith({
    bool? isProcessing,
    String? error,
    String? successMessage,
    List<LibraryItem>? purchasedItems,
  }) {
    return PurchaseState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      successMessage: successMessage,
      purchasedItems: purchasedItems,
    );
  }

  /// Clear error and success messages
  PurchaseState clearMessages() {
    return PurchaseState(
      isProcessing: isProcessing,
      error: null,
      successMessage: null,
      purchasedItems: purchasedItems,
    );
  }
}

/// Provider for purchase operations
@riverpod
class Purchase extends _$Purchase {
  @override
  PurchaseState build() {
    return const PurchaseState();
  }

  /// Purchase a single content item
  /// 
  /// Parameters:
  /// - contentId: ID of the content to purchase
  /// - currency: Currency code (e.g., 'USD', 'NGN')
  /// - paymentMethod: Payment method identifier
  /// 
  /// Returns true if purchase was successful, false otherwise
  Future<bool> purchaseContent({
    required int contentId,
    required String currency,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final repository = ref.read(purchaseRepositoryProvider);
      final response = await repository.purchase(
        contentId: contentId,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      if (response.success) {
        // Update library with purchased items
        await _updateLibraryAfterPurchase(response.purchasedItems);

        // Remove purchased item from cart
        await ref.read(cartProvider.notifier).removeFromCart(contentId);

        state = state.copyWith(
          isProcessing: false,
          successMessage: response.message,
          purchasedItems: response.purchasedItems,
        );

        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: response.message,
        );
        return false;
      }
    } on PaymentFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: _getPaymentErrorMessage(e),
      );
      return false;
    } on NetworkFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Network error: ${e.message}',
      );
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'An unexpected error occurred: $e',
      );
      return false;
    }
  }

  /// Purchase all items in cart
  /// 
  /// Parameters:
  /// - currency: Currency code (e.g., 'USD', 'NGN')
  /// - paymentMethod: Payment method identifier
  /// 
  /// Returns true if purchase was successful, false otherwise
  Future<bool> purchaseCart({
    required String currency,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final repository = ref.read(purchaseRepositoryProvider);
      final response = await repository.purchaseCart(
        currency: currency,
        paymentMethod: paymentMethod,
      );

      if (response.success) {
        // Update library with purchased items
        await _updateLibraryAfterPurchase(response.purchasedItems);

        // Clear cart after successful purchase
        await ref.read(cartProvider.notifier).clearCart();

        state = state.copyWith(
          isProcessing: false,
          successMessage: response.message,
          purchasedItems: response.purchasedItems,
        );

        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: response.message,
        );
        return false;
      }
    } on PaymentFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: _getPaymentErrorMessage(e),
      );
      return false;
    } on NetworkFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Network error: ${e.message}',
      );
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'An unexpected error occurred: $e',
      );
      return false;
    }
  }

  /// Update library after successful purchase
  Future<void> _updateLibraryAfterPurchase(List<LibraryItem> items) async {
    // Refresh library to include newly purchased items
    await ref.read(libraryProvider.notifier).refresh();
  }

  /// Get user-friendly error message for payment failures
  String _getPaymentErrorMessage(PaymentFailure failure) {
    switch (failure.code) {
      case 'PAYMENT_DECLINED':
        return 'Payment was declined. Please check your payment method and try again.';
      case 'INSUFFICIENT_FUNDS':
        return 'Insufficient funds. Please use a different payment method.';
      case 'PAYMENT_FAILED':
        return 'Payment processing failed. Please try again.';
      default:
        return failure.message;
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    state = state.clearMessages();
  }
}
