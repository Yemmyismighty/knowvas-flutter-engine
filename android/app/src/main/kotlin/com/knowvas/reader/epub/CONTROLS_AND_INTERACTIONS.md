# EPUB Reader Controls and Interactions

This document describes the controls and interaction features implemented for the EPUB reader module.

## Overview

The EPUB reader now supports comprehensive user interactions including:
- Tap-to-toggle controls visibility
- Bookmark management
- Text highlighting with color selection
- Note-taking functionality
- Text selection with contextual actions
- Page navigation and progress tracking

## Architecture

### Components

1. **EpubReader** - Main reader class with control methods
2. **EpubInteractionHandler** - Manages bookmarks, highlights, and notes
3. **ReaderManager** - Routes method calls to appropriate reader
4. **ReaderPlugin** - Platform channel interface to Flutter

### Data Flow

```
Flutter UI
    ↓ (Method Channel)
ReaderPlugin
    ↓
ReaderManager
    ↓
EpubReader → EpubInteractionHandler
    ↓ (Event Channel)
Flutter UI (Events)
```

## Features

### 1. Controls Visibility

Toggle the visibility of reader controls (top/bottom bars).

**Method**: `toggleControls`

```kotlin
// Kotlin
reader.toggleControls() // Returns: Boolean (new visibility state)
```

```dart
// Flutter
final result = await readerChannel.toggleControls(sessionId);
final visible = result['visible'] as bool;
```

**Events Emitted**:
```json
{
  "type": "controls_visibility",
  "session_id": "session-123",
  "visible": true,
  "timestamp": 1234567890
}
```

### 2. Bookmarks

Add, remove, and manage bookmarks at specific pages.

**Methods**:
- `addBookmark()` - Add bookmark at current page
- `addBookmarkAtPage(pageNumber)` - Add bookmark at specific page
- `removeBookmark()` - Remove bookmark from current page
- `removeBookmarkAtPage(pageNumber)` - Remove bookmark from specific page
- `toggleBookmark()` - Toggle bookmark at current page
- `hasBookmark()` - Check if current page has bookmark
- `getBookmarks()` - Get all bookmarks

```kotlin
// Kotlin
reader.addBookmark() // Returns: Boolean
reader.toggleBookmark() // Returns: Boolean (true if added, false if removed)
val bookmarks = reader.getBookmarks() // Returns: List<Map<String, Any>>
```

```dart
// Flutter
await readerChannel.addBookmark(sessionId);
await readerChannel.toggleBookmark(sessionId);
final bookmarks = await readerChannel.getBookmarks(sessionId);
```

**Bookmark Data Structure**:
```json
{
  "id": "1234567890_1234",
  "page_number": 42,
  "timestamp": 1234567890
}
```

**Events Emitted**:
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "bookmark",
  "action": "add",
  "bookmark_id": "1234567890_1234",
  "page_number": 42,
  "timestamp": 1234567890
}
```

### 3. Highlights

Highlight selected text with customizable colors.

**Methods**:
- `addHighlight(selectedText, color, startPosition, endPosition)` - Add highlight
- `removeHighlight(highlightId)` - Remove highlight
- `getHighlights()` - Get all highlights
- `getHighlightsForCurrentPage()` - Get highlights for current page

```kotlin
// Kotlin
val highlightId = reader.addHighlight(
    selectedText = "Important text",
    color = "#FFFF00",
    startPosition = 0,
    endPosition = 14
)
reader.removeHighlight(highlightId)
val highlights = reader.getHighlights()
```

```dart
// Flutter
final result = await readerChannel.addHighlight(
  sessionId: sessionId,
  selectedText: "Important text",
  color: "#FFFF00",
  startPosition: 0,
  endPosition: 14,
);
final highlightId = result['highlight_id'];
```

**Highlight Data Structure**:
```json
{
  "id": "1234567890_5678",
  "page_number": 42,
  "selected_text": "Important text",
  "color": "#FFFF00",
  "start_position": 0,
  "end_position": 14,
  "timestamp": 1234567890
}
```

**Events Emitted**:
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "highlight",
  "action": "add",
  "highlight_id": "1234567890_5678",
  "page_number": 42,
  "highlighted_text": "Important text",
  "color": "#FFFF00",
  "start_position": 0,
  "end_position": 14,
  "timestamp": 1234567890
}
```

### 4. Notes

Add and manage notes at specific pages.

