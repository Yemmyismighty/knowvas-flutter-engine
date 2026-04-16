import 'package:equatable/equatable.dart';

/// Reading goal model
class ReadingGoal extends Equatable {
  final int? id;
  final String userId;
  final int year;
  final int? targetBooks;
  final int? targetPages;
  final int? targetReadingTimeMinutes;
  final int currentBooks;
  final int currentPages;
  final int currentReadingTimeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReadingGoal({
    this.id,
    required this.userId,
    required this.year,
    this.targetBooks,
    this.targetPages,
    this.targetReadingTimeMinutes,
    this.currentBooks = 0,
    this.currentPages = 0,
    this.currentReadingTimeMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      year: json['year'] as int,
      targetBooks: json['target_books'] as int?,
      targetPages: json['target_pages'] as int?,
      targetReadingTimeMinutes: json['target_reading_time_minutes'] as int?,
      currentBooks: json['current_books'] as int? ?? 0,
      currentPages: json['current_pages'] as int? ?? 0,
      currentReadingTimeMinutes: json['current_reading_time_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'year': year,
      if (targetBooks != null) 'target_books': targetBooks,
      if (targetPages != null) 'target_pages': targetPages,
      if (targetReadingTimeMinutes != null) 'target_reading_time_minutes': targetReadingTimeMinutes,
      'current_books': currentBooks,
      'current_pages': currentPages,
      'current_reading_time_minutes': currentReadingTimeMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReadingGoal copyWith({
    int? id,
    String? userId,
    int? year,
    int? targetBooks,
    int? targetPages,
    int? targetReadingTimeMinutes,
    int? currentBooks,
    int? currentPages,
    int? currentReadingTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      targetPages: targetPages ?? this.targetPages,
      targetReadingTimeMinutes: targetReadingTimeMinutes ?? this.targetReadingTimeMinutes,
      currentBooks: currentBooks ?? this.currentBooks,
      currentPages: currentPages ?? this.currentPages,
      currentReadingTimeMinutes: currentReadingTimeMinutes ?? this.currentReadingTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate progress percentage for books goal
  double? get booksProgress {
    if (targetBooks == null || targetBooks == 0) return null;
    return (currentBooks / targetBooks!).clamp(0.0, 1.0);
  }

  /// Calculate progress percentage for pages goal
  double? get pagesProgress {
    if (targetPages == null || targetPages == 0) return null;
    return (currentPages / targetPages!).clamp(0.0, 1.0);
  }

  /// Calculate progress percentage for reading time goal
  double? get readingTimeProgress {
    if (targetReadingTimeMinutes == null || targetReadingTimeMinutes == 0) return null;
    return (currentReadingTimeMinutes / targetReadingTimeMinutes!).clamp(0.0, 1.0);
  }

  /// Check if any goal is completed
  bool get hasCompletedGoal {
    return (booksProgress != null && booksProgress! >= 1.0) ||
        (pagesProgress != null && pagesProgress! >= 1.0) ||
        (readingTimeProgress != null && readingTimeProgress! >= 1.0);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        year,
        targetBooks,
        targetPages,
        targetReadingTimeMinutes,
        currentBooks,
        currentPages,
        currentReadingTimeMinutes,
        createdAt,
        updatedAt,
      ];
}
