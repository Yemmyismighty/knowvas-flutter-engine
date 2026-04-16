import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

/// Repository for cart operations
class CartRepository {
  CartRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Add item to cart
  Future<CartAddResult> addToCart({
    required int resourceId,
    required String resourceType,
    int quantity = 1,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/cart/add',
        data: {
          'resource_id': resourceId,
          'resource_type': resourceType,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return CartAddResult(
          success: true,
          cartItemCount: response.data!['cart_item_count'] as int? ?? 0,
          message: response.data!['message'] as String? ?? 'Added to cart',
        );
      } else {
        throw const ServerFailure(
          'Failed to add to cart',
          code: 'CART_ADD_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}

/// Result of add to cart operation
class CartAddResult {
  final bool success;
  final int cartItemCount;
  final String message;

  CartAddResult({
    required this.success,
    required this.cartItemCount,
    required this.message,
  });
}
