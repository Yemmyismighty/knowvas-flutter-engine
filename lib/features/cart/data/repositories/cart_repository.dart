import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/cart_item.dart';

/// Repository for cart operations
/// Handles adding, removing, and retrieving cart items
class CartRepository {
  CartRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get current cart with all items
  /// Returns CartResponse with items and total price
  Future<CartResponse> getCart() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.cart,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns { "cart_items": [...], "status": "success" }
        final data = response.data!;
        final rawItems = data['cart_items'] as List<dynamic>? ?? [];
        final items = rawItems
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return CartResponse(items: items, totalPrice: {});
      } else {
        throw const ServerFailure(
          'Failed to fetch cart',
          code: 'CART_FETCH_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching cart: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Add content to cart
  /// Returns updated CartResponse
  Future<CartResponse> addToCart({
    required int contentId,
    String resourceType = 'book',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.cartAdd,
        data: {
          'resource_id': contentId,
          'resource_type': resourceType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Re-fetch cart to get updated state
        return getCart();
      }

      final msg = (response.data?['message'] as String?) ?? 'Failed to add item to cart';
      throw ServerFailure(msg, code: 'CART_ADD_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(
        'An unexpected error occurred while adding to cart: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Remove content from cart
  /// Returns updated CartResponse
  Future<CartResponse> removeFromCart({
    required int contentId,
    String resourceType = 'book',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.cartRemove,
        data: {
          'resource_id': contentId,
          'resource_type': resourceType,
        },
      );

      if (response.statusCode == 200) {
        return getCart();
      }

      throw const ServerFailure(
        'Failed to remove item from cart',
        code: 'CART_REMOVE_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(
        'An unexpected error occurred while removing from cart: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Update quantity of item in cart (not supported by backend - no-op)
  Future<CartResponse> updateQuantity({
    required int contentId,
    required int quantity,
  }) async {
    // Backend doesn't support quantity updates - just return current cart
    return getCart();
  }

  /// Clear all items from cart
  Future<CartResponse> clearCart() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/cart/clear',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const CartResponse(items: [], totalPrice: {});
      }

      throw const ServerFailure(
        'Failed to clear cart',
        code: 'CART_CLEAR_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(
        'An unexpected error occurred while clearing cart: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
