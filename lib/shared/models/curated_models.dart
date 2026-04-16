class CuratedContent {
  final int id;
  final String title;
  final String authorName;
  final String cover;
  final Map<String, dynamic> price;
  final bool isFree;
  final bool premiumOnly;
  final double averageRating;
  final String reviews;
  final String type;
  final String description;
  final List<Wishlist> wishlists;

  CuratedContent({
    required this.id,
    required this.title,
    required this.authorName,
    required this.cover,
    required this.price,
    required this.isFree,
    required this.premiumOnly,
    required this.averageRating,
    required this.reviews,
    required this.type,
    required this.description,
    required this.wishlists,
  });

  factory CuratedContent.fromJson(Map<String, dynamic> json) {
    return CuratedContent(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      authorName: json['author_name'] ?? '',
      cover: json['cover'] ?? '',
      price: json['price'] is Map ? Map<String, dynamic>.from(json['price']) : {},
      isFree: json['isFree'] ?? false,
      premiumOnly: json['premiumOnly'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      reviews: json['reviews']?.toString() ?? '0',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      wishlists: (json['wishlists'] as List?)
              ?.map((w) => Wishlist.fromJson(w))
              .toList() ??
          [],
    );
  }
}

class Wishlist {
  final int userId;
  final int resourceId;
  final String resourceType;

  Wishlist({
    required this.userId,
    required this.resourceId,
    required this.resourceType,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      userId: json['user_id'] ?? json['user'] ?? 0,
      resourceId: json['resource_id'] ?? json['resource'] ?? 0,
      resourceType: json['resource_type'] ?? '',
    );
  }
}

class GenreConfig {
  final String id;
  final String title;
  final String description;
  final String color;
  final String apiEndpoint;

  const GenreConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.apiEndpoint,
  });
}
