import 'dart:async';

import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/platform/reader_channel.dart';
import '../../../../core/platform/reader_dtos.dart';
import '../../../../core/utils/performance_service.dart';
import '../../../../shared/models/engagement_event.dart' as model;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../data/repositories/engagement_repository_provider.dart';
import '../../data/repositories/reading_progress_repository_provider.dart';
import 'reader_state.dart';

part 'reader_provider.g.dart';

/// ReaderNotifier manages reader state and handles reader events
/// Coordinates between Flutter UI, native reader modules, and backend
@riverpod
class Reader extends _$Reader {
  final Logger _logger = Logger();
  final ReaderChannel _readerChannel = ReaderChannel();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();
  
  StreamSubscription<ReaderEvent>? _eventSubscription;
  String? _currentUserId;

  @override
  ReaderState build() {
    // Listen to reader events from native platform
    _initializeEventListener();
    
    // Get current user ID
    final authState = ref.watch(authProvider);
    _currentUserId = authState.user?.id;
    
    // Cleanup on dispose
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _progressUpdateTimer?.cancel();
    });
    
    return ReaderState.initial();
  }

  /// Initialize event listener for native reader events
  void _initializeEventListener() {
    _eventSubscription?.cancel();
    _eventSubscription = _readerChannel.readerEvents.listen(
      _handleReaderEvent,
      onError: (Object error) {
        _logger.e('Error in reader event stream: $error');
        state = state.copyWithError('Reader event error: $error');
      },
    );
  }

  /// Open content in native reader
  /// Loads preferences from database and starts reading session
  Future<void> openContent({
    required int contentId,
    required String contentType,
    required String fileUrl,
    required String token,
  }) async {
    if (_currentUserId == null) {
      state = state.copyWithError('User not authenticated');
      return;
    }

    state = ReaderState.loading(
      contentId: contentId,
      contentType: contentType,
    );

    // Start tracking reader open performance
    PerformanceService().startReaderOpen(contentId, contentType);

    try {
      // Generate session ID
      final sessionId = _uuid.v4();

      // Load saved preferences for this content
      final savedPrefs = await _loadPreferences(contentId);

      // Create open reader request
      final request = OpenReaderRequest(
        contentId: contentId,
        type: contentType,
        fileUrl: fileUrl,
        token: token,
        sessionId: sessionId,
      );

      // Call native platform to open reader
      final response = await _readerChannel.openReader(request);

      if (response.isError) {
        // Stop tracking on failure
        PerformanceService().stopReaderOpen(contentId, contentType, success: false);
        
        state = state.copyWithError(
          response.errorMessage ?? 'Failed to open reader',
        );
        return;
      }

      // Create reading session record
      await _createReadingSession(
        sessionId: sessionId,
        contentId: contentId,
      );

      // Log open engagement event
      await _logEngagementEvent(
        contentId: contentId,
        sessionId: sessionId,
        eventType: 'open',
      );

      // Update state to loading with session info
      // The ready state will be set when we receive ReaderReadyEvent
      state = state.copyWith(
        sessionId: sessionId,
        contentId: contentId,
        contentType: contentType,
        preferences: savedPrefs,
        isLoading: true,
        isReaderOpen: true,
      );

      _logger.i('Reader opened for content $contentId with session $sessionId');
    } on ReaderFailure catch (e) {
      // Stop tracking on failure
      PerformanceService().stopReaderOpen(contentId, contentType, success: false);
      
      _logger.e('Reader failure: ${e.message}');
      state = state.copyWithError(e.message);
    } catch (e) {
      // Stop tracking on failure
      PerformanceService().stopReaderOpen(contentId, contentType, success: false);
      
      _logger.e('Failed to open content: $e');
      state = state.copyWithError('Failed to open content: $e');
    }
  }

  /// Close current reader session
  /// Saves progress and logs session end event
  Future<void> closeContent() async {
    if (state.sessionId == null || !state.isReaderOpen) {
      return;
    }

    try {
      final sessionId = state.sessionId!;
      final contentId = state.contentId!;
      final currentPage = state.currentPage;

      // Close reader on native platform
      await _readerChannel.closeReader(sessionId);

      // Update reading session end time
      await _updateReadingSessionEnd(
        sessionId: sessionId,
        endPage: currentPage,
      );

      // Update reading progress in library
      if (currentPage != null) {
        await _updateReadingProgress(
          contentId: contentId,
          progress: state.progress,
          currentPage: currentPage,
        );
      }

      // Log close engagement event
      await _logEngagementEvent(
        contentId: contentId,
        sessionId: sessionId,
        eventType: 'close',
        payload: {
          'final_page': currentPage,
          'progress': state.progress,
        },
      );

      // Reset state
      state = ReaderState.initial();

      _logger.i('Reader closed for session $sessionId');
    } catch (e) {
      _logger.e('Failed to close reader: $e');
      // Still reset state even if close fails
      state = ReaderState.initial();
    }
  }

  /// Update reader preferences
  /// Saves to database and applies to native reader
  Future<void> updatePreferences(ReaderPreferences preferences) async {
    if (!state.isReaderOpen || state.contentId == null) {
      return;
    }

    try {
      // Apply preferences to native reader
      await _readerChannel.setReaderPrefs(preferences);

      // Save preferences to database
      await _savePreferences(state.contentId!, preferences);

      // Update state
      state = state.copyWith(preferences: preferences);

      _logger.d('Reader preferences updated');
    } catch (e) {
      _logger.e('Failed to update preferences: $e');
      state = state.copyWithError('Failed to update preferences: $e');
    }
  }

  /// Handle reader events from native platform
  void _handleReaderEvent(ReaderEvent event) {
    _logger.d('Received reader event: ${event.runtimeType}');

    switch (event) {
      case ReaderReadyEvent():
        _handleReaderReady(event);
        break;
      case EngagementEvent():
        _handleEngagement(event);
        break;
      case ReaderErrorEvent():
        _handleReaderError(event);
        break;
    }
  }

  /// Handle reader ready event
  void _handleReaderReady(ReaderReadyEvent event) {
    if (event.sessionId != state.sessionId) {
      _logger.w('Received ready event for different session');
      return;
    }

    // Stop tracking reader open performance on success
    if (state.contentId != null && state.contentType != null) {
      PerformanceService().stopReaderOpen(
        state.contentId!,
        state.contentType!,
        success: true,
      );
    }

    state = state.copyWith(
      totalPages: event.totalPages,
      isLoading: false,
    );

    _logger.i('Reader ready with ${event.totalPages} pages');
  }

  /// Handle engagement event from native reader
  void _handleEngagement(EngagementEvent event) {
    if (event.sessionId != state.sessionId) {
      _logger.w('Received engagement event for different session');
      return;
    }

    final contentId = state.contentId;
    if (contentId == null) {
      _logger.w('Received engagement event but no content loaded');
      return;
    }

    // Handle different event types
    switch (event.eventType) {
      case 'page_turn':
        _handlePageTurn(event, contentId);
        break;
      case 'bookmark':
        _handleBookmarkEvent(event, contentId);
        break;
      case 'highlight':
        _handleHighlightEvent(event, contentId);
        break;
      case 'read_progress':
        _handleReadProgressEvent(event, contentId);
        break;
      default:
        _logger.d('Unhandled engagement event type: ${event.eventType}');
    }

    // Log all engagement events
    _logEngagementEvent(
      contentId: contentId,
      sessionId: event.sessionId,
      eventType: event.eventType,
      pageIndex: event.pageIndex,
      payload: event.payload,
    );
  }

  /// Handle page turn event
  void _handlePageTurn(EngagementEvent event, int contentId) {
    if (event.pageIndex == null) {
      _logger.w('Page turn event missing page index');
      return;
    }

    // Track page turn latency
    final latency = DateTime.now().difference(event.timestamp);
    if (state.contentType != null && state.currentPage != null) {
      PerformanceService().recordPageTurn(
        contentId,
        state.contentType!,
        state.currentPage!,
        event.pageIndex!,
        latency,
      );
    }

    // Update current page in state
    state = state.copyWith(currentPage: event.pageIndex);

    // Calculate and update reading progress
    final progress = state.progress;
    
    // Update reading progress in library (debounced to avoid too many updates)
    _updateReadingProgressDebounced(
      contentId: contentId,
      progress: progress,
      currentPage: event.pageIndex!,
    );

    _logger.d('Page turn: ${event.pageIndex}/${state.totalPages} (${(progress * 100).toStringAsFixed(1)}%)');
  }

  /// Handle bookmark event
  void _handleBookmarkEvent(EngagementEvent event, int contentId) {
    final pageNumber = event.pageIndex ?? event.payload?['page_number'] as int?;
    
    if (pageNumber == null) {
      _logger.w('Bookmark event missing page number');
      return;
    }

    _logger.d('Bookmark added at page $pageNumber');
    
    // The bookmark is already saved by the native reader or bookmark UI
    // This event is just for tracking engagement
  }

  /// Handle highlight event
  void _handleHighlightEvent(EngagementEvent event, int contentId) {
    final pageNumber = event.pageIndex ?? event.payload?['page_number'] as int?;
    final highlightedText = event.payload?['highlighted_text'] as String?;
    
    if (pageNumber == null) {
      _logger.w('Highlight event missing page number');
      return;
    }

    _logger.d('Highlight added at page $pageNumber: ${highlightedText?.substring(0, 30)}...');
    
    // The highlight is already saved by the native reader or highlight UI
    // This event is just for tracking engagement
  }

  /// Handle read progress event
  void _handleReadProgressEvent(EngagementEvent event, int contentId) {
    final progressValue = event.payload?['progress'] as double?;
    final pageIndex = event.pageIndex;
    
    if (progressValue != null && pageIndex != null) {
      // Update reading progress in library
      _updateReadingProgress(
        contentId: contentId,
        progress: progressValue,
        currentPage: pageIndex,
      );
      
      _logger.d('Read progress updated: ${(progressValue * 100).toStringAsFixed(1)}%');
    }
  }

  Timer? _progressUpdateTimer;

  /// Update reading progress with debouncing to avoid too many database writes
  void _updateReadingProgressDebounced({
    required int contentId,
    required double progress,
    required int currentPage,
  }) {
    // Cancel existing timer
    _progressUpdateTimer?.cancel();

    // Set new timer to update after 2 seconds of no page turns
    _progressUpdateTimer = Timer(const Duration(seconds: 2), () {
      _updateReadingProgress(
        contentId: contentId,
        progress: progress,
        currentPage: currentPage,
      );
    });
  }

  /// Handle reader error event
  void _handleReaderError(ReaderErrorEvent event) {
    _logger.e('Reader error: ${event.code} - ${event.message}');
    state = state.copyWithError('${event.code}: ${event.message}');
  }

  /// Load saved preferences for content
  Future<ReaderPreferences> _loadPreferences(int contentId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return const ReaderPreferences();
    }

    try {
      final prefs = await _databaseHelper.getReaderPreferences(
        userId,
        contentId,
      );

      if (prefs == null) {
        return const ReaderPreferences();
      }

      return ReaderPreferences(
        fontSize: prefs['font_size'] as int?,
        theme: prefs['theme'] as String?,
        layout: prefs['layout'] as String?,
        fontFamily: prefs['font_family'] as String?,
        lineHeight: prefs['line_height'] as double?,
        margin: prefs['margin'] as double?,
      );
    } catch (e) {
      _logger.e('Failed to load preferences: $e');
      return const ReaderPreferences();
    }
  }

  /// Save preferences to database
  Future<void> _savePreferences(
    int contentId,
    ReaderPreferences preferences,
  ) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await _databaseHelper.upsertReaderPreferences({
        'content_id': contentId,
        'user_id': userId,
        'font_size': preferences.fontSize,
        'font_family': preferences.fontFamily,
        'theme': preferences.theme,
        'line_height': preferences.lineHeight,
        'margin': preferences.margin,
        'layout': preferences.layout,
      });
    } catch (e) {
      _logger.e('Failed to save preferences: $e');
    }
  }

  /// Create reading session record
  Future<void> _createReadingSession({
    required String sessionId,
    required int contentId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await _databaseHelper.insertReadingSession({
        'session_id': sessionId,
        'content_id': contentId,
        'user_id': userId,
        'start_time': DateTime.now().millisecondsSinceEpoch,
        'start_page': 0,
        'synced': 0,
      });
    } catch (e) {
      _logger.e('Failed to create reading session: $e');
    }
  }

  /// Update reading session end time
  Future<void> _updateReadingSessionEnd({
    required String sessionId,
    int? endPage,
  }) async {
    try {
      await _databaseHelper.updateReadingSessionEnd(
        sessionId,
        DateTime.now().millisecondsSinceEpoch,
        endPage,
      );
    } catch (e) {
      _logger.e('Failed to update reading session end: $e');
    }
  }

  /// Update reading progress in library
  Future<void> _updateReadingProgress({
    required int contentId,
    required double progress,
    required int currentPage,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      // Update in database
      await _databaseHelper.updateReadingProgress(
        userId,
        contentId,
        progress,
        currentPage,
      );

      // Sync to backend
      try {
        final progressRepo = ref.read(readingProgressRepositoryProvider);
        await progressRepo.saveProgress(
          resourceId: contentId,
          progress: progress,
          currentPage: currentPage,
        );
      } catch (e) {
        _logger.w('Failed to sync progress to backend: $e');
      }

      // Notify library provider to update its state
      ref.read(libraryProvider.notifier).updateItem(
        contentId: contentId,
        readingProgress: progress,
        currentPage: currentPage,
        lastOpened: DateTime.now(),
      );

      _logger.d('Updated reading progress in library: $contentId -> ${(progress * 100).toStringAsFixed(1)}%');
    } catch (e) {
      _logger.e('Failed to update reading progress: $e');
    }
  }

  /// Log engagement event
  Future<void> _logEngagementEvent({
    required int contentId,
    required String sessionId,
    required String eventType,
    int? pageIndex,
    Map<String, dynamic>? payload,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      final event = model.EngagementEvent(
        contentId: contentId,
        sessionId: sessionId,
        eventType: eventType,
        payload: {
          if (pageIndex != null) 'page_index': pageIndex,
          if (payload != null) ...payload,
        },
        timestamp: DateTime.now(),
      );

      final repository = ref.read(engagementRepositoryProvider);
      await repository.logEngagement(event);
    } catch (e) {
      _logger.e('Failed to log engagement event: $e');
    }
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }
}
