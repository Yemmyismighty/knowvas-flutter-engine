import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';

/// Repository for content actions (wishlist, reviews, follow, cart)
class ContentActionsRepository {
  ContentActionsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Toggle wishlist for a content item
  Future<Map<String, dynamic>> toggleWishlist({
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
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to toggle wishlist',
          code: 'WISHLIST_TOGGLE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Submit a review for content
  Future<Map<String, dynamic>> submitReview({
    required int resourceId,
    required String resourceType,
    required String reviewText,
    required int rating,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/contents/reviews',
        data: {
          'resource_id': resourceId,
          'resource_type': resourceType,
          'review_text': reviewText,
          'rating': rating,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to submit review',
          code: 'REVIEW_SUBMIT_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Like a review
  Future<Map<String, dynamic>> likeReview(int reviewId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/contents/reviews/$reviewId/like',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to like review',
          code: 'REVIEW_LIKE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Dislike a review
  Future<Map<String, dynamic>> dislikeReview(int reviewId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/contents/reviews/$reviewId/dislike',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to dislike review',
          code: 'REVIEW_DISLIKE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Toggle follow for an author
  Future<Map<String, dynamic>> toggleFollow({
    required String targetType,
    required int targetId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/follow/toggle',
        data: {
          'target_type': targetType,
          'target_id': targetId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to toggle follow',
          code: 'FOLLOW_TOGGLE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Add item to cart
  Future<Map<String, dynamic>> addToCart({
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
        return response.data!;
      } else {
        throw const ServerFailure(
          'Failed to add to cart',
          code: 'CART_ADD_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
