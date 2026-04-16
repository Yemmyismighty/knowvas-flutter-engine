# Platform Channel Interface

This module provides the communication layer between Flutter and native reader modules (Android/iOS).

## Overview

The platform channel interface enables Flutter to:
- Open native readers for different content types (EPUB, PDF, Comic)
- Control reader behavior and preferences
- Receive events from native readers (page turns, bookmarks, errors)

## Architecture

```
Flutter Layer                    Native Layer
┌─────────────────┐             ┌──────────────────┐
│ ReaderChannel   │◄───────────►│ ReaderPlugin     │
│                 │  Method      │ (Android/iOS)    │
│                 │  Channel     │                  │
│                 │              │                  │
│                 │◄─────────────│                  │
│                 │  Event       │                  │
│                 │  Channel     │                  │
└─────────────────┘             └──────────────────┘
```

## Components

### ReaderChannel

Main interface for platform channel communication.

**Methods:**
- `openReader(OpenReaderRequest)` - Opens a native reader
- `closeReader(String sessionId)` - Closes an active reader session
- `setReaderPrefs(ReaderPreferences)` - Updates reader preferences
- `readerEvents` - Stream of events from native readers

### Data Transfer Objects (DTOs)

#### OpenReaderRequest
Request payload for opening a reader.

```dart
final request = OpenReaderRequest(
  contentId: 123,
  type: 'epub', // 'epub', 'pdf', or 'comic'
  fileUrl: 'https://example.com/book.epub',
  token: 'auth-token',
  sessionId: 'unique-session-id',
);
```

#### ReaderResponse
Response from native reader operations.

```dart
final response = await readerChannel.openReader(request);
if (response.isSuccess) {
  // Reader opened successfully
} else {
  // Handle error: response.errorCode, response.errorMessage
}
```

#### ReaderPreferences
Customization options for the reader.

```dart
final prefs = ReaderPreferences(
  fontSize: 18,
  theme: 'dark', // 'light', 'dark', 'sepia'
  layout: 'single', // 'single', 'double'
  fontFamily: 'serif', // 'serif', 'sans-serif', 'monospace'
  lineHeight: 1.5,
  margin: 1.0,
);
```

#### ReaderEvent (sealed class)
Base class for all reader events. Subclasses:

**ReaderReadyEvent** - Emitted when reader is initialized
```dart
event.totalPages // Total number of pages
```

**EngagementEvent** - User interaction events
```dart
event.eventType // 'page_turn', 'bookmark', 'highlight', 'session_end'
event.pageIndex // Current page number
event.payload   // Additional event data
```

**ReaderErrorEvent** - Error events
```dart
event.code    // Error code
event.message // Error description
```

## Usage Example

```dart
import 'package:knowvas_flutter_client/core/platform/platform.dart';

class ReaderService {
  final ReaderChannel _readerChannel = ReaderChannel();
  
  Future<void> openBook(int contentId, String fileUrl) async {
    // Listen to reader events
    _readerChannel.readerEvents.listen((event) {
      switch (event) {
        case ReaderReadyEvent():
          print('Reader ready with ${event.totalPages} pages');
        case EngagementEvent():
          print('User action: ${event.eventType} on page ${event.pageIndex}');
        case ReaderErrorEvent():
          print('Error: ${event.code} - ${event.message}');
      }
    });
    
    // Open the reader
    final request = OpenReaderRequest(
      contentId: contentId,
      type: 'epub',
      fileUrl: fileUrl,
      token: 'user-auth-token',
      sessionId: 'session-${DateTime.now().millisecondsSinceEpoch}',
    );
    
    final response = await _readerChannel.openReader(request);
    
    if (response.isError) {
      throw Exception('Failed to open reader: ${response.errorMessage}');
    }
  }
  
  Future<void> updateTheme(String theme) async {
    final prefs = ReaderPreferences(theme: theme);
    await _readerChannel.setReaderPrefs(prefs);
  }
  
  Future<void> closeReader(String sessionId) async {
    await _readerChannel.closeReader(sessionId);
  }
}
```

## Error Handling

The platform channel implements comprehensive error handling:

1. **PlatformException** - Caught and converted to ReaderResponse with error details
2. **Null responses** - Handled with NULL_RESPONSE error code
3. **Event stream errors** - Logged without breaking the stream
4. **Method call failures** - Throw exceptions with descriptive messages

## Testing

Comprehensive unit tests are provided in `test/core/platform/reader_channel_test.dart`.

Run tests:
```bash
flutter test test/core/platform/reader_channel_test.dart
```

## Requirements Satisfied

This implementation satisfies the following requirements:

- **13.1**: Platform channel receives openReader with content_id, type, file_url, token, session_id
- **13.2**: Native module returns status="ok" or error object
- **13.3**: closeReader closes reader and saves state
- **13.4**: setReaderPrefs applies preferences immediately
- **13.5**: Native reader emits onReaderReady event
- **13.6**: Page turn events emitted with session_id, event, page_index, timestamp
- **13.7**: Error events emitted with code and message
- **13.8**: Typed wrappers and DTOs for type safety
- **13.9**: Error logging and user-friendly messages
- **13.10**: Robust error handling for platform channel failures

## Native Implementation

For native implementation details, see:
- Android: `android/app/src/main/kotlin/com/knowvas/reader/ReaderPlugin.kt`
- iOS: `ios/Runner/Reader/ReaderPlugin.swift`
