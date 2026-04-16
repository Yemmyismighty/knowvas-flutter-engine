import 'package:logger/logger.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/highlight.dart';

/// Repository for managing highlights
/// Stores locally in SQLite and syncs to backend
class HighlightRepository {
  HighlightRepository({
    DatabaseHelper? databaseHelper,
    ApiClient? apiClient,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _apiClient = apiClient;

  final DatabaseHelper _databaseHelper;
  final ApiClient? _apiClient;
  final Logger _logger = Logger();

  /// Get all highlights for a specific content
  Future<List<Highlight>> getHighlights(String userId, int contentId) async {
    try {
      // Try backend first if online
      if (_apiClient != null) {
        try {
          final response = await _apiClient!.get<Map<String, dynamic>>(
            '/api/reader/highlights',
            queryParameters: {'content_id': contentId},
          );
          if (response.statusCode == 200 && response.data != null) {
            final items = response.data!['highlights'] as List<dynamic>? ?? [];
            final highlights = items
                .map((e) => Highlight.fromJson(e as Map<String, dynamic>))
                .toList();
            // Cache locally
            for (final h in highlights) {
              await _databaseHelper.insertHighlight({
                'content_id': h.contentId,
                'user_id': userId,
                'page_number': h.pageNumber,
                'start_position': h.startPosition,
                'end_position': h.endPosition,
                'highlighted_text': h.highlightedText,
                'color': h.color,
                'created_at': h.createdAt.millisecondsSinceEpoch,
                'synced': 1,
              });
            }
            return highlights;
          }
        } catch (e) {
          _logger.w('Failed to fetch highlights from backend, using local: $e');
        }
      }
      // Fallback to local
      final results = await _databaseHelper.getHighlights(userId, contentId);
      return results.map((json) => Highlight.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get highlights: $e');
      rethrow;
    }
  }

  /// Add a new highlight (local + backend)
  Future<Highlight> addHighlight({
    required String userId,
    required int contentId,
    required int pageNumber,
    required int startPosition,
    required int endPosition,
    required String highlightedText,
    String color = '#FFFF00',
  }) async {
    try {
      final highlight = Highlight(
        contentId: contentId,
        pageNumber: pageNumber,
        startPosition: startPosition,
        endPosition: endPosition,
        highlightedText: highlightedText,
        color: color,
        createdAt: DateTime.now(),
        synced: false,
      );

      // Save locally first
      final id = await _databaseHelper.insertHighlight({
        'content_id': highlight.contentId,
        'user_id': userId,
        'page_number': highlight.pageNumber,
        'start_position': highlight.startPosition,
        'end_position': highlight.endPosition,
        'highlighted_text': highlight.highlightedText,
        'color': highlight.color,
        'created_at': highlight.createdAt.millisecondsSinceEpoch,
        'synced': 0,
      });

      final saved = highlight.copyWith(id: id);

      // Sync to backend
      if (_apiClient != null) {
        try {
          await _apiClient!.post<Map<String, dynamic>>(
            '/api/reader/highlights',
            data: {
              'content_id': contentId,
              'page_number': pageNumber,
              'start_position': startPosition,
              'end_position': endPosition,
              'highlighted_text': highlightedText,
              'color': color,
            },
          );
          await _databaseHelper.markHighlightSynced(id);
        } catch (e) {
          _logger.w('Failed to sync highlight to backend: $e');
        }
      }

      return saved;
    } catch (e) {
      _logger.e('Failed to add highlight: $e');
      rethrow;
    }
  }

  /// Delete a highlight (local + backend)
  Future<void> deleteHighlight(int highlightId) async {
    try {
      if (_apiClient != null) {
        try {
          await _apiClient!.delete<Map<String, dynamic>>(
            '/api/reader/highlights/$highlightId',
          );
        } catch (e) {
          _logger.w('Failed to delete highlight from backend: $e');
        }
      }
      await _databaseHelper.deleteHighlight(highlightId);
    } catch (e) {
      _logger.e('Failed to delete highlight: $e');
      rethrow;
    }
  }

  /// Get unsynced highlights
  Future<List<Highlight>> getUnsyncedHighlights(String userId) async {
    try {
      final results = await _databaseHelper.getUnsyncedHighlights(userId);
      return results.map((json) => Highlight.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get unsynced highlights: $e');
      rethrow;
    }
  }

  /// Mark highlight as synced
  Future<void> markHighlightSynced(int highlightId) async {
    try {
      await _databaseHelper.markHighlightSynced(highlightId);
    } catch (e) {
      _logger.e('Failed to mark highlight as synced: $e');
      rethrow;
    }
  }

  /// Sync all unsynced highlights to backend
  Future<void> syncPendingHighlights(String userId) async {
    if (_apiClient == null) return;
    try {
      final unsynced = await getUnsyncedHighlights(userId);
      for (final highlight in unsynced) {
        try {
          await _apiClient!.post<Map<String, dynamic>>(
            '/api/reader/highlights',
            data: {
              'content_id': highlight.contentId,
              'page_number': highlight.pageNumber,
              'start_position': highlight.startPosition,
              'end_position': highlight.endPosition,
              'highlighted_text': highlight.highlightedText,
              'color': highlight.color,
            },
          );
          if (highlight.id != null) {
            await _databaseHelper.markHighlightSynced(highlight.id!);
          }
        } catch (e) {
          _logger.w('Failed to sync highlight ${highlight.id}: $e');
        }
      }
    } catch (e) {
      _logger.e('Failed to sync pending highlights: $e');
      throw StorageFailure('Failed to sync highlights: $e');
    }
  }
}
