import 'package:equatable/equatable.dart';

/// Library item model representing a book in user's library
class LibraryItem extends Equatable {
  final int id;
  final String title;
  final String author;
  final String? cover;
  final String type;
  final double progress;
  final int? currentPage;
  final int? totalPages;
  final String? lastReadAt;
  final bool isFavorite;
  final bool isPurchased;
  final bool isFinished;
  final double rating;
  final int reviewCount;
  final String? description;
  final List<String> categories;

  const LibraryItem({
    required this.id,
    required this.title,
    required this.author,
    this.cover,
    required this.type,
    required this.progress,
    this.currentPage,
    this.totalPages,
    this.lastReadAt,
    required this.isFavorite,
    required this.isPurchased,
    required this.isFinished,
    required this.rating,
    required this.reviewCount,
    this.description,
    required this.categories,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String? ?? json['author_name'] as String? ?? 'Unknown',
      cover: json['cover'] as String?,
      type: json['type'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentPage: json['current_page'] as int?,
      totalPages: json['total_pages'] as int?,
      lastReadAt: json['last_read_at'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPurchased: json['is_purchased'] as bool? ?? false,
      isFinished: json['is_finished'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      description: json['description'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover': cover,
      'type': type,
      'progress': progress,
      'current_page': currentPage,
      'total_pages': totalPages,
      'last_read_at': lastReadAt,
      'is_favorite': isFavorite,
      'is_purchased': isPurchased,
      'is_finished': isFinished,
      'rating': rating,
      'review_count': reviewCount,
      'description': description,
      'categories': categories,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        cover,
        type,
        progress,
        currentPage,
        totalPages,
        lastReadAt,
        isFavorite,
        isPurchased,
        isFinished,
        rating,
        reviewCount,
        description,
        categories,
      ];
}

/// Reading statistics model
class ReadingStats extends Equatable {
  final int totalBooksRead;
  final int currentStreak;
  final int booksThisMonth;
  final int totalReadingTime;
  final int currentlyReadingCount;

  const ReadingStats({
    required this.totalBooksRead,
    required this.currentStreak,
    required this.booksThisMonth,
    required this.totalReadingTime,
    required this.currentlyReadingCount,
  });

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalBooksRead: json['total_books_read'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      booksThisMonth: json['books_this_month'] as int? ?? 0,
      totalReadingTime: json['total_reading_time'] as int? ?? 0,
      currentlyReadingCount: json['currently_reading_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_books_read': totalBooksRead,
      'current_streak': currentStreak,
      'books_this_month': booksThisMonth,
      'total_reading_time': totalReadingTime,
      'currently_reading_count': currentlyReadingCount,
    };
  }

  @override
  List<Object?> get props => [
        totalBooksRead,
        currentStreak,
        booksThisMonth,
        totalReadingTime,
        currentlyReadingCount,
      ];
}

/// Library response model
class LibraryResponse extends Equatable {
  final List<LibraryItem> currentlyReading;
  final List<LibraryItem> purchased;
  final List<LibraryItem> recentlyViewed;
  final List<LibraryItem> finished;
  final List<LibraryItem> favorites;
  final ReadingStats stats;

  const LibraryResponse({
    required this.currentlyReading,
    required this.purchased,
    required this.recentlyViewed,
    required this.finished,
    required this.favorites,
    required this.stats,
  });

  factory LibraryResponse.fromJson(Map<String, dynamic> json) {
    return LibraryResponse(
      currentlyReading: (json['currently_reading'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      purchased: (json['purchased'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentlyViewed: (json['recently_viewed'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      finished: (json['finished'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? ReadingStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const ReadingStats(
              totalBooksRead: 0,
              currentStreak: 0,
              booksThisMonth: 0,
              totalReadingTime: 0,
              currentlyReadingCount: 0,
            ),
    );
  }

  @override
  List<Object?> get props => [
        currentlyReading,
        purchased,
        recentlyViewed,
        finished,
        favorites,
        stats,
      ];
}
