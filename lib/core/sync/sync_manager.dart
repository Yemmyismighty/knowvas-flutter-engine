import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';

import '../../shared/models/bookmark.dart';
import '../../shared/models/highlight.dart';
import '../../shared/models/note.dart';
import '../database/database_helper.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

/// Manages synchronization of local data with the backend
/// Handles automatic sync on network restore and conflict resolution
class SyncManager {
  SyncManager({
    required DatabaseHelper databaseHelper,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
    required Logger logger,
  })  : _databaseHelper = databaseHelper,
        _apiClient = apiClient,
        _networkInfo = networkInfo,
        _logger = logger {
    _initializeNetworkListener();
  }

  final DatabaseHelper _databaseHelper;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Initialize network connectivity listener
  void _initializeNetworkListener() {
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          _logger.i('Network connectivity restored, triggering sync');
          syncAll();
        }
      },
    );
  }

  /// Sync all data types
  Future<SyncResult> syncAll({String? userId}) async {
    if (_isSyncing) {
      _logger.w('Sync already in progress, skipping');
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _logger.i('Starting full sync');

    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        _logger.w('No network connection, skipping sync');
        return SyncResult(
          success: false,
          message: 'No network connection',
        );
      }

      final results = <String, bool>{};

      // Sync engagement events first (most critical)
      final engagementResult = await syncEngagementEvents(userId: userId);
      results['engagement_events'] = engagementResult.success;

      // Sync bookmarks
      final bookmarksResult = await syncBookmarks(userId: userId);
      results['bookmarks'] = bookmarksResult.success;

      // Sync highlights
      final highlightsResult = await syncHighlights(userId: userId);
      results['highlights'] = highlightsResult.success;

      // Sync notes
      final notesResult = await syncNotes(userId: userId);
      results['notes'] = notesResult.success;

      // Sync reading progress
      final progressResult = await syncReadingProgress(userId: userId);
      results['reading_progress'] = progressResult.success;

      // Sync library updates
      final libraryResult = await syncLibraryUpdates(userId: userId);
      results['library'] = libraryResult.success;

      _lastSyncTime = DateTime.now();

      final allSuccess = results.values.every((success) => success);
      final failedItems = results.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();

      _logger.i('Full sync completed. Success: $allSuccess');

      return SyncResult(
        success: allSuccess,
        message: allSuccess
            ? 'All data synced successfully'
            : 'Some items failed to sync: ${failedItems.join(", ")}',
        syncedItems: results,
      );
    } catch (e) {
      _logger.e('Error during full sync: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync queued engagement events
  Future<SyncResult> syncEngagementEvents({String? userId}) async {
    try {
      _logger.d('Syncing engagement events');

      final queuedEvents = userId != null
          ? await _databaseHelper.getUnuploadedEngagementEvents(userId)
          : [];

      if (queuedEvents.isEmpty) {
        _logger.d('No engagement events to sync');
        return SyncResult(success: true, message: 'No events to sync');
      }

      // Batch upload events
      final eventIds = <int>[];
      final eventsToUpload = <Map<String, dynamic>>[];

      for (final event in queuedEvents) {
        eventIds.add(event['id'] as int);
        eventsToUpload.add({
          'content_id': event['content_id'],
          'session_id': event['session_id'],
          'event_type': event['event_type'],
          'payload': event['payload'] != null
              ? jsonDecode(event['payload'] as String)
              : null,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(
            event['timestamp'] as int,
          ).toIso8601String(),
        });
      }

      // Upload to backend
      await _apiClient.post(
        '/api/engagement/log',
        data: {'events': eventsToUpload},
      );

      // Mark as uploaded
      await _databaseHelper.markEngagementEventsUploaded(eventIds);

      _logger.i('Synced ${eventIds.length} engagement events');

      return SyncResult(
        success: true,
        message: 'Synced ${eventIds.length} engagement events',
        syncedCount: eventIds.length,
      );
    } catch (e) {
      _logger.e('Error syncing engagement events: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync engagement events: $e',
      );
    }
  }

  /// Sync bookmarks with conflict resolution (last-write-wins)
  Future<SyncResult> syncBookmarks({String? userId}) async {
    try {
      _logger.d('Syncing bookmarks');

      if (userId == null) {
        return SyncResult(success: false, message: 'User ID required');
      }

      final unsyncedBookmarks = await _databaseHelper.getUnsyncedBookmarks(userId);

      if (unsyncedBookmarks.isEmpty) {
        _logger.d('No bookmarks to sync');
        return SyncResult(success: true, message: 'No bookmarks to sync');
      }

      int syncedCount = 0;

      for (final bookmarkData in unsyncedBookmarks) {
        try {
          final bookmark = Bookmark(
            id: bookmarkData['id'] as int?,
            contentId: bookmarkData['content_id'] as int,
            pageNumber: bookmarkData['page_number'] as int,
            location: bookmarkData['location'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              bookmarkData['created_at'] as int,
            ),
            synced: false,
          );

          // Upload to backend (last-write-wins)
          await _apiClient.post(
            '/api/bookmarks',
            data: {
              'content_id': bookmark.contentId,
              'page_number': bookmark.pageNumber,
              'location': bookmark.location,
              'created_at': bookmark.createdAt.toIso8601String(),
            },
          );

          // Mark as synced
          await _databaseHelper.markBookmarkSynced(bookmark.id!);
          syncedCount++;
        } catch (e) {
          _logger.e('Error syncing bookmark ${bookmarkData['id']}: $e');
          // Continue with next bookmark
        }
      }

      _logger.i('Synced $syncedCount bookmarks');

      return SyncResult(
        success: true,
        message: 'Synced $syncedCount bookmarks',
        syncedCount: syncedCount,
      );
    } catch (e) {
      _logger.e('Error syncing bookmarks: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync bookmarks: $e',
      );
    }
  }

  /// Sync highlights with conflict resolution (last-write-wins)
  Future<SyncResult> syncHighlights({String? userId}) async {
    try {
      _logger.d('Syncing highlights');

      if (userId == null) {
        return SyncResult(success: false, message: 'User ID required');
      }

      final unsyncedHighlights = await _databaseHelper.getUnsyncedHighlights(userId);

      if (unsyncedHighlights.isEmpty) {
        _logger.d('No highlights to sync');
        return SyncResult(success: true, message: 'No highlights to sync');
      }

      int syncedCount = 0;

      for (final highlightData in unsyncedHighlights) {
        try {
          final highlight = Highlight(
            id: highlightData['id'] as int?,
            contentId: highlightData['content_id'] as int,
            pageNumber: highlightData['page_number'] as int,
            startPosition: highlightData['start_position'] as int,
            endPosition: highlightData['end_position'] as int,
            highlightedText: highlightData['highlighted_text'] as String,
            color: highlightData['color'] as String? ?? '#FFFF00',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              highlightData['created_at'] as int,
            ),
            synced: false,
          );

          // Upload to backend (last-write-wins)
          await _apiClient.post(
            '/api/highlights',
            data: {
              'content_id': highlight.contentId,
              'page_number': highlight.pageNumber,
              'start_position': highlight.startPosition,
              'end_position': highlight.endPosition,
              'highlighted_text': highlight.highlightedText,
              'color': highlight.color,
              'created_at': highlight.createdAt.toIso8601String(),
            },
          );

          // Mark as synced
          await _databaseHelper.markHighlightSynced(highlight.id!);
          syncedCount++;
        } catch (e) {
          _logger.e('Error syncing highlight ${highlightData['id']}: $e');
          // Continue with next highlight
        }
      }

      _logger.i('Synced $syncedCount highlights');

      return SyncResult(
        success: true,
        message: 'Synced $syncedCount highlights',
        syncedCount: syncedCount,
      );
    } catch (e) {
      _logger.e('Error syncing highlights: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync highlights: $e',
      );
    }
  }

  /// Sync notes with conflict resolution (last-write-wins)
  Future<SyncResult> syncNotes({String? userId}) async {
    try {
      _logger.d('Syncing notes');

      if (userId == null) {
        return SyncResult(success: false, message: 'User ID required');
      }

      final unsyncedNotes = await _databaseHelper.getUnsyncedNotes(userId);

      if (unsyncedNotes.isEmpty) {
        _logger.d('No notes to sync');
        return SyncResult(success: true, message: 'No notes to sync');
      }

      int syncedCount = 0;

      for (final noteData in unsyncedNotes) {
        try {
          final note = Note(
            id: noteData['id'] as int?,
            contentId: noteData['content_id'] as int,
            pageNumber: noteData['page_number'] as int,
            position: noteData['position'] as int?,
            noteText: noteData['note_text'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              noteData['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              noteData['updated_at'] as int,
            ),
            synced: false,
          );

          // Upload to backend (last-write-wins based on updated_at)
          await _apiClient.post(
            '/api/notes',
            data: {
              'content_id': note.contentId,
              'page_number': note.pageNumber,
              'position': note.position,
              'note_text': note.noteText,
              'created_at': note.createdAt.toIso8601String(),
              'updated_at': note.updatedAt.toIso8601String(),
            },
          );

          // Mark as synced
          await _databaseHelper.markNoteSynced(note.id!);
          syncedCount++;
        } catch (e) {
          _logger.e('Error syncing note ${noteData['id']}: $e');
          // Continue with next note
        }
      }

      _logger.i('Synced $syncedCount notes');

      return SyncResult(
        success: true,
        message: 'Synced $syncedCount notes',
        syncedCount: syncedCount,
      );
    } catch (e) {
      _logger.e('Error syncing notes: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync notes: $e',
      );
    }
  }

  /// Sync reading progress for library items
  Future<SyncResult> syncReadingProgress({String? userId}) async {
    try {
      _logger.d('Syncing reading progress');

      if (userId == null) {
        return SyncResult(success: false, message: 'User ID required');
      }

      final unsyncedSessions = await _databaseHelper.getUnsyncedReadingSessions(userId);

      if (unsyncedSessions.isEmpty) {
        _logger.d('No reading progress to sync');
        return SyncResult(success: true, message: 'No reading progress to sync');
      }

      int syncedCount = 0;

      for (final session in unsyncedSessions) {
        try {
          // Upload reading session to backend
          await _apiClient.post(
            '/api/reading-progress',
            data: {
              'content_id': session['content_id'],
              'session_id': session['session_id'],
              'start_time': DateTime.fromMillisecondsSinceEpoch(
                session['start_time'] as int,
              ).toIso8601String(),
              'end_time': session['end_time'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      session['end_time'] as int,
                    ).toIso8601String()
                  : null,
              'start_page': session['start_page'],
              'end_page': session['end_page'],
            },
          );

          // Mark as synced
          await _databaseHelper.markReadingSessionSynced(
            session['session_id'] as String,
          );
          syncedCount++;
        } catch (e) {
          _logger.e('Error syncing reading session ${session['session_id']}: $e');
          // Continue with next session
        }
      }

      _logger.i('Synced $syncedCount reading sessions');

      return SyncResult(
        success: true,
        message: 'Synced $syncedCount reading sessions',
        syncedCount: syncedCount,
      );
    } catch (e) {
      _logger.e('Error syncing reading progress: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync reading progress: $e',
      );
    }
  }

  /// Sync library updates from backend
  Future<SyncResult> syncLibraryUpdates({String? userId}) async {
    try {
      _logger.d('Syncing library updates from backend');

      if (userId == null) {
        return SyncResult(success: false, message: 'User ID required');
      }

      // Fetch library from backend
      final response = await _apiClient.get('/api/user/library');

      if (response.statusCode == 200 && response.data != null) {
        final libraryData = response.data as Map<String, dynamic>;
        final items = libraryData['items'] as List<dynamic>? ?? [];

        int updatedCount = 0;

        for (final item in items) {
          try {
            final itemMap = item as Map<String, dynamic>;
            final contentId = itemMap['content_id'] as int;

            // Get local library item
            final localItem = await _databaseHelper.getLibraryItem(
              userId,
              contentId,
            );

            // Conflict resolution: last-write-wins based on last_synced timestamp
            final remoteLastSynced = itemMap['last_synced'] as int?;
            final localLastSynced = localItem?['last_synced'] as int?;

            if (localLastSynced == null ||
                (remoteLastSynced != null && remoteLastSynced > localLastSynced)) {
              // Update local with remote data
              await _databaseHelper.upsertLibraryItem({
                'content_id': contentId,
                'user_id': userId,
                'content_data': jsonEncode(itemMap['content']),
                'purchase_date': itemMap['purchase_date'],
                'reading_progress': itemMap['reading_progress'] ?? 0.0,
                'current_page': itemMap['current_page'],
                'last_opened': itemMap['last_opened'],
                'is_downloaded': localItem?['is_downloaded'] ?? 0,
                'is_favorite': itemMap['is_favorite'] ?? 0,
                'last_synced': DateTime.now().millisecondsSinceEpoch,
              });
              updatedCount++;
            }
          } catch (e) {
            _logger.e('Error syncing library item: $e');
            // Continue with next item
          }
        }

        _logger.i('Synced $updatedCount library items');

        return SyncResult(
          success: true,
          message: 'Synced $updatedCount library items',
          syncedCount: updatedCount,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Failed to fetch library from backend',
        );
      }
    } catch (e) {
      _logger.e('Error syncing library updates: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync library updates: $e',
      );
    }
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _logger.d('SyncManager disposed');
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int? syncedCount;
  final Map<String, bool>? syncedItems;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount,
    this.syncedItems,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, syncedCount: $syncedCount)';
  }
}
