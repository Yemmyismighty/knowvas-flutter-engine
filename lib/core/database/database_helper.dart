import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import 'database.dart';

/// Database helper class providing CRUD operations for all tables
class DatabaseHelper {
  DatabaseHelper({KnowvasDatabase? knowvasDatabase})
      : _knowvasDatabase = knowvasDatabase ?? KnowvasDatabase();

  final KnowvasDatabase _knowvasDatabase;
  final Logger _logger = Logger();

  Future<Database> get _db async => _knowvasDatabase.database;

  // ==================== Users Table ====================

  /// Insert or update a user
  Future<int> upsertUser(Map<String, dynamic> user) async {
    final db = await _db;
    try {
      return await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Error upserting user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await _db;
    try {
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.e('Error getting user: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<int> deleteUser(String userId) async {
    final db = await _db;
    try {
      return await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error deleting user: $e');
      rethrow;
    }
  }

  // ==================== Library Items Table ====================

  /// Insert or update a library item
  Future<int> upsertLibraryItem(Map<String, dynamic> item) async {
    final db = await _db;
    try {
      return await db.insert(
        'library_items',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Error upserting library item: $e');
      rethrow;
    }
  }

  /// Get all library items for a user
  Future<List<Map<String, dynamic>>> getLibraryItems(String userId) async {
    final db = await _db;
    try {
      return await db.query(
        'library_items',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'last_opened DESC',
      );
    } catch (e) {
      _logger.e('Error getting library items: $e');
      rethrow;
    }
  }

  /// Get a specific library item
  Future<Map<String, dynamic>?> getLibraryItem(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      final results = await db.query(
        'library_items',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.e('Error getting library item: $e');
      rethrow;
    }
  }

  /// Update reading progress
  Future<int> updateReadingProgress(
    String userId,
    int contentId,
    double progress,
    int? currentPage,
  ) async {
    final db = await _db;
    try {
      return await db.update(
        'library_items',
        {
          'reading_progress': progress,
          'current_page': currentPage,
          'last_opened': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
    } catch (e) {
      _logger.e('Error updating reading progress: $e');
      rethrow;
    }
  }

  /// Delete a library item
  Future<int> deleteLibraryItem(String userId, int contentId) async {
    final db = await _db;
    try {
      return await db.delete(
        'library_items',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
    } catch (e) {
      _logger.e('Error deleting library item: $e');
      rethrow;
    }
  }

  /// Get downloaded library items
  Future<List<Map<String, dynamic>>> getDownloadedLibraryItems(
    String userId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'library_items',
        where: 'user_id = ? AND is_downloaded = 1',
        whereArgs: [userId],
        orderBy: 'last_opened DESC',
      );
    } catch (e) {
      _logger.e('Error getting downloaded library items: $e');
      rethrow;
    }
  }

  // ==================== Downloaded Files Table ====================

  /// Insert or update a downloaded file
  Future<int> upsertDownloadedFile(Map<String, dynamic> file) async {
    final db = await _db;
    try {
      return await db.insert(
        'downloaded_files',
        file,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Error upserting downloaded file: $e');
      rethrow;
    }
  }

  /// Get downloaded file info
  Future<Map<String, dynamic>?> getDownloadedFile(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      final results = await db.query(
        'downloaded_files',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.e('Error getting downloaded file: $e');
      rethrow;
    }
  }

  /// Get all downloaded files for a user
  Future<List<Map<String, dynamic>>> getDownloadedFiles(String userId) async {
    final db = await _db;
    try {
      return await db.query(
        'downloaded_files',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error getting downloaded files: $e');
      rethrow;
    }
  }

  /// Delete a downloaded file record
  Future<int> deleteDownloadedFile(String userId, int contentId) async {
    final db = await _db;
    try {
      return await db.delete(
        'downloaded_files',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
    } catch (e) {
      _logger.e('Error deleting downloaded file: $e');
      rethrow;
    }
  }

  // ==================== Bookmarks Table ====================

  /// Insert a bookmark
  Future<int> insertBookmark(Map<String, dynamic> bookmark) async {
    final db = await _db;
    try {
      return await db.insert('bookmarks', bookmark);
    } catch (e) {
      _logger.e('Error inserting bookmark: $e');
      rethrow;
    }
  }

  /// Get bookmarks for content
  Future<List<Map<String, dynamic>>> getBookmarks(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'bookmarks',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
        orderBy: 'page_number ASC',
      );
    } catch (e) {
      _logger.e('Error getting bookmarks: $e');
      rethrow;
    }
  }

  /// Delete a bookmark
  Future<int> deleteBookmark(int bookmarkId) async {
    final db = await _db;
    try {
      return await db.delete(
        'bookmarks',
        where: 'id = ?',
        whereArgs: [bookmarkId],
      );
    } catch (e) {
      _logger.e('Error deleting bookmark: $e');
      rethrow;
    }
  }

  /// Mark bookmark as synced
  Future<int> markBookmarkSynced(int bookmarkId) async {
    final db = await _db;
    try {
      return await db.update(
        'bookmarks',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [bookmarkId],
      );
    } catch (e) {
      _logger.e('Error marking bookmark as synced: $e');
      rethrow;
    }
  }

  /// Get unsynced bookmarks
  Future<List<Map<String, dynamic>>> getUnsyncedBookmarks(
    String userId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'bookmarks',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error getting unsynced bookmarks: $e');
      rethrow;
    }
  }

  // ==================== Highlights Table ====================

  /// Insert a highlight
  Future<int> insertHighlight(Map<String, dynamic> highlight) async {
    final db = await _db;
    try {
      return await db.insert('highlights', highlight);
    } catch (e) {
      _logger.e('Error inserting highlight: $e');
      rethrow;
    }
  }

  /// Get highlights for content
  Future<List<Map<String, dynamic>>> getHighlights(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'highlights',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
        orderBy: 'page_number ASC, start_position ASC',
      );
    } catch (e) {
      _logger.e('Error getting highlights: $e');
      rethrow;
    }
  }

  /// Delete a highlight
  Future<int> deleteHighlight(int highlightId) async {
    final db = await _db;
    try {
      return await db.delete(
        'highlights',
        where: 'id = ?',
        whereArgs: [highlightId],
      );
    } catch (e) {
      _logger.e('Error deleting highlight: $e');
      rethrow;
    }
  }

  /// Mark highlight as synced
  Future<int> markHighlightSynced(int highlightId) async {
    final db = await _db;
    try {
      return await db.update(
        'highlights',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [highlightId],
      );
    } catch (e) {
      _logger.e('Error marking highlight as synced: $e');
      rethrow;
    }
  }

  /// Get unsynced highlights
  Future<List<Map<String, dynamic>>> getUnsyncedHighlights(
    String userId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'highlights',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error getting unsynced highlights: $e');
      rethrow;
    }
  }

  // ==================== Notes Table ====================

  /// Insert a note
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await _db;
    try {
      return await db.insert('notes', note);
    } catch (e) {
      _logger.e('Error inserting note: $e');
      rethrow;
    }
  }

  /// Update a note
  Future<int> updateNote(int noteId, Map<String, dynamic> note) async {
    final db = await _db;
    try {
      return await db.update(
        'notes',
        {
          ...note,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      _logger.e('Error updating note: $e');
      rethrow;
    }
  }

  /// Get notes for content
  Future<List<Map<String, dynamic>>> getNotes(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'notes',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
        orderBy: 'page_number ASC',
      );
    } catch (e) {
      _logger.e('Error getting notes: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<int> deleteNote(int noteId) async {
    final db = await _db;
    try {
      return await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      _logger.e('Error deleting note: $e');
      rethrow;
    }
  }

  /// Mark note as synced
  Future<int> markNoteSynced(int noteId) async {
    final db = await _db;
    try {
      return await db.update(
        'notes',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      _logger.e('Error marking note as synced: $e');
      rethrow;
    }
  }

  /// Get unsynced notes
  Future<List<Map<String, dynamic>>> getUnsyncedNotes(String userId) async {
    final db = await _db;
    try {
      return await db.query(
        'notes',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error getting unsynced notes: $e');
      rethrow;
    }
  }

  // ==================== Engagement Queue Table ====================

  /// Insert an engagement event
  Future<int> insertEngagementEvent(Map<String, dynamic> event) async {
    final db = await _db;
    try {
      return await db.insert('engagement_queue', event);
    } catch (e) {
      _logger.e('Error inserting engagement event: $e');
      rethrow;
    }
  }

  /// Get unuploaded engagement events
  Future<List<Map<String, dynamic>>> getUnuploadedEngagementEvents(
    String userId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'engagement_queue',
        where: 'user_id = ? AND uploaded = 0',
        whereArgs: [userId],
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      _logger.e('Error getting unuploaded engagement events: $e');
      rethrow;
    }
  }

  /// Mark engagement events as uploaded
  Future<int> markEngagementEventsUploaded(List<int> eventIds) async {
    final db = await _db;
    try {
      return await db.update(
        'engagement_queue',
        {'uploaded': 1},
        where: 'id IN (${eventIds.join(',')})',
      );
    } catch (e) {
      _logger.e('Error marking engagement events as uploaded: $e');
      rethrow;
    }
  }

  /// Delete uploaded engagement events older than specified days
  Future<int> deleteOldEngagementEvents(int daysOld) async {
    final db = await _db;
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;
      return await db.delete(
        'engagement_queue',
        where: 'uploaded = 1 AND timestamp < ?',
        whereArgs: [cutoffTime],
      );
    } catch (e) {
      _logger.e('Error deleting old engagement events: $e');
      rethrow;
    }
  }

  // ==================== Reading Sessions Table ====================

  /// Insert a reading session
  Future<int> insertReadingSession(Map<String, dynamic> session) async {
    final db = await _db;
    try {
      return await db.insert(
        'reading_sessions',
        session,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Error inserting reading session: $e');
      rethrow;
    }
  }

  /// Update reading session end time
  Future<int> updateReadingSessionEnd(
    String sessionId,
    int endTime,
    int? endPage,
  ) async {
    final db = await _db;
    try {
      return await db.update(
        'reading_sessions',
        {
          'end_time': endTime,
          'end_page': endPage,
        },
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      _logger.e('Error updating reading session: $e');
      rethrow;
    }
  }

  /// Get reading sessions for content
  Future<List<Map<String, dynamic>>> getReadingSessions(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'reading_sessions',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
        orderBy: 'start_time DESC',
      );
    } catch (e) {
      _logger.e('Error getting reading sessions: $e');
      rethrow;
    }
  }

  /// Get unsynced reading sessions
  Future<List<Map<String, dynamic>>> getUnsyncedReadingSessions(
    String userId,
  ) async {
    final db = await _db;
    try {
      return await db.query(
        'reading_sessions',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.e('Error getting unsynced reading sessions: $e');
      rethrow;
    }
  }

  /// Mark reading session as synced
  Future<int> markReadingSessionSynced(String sessionId) async {
    final db = await _db;
    try {
      return await db.update(
        'reading_sessions',
        {'synced': 1},
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      _logger.e('Error marking reading session as synced: $e');
      rethrow;
    }
  }

  // ==================== Reader Preferences Table ====================

  /// Insert or update reader preferences
  Future<int> upsertReaderPreferences(Map<String, dynamic> preferences) async {
    final db = await _db;
    try {
      return await db.insert(
        'reader_preferences',
        preferences,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Error upserting reader preferences: $e');
      rethrow;
    }
  }

  /// Get reader preferences for content
  Future<Map<String, dynamic>?> getReaderPreferences(
    String userId,
    int contentId,
  ) async {
    final db = await _db;
    try {
      final results = await db.query(
        'reader_preferences',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.e('Error getting reader preferences: $e');
      rethrow;
    }
  }

  /// Delete reader preferences
  Future<int> deleteReaderPreferences(String userId, int contentId) async {
    final db = await _db;
    try {
      return await db.delete(
        'reader_preferences',
        where: 'user_id = ? AND content_id = ?',
        whereArgs: [userId, contentId],
      );
    } catch (e) {
      _logger.e('Error deleting reader preferences: $e');
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  /// Clear all data for a user (useful for logout)
  Future<void> clearUserData(String userId) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        await txn.delete('library_items', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('downloaded_files', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('bookmarks', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('highlights', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('notes', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('engagement_queue', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('reading_sessions', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('reader_preferences', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      });
      _logger.i('Cleared all data for user: $userId');
    } catch (e) {
      _logger.e('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats(String userId) async {
    final db = await _db;
    try {
      final stats = <String, int>{};
      
      final libraryCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM library_items WHERE user_id = ?', [userId]),
      );
      stats['library_items'] = libraryCount ?? 0;

      final downloadedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM downloaded_files WHERE user_id = ?', [userId]),
      );
      stats['downloaded_files'] = downloadedCount ?? 0;

      final bookmarksCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM bookmarks WHERE user_id = ?', [userId]),
      );
      stats['bookmarks'] = bookmarksCount ?? 0;

      final highlightsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM highlights WHERE user_id = ?', [userId]),
      );
      stats['highlights'] = highlightsCount ?? 0;

      final notesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes WHERE user_id = ?', [userId]),
      );
      stats['notes'] = notesCount ?? 0;

      final pendingEventsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM engagement_queue WHERE user_id = ? AND uploaded = 0',
          [userId],
        ),
      );
      stats['pending_events'] = pendingEventsCount ?? 0;

      return stats;
    } catch (e) {
      _logger.e('Error getting database stats: $e');
      rethrow;
    }
  }
}
