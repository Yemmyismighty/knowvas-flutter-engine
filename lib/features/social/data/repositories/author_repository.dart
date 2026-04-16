import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/models/author.dart';
import '../../../../shared/models/content.dart';

/// Repository for author-related operations
/// Handles fetching author profiles and their published works
class AuthorRepository {
  AuthorRepository({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _apiClient = apiClient,
        _networkInfo = networkInfo;

  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  // In-memory cache for author profiles
  final Map<int, _CachedAuthorProfile> _authorProfileCache = {};

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get author profile with published works
  /// Returns AuthorProfile with author details and content list
  /// Implements caching to reduce network requests
  /// Throws AuthorFailure on errors
  Future<AuthorProfile> getAuthorProfile(int authorId) async {
    try {
      // Check if we have a valid cached response
      if (_authorProfileCache.containsKey(authorId)) {
        final cached = _authorProfileCache[authorId]!;
        if (!cached.isExpired) {
          return cached.data;
        }
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        // If we have expired cache, return it anyway when offline
        if (_authorProfileCache.containsKey(authorId)) {
          return _authorProfileCache[authorId]!.data;
        }
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      // Fetch from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.authors}/$authorId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final authorProfile = AuthorProfile.fromJson(response.data!);

        // Cache the response
        _authorProfileCache[authorId] = _CachedAuthorProfile(
          data: authorProfile,
          cachedAt: DateTime.now(),
        );

        return authorProfile;
      } else {
        throw AuthorFailure(
          'Failed to fetch author profile',
          code: 'FETCH_FAILED',
          authorId: authorId,
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
      throw AuthorFailure(
        e.message,
        code: e.code,
        authorId: authorId,
      );
    } catch (e) {
      throw AuthorFailure(
        'An unexpected error occurred while fetching author profile: $e',
        code: 'UNKNOWN_ERROR',
        authorId: authorId,
      );
    }
  }

  /// Follow an author
  /// Throws AuthorFailure on errors
  Future<void> followAuthor(int authorId) async {
    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.authors}/$authorId/follow',
      );

      if (response.statusCode == 200) {
        // Invalidate cache to force refresh
        _authorProfileCache.remove(authorId);
      } else {
        throw AuthorFailure(
          'Failed to follow author',
          code: 'FOLLOW_FAILED',
          authorId: authorId,
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
      throw AuthorFailure(
        e.message,
        code: e.code,
        authorId: authorId,
      );
    } catch (e) {
      throw AuthorFailure(
        'An unexpected error occurred while following author: $e',
        code: 'UNKNOWN_ERROR',
        authorId: authorId,
      );
    }
  }

  /// Unfollow an author
  /// Throws AuthorFailure on errors
  Future<void> unfollowAuthor(int authorId) async {
    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConstants.authors}/$authorId/follow',
      );

      if (response.statusCode == 200) {
        // Invalidate cache to force refresh
        _authorProfileCache.remove(authorId);
      } else {
        throw AuthorFailure(
          'Failed to unfollow author',
          code: 'UNFOLLOW_FAILED',
          authorId: authorId,
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
      throw AuthorFailure(
        e.message,
        code: e.code,
        authorId: authorId,
      );
    } catch (e) {
      throw AuthorFailure(
        'An unexpected error occurred while unfollowing author: $e',
        code: 'UNKNOWN_ERROR',
        authorId: authorId,
      );
    }
  }

  /// Clear all cached data
  void clearCache() {
    _authorProfileCache.clear();
  }

  /// Clear cached author profile for a specific author ID
  void clearAuthorProfileCache(int authorId) {
    _authorProfileCache.remove(authorId);
  }
}

/// Cached author profile with expiration
class _CachedAuthorProfile {
  final AuthorProfile data;
  final DateTime cachedAt;

  _CachedAuthorProfile({
    required this.data,
    required this.cachedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > AuthorRepository._cacheDuration;
}

/// Author profile response model
class AuthorProfile {
  final Author author;
  final List<Content> publishedWorks;

  const AuthorProfile({
    required this.author,
    this.publishedWorks = const [],
  });

  factory AuthorProfile.fromJson(Map<String, dynamic> json) {
    return AuthorProfile(
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      publishedWorks: (json['published_works'] as List<dynamic>?)
              ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author.toJson(),
      'published_works': publishedWorks.map((e) => e.toJson()).toList(),
    };
  }
}

/// Author-specific failure
class AuthorFailure extends Failure {
  final int? authorId;

  const AuthorFailure(
    String message, {
    String? code,
    this.authorId,
  }) : super(message, code: code);
}
