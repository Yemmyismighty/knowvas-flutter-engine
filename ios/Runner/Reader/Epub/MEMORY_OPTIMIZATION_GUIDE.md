# iOS EPUB Memory Optimization - Developer Guide

## Quick Start

### Basic Usage

```swift
// 1. Create reader instance (memory monitoring starts automatically)
let reader = EpubReader(eventSink: eventSink, sessionId: sessionId)

// 2. Open EPUB (lazy loading - fast!)
reader.open(fileUrl: epubPath) { result in
    // Ready in < 2-4 seconds
}

// 3. Navigate (automatic loading & preloading)
reader.goToPage(10)

// 4. Close (automatic cleanup)
reader.close()
```

## Key Components

### 1. MemoryManager (Singleton)

Monitors system memory and triggers cleanup when needed.

```swift
let memoryManager = MemoryManager.shared

// Check current memory status
let isHigh = memoryManager.isMemoryPressureHigh()
let level = memoryManager.getCurrentMemoryPressureLevel()

// Register for memory pressure events
memoryManager.registerMemoryPressureCallback { level in
    switch level {
    case .normal:
        // All good
    case .moderate:
        // Reduce memory usage
    case .critical:
        // Aggressive cleanup
    }
}

// Manual monitoring control (usually automatic)
memoryManager.startMonitoring(interval: 2.0)
memoryManager.stopMonitoring()
```

### 2. EpubChapterCache

Manages chapter caching with LRU eviction.

```swift
let cache = EpubChapterCache(maxCachedChapters: 5)

// Cache a chapter
cache.cacheChapter(index: 0, content: htmlContent)

// Retrieve cached chapter
if let content = cache.getChapter(index: 0) {
    // Use content
}

// Check if cached
if cache.isCached(index: 0) {
    // Already loaded
}

// Manual cleanup (usually automatic)
cache.unloadOffScreenChapters(keepCount: 2)
cache.clearAll()

// Get statistics
let stats = cache.getCacheStats()
print("Cached: \(stats.count) chapters, \(stats.totalSize) bytes")
```

### 3. EpubReader

Main reader with integrated memory optimization.

```swift
let reader = EpubReader(eventSink: eventSink, sessionId: sessionId)

// Open with lazy loading
reader.open(fileUrl: path) { result in
    // First chapter loaded, others lazy-loaded
}

// Navigate (loads chapter if needed)
reader.goToPage(5)

// Get current chapter content
if let content = reader.getCurrentChapterContent() {
    // Display content
}

// Get specific chapter (loads if needed)
if let content = reader.getChapterContent(index: 10) {
    // Display content
}
```

## Configuration

### Adjust Cache Size

```swift
// Default: 5 chapters
let cache = EpubChapterCache(maxCachedChapters: 3)  // Smaller cache
let cache = EpubChapterCache(maxCachedChapters: 10) // Larger cache
```

### Adjust Monitoring Interval

```swift
// Default: 2 seconds
memoryManager.startMonitoring(interval: 1.0)  // More frequent
memoryManager.startMonitoring(interval: 5.0)  // Less frequent
```

### Memory Thresholds

Edit `MemoryManager.swift`:
```swift
private let memoryThreshold: Double = 0.8        // 80% - moderate
private let criticalMemoryThreshold: Double = 0.9 // 90% - critical
```

## Memory Pressure Handling

### Automatic Response

The system automatically responds to memory pressure:

**Moderate Pressure (80% memory):**
- Unload 50% of cached chapters
- Keep most recent chapters
- Continue preloading

**Critical Pressure (90% memory):**
- Unload all but current chapter
- Clear WebView cache
- Pause preloading

### Manual Intervention

```swift
// Force cleanup
cache.unloadOffScreenChapters(keepCount: 1)

// Clear WebView cache
reader.clearWebViewCache()

// Clear all caches
cache.clearAll()
memoryManager.clearCaches()
```

## Performance Optimization

### Best Practices

1. **Use Default Settings**: Optimized for most devices
2. **Monitor Logs**: Check console for memory warnings
3. **Test on Low-Memory Devices**: iPhone SE, older iPads
4. **Profile Memory Usage**: Use Xcode Instruments

### Preloading Strategy

