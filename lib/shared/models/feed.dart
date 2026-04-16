import 'package:equatable/equatable.dart';
import 'content.dart';

/// A single item in the feed — maps to FeedItem on the web
class FeedItem extends Equatable {
  final int id;
  final String title;
  final String author;
  final int? authorId;
  final String type;
  final String imageUrl;
  final Map<String, double> price;
  final bool isFree;
  final bool isPremiumOnly;
  final double rating;
  final int reviewCount;
  final bool isWishlisted;
  final String? publishDate;
  final int? estimatedReadTime;
  final String? description;
  final double? progress; // for continue_reading sections

  const FeedItem({
    required this.id,
    required this.title,
    required this.author,
    this.authorId,
    required this.type,
    required this.imageUrl,
    required this.price,
    required this.isFree,
    required this.isPremiumOnly,
    required this.rating,
    required this.reviewCount,
    required this.isWishlisted,
    this.publishDate,
    this.estimatedReadTime,
    this.description,
    this.progress,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    Map<String, double> priceMap = {};
    final rawPrice = json['price'];
    if (rawPrice is Map) {
      priceMap = (rawPrice as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    } else if (rawPrice is num) {
      priceMap = {'NGN': rawPrice.toDouble()};
    }

    return FeedItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      authorId: json['authorId'] as int?,
      type: json['type'] as String? ?? 'book',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: priceMap,
      isFree: json['isFree'] as bool? ?? false,
      isPremiumOnly: json['isPremiumOnly'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isWishlisted: json['isWishlisted'] as bool? ?? false,
      publishDate: json['publishDate'] as String?,
      estimatedReadTime: json['estimatedReadTime'] as int?,
      description: json['description'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
    );
  }

  /// Convert to the shared Content model for use with existing widgets
  Content toContent() {
    return Content(
      id: id,
      type: type,
      title: title,
      authorName: author,
      authorId: authorId,
      description: description,
      cover: imageUrl,
      price: price,
      isFree: isFree,
      averageRating: rating,
      ratingCount: reviewCount,
      reviewCount: reviewCount,
      estimatedReadTime: estimatedReadTime,
      categories: [],
      publishDate: publishDate,
    );
  }

  @override
  List<Object?> get props => [id, title, author, type, imageUrl, price,
      isFree, isPremiumOnly, rating, reviewCount, isWishlisted, progress];
}

/// Creator item for creator_spotlight sections
class FeedCreator extends Equatable {
  final int id;
  final String name;
  final String bio;
  final String profilePicture;
  final int contentCount;
  final int followersCount;
  final bool isFollowing;

  const FeedCreator({
    required this.id,
    required this.name,
    required this.bio,
    required this.profilePicture,
    required this.contentCount,
    required this.followersCount,
    required this.isFollowing,
  });

  factory FeedCreator.fromJson(Map<String, dynamic> json) {
    return FeedCreator(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePicture: json['profilePicture'] as String? ?? '',
      contentCount: json['contentCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, bio, profilePicture, contentCount,
      followersCount, isFollowing];
}

/// Reading stats for stats_nudge sections
class FeedStats extends Equatable {
  final int booksThisMonth;
  final int streakDays;

  const FeedStats({required this.booksThisMonth, required this.streakDays});

  factory FeedStats.fromJson(Map<String, dynamic> json) {
    return FeedStats(
      booksThisMonth: json['booksThisMonth'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [booksThisMonth, streakDays];
}

/// A single section in the feed
class FeedSection extends Equatable {
  final String type;
  final String title;
  final List<FeedItem> items;
  final List<FeedCreator> creators;
  final FeedStats? stats;
  final String? viewAllUrl;
  final int? genreId;

  const FeedSection({
    required this.type,
    required this.title,
    required this.items,
    this.creators = const [],
    this.stats,
    this.viewAllUrl,
    this.genreId,
  });

  factory FeedSection.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';

    // Creator spotlight sections have creator objects, not content items
    List<FeedCreator> creators = [];
    List<FeedItem> items = [];

    if (type == 'creator_spotlight') {
      creators = (json['items'] as List<dynamic>?)
              ?.map((e) => FeedCreator.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } else if (type != 'stats_nudge') {
      items = (json['items'] as List<dynamic>?)
              ?.map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    FeedStats? stats;
    if (type == 'stats_nudge' && json['stats'] != null) {
      stats = FeedStats.fromJson(json['stats'] as Map<String, dynamic>);
    }

    return FeedSection(
      type: type,
      title: json['title'] as String? ?? '',
      items: items,
      creators: creators,
      stats: stats,
      viewAllUrl: json['viewAllUrl'] as String?,
      genreId: json['genreId'] as int?,
    );
  }

  bool get isEmpty => items.isEmpty && creators.isEmpty && stats == null;

  @override
  List<Object?> get props => [type, title, items, creators, stats, viewAllUrl];
}

/// The full feed response
class FeedResponse extends Equatable {
  final List<FeedSection> feed;
  final bool isPersonalised;

  const FeedResponse({required this.feed, required this.isPersonalised});

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      feed: (json['feed'] as List<dynamic>?)
              ?.map((e) => FeedSection.fromJson(e as Map<String, dynamic>))
              .where((s) => !s.isEmpty)
              .toList() ??
          [],
      isPersonalised: json['isPersonalised'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [feed, isPersonalised];
}
