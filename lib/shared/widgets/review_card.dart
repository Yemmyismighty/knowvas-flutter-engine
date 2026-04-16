import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Card displaying a single review with like/dislike functionality
class ReviewCard extends StatelessWidget {
  final int reviewId;
  final String username;
  final String? profilePicture;
  final int rating;
  final String reviewText;
  final String createdAt;
  final int likes;
  final int dislikes;
  final bool? userLikeStatus; // true = liked, false = disliked, null = no action
  final Function(int reviewId) onLike;
  final Function(int reviewId) onDislike;
  final bool isLoading;

  const ReviewCard({
    required this.reviewId,
    required this.username,
    this.profilePicture,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    this.userLikeStatus,
    required this.onLike,
    required this.onDislike,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Profile picture
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: profilePicture != null
                    ? CachedNetworkImageProvider(profilePicture!)
                    : null,
                child: profilePicture == null
                    ? Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review text
          Text(
            reviewText,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Like/Dislike buttons
          Row(
            children: [
              // Like button
              InkWell(
                onTap: isLoading ? null : () => onLike(reviewId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: userLikeStatus == true
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: userLikeStatus == true
                          ? const Color(0xFF6366F1)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: userLikeStatus == true
                            ? const Color(0xFF6366F1)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: userLikeStatus == true
                              ? const Color(0xFF6366F1)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dislike button
              InkWell(
                onTap: isLoading ? null : () => onDislike(reviewId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: userLikeStatus == false
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: userLikeStatus == false
                          ? Colors.red
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down,
                        size: 16,
                        color: userLikeStatus == false
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dislikes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: userLikeStatus == false
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
