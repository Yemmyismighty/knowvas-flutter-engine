# PageCurlView Integration with PdfReader

## Overview

This document describes the integration between `PageCurlView` (OpenGL-based 3D page curl animation) and `PdfReader` (PDF rendering engine).

**Task 14: Integrate with PdfReader**

## Requirements Addressed

### 9.1: Bitmap Reception from PDF Reader
- `PageCurlView.connectToPdfReader(reader)` establishes the connection
- `loadPagesFromReader()` loads current, next, and previous page bitmaps
- Bitmaps are automatically loaded when the view is connected

### 9.2: Page Change Callbacks
- `onPageTurnComplete` callback is invoked when page turn animation completes
- Callback triggers `PdfReader.nextPage()` or `PdfReader.previousPage()`
- PdfReader updates its internal page index
- Page turn events are emitted to Flutter for analytics

### 9.3: Texture Updates on Page Change
- After page change, `loadPagesFromReader()` is called automatically
- Current page texture is updated with new page bitmap
- Next/previous page textures are preloaded for smooth transitions
- Old textures are properly cleaned up to prevent memory leaks

### 9.4: Non-Interference with PDF Features
- `setCurlEnabled(enabled)` allows toggling curl on/off
- When curl is disabled, touch events pass through to underlying views
- Touch events near page center are ignored, allowing zoom/pan to work
- `isCurlActive()` allows other components to check curl state
- Curl only activates on edge touches (20% threshold)

### 9.5: Proper Resource Cleanup
- `cleanup()` method releases all OpenGL resources
- Disconnects from PdfReader to prevent memory leaks
- Recycles bitmap resources
- Called automatically in `PdfReaderFragment.onDestroyView()`

## Architecture

```
PdfReaderFragment
├── PdfReader (PDF rendering engine)
│   ├── renderCurrentPage() → Bitmap
│   ├── renderPage(index) → Bitmap
│   ├── nextPage() / previousPage()
│   └── Page cache management
│
└── PageCurlView (OpenGL curl animation)
    ├── connectToPdfReader(reader)
    ├── loadPagesFromReader()
    ├── onPageTurnComplete callback
    └── CurlRenderer (OpenGL rendering)
```

## Usage

### Basic Setup

```kotlin
// In PdfReaderFragment
val pageCurlView = PageCurlView(context).apply {
    // Connect to PdfReader
    connectToPdfReader(pdfReader)
    
    // Set up callbacks
    onPageTurnComplete = { direction ->
        // Page turn completed
        updatePageInfo()
    }
    
    onCurlStarted = {
        // Curl interaction started
    }
    
    onCurlEnded = {
        // Curl interaction ended
    }
}
```

### Switching Between Simple and Curl Views

```kotlin
// Switch to curl view
fun switchToCurlView() {
    pageCurlView?.apply {
        visibility = View.VISIBLE
        setCurlEnabled(true)
        connectToPdfReader(pdfReader)
    }
    pdfPageView.visibility = View.GONE
}

// Switch to simple view
fun switchToSimpleView() {
    pageCurlView?.apply {
        visibility = View.GONE
        setCurlEnabled(false)
    }
    pdfPageView.visibility = View.VISIBLE
}
```

### Cleanup

```kotlin
override fun onDestroyView() {
    super.onDestroyView()
    pageCurlView?.cleanup()
}
```

## Data Flow

### Page Turn Flow

1. User drags from page edge
2. `TouchHandler` detects edge touch and calculates curl parameters
3. `PageCurlView` updates curl in real-time during drag
4. User releases touch beyond threshold (30% of page width)
5. `AnimationController` starts page turn animation
6. Animation completes
7. `onPageTurnComplete` callback is invoked
8. `PdfReader.nextPage()` or `previousPage()` is called
9. `loadPagesFromReader()` loads new page bitmaps
10. Textures are updated with new bitmaps
11. UI is updated with new page number

### Bitmap Loading Flow

