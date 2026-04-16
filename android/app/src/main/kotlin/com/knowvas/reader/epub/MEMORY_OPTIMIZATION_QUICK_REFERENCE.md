# EPUB Memory Optimization - Quick Reference

## For Developers

### Using the ChapterCache

```kotlin
// Initialize cache (done automatically in EpubReader)
val cache = ChapterCache(publication, coroutineScope)

// Get a chapter (lazy loads if not cached)
val chapter = cache.getChapter(chapterIndex)

// Get cache statistics
val stats = cache.getCacheStats()
println("Hit rate: ${stats["hitRate"]}")
println("Cache size: ${stats["size"]} / ${stats["maxSize"]}")

// Manually trigger cleanup
cache.onCleanupRequested()

// Clear entire cache
cache.clearCache()

// Release resources
cache.release()
```

### Using MemoryManager

```kotlin
// Check memory before loading a file
val fileSizeBytes = file.length()
if (MemoryManager.canLoadFile(fileSizeBytes)) {
    // Safe to load
} else {
    // Not enough memory
    MemoryManager.forceCleanup()
}

// Get current memory statistics
val stats = MemoryManager.getMemoryStats()
println("Memory: ${stats.usedMemoryMB}MB / ${stats.maxMemoryMB}MB")
println("Pressure: ${stats.pressureLevel}")

// Start periodic monitoring
val timer = MemoryManager.startPeriodicMonitoring(5000) { stats ->
    println("Memory usage: ${stats.usagePercentage * 100}%")
}

// Stop monitoring
timer.cancel()

// Check for memory leaks
MemoryManager.recordMemoryUsage()
if (MemoryManager.isMemoryLeaking()) {
    println("Warning: Memory leak detected!")
    println("Trend: ${MemoryManager.getMemoryTrend()}")
}

// Register for cleanup notifications
MemoryManager.registerCleanupListener(object : MemoryManager.MemoryCleanupListener {
    override fun onMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        // Handle memory pressure
    }
    
    override fun onCleanupRequested() {
        // Clean up resources
    }
})
```

### EpubReader Memory Features

```kotlin
// Open EPUB (automatically checks memory and initializes cache)
reader.open(fileUrl, token) { success, error ->
    if (success) {
        // EPUB opened successfully
        // Cache is initialized
        // Memory monitoring started (if file > 50MB)
    }
}

// Navigate (uses lazy loading)
reader.goToPage(pageIndex) // Chapter loaded in background

// Get cache statistics
val cacheStats = reader.getChapterCacheStats()

// Manually trigger cache cleanup
reader.triggerCacheCleanup()

// Clear cache
reader.clearChapterCache()

// Close (automatically stops monitoring and releases cache)
reader.close()
```

## Configuration

### ChapterCache Settings

```kotlin
// In ChapterCache.kt
DEFAULT_CACHE_SIZE_MB = 50      // Default: 50MB
MIN_CACHE_SIZE_MB = 10          // Minimum: 10MB
MAX_CACHE_SIZE_MB = 200         // Maximum: 200MB
PRELOAD_AHEAD_COUNT = 2         // Pre-load 2 chapters ahead
PRELOAD_BEHIND_COUNT = 1        // Pre-load 1 chapter behind
```

### MemoryManager Thresholds

```kotlin
// In MemoryManager.kt
MEMORY_THRESHOLD_WARNING = 0.75    // 75% - WARNING level
MEMORY_THRESHOLD_CRITICAL = 0.85   // 85% - CRITICAL level
MEMORY_THRESHOLD_EMERGENCY = 0.95  // 95% - EMERGENCY level
```

## Memory Pressure Levels

| Level | Threshold | Cache Response | Pre-loading |
|-------|-----------|----------------|-------------|
| NORMAL | < 75% | No action | Active |
| WARNING | 75-85% | Evict 25% | Paused |
| CRITICAL | 85-95% | Evict 50% | Stopped |
| EMERGENCY | > 95% | Evict all but current | Stopped |

## Performance Targets

| Metric | Target | Implementation |
|--------|--------|----------------|
| Large EPUB open time | 2-4 seconds | Lazy loading, structure-only parse |
| Page turn latency | < 100ms | Pre-loaded or cached chapters |
| Jump to page | < 500ms | On-demand loading |
| Memory usage | 30-100 MB | Dynamic cache sizing |
| Reading session | 2+ hours stable | Leak detection, auto-cleanup |

## Logging

### Enable Detailed Logging

```kotlin
// Memory statistics
MemoryManager.logMemoryStats("MyTag")

// Cache statistics
chapterCache.logCacheStats()
```

### Log Output Examples

