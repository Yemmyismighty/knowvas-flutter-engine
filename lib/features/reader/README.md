# Reader Feature

This feature manages the reading experience, coordinating between Flutter UI, native reader modules, and backend services.

## Architecture

### State Management

The reader feature uses Riverpod for state management with the following components:

#### ReaderState (`presentation/providers/reader_state.dart`)
Immutable state class that holds:
- `sessionId`: Unique identifier for the current reading session
- `contentId`: ID of the content being read
- `contentType`: Type of content ('epub', 'pdf', 'comic')
- `currentPage`: Current page number
- `totalPages`: Total number of pages
- `preferences`: Reader preferences (font, theme, layout, etc.)
- `isLoading`: Loading state indicator
- `error`: Error message if any
- `isReaderOpen`: Whether reader is currently open

#### ReaderNotifier (`presentation/providers/reader_provider.dart`)
Manages reader state and coordinates:
- Opening/closing content in native reader
- Handling reader events from platform channel
- Persisting preferences per content
- Tracking engagement events
- Managing reading sessions

### Data Layer

#### EngagementRepository (`data/repositories/engagement_repository.dart`)
Handles engagement event tracking:
- Logs events locally to SQLite
- Batch uploads events to backend
- Manages event queue for offline scenarios

## Usage

### Opening Content

```dart
final readerNotifier = ref.read(readerProvider.notifier);

await readerNotifier.openContent(
  contentId: 123,
  contentType: 'epub',
  fileUrl: 'https://example.com/book.epub',
  token: 'auth-token',
);
```

### Updating Preferences

```dart
final readerNotifier = ref.read(readerProvider.notifier);

await readerNotifier.updatePreferences(
  ReaderPreferences(
    fontSize: 18,
    theme: 'dark',
    fontFamily: 'serif',
  ),
);
```

### Closing Content

```dart
final readerNotifier = ref.read(readerProvider.notifier);

await readerNotifier.closeContent();
```

### Watching State

```dart
final readerState = ref.watch(readerProvider);

if (readerState.isLoading) {
  return CircularProgressIndicator();
}

if (readerState.error != null) {
  return Text('Error: ${readerState.error}');
}

if (readerState.isReaderOpen) {
  return Text('Page ${readerState.currentPage} of ${readerState.totalPages}');
}
```

## Features

### Preference Persistence
- Preferences are saved per content in SQLite
- Automatically loaded when opening content
- Applied to native reader in real-time

### Engagement Tracking
- Tracks all user interactions (page turns, bookmarks, highlights)
- Events queued locally when offline
- Batch uploaded when online
- Supports analytics and revenue allocation

### Reading Sessions
- Creates session record on open
- Updates session on close with end time and page
- Tracks reading progress per content
- Syncs to backend for cross-device consistency

### Event Handling
- Listens to native reader events via platform channel
- Handles reader ready, engagement, and error events
- Updates state based on events
- Logs events for backend sync

## Requirements Covered

This implementation satisfies the following requirements:

- **5.1**: Opens EPUB content via platform channel
- **5.2**: Handles remote file URLs with signed download
- **5.3**: Parses metadata and emits ready event
- **5.4**: Restores last read position
- **6.1**: Opens PDF content via platform channel
- **6.2**: Emits ready event with page count
- **7.1**: Opens comic content via platform channel
- **7.2**: Displays first page and emits ready event

## Database Schema

The reader feature uses the following tables:

- `reader_preferences`: Stores per-content preferences
- `reading_sessions`: Tracks reading sessions
- `engagement_queue`: Queues engagement events for upload
- `library_items`: Updates reading progress

## Error Handling

The reader notifier handles various error scenarios:
- Platform channel communication failures
- File not found errors
- Network errors during event upload
- Database errors during persistence

All errors are logged and exposed via the state's `error` property.

## Testing

To test the reader feature:

1. Mock the `ReaderChannel` for platform channel calls
2. Mock the `DatabaseHelper` for database operations
3. Mock the `EngagementRepository` for event tracking
4. Test state transitions for various scenarios

Example test structure:
```dart
void main() {
  late Reader readerNotifier;
  late MockReaderChannel mockReaderChannel;
  late MockDatabaseHelper mockDatabaseHelper;

  setUp(() {
    mockReaderChannel = MockReaderChannel();
    mockDatabaseHelper = MockDatabaseHelper();
    // Initialize readerNotifier with mocks
  });

  test('openContent updates state to loading', () async {
    // Test implementation
  });

  test('handleReaderReady updates total pages', () {
    // Test implementation
  });
}
```
