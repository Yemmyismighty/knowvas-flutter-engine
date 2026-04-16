import 'package:equatable/equatable.dart';

import '../../../../shared/models/cart_item.dart';

/// Cart state
class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.totalPrice = const {},
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  /// Initial state - not yet loaded
  factory CartState.initial() {
    return const CartState(
      isLoading: true,
    );
  }

  /// Empty cart state
  factory CartState.empty() {
    return const CartState(
      isInitialized: true,
    );
  }

  /// Loaded cart state with items
  factory CartState.loaded({
    required List<CartItem> items,
    required Map<String, double> totalPrice,
  }) {
    return CartState(
      items: items,
      totalPrice: totalPrice,
      isInitialized: true,
    );
  }

  final List<CartItem> items;
  final Map<String, double> totalPrice;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  /// Get cart badge count (number of items)
  int get itemCount => items.length;

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get total price for a specific currency
  double getTotalPrice(String currency) {
    return totalPrice[currency] ?? 0.0;
  }

  /// Check if content is in cart
  bool containsContent(int contentId) {
    return items.any((item) => item.content.id == contentId);
  }

  /// Loading state
  CartState copyWithLoading() {
    return CartState(
      items: items,
      totalPrice: totalPrice,
      isLoading: true,
      isInitialized: isInitialized,
    );
  }

  /// Error state
  CartState copyWithError(String error) {
    return CartState(
      items: items,
      totalPrice: totalPrice,
      error: error,
      isInitialized: isInitialized,
    );
  }

  /// Copy with new values
  CartState copyWith({
    List<CartItem>? items,
    Map<String, double>? totalPrice,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return CartState(
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [
        items,
        totalPrice,
        isLoading,
        error,
        isInitialized,
      ];
}
