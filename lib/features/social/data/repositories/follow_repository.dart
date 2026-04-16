import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/models/author.dart';
import '../../../../shared/models/user.dart';

/// Repository for follow-related operations
/// Handles following/unfollowing authors and users, and fetching followers/following lists
class FollowRepository {
  FollowRepository({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _apiClient = apiClient,
        _networkInfo = networkInfo;

  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  // In-memory cache for following/followers lists
  final Map<String, _CachedFollowList> _followingCache = {};
  final Map<String, _CachedFollowList> _followersCache = {};

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Follow an author
  /// Throws FollowFailure on errors
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
        '${ApiConstants.follow}/author/$authorId',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalidate cache to force refresh
        _followingCache.clear();
      } else {
        throw FollowFailure(
          'Failed to follow author',
          code: 'FOLLOW_FAILED',
          targetId: authorId,
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
      throw FollowFailure(
        e.message,
        code: e.code,
        targetId: authorId,
      );
    } catch (e) {
      throw FollowFailure(
        'An unexpected error occurred while following author: $e',
        code: 'UNKNOWN_ERROR',
        targetId: authorId,
      );
    }
  }

  /// Unfollow an author
  /// Throws FollowFailure on errors
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
        '${ApiConstants.follow}/author/$authorId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalidate cache to force refresh
        _followingCache.clear();
      } else {
        throw FollowFailure(
          'Failed to unfollow author',
          code: 'UNFOLLOW_FAILED',
          targetId: authorId,
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
      throw FollowFailure(
        e.message,
        code: e.code,
        targetId: authorId,
      );
    } catch (e) {
      throw FollowFailure(
        'An unexpected error occurred while unfollowing author: $e',
        code: 'UNKNOWN_ERROR',
        targetId: authorId,
      );
    }
  }

  /// Get list of authors and users that the current user is following
  /// Returns FollowingList with authors and users
  /// Implements caching to reduce network requests
  /// Throws FollowFailure on errors
  Future<FollowingList> getFollowing({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'following_$page\_$limit';

      // Check if we have a valid cached response
      if (!forceRefresh && _followingCache.containsKey(cacheKey)) {
        final cached = _followingCache[cacheKey]!;
        if (!cached.isExpired) {
          return cached.data as FollowingList;
        }
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        // If we have expired cache, return it anyway when offline
        if (_followingCache.containsKey(cacheKey)) {
          return _followingCache[cacheKey]!.data as FollowingList;
        }
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      // Fetch from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.following,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final followingList = FollowingList.fromJson(response.data!);

        // Cache the response
        _followingCache[cacheKey] = _CachedFollowList(
          data: followingList,
          cachedAt: DateTime.now(),
        );

        return followingList;
      } else {
        throw const FollowFailure(
          'Failed to fetch following list',
          code: 'FETCH_FOLLOWING_FAILED',
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
      throw FollowFailure(e.message, code: e.code);
    } catch (e) {
      throw FollowFailure(
        'An unexpected error occurred while fetching following list: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get list of followers for the current user
  /// Returns FollowersList with users who follow the current user
  /// Implements caching to reduce network requests
  /// Throws FollowFailure on errors
  Future<FollowersList> getFollowers({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'followers_$page\_$limit';

      // Check if we have a valid cached response
      if (!forceRefresh && _followersCache.containsKey(cacheKey)) {
        final cached = _followersCache[cacheKey]!;
        if (!cached.isExpired) {
          return cached.data as FollowersList;
        }
      }

      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        // If we have expired cache, return it anyway when offline
        if (_followersCache.containsKey(cacheKey)) {
          return _followersCache[cacheKey]!.data as FollowersList;
        }
        throw const NetworkFailure(
          'No internet connection',
          code: 'NO_CONNECTION',
        );
      }

      // Fetch from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.followers,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final followersList = FollowersList.fromJson(response.data!);

        // Cache the response
        _followersCache[cacheKey] = _CachedFollowList(
          data: followersList,
          cachedAt: DateTime.now(),
        );

        return followersList;
      } else {
        throw const FollowFailure(
          'Failed to fetch followers list',
          code: 'FETCH_FOLLOWERS_FAILED',
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
      throw FollowFailure(e.message, code: e.code);
    } catch (e) {
      throw FollowFailure(
        'An unexpected error occurred while fetching followers list: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Clear all cached data
  void clearCache() {
    _followingCache.clear();
    _followersCache.clear();
  }

  /// Clear following cache
  void clearFollowingCache() {
    _followingCache.clear();
  }

  /// Clear followers cache
  void clearFollowersCache() {
    _followersCache.clear();
  }
}

/// Cached follow list with expiration
class _CachedFollowList {
  final dynamic data;
  final DateTime cachedAt;

  _CachedFollowList({
    required this.data,
    required this.cachedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > FollowRepository._cacheDuration;
}

/// Following list response model
class FollowingList {
  final List<Author> authors;
  final List<User> users;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const FollowingList({
    this.authors = const [],
    this.users = const [],
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory FollowingList.fromJson(Map<String, dynamic> json) {
    return FollowingList(
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => Author.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      users: (json['users'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authors': authors.map((e) => e.toJson()).toList(),
      'users': users.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}

/// Followers list response model
class FollowersList {
  final List<User> followers;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const FollowersList({
    this.followers = const [],
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory FollowersList.fromJson(Map<String, dynamic> json) {
    return FollowersList(
      followers: (json['followers'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}

/// Follow-specific failure
class FollowFailure extends Failure {
  final int? targetId;

  const FollowFailure(
    String message, {
    String? code,
    this.targetId,
  }) : super(message, code: code);
}
