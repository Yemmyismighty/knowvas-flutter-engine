import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/models/content_detail.dart';
import '../../../../shared/models/homepage.dart';

import '../../../../shared/models/feed.dart';

/// Repository for content operations
/// Handles discover, search, and content detail operations
class ContentRepository {
  ContentRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get discover page content
  /// Returns DiscoverResponse with curated content categories
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<DiscoverResponse> getDiscoverContent({
    String? category,
    int limit = 12,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.discover,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return DiscoverResponse.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch discover content',
          code: 'DISCOVER_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching discover content: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Search content with filters
  /// Returns list of content matching search criteria
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<SearchResponse> searchContent({
    String? query,
    String? type,
    String? genre,
    double? minPrice,
    double? maxPrice,
    String? language,
    String sort = 'relevance',
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (type != null) {
        queryParams['type'] = type;
      }
      if (genre != null) {
        queryParams['genre'] = genre;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      if (language != null) {
        queryParams['language'] = language;
      }
      
      // Add any additional filters
      if (filters != null) {
        queryParams.addAll(filters);
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.search,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return SearchResponse.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to search content',
          code: 'SEARCH_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while searching content: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get content details by ID
  /// Returns detailed content information
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<ContentDetail> getContentDetail(int contentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.content}/$contentId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ContentDetail.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch content details',
          code: 'CONTENT_DETAIL_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching content details: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get homepage content
  /// Returns HomepageResponse with curated content and featured sections
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<HomepageResponse> getHomepageContent() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.homepage,
      );

      if (response.statusCode == 200 && response.data != null) {
        return HomepageResponse.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch homepage content',
          code: 'HOMEPAGE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching homepage content: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get the algorithmic homepage feed
  /// Returns FeedResponse with personalised sections
  Future<FeedResponse> getFeed() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.feed,
      );
      if (response.statusCode == 200 && response.data != null) {
        return FeedResponse.fromJson(response.data!);
      } else {
        throw const ServerFailure('Failed to fetch feed', code: 'FEED_FAILED');
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching feed: $e', code: 'UNKNOWN_ERROR');
    }
  }

  /// Get autocomplete suggestions
  /// Returns list of autocomplete results
  Future<List<Map<String, dynamic>>> getAutocomplete(String query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/discover/autocomplete',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data!['results'] as List<dynamic>?;
        return results?.cast<Map<String, dynamic>>() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search for authors
  /// Returns list of authors matching query
  Future<List<Map<String, dynamic>>> searchAuthors(String query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/discover/search-authors',
        queryParameters: {'query': query, 'limit': 12},
      );

      if (response.statusCode == 200 && response.data != null) {
        final authors = response.data!['authors'] as List<dynamic>?;
        return authors?.cast<Map<String, dynamic>>() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all categories
  /// Returns list of categories with counts
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/discover/categories',
      );

      if (response.statusCode == 200 && response.data != null) {
        final categories = response.data!['categories'] as List<dynamic>?;
        return categories?.cast<Map<String, dynamic>>() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search content using discover endpoint
  /// Returns list of content matching search criteria
  Future<List<dynamic>> searchContentDiscover({
    required String query,
    String? sortBy,
    String? genre,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/discover/search',
        queryParameters: {
          'query': query,
          'page': page,
          'limit': 12,
          if (sortBy != null) 'sortBy': sortBy,
          if (genre != null) 'genre': genre,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final resources = response.data!['resources'] as List<dynamic>?;
        return resources ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Search response model
class SearchResponse extends Equatable {
  final List<Content> results;
  final SearchPagination pagination;
  final SearchFilters filtersApplied;

  const SearchResponse({
    required this.results,
    required this.pagination,
    required this.filtersApplied,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: SearchPagination.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
      filtersApplied: SearchFilters.fromJson(
          json['filters_applied'] as Map<String, dynamic>? ?? {}),
    );
  }

  // Computed property for backward compatibility
  int get totalCount => pagination.total;

  @override
  List<Object?> get props => [results, pagination, filtersApplied];
}

/// Search pagination model
class SearchPagination extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const SearchPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrev: json['has_prev'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [page, limit, total, totalPages, hasNext, hasPrev];
}

/// Search filters model
class SearchFilters extends Equatable {
  final String? query;
  final String? type;
  final String? genre;
  final double? minPrice;
  final double? maxPrice;
  final String? language;
  final String? sort;

  const SearchFilters({
    this.query,
    this.type,
    this.genre,
    this.minPrice,
    this.maxPrice,
    this.language,
    this.sort,
  });

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      query: json['query'] as String?,
      type: json['type'] as String?,
      genre: json['genre'] as String?,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      language: json['language'] as String?,
      sort: json['sort'] as String?,
    );
  }

  @override
  List<Object?> get props => [query, type, genre, minPrice, maxPrice, language, sort];
}