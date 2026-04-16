import 'package:equatable/equatable.dart';

/// Content model for books, audiobooks, etc.
class Content extends Equatable {
  final int id;
  final String type;
  final String title;
  final String authorName;
  final int? authorId;
  final String? description;
  final String? cover;
  final Map<String, double>? price;
  final bool isFree;
  final String? language;
  final int? year;
  final double averageRating;
  final int ratingCount;
  final int reviewCount;
  final int? estimatedReadTime;
  final List<String> categories;
  final String? fileType;
  
  // Computed properties for backward compatibility
  String get coverUrl => cover ?? '';
  double get ratingAverage => averageRating;
  List<String> get genres => categories;
  bool get premiumOnly => false; // Default value
  int? get totalPages => null; // Default value
  String? get publisher => null; // Default value
  String? get publishedDate => publishDate;
  String? get isbn => null; // Default value
  final String? publishDate;

  const Content({
    required this.id,
    required this.type,
    required this.title,
    required this.authorName,
    this.authorId,
    this.description,
    this.cover,
    this.price,
    required this.isFree,
    this.language,
    this.year,
    required this.averageRating,
    required this.ratingCount,
    required this.reviewCount,
    this.estimatedReadTime,
    required this.categories,
    this.publishDate,
    this.fileType,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    // Handle price - can be either a number or a map
    Map<String, double>? priceMap;
    if (json['price'] != null) {
      if (json['price'] is num) {
        // If it's a number, convert to map
        priceMap = {'NGN': (json['price'] as num).toDouble()};
      } else if (json['price'] is Map) {
        // If it's already a map, convert values to double
        final priceData = json['price'] as Map<String, dynamic>;
        priceMap = priceData.map((key, value) => 
          MapEntry(key, (value as num).toDouble())
        );
      }
    }
    
    return Content(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      authorName: json['author_name'] as String,
      authorId: json['author_id'] as int?,
      description: json['description'] as String?,
      cover: json['cover'] as String?,
      price: priceMap,
      isFree: json['is_free'] as bool? ?? false,
      language: json['language'] as String?,
      year: json['year'] as int?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      estimatedReadTime: (json['estimated_read_time'] as num?)?.toInt(),
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      publishDate: json['publish_date'] as String?,
      fileType: json['file_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'author_name': authorName,
      'author_id': authorId,
      'description': description,
      'cover': cover,
      'price': price?['NGN'],
      'is_free': isFree,
      'language': language,
      'year': year,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'review_count': reviewCount,
      'estimated_read_time': estimatedReadTime,
      'categories': categories,
      'publish_date': publishDate,
      'file_type': fileType,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        authorName,
        authorId,
        description,
        cover,
        price,
        isFree,
        language,
        year,
        averageRating,
        ratingCount,
        reviewCount,
        estimatedReadTime,
        categories,
        publishDate,
        fileType,
      ];
}

/// Genre model
class Genre extends Equatable {
  final String name;
  final int count;

  const Genre({
    required this.name,
    required this.count,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }

  @override
  List<Object?> get props => [name, count];
}

/// Discover response model
class DiscoverResponse extends Equatable {
  final List<Content> trending;
  final List<Content> newReleases;
  final List<Content> bestsellers;
  final List<Content> freeBooks;
  final List<Genre> genres;

  const DiscoverResponse({
    required this.trending,
    required this.newReleases,
    required this.bestsellers,
    required this.freeBooks,
    required this.genres,
  });

  factory DiscoverResponse.fromJson(Map<String, dynamic> json) {
    return DiscoverResponse(
      trending: (json['trending'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      newReleases: (json['new_releases'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      bestsellers: (json['bestsellers'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      freeBooks: (json['free_books'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((item) => Genre.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [trending, newReleases, bestsellers, freeBooks, genres];
}