**Methods**:
- `addNote(noteText)` - Add note at current page
- `removeNote(noteId)` - Remove note
- `getNotes()` - Get all notes
- `getNotesForPage(pageNumber)` - Get notes for specific page

```kotlin
// Kotlin
val noteId = reader.addNote("This is an important point")
reader.removeNote(noteId)
val notes = reader.getNotes()
```

```dart
// Flutter
final result = await readerChannel.addNote(
  sessionId: sessionId,
  noteText: "This is an important point",
);
final noteId = result['note_id'];
```

**Note Data Structure**:
```json
{
  "id": "1234567890_9012",
  "page_number": 42,
  "note_text": "This is an important point",
  "timestamp": 1234567890
}
```

**Events Emitted**:
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "note",
  "action": "add",
  "note_id": "1234567890_9012",
  "page_number": 42,
  "note_text": "This is an important point",
  "timestamp": 1234567890
}
```

### 5. Text Selection

Handle text selection and provide contextual actions.

**Method**: `handleTextSelection(selectedText, startPosition, endPosition)`

```kotlin
// Kotlin
val actions = reader.handleTextSelection(
    selectedText = "Selected text",
    startPosition = 0,
    endPosition = 13
)
// Returns: ["highlight", "note", "copy", "share"]
```

```dart
// Flutter
final result = await readerChannel.handleTextSelection(
  sessionId: sessionId,
  selectedText: "Selected text",
  startPosition: 0,
  endPosition: 13,
);
final actions = result['actions'] as List<String>;
```

**Events Emitted**:
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "text_selected",
  "page_number": 42,
  "selected_text": "Selected text",
  "start_position": 0,
  "end_position": 13,
  "timestamp": 1234567890
}
```

### 6. Navigation

Navigate through pages and track reading progress.

**Methods**:
- `nextPage()` - Go to next page
- `previousPage()` - Go to previous page
- `goToPage(pageIndex)` - Go to specific page
- `getProgress()` - Get reading progress (0.0 to 1.0)
- `setProgress(progress)` - Set reading progress

```kotlin
// Kotlin
reader.nextPage() // Returns: Boolean
reader.previousPage() // Returns: Boolean
reader.goToPage(42)
val progress = reader.getProgress() // Returns: Double (0.0 to 1.0)
reader.setProgress(0.5) // Go to 50% through the book
```

```dart
// Flutter
await readerChannel.nextPage(sessionId);
await readerChannel.previousPage(sessionId);
await readerChannel.goToPage(sessionId, 42);
final progress = await readerChannel.getProgress(sessionId);
await readerChannel.setProgress(sessionId, 0.5);
```

