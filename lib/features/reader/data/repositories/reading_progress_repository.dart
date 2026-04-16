import 'package:logger/logger.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

/// Repository for syncing reading progress to the backend
/// Mirrors the Next.js app's /api/reading-progress/save endpoint
class ReadingProgressRepository {
  ReadingProgressRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Logger _logger = Logger();

  /// Save reading progress for a resource
  /// Matches backend: POST /api/reading-progress/save
  Future<void> saveProgress({
    required int resourceId,
    required double progress,
    required int currentPage,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/reading-progress/save',
        data: {
          'resource_id': resourceId,
          'progress': progress,
          'current_page': currentPage,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logger.w('Failed to save reading progress: ${response.statusCode}');
      }
    } on NetworkException catch (e) {
      // Non-fatal - progress will be saved locally
      _logger.w('Network error saving progress: ${e.message}');
    } on ServerException catch (e) {
      _logger.w('Server error saving progress: ${e.message}');
    } catch (e) {
      _logger.w('Unexpected error saving progress: $e');
    }
  }

  /// Save PDF reading progress
  /// Matches backend: POST /api/pdf-progress/save
  Future<void> savePdfProgress({
    required int resourceId,
    required int pageNumber,
    required int totalPages,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/pdf-progress/save',
        data: {
          'resource_id': resourceId,
          'page_number': pageNumber,
          'total_pages': totalPages,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logger.w('Failed to save PDF progress: ${response.statusCode}');
      }
    } on NetworkException catch (e) {
      _logger.w('Network error saving PDF progress: ${e.message}');
    } catch (e) {
      _logger.w('Unexpected error saving PDF progress: $e');
    }
  }

  /// Get reading progress for a resource
  /// Matches backend: GET /api/reading-progress/{resource_id}
  Future<Map<String, dynamic>?> getProgress(int resourceId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/$resourceId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['data'] as Map<String, dynamic>?;
      }
      return null;
    } on NetworkException catch (e) {
      _logger.w('Network error fetching progress: ${e.message}');
      return null;
    } catch (e) {
      _logger.w('Error fetching progress: $e');
      return null;
    }
  }

  /// Get PDF reading progress for a resource
  /// Matches backend: GET /api/pdf-progress/{resource_id}
  Future<Map<String, dynamic>?> getPdfProgress(int resourceId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/pdf-progress/$resourceId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['data'] as Map<String, dynamic>?;
      }
      return null;
    } on NetworkException catch (e) {
      _logger.w('Network error fetching PDF progress: ${e.message}');
      return null;
    } catch (e) {
      _logger.w('Error fetching PDF progress: $e');
      return null;
    }
  }
}
