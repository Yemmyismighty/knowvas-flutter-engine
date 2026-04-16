import 'package:equatable/equatable.dart';
import 'content.dart';

/// Homepage response model
class HomepageResponse extends Equatable {
  final Content? featuredContent;
  final List<Content> curatedBooks;
  final List<Content> curatedComics;
  final List<Content> curatedAudiobooks;
  final List<Content> curatedMagazines;
  final List<Content> curatedNewspapers;
  final List<Content> curatedFictionalBooks;
  final List<Content> curatedTextBooks;
  final List<Content> curatedEducationBooks;
  final List<Content> curatedTechBooks;
  final List<Content> curatedLifestyleBooks;
  final List<Content> curatedReligionBooks;
  final List<SpotlightAuthor> spotlightAuthors;
  final TrendingStats trendingStats;
  final int currentYear;

  const HomepageResponse({
    this.featuredContent,
    required this.curatedBooks,
    required this.curatedComics,
    required this.curatedAudiobooks,
    required this.curatedMagazines,
    required this.curatedNewspapers,
    this.curatedFictionalBooks = const [],
    this.curatedTextBooks = const [],
    this.curatedEducationBooks = const [],
    this.curatedTechBooks = const [],
    this.curatedLifestyleBooks = const [],
    this.curatedReligionBooks = const [],
    required this.spotlightAuthors,
    required this.trendingStats,
    required this.currentYear,
  });

  factory HomepageResponse.fromJson(Map<String, dynamic> json) {
    List<Content> _parseList(dynamic data) =>
        (data as List<dynamic>?)
            ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return HomepageResponse(
      featuredContent: json['featured_content'] != null
          ? Content.fromJson(json['featured_content'] as Map<String, dynamic>)
          : null,
      curatedBooks: _parseList(json['curated_books']),
      curatedComics: _parseList(json['curated_comics']),
      curatedAudiobooks: _parseList(json['curated_audiobooks']),
      curatedMagazines: _parseList(json['curated_magazines']),
      curatedNewspapers: _parseList(json['curated_newspapers']),
      curatedFictionalBooks: _parseList(json['curated_fictional_books']),
      curatedTextBooks: _parseList(json['curated_text_books']),
      curatedEducationBooks: _parseList(json['curated_education_books']),
      curatedTechBooks: _parseList(json['curated_tech_books']),
      curatedLifestyleBooks: _parseList(json['curated_lifestyle_books']),
      curatedReligionBooks: _parseList(json['curated_religion_books']),
      spotlightAuthors: (json['spotlight_authors'] as List<dynamic>?)
              ?.map((item) => SpotlightAuthor.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      trendingStats: TrendingStats.fromJson(
          json['trending_stats'] as Map<String, dynamic>? ?? {}),
      currentYear: json['current_year'] as int? ?? DateTime.now().year,
    );
  }

  @override
  List<Object?> get props => [
        featuredContent, curatedBooks, curatedComics, curatedAudiobooks,
        curatedMagazines, curatedNewspapers, curatedFictionalBooks,
        curatedTextBooks, curatedEducationBooks, curatedTechBooks,
        curatedLifestyleBooks, curatedReligionBooks, spotlightAuthors,
        trendingStats, currentYear,
      ];
}

/// Spotlight author model
class SpotlightAuthor extends Equatable {
  final int id;
  final String name;
  final String specialty;
  final String? profilePicture;
  final int followersCount;
  final int contentCount;
  final bool isFollowing;

  const SpotlightAuthor({
    required this.id,
    required this.name,
    required this.specialty,
    this.profilePicture,
    required this.followersCount,
    required this.contentCount,
    required this.isFollowing,
  });

  factory SpotlightAuthor.fromJson(Map<String, dynamic> json) {
    return SpotlightAuthor(
      id: json['id'] as int,
      name: json['name'] as String,
      specialty: json['specialty'] as String? ?? '',
      profilePicture: json['profile_picture'] as String? ?? json['profilePicture'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      contentCount: json['content_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, specialty, profilePicture, followersCount, contentCount, isFollowing];
}

/// Trending stats model
class TrendingStats extends Equatable {
  final String activeReaders;
  final String contentPublished;
  final String creators;

  const TrendingStats({
    required this.activeReaders,
    required this.contentPublished,
    required this.creators,
  });

  factory TrendingStats.fromJson(Map<String, dynamic> json) {
    return TrendingStats(
      activeReaders: json['active_readers'] as String? ?? '0',
      contentPublished: json['content_published'] as String? ?? '0',
      creators: json['creators'] as String? ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_readers': activeReaders,
      'content_published': contentPublished,
      'creators': creators,
    };
  }

  @override
  List<Object?> get props => [activeReaders, contentPublished, creators];
}