```
MemoryManager: Memory check: 85MB / 256MB (33.2%) - NORMAL
ChapterCache: Cache hit for chapter 5
ChapterCache: Pre-loading chapter 6
ChapterCache: Evicted chapter 2 from cache (LRU)
EpubReader: EPUB opened in 2340ms (target: 2000-4000ms)
```

## Troubleshooting

### Issue: EPUB takes too long to open

**Check:**
1. File size - is it > 100MB?
2. Memory available - run `MemoryManager.getMemoryStats()`
3. Open time logs - check actual time vs target

**Solutions:**
- Ensure lazy loading is working
- Check if pre-loading is blocking
- Verify cache initialization

### Issue: Out of memory crashes

**Check:**
1. Memory pressure level - `MemoryManager.getMemoryStats().pressureLevel`
2. Cache size - `chapterCache.getCacheStats()`
3. Memory trend - `MemoryManager.getMemoryTrend()`

**Solutions:**
- Reduce cache size: `chapterCache.resizeCache(30)`
- Force cleanup: `MemoryManager.forceCleanup()`
- Check for leaks: `MemoryManager.isMemoryLeaking()`

### Issue: Slow navigation

**Check:**
1. Cache hit rate - should be > 70%
2. Pre-loading status - check logs
3. Memory pressure - may have disabled pre-loading

**Solutions:**
- Increase cache size if memory allows
- Adjust pre-load counts
- Check memory pressure level

### Issue: Memory leak detected

**Check:**
1. Memory trend - `MemoryManager.getMemoryTrend()`
2. Cache statistics - growing unbounded?
3. Cleanup listeners - properly registered?

**Solutions:**
- Ensure `reader.close()` is called
- Check for retained references
- Verify cache eviction is working

## Testing

### Unit Tests

```bash
# Run ChapterCache tests
./gradlew test --tests "com.knowvas.reader.epub.ChapterCacheTest"

# Run MemoryManager tests
./gradlew test --tests "com.knowvas.reader.utils.MemoryManagerTest"
```

### Manual Testing

```kotlin
// Test large EPUB loading
val startTime = System.currentTimeMillis()
reader.open(largeEpubPath, token) { success, error ->
    val openTime = System.currentTimeMillis() - startTime
    println("Open time: ${openTime}ms (target: 2000-4000ms)")
}

// Test memory usage during reading
MemoryManager.startPeriodicMonitoring(5000) { stats ->
    println("Memory: ${stats.usedMemoryMB}MB (${stats.pressureLevel})")
}

// Test cache effectiveness
val cacheStats = reader.getChapterCacheStats()
println("Hit rate: ${cacheStats["hitRate"]}")
```

## Best Practices

### DO ✅
- Always call `reader.close()` when done
- Monitor memory for large files (> 50MB)
- Check memory before opening very large files
- Use lazy loading for navigation
- Let cache handle pre-loading automatically
- Register cleanup listeners for custom components

### DON'T ❌
- Don't load all chapters at once
- Don't ignore memory pressure warnings
- Don't disable pre-loading unless necessary
- Don't hold references to closed readers
- Don't manually manage chapter loading (use cache)
- Don't set cache size too small (< 10MB)

## API Reference

### ChapterCache

| Method | Description | Returns |
|--------|-------------|---------|
| `getChapter(index)` | Get chapter (lazy loads if needed) | `CachedChapter?` |
| `clearCache()` | Clear all cached chapters | `Unit` |
| `evictChapter(index)` | Remove specific chapter | `Unit` |
| `getCacheStats()` | Get cache statistics | `Map<String, Any>` |
| `logCacheStats()` | Log statistics to console | `Unit` |
| `resizeCache(sizeMB)` | Change cache size | `Unit` |
| `release()` | Release all resources | `Unit` |

### MemoryManager

| Method | Description | Returns |
|--------|-------------|---------|
| `getMemoryStats()` | Get current memory stats | `MemoryStats` |
| `canLoadFile(size)` | Check if file can be loaded | `Boolean` |
| `estimateMemoryRequirement(size)` | Estimate memory needed | `Long` |
| `isMemoryPressureDetected()` | Check for pressure | `Boolean` |
| `forceCleanup()` | Force garbage collection | `Unit` |
| `startPeriodicMonitoring()` | Start monitoring | `Timer` |
| `recordMemoryUsage()` | Record usage sample | `Unit` |
| `isMemoryLeaking()` | Check for leaks | `Boolean` |
| `getMemoryTrend()` | Get usage trend | `String` |

## Support

For issues or questions:
1. Check logs for detailed error messages
2. Review this quick reference
3. See `TASK_33_MEMORY_OPTIMIZATION.md` for detailed documentation
4. Check unit tests for usage examples
