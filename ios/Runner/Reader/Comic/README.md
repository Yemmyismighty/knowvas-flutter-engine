# iOS Comic Reader Implementation

## Overview

This directory contains the iOS implementation of the comic reader for the Knowvas Flutter client. The comic reader supports CBZ (ZIP-based) comic archives with image sequences, providing a native reading experience with swipe navigation, zoom capabilities, and support for both single and double-page layouts.

## Requirements Implemented

### Task 50: Implement iOS Comic Reader

**Requirements Covered:**
- **7.1**: Load image sequences from comic archives (CBZ/CBR)
- **7.2**: Display first page and emit onReaderReady with total page count
- **7.3**: Support swipe gestures for navigation using UIPageViewController
- **7.4**: Support single and double-page layout modes
- **7.8**: Support reading direction (LTR/RTL)
- **7.10**: Optimized image loading with lazy loading and caching
- **14.5**: Image downsampling for thumbnails
- **14.6**: Memory monitoring and cleanup

## Architecture

### Core Components

#### 1. ComicReader.swift
The main comic reader class that manages:
- Opening and closing comic archives
- Image extraction and caching
- Page navigation
- Reader preferences (layout, reading direction, guided view)
- Event emission to Flutter
- Memory management

**Key Features:**
- Supports CBZ (ZIP) format with ZIPFoundation
- Lazy loading of images with intelligent caching
- Pre-loading of adjacent pages for smooth navigation
- Memory pressure handling with automatic cache cleanup
- Integration with MemoryManager for monitoring

#### 2. ComicPageViewController.swift
UIPageViewController-based view controller for displaying comic pages:
- Implements swipe gesture navigation
- Supports single and double-page layouts
- Handles page transitions with proper direction
- Manages page view controller data source and delegate

**ComicPageContentViewController:**
- Displays individual pages or double-page spreads
- Implements zoom and pan with UIScrollView
- Double-tap gesture for zoom toggle
- Proper image centering and scaling

#### 3. Image Extraction

**ImageExtractor Protocol:**
- Defines interface for extracting images from archives
- Supports multiple archive formats

**ZipImageExtractor:**
- Extracts images from CBZ/ZIP archives using ZIPFoundation
- Filters and sorts image files alphabetically
- Efficient data extraction with streaming

**RarImageExtractor:**
- Placeholder for CBR/RAR support
- Can be extended with a RAR library (e.g., UnrarKit)

#### 4. ComicImageCache
Intelligent image caching system:
- LRU-based cache with configurable size
- Lazy loading on demand
- Pre-loading of adjacent pages (configurable range)
- Memory-aware cleanup
- Thumbnail generation with downsampling
- Thread-safe operations with GCD

### Data Flow

```
Flutter Layer
    ↓
ReaderManager.openComicReader()
    ↓
ComicReader.open()
    ↓
ImageExtractor.initialize() → Extract image list
    ↓
ComicImageCache.preloadPages() → Load first few pages
    ↓
Emit onReaderReady event
    ↓
User swipes → ComicPageViewController handles gesture
    ↓
ComicReader.goToPage() → Update current page
    ↓
ComicImageCache.getPage() → Return cached or load image
    ↓
ComicImageCache.preloadPages() → Pre-load adjacent pages
    ↓
Emit page_turn event
```

## Usage

### Opening a Comic

```swift
let comicReader = ComicReader(eventSink: eventSink, sessionId: sessionId)

comicReader.open(fileUrl: "/path/to/comic.cbz") { result in
    switch result {
    case .success:
        print("Comic opened successfully")
        // Create and present page view controller
        let pageVC = comicReader.createPageViewController()
        
    case .failure(let error):
        print("Failed to open comic: \(error)")
    }
}
```

### Setting Preferences

```swift
let preferences: [String: Any] = [
    "layout": "double",              // "single" or "double"
    "reading_direction": "rtl",      // "ltr" or "rtl"
    "guided_view": false             // true or false
]

comicReader.setPreferences(preferences)
```

### Navigation

```swift
// Navigate to specific page
comicReader.goToPage(10)

// Next page
comicReader.nextPage()

// Previous page
comicReader.previousPage()

// Get current page images
let images = comicReader.getCurrentPageImages()
```

### Closing the Reader

```swift
comicReader.close()
```

## Features

### 1. Image Extraction
- **CBZ Support**: Full support for CBZ (ZIP-based) comic archives
- **Image Filtering**: Automatically filters and sorts image files
- **Supported Formats**: JPG, JPEG, PNG, GIF, BMP, WEBP

### 2. Page Layouts
- **Single Page**: Display one page at a time
- **Double Page**: Display two pages side-by-side (spread view)
- **Reading Direction**: Support for LTR and RTL reading directions

### 3. Navigation
- **Swipe Gestures**: Natural swipe navigation using UIPageViewController
- **Page Transitions**: Smooth animated transitions between pages
- **Direct Navigation**: Jump to any page by index

### 4. Zoom and Pan
- **Pinch to Zoom**: Zoom from 100% to 400%
- **Double-tap Toggle**: Quick zoom in/out
- **Pan Support**: Navigate zoomed images with pan gestures
- **Smooth Animations**: Fluid zoom and pan animations

