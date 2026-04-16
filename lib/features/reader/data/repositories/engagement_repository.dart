import 'package:logger/logger.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/engagement_event.dart';

/// Repository for managing engagement events
/// Handles local storage and backend synchronization
class EngagementRepository {
  EngagementRepository({
    required ApiClient apiClient,
    required DatabaseHelper databaseHelper,
  })  : _apiClient = apiClient,
        _databaseHelper = databaseHelper;

  final ApiClient _apiClient;
  final DatabaseHelper _databaseHelper;
  final Logger _logger = Logger();

  /// Log an engagement event locally
  /// Events are queued for upload when online
  Future<void> logEngagement(EngagementEvent event) async {
    try {
      await _databaseHelper.insertEngagementEvent({
        'content_id': event.contentId,
        'user_id': '', // Will be set by the caller with actual user ID
        'session_id': event.sessionId,
        'event_type': event.eventType,
        'payload': event.payload?.toString(),
        'timestamp': event.timestamp.millisecondsSinceEpoch,
        'uploaded': 0,
      });
      _logger.d('Engagement event logged: ${event.eventType}');
    } catch (e) {
      _logger.e('Failed to log engagement event: $e');
      throw StorageFailure('Failed to log engagement event: $e');
    }
  }

  /// Batch upload queued engagement events to backend
  /// Returns number of events successfully uploaded
  Future<int> batchUploadEngagements(String userId) async {
    try {
      // Get unuploaded events
      final events = await _databaseHelper.getUnuploadedEngagementEvents(userId);

      if (events.isEmpty) {
        return 0;
      }

      // Convert to EngagementEvent objects
      final engagementEvents = events.map((e) {
        return EngagementEvent(
          id: e['id'] as int?,
          contentId: e['content_id'] as int,
          sessionId: e['session_id'] as String,
          eventType: e['event_type'] as String,
          payload: e['payload'] != null 
              ? {'raw': e['payload']} 
              : null,
          timestamp: DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
        );
      }).toList();

      // Upload to backend
      final request = EngagementBatchRequest(events: engagementEvents);
      await _apiClient.post<Map<String, dynamic>>(
        '/api/engagement/log',
        data: request.toJson(),
      );

      // Mark as uploaded
      final eventIds = events.map((e) => e['id'] as int).toList();
      await _databaseHelper.markEngagementEventsUploaded(eventIds);

      _logger.i('Uploaded ${eventIds.length} engagement events');
      return eventIds.length;
    } on NetworkFailure catch (e) {
      _logger.w('Network failure during engagement upload: ${e.message}');
      rethrow;
    } on ServerFailure catch (e) {
      _logger.w('Server failure during engagement upload: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Failed to upload engagement events: $e');
      throw StorageFailure('Failed to upload engagement events: $e');
    }
  }

  /// Get count of pending (unuploaded) engagement events
  Future<int> getPendingEventsCount(String userId) async {
    try {
      final events = await _databaseHelper.getUnuploadedEngagementEvents(userId);
      return events.length;
    } catch (e) {
      _logger.e('Failed to get pending events count: $e');
      return 0;
    }
  }

  /// Clean up old uploaded events (older than specified days)
  Future<void> cleanupOldEvents(int daysOld) async {
    try {
      final deletedCount = await _databaseHelper.deleteOldEngagementEvents(daysOld);
      _logger.i('Cleaned up $deletedCount old engagement events');
    } catch (e) {
      _logger.e('Failed to cleanup old events: $e');
    }
  }
}
