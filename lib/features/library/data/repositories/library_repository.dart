import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/library_item.dart';

/// Repository for library operations
class LibraryRepository {
  LibraryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get all library data
  Future<LibraryResponse> getLibrary() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library',
      );

      if (response.statusCode == 200 && response.data != null) {
        return LibraryResponse.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch library',
          code: 'LIBRARY_FETCH_FAILED',
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
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get currently reading books
  Future<List<LibraryItem>> getCurrentlyReading() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/currently-reading',
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!['items'] as List<dynamic>?;
        return items
                ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch currently reading books',
          code: 'CURRENTLY_READING_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch currently reading: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get purchased books
  Future<List<LibraryItem>> getPurchased() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/purchased',
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!['items'] as List<dynamic>?;
        return items
                ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch purchased books',
          code: 'PURCHASED_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch purchased: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get recently viewed books
  Future<List<LibraryItem>> getRecentlyViewed() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/recently-viewed',
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!['items'] as List<dynamic>?;
        return items
                ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch recently viewed books',
          code: 'RECENTLY_VIEWED_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch recently viewed: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get finished books
  Future<List<LibraryItem>> getFinished() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/finished',
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!['items'] as List<dynamic>?;
        return items
                ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch finished books',
          code: 'FINISHED_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch finished: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get favorite books
  Future<List<LibraryItem>> getFavorites() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/favorites',
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!['items'] as List<dynamic>?;
        return items
                ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch favorite books',
          code: 'FAVORITES_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch favorites: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get reading statistics
  Future<ReadingStats> getReadingStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/user/library/stats',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReadingStats.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch reading stats',
          code: 'STATS_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch stats: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