### 5. Performance Optimization
- **Lazy Loading**: Images loaded on demand
- **Pre-loading**: Adjacent pages pre-loaded for smooth navigation
- **Image Caching**: LRU cache with configurable size
- **Memory Management**: Automatic cleanup under memory pressure
- **Thumbnail Generation**: Downsampled thumbnails for previews

### 6. Memory Management
- **Memory Monitoring**: Integration with MemoryManager
- **Pressure Handling**: Automatic cache cleanup on memory warnings
- **Configurable Cache**: Adjustable cache size and pre-load range
- **Statistics**: Cache statistics for monitoring

## Event Emission

### Reader Ready Event
```json
{
  "type": "ready",
  "session_id": "session-123",
  "total_pages": 50,
  "timestamp": 1234567890000
}
```

### Page Turn Event
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "page_turn",
  "page_index": 10,
  "previous_page": 9,
  "timestamp": 1234567890000
}
```

### Session End Event
```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "session_end",
  "page_index": 25,
  "timestamp": 1234567890000
}
```

### Error Event
```json
{
  "type": "error",
  "session_id": "session-123",
  "code": "COMIC_OPEN_FAILED",
  "message": "Failed to open comic archive",
  "timestamp": 1234567890000
}
```

## Dependencies

### Required
- **ZIPFoundation**: For CBZ/ZIP archive extraction
  - Add to Podfile: `pod 'ZIPFoundation', '~> 0.9'`

### Optional
- **UnrarKit**: For CBR/RAR support (not yet implemented)
  - Can be added for RAR archive support

## Configuration

### Cache Settings
```swift
// Adjust cache size (default: 10 pages)
let cache = ComicImageCache(extractor: extractor, maxCacheSize: 15)

// Adjust pre-load range (default: 3 pages)
cache.preloadPages(around: currentPage, range: 5)
```

### Memory Management
```swift
// Configure memory thresholds in MemoryManager
// Default: 80% moderate, 90% critical
```

## Testing

### Manual Testing
1. Open a CBZ file with various page counts
2. Test swipe navigation in both directions
3. Verify single and double-page layouts
4. Test LTR and RTL reading directions
5. Test zoom and pan functionality
6. Monitor memory usage during long reading sessions
7. Test memory pressure handling

### Test Cases
- Open valid CBZ file → Success
- Open invalid file → Error event
- Navigate through all pages → Correct page turn events
- Switch layouts → Proper display
- Memory pressure → Cache cleanup
- Close reader → Proper cleanup

## Known Limitations

1. **CBR Support**: RAR format not yet implemented (requires RAR library)
2. **Guided View**: Panel-by-panel navigation not yet implemented
3. **Bookmarks**: Bookmark functionality to be added in future tasks
4. **Text Selection**: Not applicable for image-based comics

## Future Enhancements

1. **CBR Support**: Integrate UnrarKit for RAR archive support
2. **Guided View**: Implement panel-by-panel navigation
3. **Bookmarks**: Add bookmark support for comic pages
4. **Page Thumbnails**: Generate and cache page thumbnails for navigation
5. **Preload Optimization**: Adaptive pre-loading based on reading speed
6. **Image Optimization**: Further optimize image loading and rendering

## Performance Metrics

### Target Performance
- **Open Time**: < 2 seconds for archives with 100+ pages
- **Page Turn**: < 100ms for cached pages
- **Memory Usage**: < 200MB for typical comics
- **Cache Hit Rate**: > 90% for sequential reading

### Optimization Strategies
1. Pre-load adjacent pages during idle time
2. Downsample images for thumbnails
3. Clear distant pages from cache
4. Monitor memory pressure and adjust cache size
5. Use efficient image formats (JPEG for photos, PNG for line art)

## Integration with Flutter

The comic reader integrates with Flutter through the ReaderManager:

```swift
// In ReaderManager.swift
private func openComicReader(
    contentId: Int,
    fileUrl: String,
    token: String?,
    sessionId: String,
    eventSink: FlutterEventSink?,
    completion: @escaping (Any) -> Void
) {
    let reader = ComicReader(eventSink: eventSink, sessionId: sessionId)
    activeReaders[sessionId] = reader
    
    reader.open(fileUrl: fileUrl) { result in
        switch result {
        case .success:
            completion(self.createSuccessResponse())
        case .failure(let error):
            completion(self.createErrorResponse(
                code: "COMIC_OPEN_FAILED",
                message: error.localizedDescription
            ))
        }
    }
}
```

## Troubleshooting

### Issue: Images not loading
- Check file path is correct
- Verify archive is valid CBZ/ZIP
- Check image file extensions are supported
- Review console logs for extraction errors

### Issue: Memory warnings
- Reduce cache size
- Decrease pre-load range
- Check for memory leaks
- Monitor MemoryManager logs

### Issue: Slow page turns
- Increase pre-load range
- Increase cache size
- Check image sizes (consider downsampling)
- Profile with Instruments

## References

- [ZIPFoundation Documentation](https://github.com/weichsel/ZIPFoundation)
- [UIPageViewController Documentation](https://developer.apple.com/documentation/uikit/uipageviewcontroller)
- [UIScrollView Zoom Documentation](https://developer.apple.com/documentation/uikit/uiscrollview)
- [Memory Management Best Practices](https://developer.apple.com/documentation/performance/memory)
