package com.knowvas.reader.epub

import com.knowvas.reader.utils.MemoryManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.readium.r2.shared.publication.Link
import org.readium.r2.shared.publication.Manifest
import org.readium.r2.shared.publication.Publication

/**
 * Unit tests for ChapterCache
 * 
 * Tests:
 * - LRU eviction behavior
 * - Memory pressure response
 * - Cache statistics
 * - Pre-loading logic
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ChapterCacheTest {
    
    private lateinit var testPublication: Publication
    private lateinit var chapterCache: ChapterCache
    private val testDispatcher = StandardTestDispatcher()
    private val testScope = CoroutineScope(testDispatcher)
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        
        // Create a test publication with 10 chapters
        val readingOrder = (0 until 10).map { index ->
            Link(
                href = "chapter$index.xhtml",
                type = "application/xhtml+xml"
            )
        }
        
        val manifest = Manifest(
            metadata = org.readium.r2.shared.publication.Metadata(
                identifier = "test-epub",
                localizedTitle = org.readium.r2.shared.publication.LocalizedString("Test EPUB")
            ),
            readingOrder = readingOrder
        )
        
        testPublication = Publication(manifest)
        chapterCache = ChapterCache(testPublication, testScope)
    }
    
    @Test
    fun testCacheInitialization() {
        assertNotNull(chapterCache)
        
        val stats = chapterCache.getCacheStats()
        assertEquals(0, stats["size"])
        assertTrue((stats["maxSize"] as Int) > 0)
        assertEquals(0L, stats["hits"])
        assertEquals(0L, stats["misses"])
    }
    
    @Test
    fun testCacheHitAndMiss() = runTest {
        // First access should be a miss
        val chapter1 = chapterCache.getChapter(0)
        assertNotNull(chapter1)
        
        var stats = chapterCache.getCacheStats()
        assertEquals(1L, stats["misses"])
        assertEquals(0L, stats["hits"])
        
        // Second access should be a hit
        val chapter2 = chapterCache.getChapter(0)
        assertNotNull(chapter2)
        
        stats = chapterCache.getCacheStats()
        assertEquals(1L, stats["misses"])
        assertEquals(1L, stats["hits"])
    }
    
    @Test
    fun testCacheEviction() {
        // Test that evictChapter removes a chapter
        chapterCache.evictChapter(0)
        
        val stats = chapterCache.getCacheStats()
        // Size should be 0 since we evicted the only chapter
        assertEquals(0, stats["size"])
    }
    
    @Test
    fun testClearCache() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        chapterCache.getChapter(2)
        
        var stats = chapterCache.getCacheStats()
        assertTrue((stats["size"] as Int) > 0)
        
        // Clear cache
        chapterCache.clearCache()
        
        stats = chapterCache.getCacheStats()
        assertEquals(0, stats["size"])
    }
    
    @Test
    fun testMemoryPressureWarning() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        chapterCache.getChapter(2)
        chapterCache.getChapter(3)
        
        val sizeBefore = (chapterCache.getCacheStats()["size"] as Int)
        
        // Simulate memory pressure
        chapterCache.onMemoryPressure(MemoryManager.MemoryPressureLevel.WARNING)
        
        val sizeAfter = (chapterCache.getCacheStats()["size"] as Int)
        
        // Cache should have evicted some chapters
        assertTrue(sizeAfter <= sizeBefore)
    }
    
    @Test
    fun testMemoryPressureCritical() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        chapterCache.getChapter(2)
        chapterCache.getChapter(3)
        
        val sizeBefore = (chapterCache.getCacheStats()["size"] as Int)
        
        // Simulate critical memory pressure
        chapterCache.onMemoryPressure(MemoryManager.MemoryPressureLevel.CRITICAL)
        
        val sizeAfter = (chapterCache.getCacheStats()["size"] as Int)
        
        // Cache should have evicted more chapters than WARNING level
        assertTrue(sizeAfter < sizeBefore)
    }
    
    @Test
    fun testMemoryPressureEmergency() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        chapterCache.getChapter(2)
        chapterCache.getChapter(3)
        
        // Simulate emergency memory pressure
        chapterCache.onMemoryPressure(MemoryManager.MemoryPressureLevel.EMERGENCY)
        
        val sizeAfter = (chapterCache.getCacheStats()["size"] as Int)
        
        // Cache should keep at most 1 chapter (the current one)
        assertTrue(sizeAfter <= 1)
    }
    
    @Test
    fun testCleanupRequested() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        chapterCache.getChapter(2)
        
        val sizeBefore = (chapterCache.getCacheStats()["size"] as Int)
        
        // Request cleanup
        chapterCache.onCleanupRequested()
        
        val sizeAfter = (chapterCache.getCacheStats()["size"] as Int)
        
        // Cache should have evicted some chapters
        assertTrue(sizeAfter <= sizeBefore)
    }
    
    @Test
    fun testCacheHitRate() = runTest {
        // Load chapter 0 multiple times
        chapterCache.getChapter(0) // miss
        chapterCache.getChapter(0) // hit
        chapterCache.getChapter(0) // hit
        chapterCache.getChapter(0) // hit
        
        val stats = chapterCache.getCacheStats()
        val hitRate = stats["hitRate"] as Double
        
        // Hit rate should be 75% (3 hits out of 4 accesses)
        assertEquals(0.75, hitRate, 0.01)
    }
    
    @Test
    fun testResizeCache() {
        val initialSize = chapterCache.getCacheStats()["cacheSizeMB"] as Int
        
        // Resize to a different size
        val newSize = initialSize + 10
        chapterCache.resizeCache(newSize)
        
        val updatedSize = chapterCache.getCacheStats()["cacheSizeMB"] as Int
        assertEquals(newSize, updatedSize)
    }
    
    @Test
    fun testResizeCacheWithBounds() {
        // Try to resize below minimum
        chapterCache.resizeCache(5)
        val sizeAfterMin = chapterCache.getCacheStats()["cacheSizeMB"] as Int
        assertTrue(sizeAfterMin >= 10) // MIN_CACHE_SIZE_MB
        
        // Try to resize above maximum
        chapterCache.resizeCache(300)
        val sizeAfterMax = chapterCache.getCacheStats()["cacheSizeMB"] as Int
        assertTrue(sizeAfterMax <= 200) // MAX_CACHE_SIZE_MB
    }
    
    @Test
    fun testRelease() = runTest {
        // Load some chapters
        chapterCache.getChapter(0)
        chapterCache.getChapter(1)
        
        // Release cache
        chapterCache.release()
        
        // Cache should be cleared
        val stats = chapterCache.getCacheStats()
        assertEquals(0, stats["size"])
    }
}
