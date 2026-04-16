import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Service for queuing engagement events when offline
/// Events are stored locally and uploaded when connectivity is restored
class EngagementQueueService {
  EngagementQueueService({
    required DatabaseHelper databaseHelper,
    required Logger logger,
  })  : _databaseHelper = databaseHelper,
        _logger = logger;

  final DatabaseHelper _databaseHelper;
  final Logger _logger;

  /// Queue an engagement event for later upload
  Future<void> queueEvent({
    required int contentId,
    required String userId,
    required String sessionId,
    required String eventType,
    required DateTime timestamp,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'engagement_queue',
        {
          'content_id': contentId,
          'user_id': userId,
          'session_id': sessionId,
          'event_type': eventType,
          'payload': payload != null ? _encodePayload(payload) : null,
          'timestamp': timestamp.millisecondsSinceEpoch,
          'uploaded': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d(
        'Queued engagement event: $eventType for content $contentId',
      );
    } catch (e) {
      _logger.e('Failed to queue engagement event: $e');
      rethrow;
    }
  }

  /// Get all queued events that haven't been uploaded
  Future<List<Map<String, dynamic>>> getQueuedEvents() async {
    try {
      final db = await _databaseHelper.database;

      final results = await db.query(
        'engagement_queue',
        where: 'uploaded = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'content_id': row['content_id'],
          'user_id': row['user_id'],
          'session_id': row['session_id'],
          'event_type': row['event_type'],
          'payload': row['payload'] != null
              ? _decodePayload(row['payload'] as String)
              : null,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(
            row['timestamp'] as int,
          ),
        };
      }).toList();
    } catch (e) {
      _logger.e('Failed to get queued events: $e');
      return [];
    }
  }

  /// Mark events as uploaded
  Future<void> markEventsAsUploaded(List<int> eventIds) async {
    if (eventIds.isEmpty) return;

    try {
      final db = await _databaseHelper.database;

      await db.update(
        'engagement_queue',
        {'uploaded': 1},
        where: 'id IN (${eventIds.map((_) => '?').join(', ')})',
        whereArgs: eventIds,
      );

      _logger.d('Marked ${eventIds.length} events as uploaded');
    } catch (e) {
      _logger.e('Failed to mark events as uploaded: $e');
      rethrow;
    }
  }

  /// Delete uploaded events older than specified days
  Future<void> cleanupOldEvents({int daysToKeep = 7}) async {
    try {
      final db = await _databaseHelper.database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysToKeep))
          .millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'engagement_queue',
        where: 'uploaded = ? AND timestamp < ?',
        whereArgs: [1, cutoffTime],
      );

      _logger.d('Cleaned up $deletedCount old engagement events');
    } catch (e) {
      _logger.e('Failed to cleanup old events: $e');
    }
  }

  /// Get count of queued events
  Future<int> getQueuedEventCount() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM engagement_queue WHERE uploaded = 0',
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      _logger.e('Failed to get queued event count: $e');
      return 0;
    }
  }

  /// Clear all queued events (use with caution)
  Future<void> clearQueue() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('engagement_queue');
      _logger.d('Cleared engagement queue');
    } catch (e) {
      _logger.e('Failed to clear queue: $e');
      rethrow;
    }
  }

  /// Encode payload to JSON string
  String _encodePayload(Map<String, dynamic> payload) {
    // Simple JSON encoding - in production, use json.encode
    final entries = payload.entries.map((e) {
      final value = e.value is String ? '"${e.value}"' : e.value.toString();
      return '"${e.key}":$value';
    }).join(',');
    return '{$entries}';
  }

  /// Decode payload from JSON string
  Map<String, dynamic> _decodePayload(String payload) {
    // Simple JSON decoding - in production, use json.decode
    // For now, return empty map as placeholder
    return {};
  }
}
