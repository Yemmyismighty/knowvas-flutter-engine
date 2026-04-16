import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/bookmark.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookmark_repository_provider.dart';

part 'bookmarks_provider.g.dart';

/// Provider for bookmarks of a specific content
@riverpod
class Bookmarks extends _$Bookmarks {
  final Logger _logger = Logger();

  @override
  Future<List<Bookmark>> build(int contentId) async {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return [];
    }

    return _loadBookmarks(userId, contentId);
  }

  /// Load bookmarks from database
  Future<List<Bookmark>> _loadBookmarks(String userId, int contentId) async {
    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      return await repository.getBookmarks(userId, contentId);
    } catch (e) {
      _logger.e('Failed to load bookmarks: $e');
      return [];
    }
  }

  /// Add a bookmark
  Future<void> addBookmark({
    required int pageNumber,
    String? location,
  }) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      _logger.w('Cannot add bookmark: user not authenticated');
      return;
    }

    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      
      // Check if page is already bookmarked
      final isBookmarked = await repository.isPageBookmarked(
        userId,
        contentId,
        pageNumber,
      );

      if (isBookmarked) {
        _logger.i('Page $pageNumber is already bookmarked');
        return;
      }

      await repository.addBookmark(
        userId: userId,
        contentId: contentId,
        pageNumber: pageNumber,
        location: location,
      );

      // Refresh bookmarks list
      ref.invalidateSelf();
    } catch (e) {
      _logger.e('Failed to add bookmark: $e');
      rethrow;
    }
  }

  /// Delete a bookmark
  Future<void> deleteBookmark(int bookmarkId) async {
    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      await repository.deleteBookmark(bookmarkId);

      // Refresh bookmarks list
      ref.invalidateSelf();
    } catch (e) {
      _logger.e('Failed to delete bookmark: $e');
      rethrow;
    }
  }

  /// Check if a page is bookmarked
  Future<bool> isPageBookmarked(int pageNumber) async {
    final bookmarks = await future;
    return bookmarks.any((b) => b.pageNumber == pageNumber);
  }
}
