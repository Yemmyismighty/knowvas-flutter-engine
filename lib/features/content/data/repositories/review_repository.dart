import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

/// Repository for review operations
class ReviewRepository {
  ReviewRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Submit a review
  Future<ReviewSubmitResult> submitReview({
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
        return ReviewSubmitResult(
          success: true,
          review: response.data!['review'] as Map<String, dynamic>,
        );
      } else {
        throw const ServerFailure(
          'Failed to submit review',
          code: 'REVIEW_SUBMIT_FAILED',
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

  /// Like a review
  Future<ReviewLikeResult> likeReview(int reviewId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/contents/reviews/$reviewId/like',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReviewLikeResult(
          likes: response.data!['likes'] as int,
          dislikes: response.data!['dislikes'] as int,
        );
      } else {
        throw const ServerFailure(
          'Failed to like review',
          code: 'REVIEW_LIKE_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure('Failed to like review: $e', code: 'UNKNOWN_ERROR');
    }
  }

  /// Dislike a review
  Future<ReviewLikeResult> dislikeReview(int reviewId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/contents/reviews/$reviewId/dislike',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReviewLikeResult(
          likes: response.data!['likes'] as int,
          dislikes: response.data!['dislikes'] as int,
        );
      } else {
        throw const ServerFailure(
          'Failed to dislike review',
          code: 'REVIEW_DISLIKE_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure('Failed to dislike review: $e', code: 'UNKNOWN_ERROR');
    }
  }
}

class ReviewSubmitResult {
  final bool success;
  final Map<String, dynamic> review;

  ReviewSubmitResult({required this.success, required this.review});
}

class ReviewLikeResult {
  final int likes;
  final int dislikes;

  ReviewLikeResult({required this.likes, required this.dislikes});
}
