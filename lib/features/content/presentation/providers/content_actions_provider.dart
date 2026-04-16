import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/content_actions_repository.dart';
import '../../data/repositories/content_actions_repository_provider.dart';

/// State for content actions
class ContentActionsState {
  final bool isWishlistLoading;
  final bool isFollowLoading;
  final bool isReviewLoading;
  final int? reviewLoadingId;
  final String? error;

  const ContentActionsState({
    this.isWishlistLoading = false,
    this.isFollowLoading = false,
    this.isReviewLoading = false,
    this.reviewLoadingId,
    this.error,
  });

  ContentActionsState copyWith({
    bool? isWishlistLoading,
    bool? isFollowLoading,
    bool? isReviewLoading,
    int? reviewLoadingId,
    String? error,
  }) {
    return ContentActionsState(
      isWishlistLoading: isWishlistLoading ?? this.isWishlistLoading,
      isFollowLoading: isFollowLoading ?? this.isFollowLoading,
      isReviewLoading: isReviewLoading ?? this.isReviewLoading,
      reviewLoadingId: reviewLoadingId,
      error: error,
    );
  }
}

/// Notifier for content actions
class ContentActionsNotifier extends StateNotifier<ContentActionsState> {
  ContentActionsNotifier(this._repository)
      : super(const ContentActionsState());

  final ContentActionsRepository _repository;

  /// Toggle wishlist
  Future<bool> toggleWishlist({
    required int resourceId,
    required String resourceType,
  }) async {
    state = state.copyWith(isWishlistLoading: true, error: null);

    try {
      final result = await _repository.toggleWishlist(
        resourceId: resourceId,
        resourceType: resourceType,
      );

      state = state.copyWith(isWishlistLoading: false);
      return result['is_wishlisted'] as bool? ?? false;
    } catch (e) {
      state = state.copyWith(
        isWishlistLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Submit review
  Future<Map<String, dynamic>> submitReview({
    required int resourceId,
    required String resourceType,
    required String reviewText,
    required int rating,
  }) async {
    state = state.copyWith(isReviewLoading: true, error: null);

    try {
      final result = await _repository.submitReview(
        resourceId: resourceId,
        resourceType: resourceType,
        reviewText: reviewText,
        rating: rating,
      );

      state = state.copyWith(isReviewLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isReviewLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Like review
  Future<Map<String, dynamic>> likeReview(int reviewId) async {
    state = state.copyWith(reviewLoadingId: reviewId, error: null);

    try {
      final result = await _repository.likeReview(reviewId);
      state = state.copyWith(reviewLoadingId: null);
      return result;
    } catch (e) {
      state = state.copyWith(reviewLoadingId: null, error: e.toString());
      rethrow;
    }
  }

  /// Dislike review
  Future<Map<String, dynamic>> dislikeReview(int reviewId) async {
    state = state.copyWith(reviewLoadingId: reviewId, error: null);

    try {
      final result = await _repository.dislikeReview(reviewId);
      state = state.copyWith(reviewLoadingId: null);
      return result;
    } catch (e) {
      state = state.copyWith(reviewLoadingId: null, error: e.toString());
      rethrow;
    }
  }

  /// Toggle follow
  Future<bool> toggleFollow({
    required String targetType,
    required int targetId,
  }) async {
    state = state.copyWith(isFollowLoading: true, error: null);

    try {
      final result = await _repository.toggleFollow(
        targetType: targetType,
        targetId: targetId,
      );

      state = state.copyWith(isFollowLoading: false);
      return result['is_following'] as bool? ?? false;
    } catch (e) {
      state = state.copyWith(
        isFollowLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Add to cart
  Future<void> addToCart({
    required int resourceId,
    required String resourceType,
  }) async {
    try {
      await _repository.addToCart(
        resourceId: resourceId,
        resourceType: resourceType,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Provider for content actions
final contentActionsProvider =
    StateNotifierProvider<ContentActionsNotifier, ContentActionsState>((ref) {
  final repository = ref.watch(contentActionsRepositoryProvider);
  return ContentActionsNotifier(repository);
});
