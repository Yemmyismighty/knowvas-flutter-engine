import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/review.dart';
import '../../data/repositories/rating_repository.dart';
import '../../data/repositories/rating_repository_provider.dart';

part 'reviews_provider.g.dart';

/// State for reviews list
class ReviewsState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final double averageRating;
  final int totalCount;

  const ReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.averageRating = 0.0,
    this.totalCount = 0,
  });

  ReviewsState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    double? averageRating,
    int? totalCount,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      averageRating: averageRating ?? this.averageRating,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Provider for reviews list for a specific content
@riverpod
class Reviews extends _$Reviews {
  static const int _pageSize = 20;
  String _sortBy = 'recent';

  @override
  ReviewsState build(int contentId) {
    _loadReviews();
    return const ReviewsState(isLoading: true);
  }

  Future<void> _loadReviews({bool forceRefresh = false}) async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      final reviewsList = await repository.getReviews(
        contentId: contentId,
        page: state.currentPage,
        limit: _pageSize,
        sortBy: _sortBy,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        reviews: reviewsList.reviews,
        isLoading: false,
        error: null,
        currentPage: reviewsList.currentPage,
        totalPages: reviewsList.totalPages,
        hasMore: reviewsList.currentPage < reviewsList.totalPages,
        averageRating: reviewsList.averageRating,
        totalCount: reviewsList.totalCount,
      );
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Refresh reviews list
  Future<void> refresh() async {
    state = state.copyWith(
      currentPage: 1,
      isLoading: true,
      error: null,
    );
    await _loadReviews(forceRefresh: true);
  }

  /// Load next page of reviews
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(
      currentPage: state.currentPage + 1,
      isLoading: true,
    );

    try {
      final repository = ref.read(ratingRepositoryProvider);
      final reviewsList = await repository.getReviews(
        contentId: contentId,
        page: state.currentPage,
        limit: _pageSize,
        sortBy: _sortBy,
      );

      state = state.copyWith(
        reviews: [...state.reviews, ...reviewsList.reviews],
        isLoading: false,
        error: null,
        totalPages: reviewsList.totalPages,
        hasMore: reviewsList.currentPage < reviewsList.totalPages,
      );
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        currentPage: state.currentPage - 1, // Revert page increment
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
        currentPage: state.currentPage - 1, // Revert page increment
      );
    }
  }

  /// Change sort order
  Future<void> changeSortOrder(String sortBy) async {
    if (_sortBy == sortBy) return;

    _sortBy = sortBy;
    state = state.copyWith(
      currentPage: 1,
      isLoading: true,
      error: null,
    );
    await _loadReviews(forceRefresh: true);
  }

  /// Like a review
  Future<void> likeReview(int reviewId) async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.likeReview(reviewId: reviewId);

      // Update the review in the list
      final updatedReviews = state.reviews.map((review) {
        if (review.id == reviewId) {
          return review.copyWith(
            likes: review.likes + 1,
            userLikeStatus: true,
          );
        }
        return review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews.cast<Review>());
    } on Failure catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to like review: $e',
      );
    }
  }

  /// Unlike a review
  Future<void> unlikeReview(int reviewId) async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.unlikeReview(reviewId: reviewId);

      // Update the review in the list
      final updatedReviews = state.reviews.map((review) {
        if (review.id == reviewId) {
          return review.copyWith(
            likes: review.likes - 1,
            userLikeStatus: false,
          );
        }
        return review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews.cast<Review>());
    } on Failure catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to unlike review: $e',
      );
    }
  }
}

/// Provider for submitting a rating
@riverpod
class RatingSubmission extends _$RatingSubmission {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Submit a rating for content
  Future<void> submitRating({
    required int contentId,
    required double rating,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.rateContent(
        contentId: contentId,
        rating: rating,
      );

      // Invalidate reviews to refresh
      ref.invalidate(reviewsProvider(contentId));
    });
  }
}

/// Provider for submitting a review
@riverpod
class ReviewSubmission extends _$ReviewSubmission {
  @override
  AsyncValue<Review?> build() {
    return const AsyncValue.data(null);
  }

  /// Submit a review for content
  Future<void> submitReview({
    required int contentId,
    required double rating,
    required String reviewText,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(ratingRepositoryProvider);
      final review = await repository.writeReview(
        contentId: contentId,
        rating: rating,
        reviewText: reviewText,
      );

      // Invalidate reviews to refresh
      ref.invalidate(reviewsProvider(contentId));

      return review;
    });
  }

  /// Reset the submission state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

