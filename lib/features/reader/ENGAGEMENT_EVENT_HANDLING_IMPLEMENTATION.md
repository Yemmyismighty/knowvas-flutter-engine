# Engagement Event Handling Implementation

## Overview

This document describes the implementation of engagement event handling in the Knowvas Flutter reader. The system listens to reader events from native platform modules, processes them, updates the UI state, queues events for backend upload, and updates reading progress in the library.

## Implementation Summary

### Task 57: Implement engagement event handling

**Status**: ✅ Completed

**Requirements Addressed**:
- 9.1: Track user opening content
- 9.2: Track page turn events
- 9.3: Track user closing content
- 9.4: Track bookmark additions
- 9.5: Track highlight additions
- 9.6: Track reading progress changes

## Architecture

### Event Flow

```
Native Reader (Android/iOS)
    ↓ (Platform Channel Event Stream)
ReaderChannel
    ↓ (Stream<ReaderEvent>)
ReaderNotifier._handleReaderEvent()
    ↓ (Event Processing)
├─→ _handleReaderReady()      → Update UI with total pages
├─→ _handleEngagement()        → Process engagement events
│   ├─→ _handlePageTurn()      → Update current page & progress
│   ├─→ _handleBookmarkEvent() → Log bookmark engagement
│   ├─→ _handleHighlightEvent()→ Log highlight engagement
│   └─→ _handleReadProgressEvent() → Update progress
└─→ _handleReaderError()       → Display error to user
    ↓
├─→ _logEngagementEvent()      → Queue for backend upload
└─→ _updateReadingProgress()   → Update library & database
```

## Key Components

### 1. Event Listener Initialization

**Location**: `reader_provider.dart` - `_initializeEventListener()`

```dart
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
```

**Features**:
- Subscribes to platform channel event stream
- Handles errors gracefully
- Cancels previous subscription to prevent memory leaks

### 2. Reader Ready Event Handler

**Location**: `reader_provider.dart` - `_handleReaderReady()`

```dart
void _handleReaderReady(ReaderReadyEvent event) {
  if (event.sessionId != state.sessionId) {
    _logger.w('Received ready event for different session');
    return;
  }

  state = state.copyWith(
    totalPages: event.totalPages,
    isLoading: false,
  );

  _logger.i('Reader ready with ${event.totalPages} pages');
}
```

**Features**:
- Validates session ID to prevent stale events
- Updates UI state with total page count
- Removes loading indicator

### 3. Engagement Event Handler

**Location**: `reader_provider.dart` - `_handleEngagement()`

```dart
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
```

**Features**:
- Routes events to specific handlers based on type
- Validates session and content state
- Logs all events for backend upload

### 4. Page Turn Event Handler

**Location**: `reader_provider.dart` - `_handlePageTurn()`

```dart
void _handlePageTurn(EngagementEvent event, int contentId) {
  if (event.pageIndex == null) {
    _logger.w('Page turn event missing page index');
    return;
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
```

**Features**:
- Updates current page in reader state
- Calculates reading progress percentage
- Debounces progress updates to reduce database writes
- Logs progress for debugging

### 5. Bookmark Event Handler

**Location**: `reader_provider.dart` - `_handleBookmarkEvent()`

```dart
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
```

**Features**:
- Extracts page number from event
- Logs bookmark creation for analytics
- Assumes bookmark is already persisted by UI layer

### 6. Highlight Event Handler

**Location**: `reader_provider.dart` - `_handleHighlightEvent()`

```dart
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
```

**Features**:
- Extracts page number and highlighted text
- Logs highlight creation for analytics
- Assumes highlight is already persisted by UI layer

### 7. Read Progress Event Handler

**Location**: `reader_provider.dart` - `_handleReadProgressEvent()`

```dart
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
```

**Features**:
- Handles explicit progress update events
- Updates library immediately (not debounced)
- Useful for periodic progress sync

### 8. Debounced Progress Update

**Location**: `reader_provider.dart` - `_updateReadingProgressDebounced()`

```dart
Timer? _progressUpdateTimer;

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
```

**Features**:
- Debounces progress updates by 2 seconds
- Prevents excessive database writes during rapid page turns
- Cancels previous timer on new page turn
- Ensures final progress is saved after reading stops

### 9. Reading Progress Update

**Location**: `reader_provider.dart` - `_updateReadingProgress()`

```dart
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
```

**Features**:
- Updates progress in local SQLite database
- Notifies library provider to update UI
- Updates last opened timestamp
- Handles errors gracefully

### 10. Engagement Event Logging

**Location**: `reader_provider.dart` - `_logEngagementEvent()`

```dart
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
```

**Features**:
- Creates engagement event model
- Queues event for backend upload via repository
- Includes page index and custom payload
- Handles errors without breaking reader flow

### 11. Resource Cleanup

**Location**: `reader_provider.dart` - `build()`

```dart
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
```

**Features**:
- Cancels event stream subscription on dispose
- Cancels debounce timer on dispose
- Prevents memory leaks

## Event Types Handled

### 1. Reader Ready Event
- **Type**: `ReaderReadyEvent`
- **Trigger**: Native reader finishes loading content
- **Data**: `totalPages`
- **Action**: Update UI state, remove loading indicator

