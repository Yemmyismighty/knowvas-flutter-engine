import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/review.dart';
import '../providers/reviews_provider.dart';
import '../widgets/rating_widget.dart';

/// Reviews screen showing all reviews for content
class ReviewsScreen extends HookConsumerWidget {
  const ReviewsScreen({
    required this.contentId,
    this.contentTitle,
    super.key,
  });

  final int contentId;
  final String? contentTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsState = ref.watch(reviewsProvider(contentId));
    final reviewsNotifier = ref.read(reviewsProvider(contentId).notifier);
    final scrollController = useScrollController();

    // Listen for scroll to load more
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          reviewsNotifier.loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Scaffold(
      appBar: AppBar(
        title: Text(contentTitle != null ? '$contentTitle Reviews' : 'Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => reviewsNotifier.changeSortOrder(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: 'helpful',
                child: Text('Most Helpful'),
              ),
              const PopupMenuItem(
                value: 'rating_high',
                child: Text('Highest Rating'),
              ),
              const PopupMenuItem(
                value: 'rating_low',
                child: Text('Lowest Rating'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reviewsNotifier.refresh,
        child: _buildBody(context, reviewsState, reviewsNotifier, scrollController),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteReviewDialog(context, ref),
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReviewsState state,
    Reviews notifier,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: notifier.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to write a review!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Rating summary
        _buildRatingSummary(context, state),
        const Divider(height: 1),
        // Reviews list
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= state.reviews.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _ReviewCard(
                review: state.reviews[index],
                onLike: () => notifier.likeReview(state.reviews[index].id),
                onUnlike: () => notifier.unlikeReview(state.reviews[index].id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary(BuildContext context, ReviewsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              RatingWidget(
                rating: state.averageRating,
                size: 20,
                isReadOnly: true,
              ),
              const SizedBox(height: 4),
              Text(
                '${state.totalCount} ${state.totalCount == 1 ? 'review' : 'reviews'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WriteReviewSheet(contentId: contentId),
    );
  }
}

/// Review card widget
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onLike,
    required this.onUnlike,
  });

  final Review review;
  final VoidCallback onLike;
  final VoidCallback onUnlike;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.profilePicture != null
                    ? NetworkImage(review.profilePicture!)
                    : null,
                child: review.profilePicture == null
                    ? Text(review.username[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      review.createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              RatingWidget(
                rating: review.rating.toDouble(),
                size: 16,
                isReadOnly: true,
              ),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          // Like button
          Row(
            children: [
              TextButton.icon(
                onPressed: (review.userLikeStatus == true) ? onUnlike : onLike,
                icon: Icon(
                  (review.userLikeStatus == true)
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 16,
                ),
                label: Text('${review.likes}'),
                style: TextButton.styleFrom(
                  foregroundColor: (review.userLikeStatus == true)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Write review bottom sheet
class _WriteReviewSheet extends HookConsumerWidget {
  const _WriteReviewSheet({
    required this.contentId,
  });

  final int contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = useState<double>(5.0);
    final reviewController = useTextEditingController();
    final reviewSubmission = ref.watch(reviewSubmissionProvider);

    ref.listen<AsyncValue<Review?>>(reviewSubmissionProvider, (previous, next) {
      next.whenOrNull(
        data: (review) {
          if (review != null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted successfully')),
            );
            ref.read(reviewSubmissionProvider.notifier).reset();
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit review: $error')),
          );
        },
      );
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Write a Review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Rating selector
            Center(
              child: Column(
                children: [
                  Text(
                    'Your Rating',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InteractiveRatingWidget(
                    initialRating: rating.value,
                    onRatingChanged: (newRating) => rating.value = newRating,
                    size: 40,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rating.value.toStringAsFixed(1)} stars',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Review text
            TextField(
              controller: reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                hintText: 'Share your thoughts about this content...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            FilledButton(
              onPressed: reviewSubmission.isLoading
                  ? null
                  : () {
                      if (reviewController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please write a review'),
                          ),
                        );
                        return;
                      }
                      ref.read(reviewSubmissionProvider.notifier).submitReview(
                            contentId: contentId,
                            rating: rating.value,
                            reviewText: reviewController.text.trim(),
                          );
                    },
              child: reviewSubmission.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}

