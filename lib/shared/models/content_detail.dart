import 'package:equatable/equatable.dart';
import 'content.dart';
import 'review.dart';

/// Content detail response model with additional information
class ContentDetail extends Equatable {
  final Content content;
  final List<Content> similarContent;
  final List<Review> reviews;
  final bool isPurchased;
  final bool isInLibrary;
  final String? previewUrl;
  final bool? isWishlisted;
  final AuthorInfo? authorInfo;
  final bool isPremiumOnly;
  final bool isPurchaseOnly;
  final bool? withinFreeLimit;
  final bool? withinNonFreeLimit;
  final String? userSubscriptionTier;

  const ContentDetail({
    required this.content,
    this.similarContent = const [],
    this.reviews = const [],
    this.isPurchased = false,
    this.isInLibrary = false,
    this.previewUrl,
    this.isWishlisted,
    this.authorInfo,
    this.isPremiumOnly = false,
    this.isPurchaseOnly = false,
    this.withinFreeLimit,
    this.withinNonFreeLimit,
    this.userSubscriptionTier,
  });

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    return ContentDetail(
      content: Content.fromJson(json['content'] as Map<String, dynamic>),
      similarContent: (json['similar_content'] as List<dynamic>?)
              ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPurchased: json['is_purchased'] as bool? ?? false,
      isInLibrary: json['is_in_library'] as bool? ?? false,
      previewUrl: json['preview_url'] as String?,
      isWishlisted: json['is_wishlisted'] as bool?,
      authorInfo: json['author_info'] != null
          ? AuthorInfo.fromJson(json['author_info'] as Map<String, dynamic>)
          : null,
      isPremiumOnly: json['is_premium_only'] as bool? ?? false,
      isPurchaseOnly: json['is_purchase_only'] as bool? ?? false,
      withinFreeLimit: json['within_free_limit'] as bool?,
      withinNonFreeLimit: json['within_non_free_limit'] as bool?,
      userSubscriptionTier: json['user_subscription_tier'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.toJson(),
      'similar_content': similarContent.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'is_purchased': isPurchased,
      'is_in_library': isInLibrary,
      'preview_url': previewUrl,
      'is_wishlisted': isWishlisted,
      'author_info': authorInfo?.toJson(),
      'is_premium_only': isPremiumOnly,
      'is_purchase_only': isPurchaseOnly,
      'within_free_limit': withinFreeLimit,
      'within_non_free_limit': withinNonFreeLimit,
      'user_subscription_tier': userSubscriptionTier,
    };
  }

  @override
  List<Object?> get props => [
        content,
        similarContent,
        reviews,
        isPurchased,
        isInLibrary,
        previewUrl,
        isWishlisted,
        authorInfo,
        isPremiumOnly,
        isPurchaseOnly,
        withinFreeLimit,
        withinNonFreeLimit,
        userSubscriptionTier,
      ];
}

/// Author info model
class AuthorInfo extends Equatable {
  final int followersCount;
  final bool isFollowing;

  const AuthorInfo({
    required this.followersCount,
    required this.isFollowing,
  });

  factory AuthorInfo.fromJson(Map<String, dynamic> json) {
    return AuthorInfo(
      followersCount: json['followers_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'is_following': isFollowing,
    };
  }

  @override
  List<Object?> get props => [followersCount, isFollowing];
}