```swift
// Automatic preloading (default)
reader.goToPage(5)
// - Loads chapter 5
// - Preloads chapters 6 and 7 in background

// Disable preloading (if needed)
// Modify EpubReader.swift:
// Comment out: await preloadAdjacentChapters()
```

### Cache Tuning

For different scenarios:

```swift
// Large device (iPad Pro)
let cache = EpubChapterCache(maxCachedChapters: 10)

// Small device (iPhone SE)
let cache = EpubChapterCache(maxCachedChapters: 3)

// Low memory situation
let cache = EpubChapterCache(maxCachedChapters: 2)
```

## Debugging

### Enable Verbose Logging

All components include detailed logging:

```swift
// Memory status
memoryManager.logMemoryStatus()
// Output: Used: 150 MB, Total: 2 GB, Usage: 7.32%

// Cache status
cache.logCacheStatus()
// Output: Cached: 3/5 chapters, Total: 450 KB, Access order: [2, 3, 4]
```

### Monitor Memory in Xcode

1. Run app in Xcode
2. Open Debug Navigator (Cmd+7)
3. Select Memory
4. Watch memory usage while navigating

### Common Issues

**Issue: Slow chapter loading**
- Check: Is preloading working?
- Solution: Verify background tasks not blocked

**Issue: Memory warnings**
- Check: Cache size too large?
- Solution: Reduce `maxCachedChapters`

**Issue: Chapters not unloading**
- Check: Memory monitoring running?
- Solution: Verify `startMonitoring()` called

## Testing

### Unit Tests

```bash
# Run all tests
xcodebuild test -workspace Runner.xcworkspace -scheme Runner

# Run specific test
xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -only-testing:RunnerTests/EpubMemoryOptimizationTests
```

### Manual Testing

1. **Large EPUB Test**:
   - Open 100+ MB EPUB
   - Verify opens in < 4 seconds
   - Navigate through chapters
   - Check memory usage stays stable

2. **Memory Pressure Test**:
   - Open multiple EPUBs
   - Navigate rapidly
   - Verify no crashes
   - Check automatic cleanup

3. **Performance Test**:
   - Measure open time
   - Measure navigation time
   - Profile memory usage
   - Check for leaks

## Integration with Readium

When integrating Readium SDK:

```swift
// Replace placeholder parsing
private func parseEpubStructure(fileUrl: String) throws {
    // Use Readium Streamer
    let asset = FileAsset(File(fileUrl))
    let publication = try Streamer(context).open(asset).get()
    
    // Extract chapters
    chapters = publication.readingOrder.enumerated().map { index, link in
        EpubChapter(
            index: index,
            title: link.title ?? "Chapter \(index + 1)",
            href: link.href,
            isLoaded: false
        )
    }
}

// Replace placeholder loading
private func loadChapter(index: Int) throws {
    guard let publication = publication else { return }
    
    let link = publication.readingOrder[index]
    let resource = publication.get(link)
    let content = try resource.readAsString().get()
    
    chapterCache.cacheChapter(index: index, content: content)
}
```

## Performance Targets

- **Initial Open**: < 2-4 seconds (100+ MB EPUB)
- **Chapter Navigation**: < 100ms (cached), < 500ms (uncached)
- **Memory Usage**: < 50 MB for reader (excluding content)
- **Cache Size**: ~1 MB (5 chapters average)
- **Preload Time**: < 1 second (background)

## Monitoring Checklist

- [ ] Memory usage stays below 80% during normal reading
- [ ] Large EPUBs open within 2-4 seconds
- [ ] Chapter navigation is smooth (< 100ms)
- [ ] No memory warnings during extended reading
- [ ] Automatic cleanup works under pressure
- [ ] Cache eviction follows LRU strategy
- [ ] Preloading doesn't block UI

## Support

For issues or questions:
1. Check console logs for detailed information
2. Review `MEMORY_OPTIMIZATION_SUMMARY.md`
3. Run unit tests to verify functionality
4. Profile with Xcode Instruments

## References

- `MemoryManager.swift` - Memory monitoring
- `EpubChapterCache.swift` - Chapter caching
- `EpubReader.swift` - Reader integration
- `EpubMemoryOptimizationTests.swift` - Test suite
- `MEMORY_OPTIMIZATION_SUMMARY.md` - Implementation details
