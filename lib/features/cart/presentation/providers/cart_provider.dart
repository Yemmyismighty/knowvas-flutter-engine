import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/cart_item.dart';
import '../../data/repositories/cart_repository_provider.dart';
import 'cart_state.dart';

part 'cart_provider.g.dart';

/// Storage key for cart persistence
const String _cartStorageKey = 'cart_data';

/// CartNotifier manages cart state
/// Handles adding, removing, and updating cart items
/// Persists cart state locally for offline access
@riverpod
class Cart extends _$Cart {
  SharedPreferences? _prefs;

  @override
  CartState build() {
    // Initialize by loading persisted cart
    _initializeCart();
    return CartState.initial();
  }

  /// Initialize cart state by loading from local storage and syncing with backend
  Future<void> _initializeCart() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // First, load from local storage for immediate display
      final cachedCart = _loadFromStorage();
      if (cachedCart != null) {
        state = cachedCart;
      }

      // Then fetch fresh data from backend
      await refresh();
    } catch (e) {
      // If initialization fails, start with empty cart
      state = CartState.empty();
    }
  }

  /// Load cart from local storage
  CartState? _loadFromStorage() {
    try {
      final cartJson = _prefs?.getString(_cartStorageKey);
      if (cartJson != null) {
        final cartData = json.decode(cartJson) as Map<String, dynamic>;
        final items = (cartData['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final totalPrice = (cartData['total_price'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as num).toDouble()));

        return CartState.loaded(
          items: items,
          totalPrice: totalPrice,
        );
      }
    } catch (e) {
      // If loading fails, return null to fetch from backend
      return null;
    }
    return null;
  }

  /// Save cart to local storage
  Future<void> _saveToStorage() async {
    try {
      final cartData = {
        'items': state.items.map((e) => e.toJson()).toList(),
        'total_price': state.totalPrice,
      };
      await _prefs?.setString(_cartStorageKey, json.encode(cartData));
    } catch (e) {
      // Log error but don't throw - persistence failure shouldn't break functionality
      // In production, you might want to log this to analytics
    }
  }

  /// Refresh cart from backend
  /// Fetches latest cart data and updates state
  Future<void> refresh() async {
    try {
      final repository = ref.read(cartRepositoryProvider);
      final cartResponse = await repository.getCart();

      state = CartState.loaded(
        items: cartResponse.items,
        totalPrice: cartResponse.totalPrice,
      );

      // Persist to local storage
      await _saveToStorage();
    } on NetworkFailure catch (e) {
      // If network fails and we have cached data, keep it
      if (!state.isInitialized) {
        state = state.copyWithError(e.message);
      }
    } on ServerFailure catch (e) {
      if (!state.isInitialized) {
        state = state.copyWithError(e.message);
      }
    } catch (e) {
      if (!state.isInitialized) {
        state = state.copyWithError('Failed to load cart: $e');
      }
    }
  }

  /// Add content to cart
  /// Updates state with new cart data on success
  /// Sets error message on failure
  Future<void> addToCart(int contentId, {String resourceType = 'book'}) async {
    // Check if already in cart
    if (state.containsContent(contentId)) {
      state = state.copyWithError('Item is already in cart');
      return;
    }

    state = state.copyWithLoading();

    try {
      final repository = ref.read(cartRepositoryProvider);
      final cartResponse = await repository.addToCart(
        contentId: contentId,
        resourceType: resourceType,
      );

      state = CartState.loaded(
        items: cartResponse.items,
        totalPrice: cartResponse.totalPrice,
      );

      // Persist to local storage
      await _saveToStorage();
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('Failed to add item to cart: $e');
    }
  }

  /// Remove content from cart
  /// Updates state with new cart data on success
  /// Sets error message on failure
  Future<void> removeFromCart(int contentId) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read(cartRepositoryProvider);
      final cartResponse =
          await repository.removeFromCart(contentId: contentId);

      state = CartState.loaded(
        items: cartResponse.items,
        totalPrice: cartResponse.totalPrice,
      );

      // Persist to local storage
      await _saveToStorage();
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('Failed to remove item from cart: $e');
    }
  }

  /// Update quantity of item in cart
  /// Note: Based on requirements, cart items don't have quantities
  /// This method is included for API completeness but may not be used
  Future<void> updateQuantity(int contentId, int quantity) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read(cartRepositoryProvider);
      final cartResponse = await repository.updateQuantity(
        contentId: contentId,
        quantity: quantity,
      );

      state = CartState.loaded(
        items: cartResponse.items,
        totalPrice: cartResponse.totalPrice,
      );

      // Persist to local storage
      await _saveToStorage();
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('Failed to update cart: $e');
    }
  }

  /// Clear all items from cart
  /// Updates state to empty cart on success
  Future<void> clearCart() async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read(cartRepositoryProvider);
      await repository.clearCart();

      state = CartState.empty();

      // Clear from local storage
      await _prefs?.remove(_cartStorageKey);
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('Failed to clear cart: $e');
    }
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }

  /// Get cart badge count
  int get badgeCount => state.itemCount;

  /// Check if cart is empty
  bool get isEmpty => state.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => state.isNotEmpty;

  /// Check if content is in cart
  bool containsContent(int contentId) => state.containsContent(contentId);

  /// Get total price for a specific currency
  double getTotalPrice(String currency) => state.getTotalPrice(currency);
}
