# PDF Reader Module

## Overview
Native Android PDF reader implementation using Android's PdfRenderer API. Provides high-performance PDF rendering with page navigation, swipe gestures, and zoom support.

## Architecture

```
PdfReader.kt          - Main reader class, handles PDF lifecycle and events
PdfPageView.kt        - Custom view for rendering and gesture detection
```

## Usage

### Opening a PDF

```kotlin
val pdfReader = PdfReader(context, eventSink, sessionId)

pdfReader.open(fileUrl, token) { success, error ->
    if (success) {
        // PDF opened successfully
        // Reader ready event will be emitted automatically
    } else {
        // Handle error
        Log.e("PDF", "Failed to open: $error")
    }
}
```

### Navigation

```kotlin
// Next page
val success = pdfReader.nextPage()

// Previous page
val success = pdfReader.previousPage()

// Go to specific page
pdfReader.goToPage(pageIndex)

// Get current page
val currentPage = pdfReader.getCurrentPage()

// Get total pages
val totalPages = pdfReader.getTotalPages()

// Get/Set progress
val progress = pdfReader.getProgress() // 0.0 to 1.0
pdfReader.setProgress(0.5) // Jump to 50%
```

### Rendering

```kotlin
// Render current page
val bitmap = pdfReader.renderCurrentPage()

// Render specific page
val bitmap = pdfReader.renderPage(pageIndex)

// Pre-load adjacent pages for smooth navigation
pdfReader.preloadAdjacentPages()

// Clear cache to free memory
pdfReader.clearCache()
```

### Using PdfPageView

```kotlin
val pdfPageView = PdfPageView(context)

// Set callbacks
pdfPageView.onSwipeLeft = {
    pdfReader.nextPage()
    updateView()
}

pdfPageView.onSwipeRight = {
    pdfReader.previousPage()
    updateView()
}

pdfPageView.onTap = {
    toggleControls()
}

pdfPageView.onDoubleTap = {
    pdfPageView.toggleZoom()
}

// Display a page
val bitmap = pdfReader.renderCurrentPage()
pdfPageView.setBitmap(bitmap)
```

### Closing

```kotlin
pdfReader.close()
// Automatically emits session_end event
// Cleans up all resources
```

## Events

### Reader Ready Event
Emitted when PDF is successfully opened.

```json
{
  "type": "ready",
  "session_id": "unique-session-id",
  "total_pages": 150,
  "timestamp": 1234567890
}
```

### Page Turn Event
Emitted when user navigates to a different page.

```json
{
  "type": "engagement",
  "session_id": "unique-session-id",
  "event": "page_turn",
  "page_index": 5,
  "total_pages": 150,
  "progress": 0.04,
  "timestamp": 1234567890
}
```

### Session End Event
Emitted when reader is closed.

```json
{
  "type": "engagement",
  "session_id": "unique-session-id",
  "event": "session_end",
  "final_page_index": 42,
  "session_duration": 300000,
  "timestamp": 1234567890
}
```

## Performance

### Opening Performance
- **Target**: 2-4 seconds for first page render
- **Optimization**: Lazy loading, no full document parse
- **Large Files**: Pre-checks memory before opening 50+ MB PDFs

### Memory Management
- **Page Cache**: Up to 5 pages cached
- **Automatic Cleanup**: Old pages recycled when cache is full
- **Memory Monitoring**: Integrated with MemoryManager utility

### Navigation Performance
- **Pre-loading**: Adjacent pages pre-loaded in background
- **Cache Hits**: Instant display for cached pages
- **Gesture Response**: Native gesture detection for immediate feedback

## Gesture Support

### Swipe Gestures
- **Swipe Left**: Next page (when not zoomed)
- **Swipe Right**: Previous page (when not zoomed)
- **Threshold**: 100 pixels minimum distance
- **Velocity**: 100 pixels/second minimum

### Tap Gestures
- **Single Tap**: Toggle controls visibility
- **Double Tap**: Toggle zoom (fit-to-width ↔ zoomed)

### Zoom Gestures (Task 35 - Complete)
- **Pinch-to-Zoom**: Zoom in/out with two fingers (1.0x to 4.0x range)
  - Minimum zoom: 100% (fit-to-screen)
  - Maximum zoom: 400% (4x magnification)
  - Zoom centers on pinch focal point
  - Smooth, responsive scaling
- **Pan**: Move around when zoomed (only active when zoom > 100%)
  - Drag to pan in any direction
  - Automatic boundary constraints
  - Content stays within view bounds
  - Smooth scrolling with gesture velocity
- **Double-Tap**: Toggle between zoom levels
  - First tap: Zoom to 150% (fit-to-width)
  - Second tap: Reset to 100% (fit-to-screen)
  - Zoom centers on tap location
  - Quick access to common zoom levels

## Error Handling

### Common Errors
- **File Not Found**: Check file path and permissions
- **Insufficient Memory**: Large PDFs may require memory cleanup
- **Invalid Format**: File is not a valid PDF
- **Renderer Error**: PdfRenderer initialization failed

### Error Callback
```kotlin
pdfReader.open(fileUrl, token) { success, error ->
    if (!success) {
        when {
            error?.contains("not found") == true -> {
                // Handle file not found
            }
            error?.contains("memory") == true -> {
                // Handle memory issue
            }
            else -> {
                // Handle other errors
            }
        }
    }
}
```

