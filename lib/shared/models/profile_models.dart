import 'package:equatable/equatable.dart';

/// Profile header model
class ProfileHeader extends Equatable {
  final String name;
  final String username;
  final String email;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final String joinDate;
  final int followers;
  final int following;
  final int totalBooksRead;
  final int currentStreak;
  final int longestStreak;
  final String readingLevel;
  final bool emailVerified;
  final bool publicProfile;
  final int booksThisYear;
  final List<String> favoriteGenres;

  const ProfileHeader({
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    this.avatar,
    this.coverImage,
    required this.joinDate,
    required this.followers,
    required this.following,
    required this.totalBooksRead,
    required this.currentStreak,
    required this.longestStreak,
    required this.readingLevel,
    required this.emailVerified,
    required this.publicProfile,
    required this.booksThisYear,
    required this.favoriteGenres,
  });

  factory ProfileHeader.fromJson(Map<String, dynamic> json) {
    return ProfileHeader(
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      coverImage: json['cover_image'] as String?,
      joinDate: json['join_date'] as String? ?? '',
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      totalBooksRead: json['total_books_read'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      readingLevel: json['reading_level'] as String? ?? 'Reader',
      emailVerified: json['email_verified'] as bool? ?? false,
      publicProfile: json['public_profile'] as bool? ?? true,
      booksThisYear: json['books_this_year'] as int? ?? 0,
      favoriteGenres: (json['favorite_genres'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  List<Object?> get props => [
        name,
        username,
        email,
        bio,
        avatar,
        coverImage,
        joinDate,
        followers,
        following,
        totalBooksRead,
        currentStreak,
        longestStreak,
        readingLevel,
        emailVerified,
        publicProfile,
        booksThisYear,
        favoriteGenres,
      ];
}

/// Reading goal model
class ReadingGoal extends Equatable {
  final int year;
  final int targetBooks;
  final int currentBooks;

  const ReadingGoal({
    required this.year,
    required this.targetBooks,
    required this.currentBooks,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      year: json['year'] as int? ?? DateTime.now().year,
      targetBooks: json['target_books'] as int? ?? 0,
      currentBooks: json['current_books'] as int? ?? 0,
    );
  }

  double get progress => targetBooks > 0 ? (currentBooks / targetBooks) * 100 : 0;
  int get remaining => targetBooks - currentBooks;

  @override
  List<Object?> get props => [year, targetBooks, currentBooks];
}

/// Quick stats model
class QuickStats extends Equatable {
  final int contentsThisMonth;
  final double averageRating;
  final String totalReadingTime;
  final int purchases;

  const QuickStats({
    required this.contentsThisMonth,
    required this.averageRating,
    required this.totalReadingTime,
    required this.purchases,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      contentsThisMonth: json['contents_this_month'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReadingTime: json['total_reading_time'] as String? ?? '0h 0m',
      purchases: json['purchases'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [contentsThisMonth, averageRating, totalReadingTime, purchases];
}

/// Achievement model
class Achievement extends Equatable {
  final int id;
  final String name;
  final String description;
  final String icon;
  final bool earned;
  final String? earnedDate;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earned,
    this.earnedDate,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '🏆',
      earned: json['earned'] as bool? ?? false,
      earnedDate: json['earned_date'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, description, icon, earned, earnedDate];
}

/// Activity model
class Activity extends Equatable {
  final String type;
  final String? title;
  final String? author;
  final String? name;
  final int? rating;
  final String timestamp;

  const Activity({
    required this.type,
    this.title,
    this.author,
    this.name,
    this.rating,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      type: json['type'] as String,
      title: json['title'] as String?,
      author: json['author'] as String?,
      name: json['name'] as String?,
      rating: json['rating'] as int?,
      timestamp: json['timestamp'] as String,
    );
  }

  @override
  List<Object?> get props => [type, title, author, name, rating, timestamp];
}