### 2. Page Turn Event
- **Type**: `EngagementEvent` with `eventType: 'page_turn'`
- **Trigger**: User navigates to a different page
- **Data**: `pageIndex`
- **Actions**:
  - Update current page in state
  - Calculate reading progress
  - Update library progress (debounced)
  - Log engagement event

### 3. Bookmark Event
- **Type**: `EngagementEvent` with `eventType: 'bookmark'`
- **Trigger**: User adds a bookmark
- **Data**: `pageIndex` or `payload.page_number`
- **Actions**:
  - Log engagement event for analytics
  - Bookmark already saved by UI layer

### 4. Highlight Event
- **Type**: `EngagementEvent` with `eventType: 'highlight'`
- **Trigger**: User creates a highlight
- **Data**: `pageIndex`, `payload.highlighted_text`
- **Actions**:
  - Log engagement event for analytics
  - Highlight already saved by UI layer

### 5. Read Progress Event
- **Type**: `EngagementEvent` with `eventType: 'read_progress'`
- **Trigger**: Periodic progress sync from native reader
- **Data**: `pageIndex`, `payload.progress`
- **Actions**:
  - Update library progress immediately
  - Log engagement event

### 6. Reader Error Event
- **Type**: `ReaderErrorEvent`
- **Trigger**: Error occurs in native reader
- **Data**: `code`, `message`
- **Action**: Display error to user

## Database Integration

### Tables Updated

1. **library_items**
   - `reading_progress`: Updated on page turns
   - `current_page`: Updated on page turns
   - `last_opened`: Updated on progress changes

2. **engagement_queue**
   - All engagement events queued for backend upload
   - Includes: open, page_turn, bookmark, highlight, close

3. **reading_sessions**
   - Created on reader open
   - Updated on reader close

## Backend Sync

### Engagement Event Queue

Events are queued locally and uploaded when online:

```dart
// Queue event
await repository.logEngagement(event);

// Events are uploaded by SyncManager when online
await syncManager.uploadEngagementEvents();
```

### Sync Strategy

1. **Immediate**: Events queued immediately in local database
2. **Batch Upload**: SyncManager uploads queued events in batches
3. **Retry Logic**: Failed uploads are retried with exponential backoff
4. **Offline Support**: Events queued offline and uploaded when online

## Performance Optimizations

### 1. Debounced Progress Updates
- Page turn events trigger immediate UI update
- Database writes debounced by 2 seconds
- Reduces database load during rapid page turns

### 2. Session Validation
- All events validated against current session ID
- Prevents processing stale events from previous sessions

### 3. Error Handling
- All operations wrapped in try-catch
- Errors logged but don't break reader flow
- User-friendly error messages displayed

### 4. Resource Cleanup
- Event subscriptions cancelled on dispose
- Timers cancelled on dispose
- Prevents memory leaks

## Testing Considerations

### Unit Tests

Test the following scenarios:

1. **Event Routing**
   - Verify correct handler called for each event type
   - Test session ID validation
   - Test content ID validation

2. **Page Turn Handling**
   - Verify state updates correctly
   - Test progress calculation
   - Test debounced updates

3. **Progress Updates**
   - Verify database updates
   - Verify library provider notification
   - Test error handling

4. **Event Logging**
   - Verify events queued correctly
   - Test payload construction
   - Test error handling

### Integration Tests

Test the following flows:

1. **Complete Reading Session**
   - Open content → page turns → close content
   - Verify all events logged
   - Verify progress updated

2. **Offline Reading**
   - Read while offline
   - Verify events queued
   - Go online and verify sync

3. **Error Recovery**
   - Simulate reader errors
   - Verify error handling
   - Verify state recovery

## Requirements Verification

### ✅ Requirement 9.1: Track user opening content
- Implemented in `openContent()` method
- Logs 'open' engagement event with session_id and timestamp

### ✅ Requirement 9.2: Track page turn events
- Implemented in `_handlePageTurn()` method
- Logs 'page_turn' event with page_index and timestamp
- Updates current page in state

### ✅ Requirement 9.3: Track user closing content
- Implemented in `closeContent()` method
- Logs 'close' event with final_page_index and session_duration

### ✅ Requirement 9.4: Track bookmark additions
- Implemented in `_handleBookmarkEvent()` method
- Logs 'bookmark' event with page_number and timestamp

### ✅ Requirement 9.5: Track highlight additions
- Implemented in `_handleHighlightEvent()` method
- Logs 'highlight' event with highlighted_text, page_number, and timestamp

### ✅ Requirement 9.6: Track reading progress changes
- Implemented in `_handleReadProgressEvent()` and `_handlePageTurn()` methods
- Updates progress in library and database
- Logs 'read_progress' events

## Future Enhancements

1. **Analytics Dashboard**
   - Aggregate engagement data
   - Display reading statistics
   - Show reading patterns

2. **Smart Recommendations**
   - Use engagement data for recommendations
   - Suggest similar content based on reading behavior

3. **Reading Goals**
   - Track progress towards reading goals
   - Send notifications for milestones

4. **Social Features**
   - Share reading progress with friends
   - Compare reading stats

## Conclusion

The engagement event handling implementation provides a robust, performant, and maintainable solution for tracking user interactions with content. It successfully addresses all requirements while maintaining clean architecture and proper error handling.
