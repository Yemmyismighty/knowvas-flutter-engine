import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

/// Repository for wishlist operations
class WishlistRepository {
  WishlistRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Toggle wishlist status for a resource
  Future<WishlistToggleResult> toggleWishlist({
    required int resourceId,
    required String resourceType,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/user/wishlist/toggle',
        data: {
          'resource_id': resourceId,
          'resource_type': resourceType,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return WishlistToggleResult(
          isWishlisted: response.data!['is_wishlisted'] as bool,
          action: response.data!['action'] as String,
        );
      } else {
        throw const ServerFailure(
          'Failed to toggle wishlist',
          code: 'WISHLIST_TOGGLE_FAILED',
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

/// Result of wishlist toggle operation
class WishlistToggleResult {
  final bool isWishlisted;
  final String action; // "added" or "removed"

  WishlistToggleResult({
    required this.isWishlisted,
    required this.action,
  });
}
