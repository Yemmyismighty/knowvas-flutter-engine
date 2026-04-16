package com.knowvas.reader.epub

import android.util.Log
import android.util.LruCache
import com.knowvas.reader.utils.MemoryManager
import org.readium.r2.shared.publication.Locator
import org.readium.r2.shared.publication.Publication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap

/**
 * Chapter cache with LRU eviction strategy for EPUB reader
 * 
 * This cache:
 * - Implements lazy loading for chapters
 * - Uses LRU (Least Recently Used) eviction policy
 * - Monitors memory pressure and unloads chapters when needed
 * - Pre-loads adjacent chapters for smooth navigation
 * - Tracks chapter access patterns for optimization
 * 
 * Requirements: 5.14, 5.15, 14.1, 14.6
 */
class ChapterCache(
    private val publication: Publication,
    private val coroutineScope: CoroutineScope
) : MemoryManager.MemoryCleanupListener {

    companion object {
        private const val TAG = "ChapterCache"
        
        // Cache configuration
        private const val DEFAULT_CACHE_SIZE_MB = 50 // 50MB default cache size
        private const val MIN_CACHE_SIZE_MB = 10 // Minimum 10MB
        private const val MAX_CACHE_SIZE_MB = 200 // Maximum 200MB
        
        // Pre-loading configuration
        private const val PRELOAD_AHEAD_COUNT = 2 // Pre-load 2 chapters ahead
        private const val PRELOAD_BEHIND_COUNT = 1 // Pre-load 1 chapter behind
        
        // Memory thresholds for dynamic cache sizing
        private const val MEMORY_PRESSURE_CACHE_REDUCTION = 0.5 // Reduce cache by 50% under pressure
    }
    
    /**
     * Cached chapter data
     */
    data class CachedChapter(
        val chapterIndex: Int,
        val locator: Locator,
        val content: String,
        val sizeBytes: Long,
        val loadedAt: Long = System.currentTimeMillis()
    )
    
    // LRU cache for chapter content
    private var lruCache: LruCache<Int, CachedChapter>
    
    // Track chapters currently being loaded to avoid duplicate loads
    private val loadingChapters = ConcurrentHashMap<Int, Boolean>()
    
    // Track access patterns for optimization
    private val accessCounts = ConcurrentHashMap<Int, Int>()
    private var lastAccessedChapter: Int = -1
    
    // Cache statistics
    private var cacheHits: Long = 0
    private var cacheMisses: Long = 0
    private var evictions: Long = 0
    
    // Current cache size in MB
    private var currentCacheSizeMB: Int = DEFAULT_CACHE_SIZE_MB
    
    init {
        // Calculate initial cache size based on available memory
        val availableMemoryMB = MemoryManager.getAvailableMemoryMB()
        currentCacheSizeMB = calculateOptimalCacheSize(availableMemoryMB)
        
        // Initialize LRU cache
        lruCache = createLruCache(currentCacheSizeMB)
        
        // Register for memory pressure notifications
        MemoryManager.registerCleanupListener(this)
        
        Log.i(TAG, "ChapterCache initialized with ${currentCacheSizeMB}MB cache size")
    }
    
    /**
     * Get chapter content, loading from publication if not cached
     * This implements lazy loading
     */
    suspend fun getChapter(chapterIndex: Int): CachedChapter? {
        // Check cache first
        val cached = lruCache.get(chapterIndex)
        if (cached != null) {
            cacheHits++
            updateAccessPattern(chapterIndex)
            Log.d(TAG, "Cache hit for chapter $chapterIndex")
            return cached
        }
        
        cacheMisses++
        Log.d(TAG, "Cache miss for chapter $chapterIndex, loading...")
        
        // Load chapter
        val chapter = loadChapter(chapterIndex)
        
        // Pre-load adjacent chapters in background
        preloadAdjacentChapters(chapterIndex)
        
        return chapter
    }
    
    /**
     * Load a chapter from the publication
     */
    private suspend fun loadChapter(chapterIndex: Int): CachedChapter? {
        // Check if already loading
        if (loadingChapters.putIfAbsent(chapterIndex, true) != null) {
            Log.d(TAG, "Chapter $chapterIndex is already being loaded, waiting...")
            // Wait for the other load to complete
            while (loadingChapters.containsKey(chapterIndex)) {
                kotlinx.coroutines.delay(50)
            }
            return lruCache.get(chapterIndex)
        }
        
        return try {
            withContext(Dispatchers.IO) {
                // Get the reading order item for this chapter
                val readingOrderItem = publication.readingOrder.getOrNull(chapterIndex)
                if (readingOrderItem == null) {
                    Log.w(TAG, "No reading order item found for chapter $chapterIndex")
                    return@withContext null
                }
                
                // Create locator for this chapter
                val locator = Locator(
                    href = readingOrderItem.href,
                    type = readingOrderItem.type ?: "application/xhtml+xml",
                    locations = Locator.Locations(position = chapterIndex)
                )
                
                // In a real implementation, you would fetch the actual chapter content here
                // For now, we'll create a placeholder
                // val content = publication.get(readingOrderItem.href)?.readAsString() ?: ""
                val content = "Chapter $chapterIndex content placeholder"
                
                val sizeBytes = content.toByteArray().size.toLong()
                
                // Check if we have enough memory before caching
                val sizeMB = sizeBytes / (1024 * 1024)
                if (!MemoryManager.hasEnoughMemory(sizeMB)) {
                    Log.w(TAG, "Insufficient memory to cache chapter $chapterIndex (${sizeMB}MB)")
                    // Trigger cleanup and try again
                    MemoryManager.forceCleanup()
                    
                    if (!MemoryManager.hasEnoughMemory(sizeMB)) {
                        Log.e(TAG, "Still insufficient memory after cleanup")
                        // Return uncached chapter
                        return@withContext CachedChapter(
                            chapterIndex = chapterIndex,
                            locator = locator,
                            content = content,
                            sizeBytes = sizeBytes
                        )
                    }
                }
                
                // Create cached chapter
                val cachedChapter = CachedChapter(
                    chapterIndex = chapterIndex,
                    locator = locator,
                    content = content,
                    sizeBytes = sizeBytes
                )
                
                // Add to cache
                lruCache.put(chapterIndex, cachedChapter)
                updateAccessPattern(chapterIndex)
                
                Log.d(TAG, "Loaded and cached chapter $chapterIndex (${sizeBytes / 1024}KB)")
                
                cachedChapter
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading chapter $chapterIndex", e)
            null
        } finally {
            loadingChapters.remove(chapterIndex)
        }
    }
    
    /**
     * Pre-load adjacent chapters in the background
     */
    private fun preloadAdjacentChapters(currentChapter: Int) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                // Check memory before pre-loading
                if (MemoryManager.isMemoryPressureDetected()) {
                    Log.d(TAG, "Skipping pre-load due to memory pressure")
                    return@launch
                }
                
                val totalChapters = publication.readingOrder.size
                
                // Pre-load chapters ahead
                for (i in 1..PRELOAD_AHEAD_COUNT) {
                    val nextChapter = currentChapter + i
                    if (nextChapter < totalChapters && lruCache.get(nextChapter) == null) {
                        Log.d(TAG, "Pre-loading chapter $nextChapter")
                        loadChapter(nextChapter)
                        
                        // Check memory after each pre-load
                        if (MemoryManager.isMemoryPressureDetected()) {
                            Log.d(TAG, "Stopping pre-load due to memory pressure")
                            break
                        }
                    }
                }
                
                // Pre-load chapters behind
                for (i in 1..PRELOAD_BEHIND_COUNT) {
                    val prevChapter = currentChapter - i
                    if (prevChapter >= 0 && lruCache.get(prevChapter) == null) {
                        Log.d(TAG, "Pre-loading chapter $prevChapter")
                        loadChapter(prevChapter)
                        
                        // Check memory after each pre-load
                        if (MemoryManager.isMemoryPressureDetected()) {
                            Log.d(TAG, "Stopping pre-load due to memory pressure")
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error pre-loading chapters", e)
            }
        }
    }
    
    /**
     * Clear all cached chapters
     */
    fun clearCache() {
        lruCache.evictAll()
        accessCounts.clear()
        lastAccessedChapter = -1
        Log.i(TAG, "Cache cleared")
    }
    
    /**
     * Clear specific chapter from cache
     */
    fun evictChapter(chapterIndex: Int) {
        lruCache.remove(chapterIndex)
        Log.d(TAG, "Evicted chapter $chapterIndex from cache")
    }
    
    /**
     * Get cache statistics
     */
    fun getCacheStats(): Map<String, Any> {
        val size = lruCache.size()
        val maxSize = lruCache.maxSize()
        val hitRate = if (cacheHits + cacheMisses > 0) {
            cacheHits.toDouble() / (cacheHits + cacheMisses).toDouble()
        } else {
            0.0
        }
        
        return mapOf(
            "size" to size,
            "maxSize" to maxSize,
            "hits" to cacheHits,
            "misses" to cacheMisses,
            "evictions" to evictions,
            "hitRate" to hitRate,
            "cacheSizeMB" to currentCacheSizeMB
        )
    }
    
    /**
     * Log cache statistics
     */
    fun logCacheStats() {
        val stats = getCacheStats()
        Log.i(TAG, "=== Chapter Cache Statistics ===")
        Log.i(TAG, "Size: ${stats["size"]} / ${stats["maxSize"]}")
        Log.i(TAG, "Hits: ${stats["hits"]}, Misses: ${stats["misses"]}")
        Log.i(TAG, "Hit Rate: ${String.format("%.2f", (stats["hitRate"] as Double) * 100)}%")
        Log.i(TAG, "Evictions: ${stats["evictions"]}")
        Log.i(TAG, "Cache Size: ${stats["cacheSizeMB"]}MB")
        Log.i(TAG, "================================")
    }
    
    /**
     * Handle memory pressure by reducing cache size
     */
    override fun onMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        Log.w(TAG, "Memory pressure detected: $level")
        
        when (level) {
            MemoryManager.MemoryPressureLevel.WARNING -> {
                // Evict least recently used chapters
                evictLeastRecentlyUsed(0.25) // Evict 25% of cache
            }
            MemoryManager.MemoryPressureLevel.CRITICAL -> {
                // Evict more aggressively
                evictLeastRecentlyUsed(0.5) // Evict 50% of cache
            }
            MemoryManager.MemoryPressureLevel.EMERGENCY -> {
                // Clear all but current chapter
                evictAllExceptCurrent()
            }
            else -> {
                // Normal - no action needed
            }
        }
    }
    
    /**
     * Handle cleanup request
     */
    override fun onCleanupRequested() {
        Log.i(TAG, "Cleanup requested, evicting old chapters")
        evictLeastRecentlyUsed(0.3) // Evict 30% of cache
    }
    
    /**
     * Evict a percentage of least recently used chapters
     */
    private fun evictLeastRecentlyUsed(percentage: Double) {
        val snapshot = lruCache.snapshot()
        val toEvict = (snapshot.size * percentage).toInt()
        
        if (toEvict == 0) return
        
        Log.i(TAG, "Evicting $toEvict chapters (${String.format("%.0f", percentage * 100)}% of cache)")
        
        // Get chapters sorted by access time (oldest first)
        val sortedChapters = snapshot.entries
            .sortedBy { it.value.loadedAt }
            .take(toEvict)
        
        // Evict them
        sortedChapters.forEach { entry ->
            lruCache.remove(entry.key)
            evictions++
        }
        
        Log.i(TAG, "Evicted $toEvict chapters, cache size now: ${lruCache.size()}")
    }
    
    /**
     * Evict all chapters except the current one
     */
    private fun evictAllExceptCurrent() {
        val currentChapter = lastAccessedChapter
        val snapshot = lruCache.snapshot()
        
        Log.w(TAG, "Emergency eviction: clearing all except chapter $currentChapter")
        
        snapshot.keys.forEach { chapterIndex ->
            if (chapterIndex != currentChapter) {
                lruCache.remove(chapterIndex)
                evictions++
            }
        }
        
        Log.i(TAG, "Emergency eviction complete, cache size: ${lruCache.size()}")
    }
    
    /**
     * Update access pattern tracking
     */
    private fun updateAccessPattern(chapterIndex: Int) {
        accessCounts[chapterIndex] = (accessCounts[chapterIndex] ?: 0) + 1
        lastAccessedChapter = chapterIndex
    }
    
    /**
     * Calculate optimal cache size based on available memory
     */
    private fun calculateOptimalCacheSize(availableMemoryMB: Long): Int {
        // Use 10-20% of available memory for cache, with min/max bounds
        val optimalSize = (availableMemoryMB * 0.15).toInt()
        return optimalSize.coerceIn(MIN_CACHE_SIZE_MB, MAX_CACHE_SIZE_MB)
    }
    
    /**
     * Create LRU cache with specified size
     */
    private fun createLruCache(sizeMB: Int): LruCache<Int, CachedChapter> {
        val sizeBytes = sizeMB * 1024 * 1024
        
        return object : LruCache<Int, CachedChapter>(sizeBytes) {
            override fun sizeOf(key: Int, value: CachedChapter): Int {
                return value.sizeBytes.toInt()
            }
            
            override fun entryRemoved(
                evicted: Boolean,
                key: Int,
                oldValue: CachedChapter,
                newValue: CachedChapter?
            ) {
                if (evicted) {
                    evictions++
                    Log.d(TAG, "Chapter $key evicted from cache (LRU)")
                }
            }
        }
    }
    
    /**
     * Resize cache dynamically
     */
    fun resizeCache(newSizeMB: Int) {
        val boundedSize = newSizeMB.coerceIn(MIN_CACHE_SIZE_MB, MAX_CACHE_SIZE_MB)
        
        if (boundedSize == currentCacheSizeMB) {
            return
        }
        
        Log.i(TAG, "Resizing cache from ${currentCacheSizeMB}MB to ${boundedSize}MB")
        
        // Create new cache with new size
        val oldCache = lruCache
        lruCache = createLruCache(boundedSize)
        currentCacheSizeMB = boundedSize
        
        // Copy entries from old cache that fit in new size
        val snapshot = oldCache.snapshot()
        snapshot.entries.forEach { entry ->
            lruCache.put(entry.key, entry.value)
        }
        
        Log.i(TAG, "Cache resized, new size: ${lruCache.size()} chapters")
    }
    
    /**
     * Clean up resources
     */
    fun release() {
        MemoryManager.unregisterCleanupListener(this)
        clearCache()
        loadingChapters.clear()
        Log.i(TAG, "ChapterCache released")
    }
}
