import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/models/review.dart';

/// Repository for rating and review operations
/// Handles rating content, writing reviews, fetching reviews, and liking reviews
class RatingRepository {
  RatingRepository({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _apiClient = apiClient,
        _networkInfo = networkInfo;

  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  // In-memory cache for reviews
  final Map<String, _CachedReviews> _reviewsCache = {};

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Rate content with a star rating (1-5)
  /// Throws RatingFailure on errors
  Future<void> rateContent({
    required int contentId,
    required double rating,
  }) async {
    try {
      // Validate rating
      if (rating < 1.0 || rating > 5.0) {
        throw const RatingFailure(
          'Rating must be between 1 and 5',
          code: 'INVALID_RATING',
        );
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.content}/$contentId/rate',
        data: {
          'rating': rating,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalidate cache to force refresh
        _clearContentReviewsCache(contentId);
      } else {
        throw RatingFailure(
          'Failed to rate content',
          code: 'RATE_FAILED',
          contentId: contentId,
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
      throw RatingFailure(
        e.message,
        code: e.code,
        contentId: contentId,
      );
    } catch (e) {
      if (e is RatingFailure) rethrow;
      throw RatingFailure(
        'An unexpected error occurred while rating content: $e',
        code: 'UNKNOWN_ERROR',
        contentId: contentId,
      );
    }
  }

  /// Write a review for content
  /// Throws RatingFailure on errors
  Future<Review> writeReview({
    required int contentId,
    required double rating,
    required String reviewText,
  }) async {
    try {
      // Validate rating
      if (rating < 1.0 || rating > 5.0) {
        throw const RatingFailure(
          'Rating must be between 1 and 5',
          code: 'INVALID_RATING',
        );
      }

      // Validate review text
      if (reviewText.trim().isEmpty) {
        throw const RatingFailure(
          'Review text cannot be empty',
          code: 'EMPTY_REVIEW',
        );
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.content}/$contentId/review',
        data: {
          'rating': rating,
          'review_text': reviewText,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 && response.data != null) {
        // Invalidate cache to force refresh
        _clearContentReviewsCache(contentId);

        return Review.fromJson(response.data!);
      } else {
        throw RatingFailure(
          'Failed to write review',
          code: 'REVIEW_FAILED',
          contentId: contentId,
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
      throw RatingFailure(
        e.message,
        code: e.code,
        contentId: contentId,
      );
    } catch (e) {
      if (e is RatingFailure) rethrow;
      throw RatingFailure(
        'An unexpected error occurred while writing review: $e',
        code: 'UNKNOWN_ERROR',
        contentId: contentId,
      );
    }
  }

  /// Get reviews for content
  /// Returns ReviewsList with reviews and pagination info
  /// Implements caching to reduce network requests
  /// Throws RatingFailure on errors
  Future<ReviewsList> getReviews({
    required int contentId,
    int page = 1,
    int limit = 20,
    String sortBy = 'recent', // 'recent', 'helpful', 'rating_high', 'rating_low'
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'reviews_$contentId\_$page\_$limit\_$sortBy';

      // Check if we have a valid cached response
      if (!forceRefresh && _reviewsCache.containsKey(cacheKey)) {
        final cached = _reviewsCache[cacheKey]!;
        if (!cached.isExpired) {
          return cached.data;
        }
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        // If we have expired cache, return it anyway when offline
        if (_reviewsCache.containsKey(cacheKey)) {
          return _reviewsCache[cacheKey]!.data;
        }
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      // Fetch from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.content}/$contentId/reviews',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort_by': sortBy,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final reviewsList = ReviewsList.fromJson(response.data!);

        // Cache the response
        _reviewsCache[cacheKey] = _CachedReviews(
          data: reviewsList,
          cachedAt: DateTime.now(),
        );

        return reviewsList;
      } else {
        throw RatingFailure(
          'Failed to fetch reviews',
          code: 'FETCH_REVIEWS_FAILED',
          contentId: contentId,
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
      throw RatingFailure(
        e.message,
        code: e.code,
        contentId: contentId,
      );
    } catch (e) {
      if (e is RatingFailure) rethrow;
      throw RatingFailure(
        'An unexpected error occurred while fetching reviews: $e',
        code: 'UNKNOWN_ERROR',
        contentId: contentId,
      );
    }
  }

  /// Like a review
  /// Throws RatingFailure on errors
  Future<void> likeReview({
    required int reviewId,
  }) async {
    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.content}/reviews/$reviewId/like',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalidate all review caches to force refresh
        _reviewsCache.clear();
      } else {
        throw RatingFailure(
          'Failed to like review',
          code: 'LIKE_FAILED',
          reviewId: reviewId,
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
      throw RatingFailure(
        e.message,
        code: e.code,
        reviewId: reviewId,
      );
    } catch (e) {
      throw RatingFailure(
        'An unexpected error occurred while liking review: $e',
        code: 'UNKNOWN_ERROR',
        reviewId: reviewId,
      );
    }
  }

  /// Unlike a review
  /// Throws RatingFailure on errors
  Future<void> unlikeReview({
    required int reviewId,
  }) async {
    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConstants.content}/reviews/$reviewId/like',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalidate all review caches to force refresh
        _reviewsCache.clear();
      } else {
        throw RatingFailure(
          'Failed to unlike review',
          code: 'UNLIKE_FAILED',
          reviewId: reviewId,
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
      throw RatingFailure(
        e.message,
        code: e.code,
        reviewId: reviewId,
      );
    } catch (e) {
      throw RatingFailure(
        'An unexpected error occurred while unliking review: $e',
        code: 'UNKNOWN_ERROR',
        reviewId: reviewId,
      );
    }
  }

  /// Clear all cached data
  void clearCache() {
    _reviewsCache.clear();
  }

  /// Clear reviews cache for a specific content
  void _clearContentReviewsCache(int contentId) {
    _reviewsCache.removeWhere(
      (key, value) => key.startsWith('reviews_$contentId\_'),
    );
  }
}

/// Cached reviews with expiration
class _CachedReviews {
  final ReviewsList data;
  final DateTime cachedAt;

  _CachedReviews({
    required this.data,
    required this.cachedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > RatingRepository._cacheDuration;
}

/// Reviews list response model
class ReviewsList {
  final List<Review> reviews;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final double averageRating;

  const ReviewsList({
    this.reviews = const [],
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    this.averageRating = 0.0,
  });

  factory ReviewsList.fromJson(Map<String, dynamic> json) {
    return ReviewsList(
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'average_rating': averageRating,
    };
  }
}

/// Rating-specific failure
class RatingFailure extends Failure {
  final int? contentId;
  final int? reviewId;

  const RatingFailure(
    String message, {
    String? code,
    this.contentId,
    this.reviewId,
  }) : super(message, code: code);
}
