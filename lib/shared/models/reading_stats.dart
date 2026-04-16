import 'package:equatable/equatable.dart';

/// Reading statistics model
class ReadingStats extends Equatable {
  final int booksRead;
  final int totalReadingTimeMinutes;
  final int currentStreak;
  final int longestStreak;
  final String? favoriteGenre;
  final int pagesRead;

  const ReadingStats({
    this.booksRead = 0,
    this.totalReadingTimeMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.favoriteGenre,
    this.pagesRead = 0,
  });

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      booksRead: json['books_read'] as int? ?? 0,
      totalReadingTimeMinutes: json['total_reading_time_minutes'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      favoriteGenre: json['favorite_genre'] as String?,
      pagesRead: json['pages_read'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'books_read': booksRead,
      'total_reading_time_minutes': totalReadingTimeMinutes,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'favorite_genre': favoriteGenre,
      'pages_read': pagesRead,
    };
  }

  ReadingStats copyWith({
    int? booksRead,
    int? totalReadingTimeMinutes,
    int? currentStreak,
    int? longestStreak,
    String? favoriteGenre,
    int? pagesRead,
  }) {
    return ReadingStats(
      booksRead: booksRead ?? this.booksRead,
      totalReadingTimeMinutes: totalReadingTimeMinutes ?? this.totalReadingTimeMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      pagesRead: pagesRead ?? this.pagesRead,
    );
  }

  @override
  List<Object?> get props => [
        booksRead,
        totalReadingTimeMinutes,
        currentStreak,
        longestStreak,
        favoriteGenre,
        pagesRead,
      ];
}
