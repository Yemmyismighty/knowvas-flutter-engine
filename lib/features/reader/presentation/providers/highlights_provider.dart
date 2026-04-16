import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/highlight.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/highlight_repository_provider.dart';

part 'highlights_provider.g.dart';

/// Provider for highlights of a specific content
@riverpod
class Highlights extends _$Highlights {
  final Logger _logger = Logger();

  @override
  Future<List<Highlight>> build(int contentId) async {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return [];
    }

    return _loadHighlights(userId, contentId);
  }

  /// Load highlights from database
  Future<List<Highlight>> _loadHighlights(String userId, int contentId) async {
    try {
      final repository = ref.read(highlightRepositoryProvider);
      return await repository.getHighlights(userId, contentId);
    } catch (e) {
      _logger.e('Failed to load highlights: $e');
      return [];
    }
  }

  /// Add a highlight
  Future<void> addHighlight({
    required int pageNumber,
    required int startPosition,
    required int endPosition,
    required String highlightedText,
    String color = '#FFFF00',
  }) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      _logger.w('Cannot add highlight: user not authenticated');
      return;
    }

    try {
      final repository = ref.read(highlightRepositoryProvider);
      await repository.addHighlight(
        userId: userId,
        contentId: contentId,
        pageNumber: pageNumber,
        startPosition: startPosition,
        endPosition: endPosition,
        highlightedText: highlightedText,
        color: color,
      );

      // Refresh highlights list
      ref.invalidateSelf();
    } catch (e) {
      _logger.e('Failed to add highlight: $e');
      rethrow;
    }
  }

  /// Delete a highlight
  Future<void> deleteHighlight(int highlightId) async {
    try {
      final repository = ref.read(highlightRepositoryProvider);
      await repository.deleteHighlight(highlightId);

      // Refresh highlights list
      ref.invalidateSelf();
    } catch (e) {
      _logger.e('Failed to delete highlight: $e');
      rethrow;
    }
  }
}
