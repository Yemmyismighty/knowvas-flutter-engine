import 'package:logger/logger.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/bookmark.dart';

/// Repository for managing bookmarks
/// Stores locally in SQLite and syncs to backend
class BookmarkRepository {
  BookmarkRepository({
    DatabaseHelper? databaseHelper,
    ApiClient? apiClient,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _apiClient = apiClient;

  final DatabaseHelper _databaseHelper;
  final ApiClient? _apiClient;
  final Logger _logger = Logger();

  /// Get all bookmarks for a specific content
  Future<List<Bookmark>> getBookmarks(String userId, int contentId) async {
    try {
      // Try to fetch from backend first if online
      if (_apiClient != null) {
        try {
          final response = await _apiClient!.get<Map<String, dynamic>>(
            '/api/reader/bookmarks',
            queryParameters: {'content_id': contentId},
          );
          if (response.statusCode == 200 && response.data != null) {
            final items = response.data!['bookmarks'] as List<dynamic>? ?? [];
            final bookmarks = items
                .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
                .toList();
            // Cache locally
            for (final b in bookmarks) {
              await _databaseHelper.insertBookmark({
                'content_id': b.contentId,
                'user_id': userId,
                'page_number': b.pageNumber,
                'location': b.location,
                'created_at': b.createdAt.millisecondsSinceEpoch,
                'synced': 1,
              });
            }
            return bookmarks;
          }
        } catch (e) {
          _logger.w('Failed to fetch bookmarks from backend, using local: $e');
        }
      }
      // Fallback to local
      final results = await _databaseHelper.getBookmarks(userId, contentId);
      return results.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get bookmarks: $e');
      rethrow;
    }
  }

  /// Add a new bookmark (local + backend)
  Future<Bookmark> addBookmark({
    required String userId,
    required int contentId,
    required int pageNumber,
    String? location,
  }) async {
    try {
      final bookmark = Bookmark(
        contentId: contentId,
        pageNumber: pageNumber,
        location: location,
        createdAt: DateTime.now(),
        synced: false,
      );

      // Save locally first
      final id = await _databaseHelper.insertBookmark({
        'content_id': bookmark.contentId,
        'user_id': userId,
        'page_number': bookmark.pageNumber,
        'location': bookmark.location,
        'created_at': bookmark.createdAt.millisecondsSinceEpoch,
        'synced': 0,
      });

      final saved = bookmark.copyWith(id: id);

      // Sync to backend
      if (_apiClient != null) {
        try {
          await _apiClient!.post<Map<String, dynamic>>(
            '/api/reader/bookmarks',
            data: {
              'content_id': contentId,
              'page_number': pageNumber,
              'location': location,
            },
          );
          await _databaseHelper.markBookmarkSynced(id);
        } catch (e) {
          _logger.w('Failed to sync bookmark to backend: $e');
        }
      }

      return saved;
    } catch (e) {
      _logger.e('Failed to add bookmark: $e');
      rethrow;
    }
  }

  /// Delete a bookmark (local + backend)
  Future<void> deleteBookmark(int bookmarkId) async {
    try {
      if (_apiClient != null) {
        try {
          await _apiClient!.delete<Map<String, dynamic>>(
            '/api/reader/bookmarks/$bookmarkId',
          );
        } catch (e) {
          _logger.w('Failed to delete bookmark from backend: $e');
        }
      }
      await _databaseHelper.deleteBookmark(bookmarkId);
    } catch (e) {
      _logger.e('Failed to delete bookmark: $e');
      rethrow;
    }
  }

  /// Check if a page is bookmarked
  Future<bool> isPageBookmarked(
    String userId,
    int contentId,
    int pageNumber,
  ) async {
    try {
      final bookmarks = await _databaseHelper.getBookmarks(userId, contentId);
      return bookmarks.any((b) => b['page_number'] == pageNumber);
    } catch (e) {
      _logger.e('Failed to check if page is bookmarked: $e');
      return false;
    }
  }

  /// Get unsynced bookmarks
  Future<List<Bookmark>> getUnsyncedBookmarks(String userId) async {
    try {
      final results = await _databaseHelper.getUnsyncedBookmarks(userId);
      return results.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get unsynced bookmarks: $e');
      rethrow;
    }
  }

  /// Mark bookmark as synced
  Future<void> markBookmarkSynced(int bookmarkId) async {
    try {
      await _databaseHelper.markBookmarkSynced(bookmarkId);
    } catch (e) {
      _logger.e('Failed to mark bookmark as synced: $e');
      rethrow;
    }
  }

  /// Sync all unsynced bookmarks to backend
  Future<void> syncPendingBookmarks(String userId) async {
    if (_apiClient == null) return;
    try {
      final unsynced = await getUnsyncedBookmarks(userId);
      for (final bookmark in unsynced) {
        try {
          await _apiClient!.post<Map<String, dynamic>>(
            '/api/reader/bookmarks',
            data: {
              'content_id': bookmark.contentId,
              'page_number': bookmark.pageNumber,
              'location': bookmark.location,
            },
          );
          if (bookmark.id != null) {
            await _databaseHelper.markBookmarkSynced(bookmark.id!);
          }
        } catch (e) {
          _logger.w('Failed to sync bookmark ${bookmark.id}: $e');
        }
      }
    } catch (e) {
      _logger.e('Failed to sync pending bookmarks: $e');
      throw StorageFailure('Failed to sync bookmarks: $e');
    }
  }
}
