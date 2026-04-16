// Author profile models

class AuthorAward {
  final String award;
  final String year;
  final String work;

  AuthorAward({
    required this.award,
    required this.year,
    required this.work,
  });

  factory AuthorAward.fromJson(Map<String, dynamic> json) {
    return AuthorAward(
      award: json['award'] ?? '',
      year: json['year'] ?? '',
      work: json['work'] ?? '',
    );
  }
}

class AuthorData {
  final int id;
  final String name;
  final String bio;
  final String? profilePicture;
  final int followers;
  final bool verified;
  final String? background;
  final List<AuthorAward> awards;
  final bool isFollowing;

  AuthorData({
    required this.id,
    required this.name,
    required this.bio,
    this.profilePicture,
    required this.followers,
    required this.verified,
    this.background,
    required this.awards,
    required this.isFollowing,
  });

  factory AuthorData.fromJson(Map<String, dynamic> json) {
    return AuthorData(
      id: json['id'],
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      profilePicture: json['profile_picture'] ?? json['profilePicture'],
      followers: json['followers'] ?? 0,
      verified: json['verified'] ?? false,
      background: json['background'],
      awards: (json['awards'] as List?)
              ?.map((award) => AuthorAward.fromJson(award))
              .toList() ??
          [],
      isFollowing: json['is_following'] ?? json['isFollowing'] ?? false,
    );
  }
}

class AuthorStatistics {
  final int totalReads;
  final double? monthlyRevenue;
  final double avgRating;
  final int totalLikes;
  final int totalBooks;
  final int totalAwards;

  AuthorStatistics({
    required this.totalReads,
    this.monthlyRevenue,
    required this.avgRating,
    required this.totalLikes,
    required this.totalBooks,
    required this.totalAwards,
  });

  factory AuthorStatistics.fromJson(Map<String, dynamic> json) {
    return AuthorStatistics(
      totalReads: json['total_reads'] ?? json['totalReads'] ?? 0,
      monthlyRevenue: json['monthly_revenue']?.toDouble() ?? json['monthlyRevenue']?.toDouble(),
      avgRating: (json['avg_rating'] ?? json['avgRating'] ?? 0).toDouble(),
      totalLikes: json['total_likes'] ?? json['totalLikes'] ?? 0,
      totalBooks: json['total_books'] ?? json['totalBooks'] ?? 0,
      totalAwards: json['total_awards'] ?? json['totalAwards'] ?? 0,
    );
  }
}

class AuthorResource {
  final int id;
  final String title;
  final String type;
  final int year;
  final double rating;
  final int reviews;
  final dynamic price; // Can be number or object
  final String? cover;
  final bool isBestseller;
  final bool isFree;
  final bool premiumOnly;

  AuthorResource({
    required this.id,
    required this.title,
    required this.type,
    required this.year,
    required this.rating,
    required this.reviews,
    required this.price,
    this.cover,
    required this.isBestseller,
    required this.isFree,
    required this.premiumOnly,
  });

  factory AuthorResource.fromJson(Map<String, dynamic> json) {
    return AuthorResource(
      id: json['id'],
      title: json['title'] ?? '',
      type: json['type'] ?? 'book',
      year: json['year'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      price: json['price'],
      cover: json['cover'],
      isBestseller: json['is_bestseller'] ?? json['isBestseller'] ?? false,
      isFree: json['is_free'] ?? json['isFree'] ?? false,
      premiumOnly: json['premium_only'] ?? json['premiumOnly'] ?? false,
    );
  }
}

class AuthorProfile {
  final AuthorData author;
  final AuthorStatistics statistics;
  final List<AuthorResource> resources;

  AuthorProfile({
    required this.author,
    required this.statistics,
    required this.resources,
  });

  factory AuthorProfile.fromJson(Map<String, dynamic> json) {
    return AuthorProfile(
      author: AuthorData.fromJson(json['author']),
      statistics: AuthorStatistics.fromJson(json['statistics']),
      resources: (json['resources'] as List)
          .map((resource) => AuthorResource.fromJson(resource))
          .toList(),
    );
  }
}
