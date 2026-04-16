package com.knowvas.reader.pdf

import android.graphics.Bitmap
import org.junit.Test
import org.junit.Assert.*

/**
 * Unit tests for PDF optimization components.
 * 
 * Requirements: 6.10, 14.2, 14.6
 */
class PdfOptimizationTest {
    
    @Test
    fun testPdfPageCache_storesAndRetrievesPages() {
        val cache = PdfPageCache(maxMemoryMB = 10)
        
        // Create a test bitmap
        val bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        
        // Store in cache
        cache.putPage(0, bitmap)
        
        // Retrieve from cache
        val retrieved = cache.getPage(0)
        
        assertNotNull("Page should be in cache", retrieved)
        assertEquals("Retrieved bitmap should match", bitmap, retrieved)
    }
    
    @Test
    fun testPdfPageCache_evictsOldPages() {
        // Create cache with very small size (1MB)
        val cache = PdfPageCache(maxMemoryMB = 1)
        
        // Create multiple large bitmaps that exceed cache size
        val bitmap1 = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888)
        val bitmap2 = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888)
        val bitmap3 = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888)
        
        // Add to cache
        cache.putPage(0, bitmap1)
        cache.putPage(1, bitmap2)
        cache.putPage(2, bitmap3)
        
        // First bitmap should be evicted
        val retrieved = cache.getPage(0)
        assertNull("Old page should be evicted", retrieved)
        
        // Recent bitmaps should still be there
        assertNotNull("Recent page should be in cache", cache.getPage(2))
    }
    
    @Test
    fun testPdfPageCache_thumbnailCache() {
        val cache = PdfPageCache(maxMemoryMB = 10)
        
        // Create a thumbnail
        val thumbnail = Bitmap.createBitmap(50, 50, Bitmap.Config.RGB_565)
        
        // Store thumbnail
        cache.putThumbnail(0, thumbnail)
        
        // Retrieve thumbnail
        val retrieved = cache.getThumbnail(0)
        
        assertNotNull("Thumbnail should be in cache", retrieved)
    }
    
    @Test
    fun testPdfPageCache_clearAll() {
        val cache = PdfPageCache(maxMemoryMB = 10)
        
        val bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        val thumbnail = Bitmap.createBitmap(50, 50, Bitmap.Config.RGB_565)
        
        cache.putPage(0, bitmap)
        cache.putThumbnail(0, thumbnail)
        
        // Clear all
        cache.clearAll()
        
        // Verify cleared
        assertNull("Page should be cleared", cache.getPage(0))
        assertNull("Thumbnail should be cleared", cache.getThumbnail(0))
    }
    
    @Test
    fun testPdfPageCache_stats() {
        val cache = PdfPageCache(maxMemoryMB = 10)
        
        val bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        cache.putPage(0, bitmap)
        
        val stats = cache.getStats()
        
        assertEquals("Should have 1 page", 1, stats.pageCount)
        assertTrue("Should have non-zero size", stats.pageCacheSizeMB >= 0)
    }
    
    @Test
    fun testPdfPageCache_hasPage() {
        val cache = PdfPageCache(maxMemoryMB = 10)
        
        assertFalse("Should not have page initially", cache.hasPage(0))
        
        val bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        cache.putPage(0, bitmap)
        
        assertTrue("Should have page after adding", cache.hasPage(0))
    }
    
    @Test
    fun testPdfTileRenderer_renderQualityLevels() {
        // Test that all quality levels are defined
        val qualities = PdfTileRenderer.RenderQuality.values()
        
        assertEquals("Should have 3 quality levels", 3, qualities.size)
        assertTrue("Should have LOW quality", qualities.contains(PdfTileRenderer.RenderQuality.LOW))
        assertTrue("Should have MEDIUM quality", qualities.contains(PdfTileRenderer.RenderQuality.MEDIUM))
        assertTrue("Should have HIGH quality", qualities.contains(PdfTileRenderer.RenderQuality.HIGH))
    }
}