1. `connectToPdfReader(reader)` is called
2. `loadPagesFromReader()` is invoked
3. Current page: `reader.renderCurrentPage()`
4. Next page: `reader.renderPage(currentIndex + 1)`
5. Previous page: `reader.renderPage(currentIndex - 1)`
6. Bitmaps are passed to `CurlRenderer`
7. `TextureManager` converts bitmaps to OpenGL textures
8. Textures are bound to mesh for rendering

## Non-Interference with Zoom/Pan

### Edge Touch Detection

- Curl only activates on touches within 20% of page edges
- Center touches (80% of page) are ignored by curl
- This allows zoom/pan gestures to work normally

### Curl Enable/Disable

- `setCurlEnabled(false)` disables curl completely
- All touch events pass through to underlying views
- Zoom and pan work as if curl view doesn't exist

### Curl State Checking

- `isCurlActive()` returns true if curl is in progress
- Other components can check this before handling touches
- Prevents conflicts between curl and zoom/pan

## Memory Management

### Bitmap Lifecycle

1. Bitmaps are rendered by PdfReader
2. Bitmaps are cached in PdfReader's page cache
3. Bitmaps are passed to PageCurlView (not copied)
4. TextureManager uploads bitmaps to GPU
5. Original bitmaps remain in PdfReader cache
6. When page changes, old textures are deleted
7. On cleanup, all textures are deleted
8. Bitmaps are recycled when no longer needed

### Resource Cleanup

- OpenGL textures are deleted when no longer needed
- Bitmaps are recycled in `cleanup()`
- PdfReader connection is cleared
- All callbacks are cleared to prevent leaks

## Performance Considerations

### Texture Loading

- Textures are loaded on GL thread to avoid blocking UI
- Bitmap-to-texture conversion is fast (< 50ms for typical pages)
- Textures are reused when possible

### Page Preloading

- Next and previous pages are preloaded for smooth transitions
- Preloading happens in background
- Memory usage is managed by PdfReader's cache

### Frame Rate

- Target: 60 FPS on high-end devices, 30 FPS on mid-range
- Curl updates are optimized for real-time performance
- Mesh updates are minimized during animation

## Testing

### Unit Tests

See `PageCurlIntegrationTest.kt` for integration tests covering:
- Connection to PdfReader
- Page navigation
- Bitmap loading
- Resource cleanup
- Event emission

### Manual Testing

1. Load a PDF document
2. Switch to "Page Curl (3D)" mode in settings
3. Drag from right edge to turn page forward
4. Drag from left edge to turn page backward
5. Tap center to verify zoom/pan still works
6. Switch back to simple view
7. Verify no memory leaks or crashes

## Troubleshooting

### Curl Not Working

- Check that `setCurlEnabled(true)` is called
- Verify `connectToPdfReader()` was called
- Check that touch is near page edge (within 20%)
- Verify OpenGL context initialized successfully

### Textures Not Updating

- Check that `onPageTurnComplete` callback is set
- Verify `loadPagesFromReader()` is called after page change
- Check PdfReader has rendered the new page
- Verify textures are not null

### Memory Leaks

- Ensure `cleanup()` is called in `onDestroyView()`
- Verify `disconnectFromPdfReader()` is called
- Check that bitmaps are recycled
- Use Android Profiler to monitor memory

### Performance Issues

- Reduce mesh resolution if frame rate drops
- Disable visual effects if needed
- Check GPU memory usage
- Verify page cache is not too large

## Future Enhancements

1. **Progressive Texture Loading**: Load low-res texture first, then high-res
2. **Tile-Based Rendering**: For very large pages, render in tiles
3. **Curl Customization**: Allow different curl styles and speeds
4. **Haptic Feedback**: Vibrate when page turn threshold is reached
5. **Sound Effects**: Add subtle paper sound during curl

## References

- OpenGL Page Curl Design: `.kiro/specs/opengl-page-curl/design.md`
- OpenGL Page Curl Requirements: `.kiro/specs/opengl-page-curl/requirements.md`
- PdfReader Implementation: `PdfReader.kt`
- PageCurlView Implementation: `PageCurlView.kt`
