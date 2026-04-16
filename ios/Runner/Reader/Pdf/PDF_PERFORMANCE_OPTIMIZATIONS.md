# PDF Performance Optimizations

This document describes the performance optimizations implemented for the iOS PDF reader to ensure large PDFs open within 2-4 seconds and maintain smooth performance during reading.

## Overview

The PDF reader has been optimized with the following key features:

1. **Optimized PDFView Configuration**
2. **Thumbnail Caching**
3. **Progressive Rendering**
4. **Memory Management**
5. **Lazy Loading**

## Implementation Details

### 1. Optimized PDFView Configuration

The PDFView is configured with optimal settings for performance:

```swift
// High-quality interpolation for smooth rendering
pdfView.interpolationQuality = .high

// Page breaks for better memory management
pdfView.displaysPageBreaks = true
pdfView.pageBreakMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

// Conditional shadow rendering based on device capabilities
if #available(iOS 14.0, *) {
    pdfView.pageShadowsEnabled = true  // Newer devices
} else {
    pdfView.pageShadowsEnabled = false // Older devices for better performance
}
```

### 2. Thumbnail Cache

A dedicated `PDFThumbnailCache` class manages thumbnail generation and caching:

**Features:**
- Thread-safe concurrent access using dispatch queues
- LRU-style cache with configurable maximum size (default: 50 thumbnails)
- Automatic cleanup of distant pages
- Memory-efficient thumbnail generation

**Usage:**
```swift
// Get thumbnail (from cache or generate)
let thumbnail = pdfReader.getThumbnail(forPage: pageIndex, size: CGSize(width: 200, height: 300))

// Thumbnails are automatically cached and cleaned up
```

**Cache Management:**
- Thumbnails for pages far from the current position are automatically removed
- Cache size is limited to prevent excessive memory usage
- Oldest thumbnails are removed when cache is full

### 3. Progressive Rendering

Progressive rendering ensures fast initial load times:

**Initial Load:**
- First 5 pages are preloaded immediately after document opens
- Thumbnails are generated in the background
- User can start reading while remaining pages load

**Dynamic Preloading:**
- Pages within ±2 positions of current page are preloaded
- Preloading happens on a background queue
- Distant pages are automatically unloaded to save memory

**Configuration:**
```swift
private let preloadRange = 2 // Preload 2 pages ahead and behind
private var isProgressiveRenderingEnabled = true
```

### 4. Memory Management

Comprehensive memory monitoring and management:

**Memory Monitoring:**
- Continuous monitoring of memory usage via `MemoryManager`
- Three pressure levels: normal, moderate, critical
- Automatic callbacks when memory pressure increases

**Memory Pressure Handling:**

**Moderate Pressure:**
- Clean up pages far from current position
- Remove distant thumbnails from cache

**Critical Pressure:**
- Clear all thumbnail caches
- Remove all preloaded pages
- Clear PDFView selection

**System Memory Warnings:**
- Registered observer for system memory warnings
- Immediate cache cleanup on warning
- Memory status logging for debugging

### 5. Lazy Loading

Efficient page loading strategy:

**Document Loading:**
- PDF document is loaded on a background queue
- Only metadata is loaded initially
- Pages are rendered on-demand

**Page Rendering:**
- Pages are rendered only when needed
- Background queue handles rendering to avoid blocking UI
- Rendered pages are cached by PDFKit

## Performance Metrics

### Target Performance

- **Large PDFs (1000+ pages):** Open within 2-4 seconds
- **Memory Usage:** Stay below 80% threshold under normal conditions
- **Navigation:** Smooth 60fps page transitions
- **Thumbnail Generation:** < 100ms per thumbnail

### Monitoring

Memory usage is continuously monitored and logged:

```swift
MemoryManager.shared.logMemoryStatus()
// Output:
// MemoryManager Status:
// - Used: 245.3 MB
// - Total: 2.0 GB
// - Usage: 12.27%
```

## Configuration Options

### Adjustable Parameters

```swift
// Thumbnail cache size
private let maxCacheSize = 50

// Preload range (pages ahead/behind)
private let preloadRange = 2

// Memory thresholds
private let memoryThreshold: Double = 0.8      // 80%
private let criticalMemoryThreshold: Double = 0.9  // 90%

// Progressive rendering
private var isProgressiveRenderingEnabled = true
```

### Disabling Features

If needed, features can be disabled:

```swift
// Disable progressive rendering
isProgressiveRenderingEnabled = false

// Disable memory monitoring
MemoryManager.shared.stopMonitoring()
```

## Testing

Performance tests are included in `PdfPerformanceTests.swift`:

- PDF open performance
- Thumbnail caching functionality
- Memory pressure handling
- Memory tracking accuracy
- Cache cleanup operations

Run tests with:
```bash
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Best Practices

### For Large PDFs (1000+ pages)

1. **Enable progressive rendering** (enabled by default)
2. **Monitor memory usage** during development
3. **Test on older devices** to ensure performance
4. **Use appropriate thumbnail sizes** (200x300 recommended)

### For Memory-Constrained Devices

1. **Reduce preload range** to 1 page
2. **Decrease thumbnail cache size** to 25
3. **Disable page shadows** on older devices
4. **Monitor memory pressure levels**

### For Optimal User Experience

1. **Keep progressive rendering enabled**
2. **Use default preload range** (2 pages)
3. **Enable memory monitoring**
4. **Log performance metrics** in development

## Troubleshooting

### PDF Opens Slowly

- Check file size and page count
- Verify progressive rendering is enabled
- Check memory pressure levels
- Review device capabilities

### High Memory Usage

- Reduce thumbnail cache size
- Decrease preload range
- Check for memory leaks
- Monitor memory pressure callbacks

### Choppy Navigation

- Increase preload range
- Check memory pressure
- Verify background rendering is working
- Test on target device

## Future Improvements

Potential enhancements for future versions:

1. **Adaptive preloading** based on reading speed
2. **Disk-based thumbnail cache** for very large PDFs
3. **Predictive preloading** based on user behavior
4. **Quality-based rendering** (low-res preview, high-res final)
5. **Network-aware caching** for remote PDFs

## References

- [PDFKit Documentation](https://developer.apple.com/documentation/pdfkit)
- [Memory Management Best Practices](https://developer.apple.com/documentation/xcode/improving_your_app_s_performance)
- Requirements: 6.10, 14.2, 14.6