## Integration with Flutter

### Platform Channel
The PDF reader integrates with Flutter through the ReaderManager:

```dart
// Flutter side
await readerChannel.openReader(OpenReaderRequest(
  contentId: contentId,
  type: 'pdf',
  fileUrl: localFilePath,
  token: authToken,
  sessionId: sessionId,
));

// Listen for events
readerChannel.readerEvents.listen((event) {
  if (event is ReaderReadyEvent) {
    print('PDF ready: ${event.totalPages} pages');
  } else if (event is EngagementEvent) {
    if (event.eventType == 'page_turn') {
      print('Page ${event.pageIndex} of ${event.payload['total_pages']}');
    }
  }
});
```

## Best Practices

### Memory Management
1. Always call `close()` when done
2. Use `clearCache()` if memory is low
3. Pre-load adjacent pages for smooth navigation
4. Monitor memory for large PDFs (50+ MB)

### Performance
1. Render pages on background thread
2. Cache frequently accessed pages
3. Use pre-loading for anticipated navigation
4. Recycle bitmaps when no longer needed

### User Experience
1. Show loading indicator during open
2. Display progress (page X of Y)
3. Provide visual feedback for gestures
4. Handle errors gracefully with user-friendly messages

## Requirements Mapping

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| 6.1 - Open PDF using PdfRenderer | `PdfReader.open()` | ✅ Complete |
| 6.2 - Emit onReaderReady | `emitReaderReadyEvent()` | ✅ Complete |
| 6.3 - Page navigation with swipe | `PdfPageView` gestures | ✅ Complete |
| 6.3 - Emit page_turn events | `emitPageTurnEvent()` | ✅ Complete |
| 6.4 - Pinch-to-zoom (100%-400%) | `PdfPageView.ScaleListener` | ✅ Complete |
| 6.5 - Pan gestures for zoomed pages | `PdfPageView.GestureListener` | ✅ Complete |
| 6.6 - Double-tap zoom toggle | `PdfPageView.toggleZoom()` | ✅ Complete |

## Next Steps

### Task 36: Reader Controls
- Settings panel integration
- Theme support
- Bookmarks
- Text selection

### Task 36: Reader Controls
- Settings panel
- Theme support
- Bookmarks
- Text selection

### Task 37: Performance Optimization
- Tile-based rendering
- Thumbnail cache
- Progressive rendering
- Memory optimization

## Troubleshooting

### PDF Won't Open
1. Check file exists at specified path
2. Verify file is a valid PDF
3. Check available memory
4. Review logs for specific error

### Slow Performance
1. Check PDF file size
2. Monitor memory usage
3. Reduce cache size if needed
4. Consider pre-loading optimization

### Gestures Not Working
1. Verify PdfPageView is properly initialized
2. Check callbacks are set
3. Ensure view is receiving touch events
4. Test with different swipe velocities

## API Reference

### PdfReader Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `open()` | fileUrl, token, callback | void | Open PDF file |
| `close()` | - | void | Close reader and cleanup |
| `nextPage()` | - | Boolean | Navigate to next page |
| `previousPage()` | - | Boolean | Navigate to previous page |
| `goToPage()` | pageIndex | void | Jump to specific page |
| `getCurrentPage()` | - | Int | Get current page index |
| `getTotalPages()` | - | Int | Get total page count |
| `getProgress()` | - | Double | Get reading progress (0-1) |
| `setProgress()` | progress | void | Set reading position |
| `renderPage()` | pageIndex | Bitmap? | Render specific page |
| `renderCurrentPage()` | - | Bitmap? | Render current page |
| `preloadAdjacentPages()` | - | void | Pre-load next/prev pages |
| `clearCache()` | - | void | Clear page cache |

### PdfPageView Properties

| Property | Type | Description |
|----------|------|-------------|
| `onSwipeLeft` | () -> Unit | Callback for left swipe |
| `onSwipeRight` | () -> Unit | Callback for right swipe |
| `onTap` | () -> Unit | Callback for single tap |
| `onDoubleTap` | () -> Unit | Callback for double tap |
| `onZoomChanged` | (Float) -> Unit | Callback when zoom level changes |

### PdfPageView Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setPageBitmap()` | bitmap | void | Set page to display |
| `getZoom()` | - | Float | Get current zoom level (1.0-4.0) |
| `setZoom()` | zoom, focusX, focusY | void | Set zoom level with focal point |
| `toggleZoom()` | focusX, focusY | void | Toggle between fit and zoomed |
| `resetTransform()` | - | void | Reset zoom and pan to default |

### PdfReader Zoom Methods (Task 35)

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setZoom()` | zoomLevel | Boolean | Set zoom level (1.0-4.0) |
| `getZoom()` | - | Float | Get current zoom level |
| `zoomIn()` | factor | Float | Zoom in by factor (default 1.2) |
| `zoomOut()` | factor | Float | Zoom out by factor (default 1.2) |
| `toggleZoom()` | - | Float | Toggle zoom state |
| `resetZoom()` | - | void | Reset to 100% zoom |
| `isZoomed()` | - | Boolean | Check if currently zoomed |

## License
Part of the Knowvas Flutter Client application.
