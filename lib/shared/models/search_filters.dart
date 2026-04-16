import 'package:equatable/equatable.dart';
import 'content.dart';

/// Search filters model
class SearchFilters extends Equatable {
  final String? query;
  final List<String> genres;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> languages;
  final List<String> types; // 'ebook', 'pdf', 'comic', 'magazine', 'audiobook'
  final String? authorId;
  final String sortBy; // 'relevance', 'newest', 'price_asc', 'price_desc', 'rating'
  final int page;
  final int pageSize;

  const SearchFilters({
    this.query,
    this.genres = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.languages = const [],
    this.types = const [],
    this.authorId,
    this.sortBy = 'relevance',
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
    };

    if (query != null && query!.isNotEmpty) {
      json['query'] = query;
    }
    if (genres.isNotEmpty) {
      json['genres'] = genres;
    }
    if (minPrice != null) {
      json['min_price'] = minPrice;
    }
    if (maxPrice != null) {
      json['max_price'] = maxPrice;
    }
    if (minRating != null) {
      json['min_rating'] = minRating;
    }
    if (languages.isNotEmpty) {
      json['languages'] = languages;
    }
    if (types.isNotEmpty) {
      json['types'] = types;
    }
    if (authorId != null) {
      json['author_id'] = authorId;
    }

    return json;
  }

  SearchFilters copyWith({
    String? query,
    List<String>? genres,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? languages,
    List<String>? types,
    String? authorId,
    String? sortBy,
    int? page,
    int? pageSize,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      genres: genres ?? this.genres,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      languages: languages ?? this.languages,
      types: types ?? this.types,
      authorId: authorId ?? this.authorId,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        query,
        genres,
        minPrice,
        maxPrice,
        minRating,
        languages,
        types,
        authorId,
        sortBy,
        page,
        pageSize,
      ];
}

/// Search response model
class SearchResponse extends Equatable {
  final List<Content> results;
  final int totalCount;
  final int page;
  final int pageSize;

  const SearchResponse({
    required this.results,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => [results, totalCount, page, pageSize];
}