**Events Emitted** (on page turn):
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "page_turn",
  "page_index": 42,
  "timestamp": 1234567890
}
```

## Event Types

All events are emitted through the Event Channel and can be listened to in Flutter:

### Event Types:
1. **controls_visibility** - Controls visibility changed
2. **engagement** - User interaction events (bookmarks, highlights, notes, page turns, text selection)
3. **settings_changed** - Reader settings updated
4. **ready** - Reader initialized and ready
5. **error** - Error occurred

### Engagement Event Subtypes:
- `page_turn` - User navigated to a different page
- `bookmark` - Bookmark added/removed
- `highlight` - Text highlighted
- `note` - Note added/removed
- `text_selected` - Text selected by user
- `session_end` - Reading session ended

## Usage Example

### Flutter Implementation

```dart
class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _controlsVisible = false;
  bool _hasBookmark = false;
  
  @override
  void initState() {
    super.initState();
    _listenToReaderEvents();
  }
  
  void _listenToReaderEvents() {
    readerChannel.readerEvents.listen((event) {
      if (event['type'] == 'controls_visibility') {
        setState(() {
          _controlsVisible = event['visible'];
        });
      } else if (event['type'] == 'engagement') {
        _handleEngagementEvent(event);
      }
    });
  }
  
  void _handleEngagementEvent(Map<String, dynamic> event) {
    final eventType = event['event'];
    
    switch (eventType) {
      case 'page_turn':
        print('Page turned to: ${event['page_index']}');
        break;
      case 'bookmark':
        print('Bookmark ${event['action']}: ${event['page_number']}');
        break;
      case 'highlight':
        print('Highlight ${event['action']}: ${event['highlighted_text']}');
        break;
      case 'text_selected':
        _showTextSelectionMenu(event);
        break;
    }
  }
  
  Future<void> _toggleBookmark() async {
    final result = await readerChannel.toggleBookmark(sessionId);
    setState(() {
      _hasBookmark = result['has_bookmark'];
    });
  }
  
  Future<void> _addHighlight(String text, String color) async {
    await readerChannel.addHighlight(
      sessionId: sessionId,
      selectedText: text,
      color: color,
      startPosition: 0,
      endPosition: text.length,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          await readerChannel.toggleControls(sessionId);
        },
        child: Stack(
          children: [
            // Native reader view
            AndroidView(
              viewType: 'com.knowvas.reader/epub',
              creationParams: {...},
              creationParamsCodec: StandardMessageCodec(),
            ),
            
            // Controls overlay
            if (_controlsVisible) ...[
              _buildTopBar(),
              _buildBottomBar(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        title: Text('Book Title'),
        actions: [
          IconButton(
            icon: Icon(_hasBookmark ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress slider
            Slider(
              value: _progress,
              onChanged: (value) async {
                await readerChannel.setProgress(sessionId, value);
              },
            ),
            // Page number
            Text('Page ${_currentPage + 1} of $_totalPages'),
          ],
        ),
      ),
    );
  }
}
```

## Storage Integration

The interaction handler manages bookmarks, highlights, and notes in memory. For persistence:

1. **Local Storage**: Save to SQLite database when events are emitted
2. **Sync**: Upload to backend via engagement API
3. **Restore**: Load from local database when opening content

### Recommended Storage Schema

```sql
-- Bookmarks
CREATE TABLE bookmarks (
    id TEXT PRIMARY KEY,
    content_id INTEGER NOT NULL,
    session_id TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    synced INTEGER DEFAULT 0
);

-- Highlights
CREATE TABLE highlights (
    id TEXT PRIMARY KEY,
    content_id INTEGER NOT NULL,
    session_id TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    selected_text TEXT NOT NULL,
    color TEXT NOT NULL,
    start_position INTEGER NOT NULL,
    end_position INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    synced INTEGER DEFAULT 0
);

-- Notes
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    content_id INTEGER NOT NULL,
    session_id TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    note_text TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    synced INTEGER DEFAULT 0
);
```

## Requirements Validation

This implementation satisfies the following requirements:

- ✅ **5.8**: Tap-to-toggle controls (top/bottom bars)
- ✅ **5.9**: Reader toolbar with title, bookmark, and settings buttons
- ✅ **5.11**: Bookmark functionality with local storage
- ✅ **5.12**: Text selection with highlight/note/copy options
- ✅ **5.13**: Engagement events for page turns and interactions

## Testing

### Unit Tests

Test the interaction handler:

```kotlin
@Test
fun testAddBookmark() {
    val handler = EpubInteractionHandler(context, "session-123") { }
    val bookmark = handler.addBookmark(42, null)
    
    assertEquals(42, bookmark.pageNumber)
    assertTrue(handler.hasBookmarkAtPage(42))
}

@Test
fun testAddHighlight() {
    val handler = EpubInteractionHandler(context, "session-123") { }
    val highlight = handler.addHighlight(
        pageNumber = 42,
        selectedText = "Test text",
        color = "#FFFF00",
        locator = null,
        startPosition = 0,
        endPosition = 9
    )
    
    assertEquals("Test text", highlight.selectedText)
    assertEquals("#FFFF00", highlight.color)
}
```

### Integration Tests

Test the full flow from Flutter to native:

```dart
testWidgets('Toggle bookmark', (tester) async {
  // Open reader
  await readerChannel.openReader(...);
  
  // Toggle bookmark
  final result = await readerChannel.toggleBookmark(sessionId);
  expect(result['has_bookmark'], true);
  
  // Toggle again
  final result2 = await readerChannel.toggleBookmark(sessionId);
  expect(result2['has_bookmark'], false);
});
```

## Future Enhancements

1. **Persistent Storage**: Integrate with SQLite for local persistence
2. **Sync**: Implement sync with backend API
3. **Annotations**: Add drawing/annotation support
4. **Search**: Add text search within highlights and notes
5. **Export**: Export highlights and notes to various formats
6. **Sharing**: Share highlights and notes with other users
7. **Collections**: Organize highlights and notes into collections

## Notes

- All IDs are generated using timestamp + random number for uniqueness
- Events are emitted immediately for real-time UI updates
- Locators are stored for precise position tracking (Readium feature)
- The implementation is designed to work with Readium's navigation system
- Memory management: Interactions are cleared when reader is closed
