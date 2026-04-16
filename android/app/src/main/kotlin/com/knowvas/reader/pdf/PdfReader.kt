package com.knowvas.reader.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.EventChannel
import com.knowvas.reader.BaseReader
import com.knowvas.reader.utils.MemoryManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * PDF reader implementation using Android PdfRenderer
 * Handles PDF rendering, page navigation, and user interactions
 * 
 * Requirements:
 * - 6.1: Open PDF from library using PdfRenderer
 * - 6.2: Emit onReaderReady with total page count
 * - 6.3: Support page navigation with swipe gestures and emit page_turn events
 */
class PdfReader(
    private val context: Context,
    private var eventSink: EventChannel.EventSink?,
    val sessionId: String  // Made public for PdfReaderFragment access
) : BaseReader {

    private var pdfRenderer: PdfRenderer? = null
    private var currentPage: PdfRenderer.Page? = null
    private var fileDescriptor: ParcelFileDescriptor? = null
    private var currentPageIndex: Int = 0
    private var totalPages: Int = 0
    private var isOpen: Boolean = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    
    // Cache for rendered pages to improve performance
    private val pageCache = mutableMapOf<Int, Bitmap>()
    private val maxCacheSize = 5 // Cache up to 5 pages
    
    // Thumbnail cache for page navigation (Task 37)
    private val thumbnailCache = mutableMapOf<Int, Bitmap>()
    private val maxThumbnailCacheSize = 50 // Cache more thumbnails as they're smaller
    private val thumbnailScale = 0.2f // 20% of original size for thumbnails
    
    // Progressive rendering state (Task 37)
    private var isProgressiveRenderingEnabled = true
    private val progressiveRenderScale = 0.5f // 50% for low-res first pass
    
    // Tile-based rendering for large pages (Task 37)
    private var isTileRenderingEnabled = true
    private val tileSize = 512 // 512x512 pixel tiles
    
    // Session start time for engagement tracking
    private var sessionStartTime: Long = 0
    
    // Memory cleanup listener (Task 37)
    private val memoryCleanupListener = object : MemoryManager.MemoryCleanupListener {
        override fun onMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
            android.util.Log.w("PdfReader", "Memory pressure detected: $level")
            when (level) {
                MemoryManager.MemoryPressureLevel.WARNING -> {
                    // Clear thumbnail cache
                    clearThumbnailCache()
                }
                MemoryManager.MemoryPressureLevel.CRITICAL -> {
                    // Clear both caches
                    clearThumbnailCache()
                    clearCache()
                }
                MemoryManager.MemoryPressureLevel.EMERGENCY -> {
                    // Aggressive cleanup
                    clearThumbnailCache()
                    clearCache()
                    System.gc()
                }
                else -> {}
            }
        }
        
        override fun onCleanupRequested() {
            android.util.Log.i("PdfReader", "Cleanup requested")
            clearThumbnailCache()
            // Keep current page cache but clear others
            val currentBitmap = pageCache[currentPageIndex]
            clearCache()
            if (currentBitmap != null && !currentBitmap.isRecycled) {
                pageCache[currentPageIndex] = currentBitmap
            }
        }
    }

    override fun open(fileUrl: String, token: String, callback: (Boolean, String?) -> Unit) {
        coroutineScope.launch {
            val startTime = System.currentTimeMillis()
            
            try {
                // Register memory cleanup listener (Task 37)
                MemoryManager.registerCleanupListener(memoryCleanupListener)
                
                // Log initial memory state
                MemoryManager.logMemoryStats("PdfReader-Open")
                
                // Check if file exists
                val file = File(fileUrl)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        callback(false, "File not found: $fileUrl")
                    }
                    return@launch
                }
                
                val fileSizeBytes = file.length()
                val fileSizeMB = fileSizeBytes / (1024 * 1024)
                android.util.Log.i("PdfReader", "Opening PDF file: ${fileSizeMB}MB")
                
                // Check memory availability for large files
                if (fileSizeMB > 50 && !MemoryManager.canLoadFile(fileSizeBytes)) {
                    android.util.Log.w("PdfReader", "Insufficient memory for large PDF, triggering cleanup")
                    MemoryManager.forceCleanup()
                    
                    // Check again after cleanup
                    if (!MemoryManager.canLoadFile(fileSizeBytes)) {
                        withContext(Dispatchers.Main) {
                            callback(false, "Insufficient memory to open this PDF (${fileSizeMB}MB)")
                        }
                        return@launch
                    }
                }

                // Open file descriptor for PdfRenderer (Task 37: Lazy loading - only open descriptor, don't render yet)
                fileDescriptor = withContext(Dispatchers.IO) {
                    ParcelFileDescriptor.open(
                        file,
                        ParcelFileDescriptor.MODE_READ_ONLY
                    )
                }
                
                if (fileDescriptor == null) {
                    withContext(Dispatchers.Main) {
                        callback(false, "Failed to open file descriptor")
                    }
                    return@launch
                }

                // Initialize PdfRenderer (Task 37: Fast initialization - only parse metadata, don't render pages)
                pdfRenderer = PdfRenderer(fileDescriptor!!)
                totalPages = pdfRenderer?.pageCount ?: 0
                currentPageIndex = 0
                isOpen = true
                sessionStartTime = System.currentTimeMillis()
                
                // Calculate and log open time (Task 37: Should be <2-4s even for 1000+ pages)
                val openTime = System.currentTimeMillis() - startTime
                android.util.Log.i("PdfReader", "PDF opened in ${openTime}ms (target: 2000-4000ms) with $totalPages pages")
                
                // Performance check for requirement 6.10 and 14.2
                if (totalPages >= 1000 && openTime > 4000) {
                    android.util.Log.w("PdfReader", "WARNING: Large PDF (${totalPages} pages) took ${openTime}ms to open (target: <4000ms)")
                } else if (openTime <= 4000) {
                    android.util.Log.i("PdfReader", "✓ Performance target met: ${openTime}ms <= 4000ms")
                }
                
                // Emit reader ready event
                emitReaderReadyEvent()
                
                // Task 37: Start background thumbnail generation for fast navigation
                // DISABLED: Causing page locking issues, will re-enable after fixing
                // if (totalPages > 10) {
                //     startBackgroundThumbnailGeneration()
                // }
                
                // Log final memory state
                MemoryManager.logMemoryStats("PdfReader-Ready")

                withContext(Dispatchers.Main) {
                    callback(true, null)
                }
            } catch (e: Exception) {
                android.util.Log.e("PdfReader", "Error opening PDF", e)
                withContext(Dispatchers.Main) {
                    callback(false, "Exception opening PDF: ${e.message}")
                }
            }
        }
    }

    override fun close() {
        try {
            // Unregister memory cleanup listener (Task 37)
            MemoryManager.unregisterCleanupListener(memoryCleanupListener)
            
            // Emit session end event
            emitSessionEndEvent()
            
            // Close current page
            currentPage?.close()
            currentPage = null
            
            // Close PDF renderer
            pdfRenderer?.close()
            pdfRenderer = null
            
            // Close file descriptor
            fileDescriptor?.close()
            fileDescriptor = null
            
            // Clear page cache
            pageCache.values.forEach { bitmap ->
                if (!bitmap.isRecycled) {
                    bitmap.recycle()
                }
            }
            pageCache.clear()
            
            // Clear thumbnail cache (Task 37)
            clearThumbnailCache()
            
            isOpen = false
            
            android.util.Log.i("PdfReader", "PDF reader closed successfully")
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error closing PDF reader", e)
        }
    }

    // ========== Zoom and Pan State ==========
    
    // Current zoom level (1.0 = 100%, 4.0 = 400%)
    private var currentZoomLevel: Float = 1.0f
    
    // Zoom limits (Requirement 6.4)
    companion object ZoomLimits {
        const val MIN_ZOOM = 1.0f  // 100%
        const val MAX_ZOOM = 4.0f  // 400%
        const val FIT_TO_WIDTH_ZOOM = 1.5f
    }
    
    override fun setPreferences(preferences: Map<*, *>) {
        // PDF preferences will be implemented in Task 36
        // For now, just log the preferences
        android.util.Log.d("PdfReader", "setPreferences called (will be implemented in Task 36)")
    }
    
    // ========== Zoom and Pan Methods ==========
    
    /**
     * Set zoom level
     * Requirement 6.4: Zoom with 100% to 400% limits
     * 
     * @param zoomLevel Zoom level from 1.0 (100%) to 4.0 (400%)
     * @return true if zoom was applied, false if out of bounds
     */
    fun setZoom(zoomLevel: Float): Boolean {
        val constrainedZoom = zoomLevel.coerceIn(MIN_ZOOM, MAX_ZOOM)
        
        if (constrainedZoom != currentZoomLevel) {
            currentZoomLevel = constrainedZoom
            android.util.Log.d("PdfReader", "Zoom set to ${currentZoomLevel}x")
            
            // Emit zoom change event
            emitZoomChangeEvent()
            
            return true
        }
        
        return false
    }
    
    /**
     * Get current zoom level
     * @return Current zoom level (1.0 to 4.0)
     */
    fun getZoom(): Float = currentZoomLevel
    
    /**
     * Zoom in by a factor
     * @param factor Zoom factor (default 1.2 = 20% increase)
     * @return New zoom level
     */
    fun zoomIn(factor: Float = 1.2f): Float {
        val newZoom = (currentZoomLevel * factor).coerceAtMost(MAX_ZOOM)
        setZoom(newZoom)
        return currentZoomLevel
    }
    
    /**
     * Zoom out by a factor
     * @param factor Zoom factor (default 1.2 = 20% decrease)
     * @return New zoom level
     */
    fun zoomOut(factor: Float = 1.2f): Float {
        val newZoom = (currentZoomLevel / factor).coerceAtLeast(MIN_ZOOM)
        setZoom(newZoom)
        return currentZoomLevel
    }
    
    /**
     * Toggle between fit-to-screen and fit-to-width zoom
     * Requirement 6.6: Double-tap to toggle zoom levels
     * 
     * @return New zoom level
     */
    fun toggleZoom(): Float {
        val targetZoom = if (currentZoomLevel <= MIN_ZOOM) {
            FIT_TO_WIDTH_ZOOM
        } else {
            MIN_ZOOM
        }
        
        setZoom(targetZoom)
        android.util.Log.d("PdfReader", "Toggled zoom to ${currentZoomLevel}x")
        
        return currentZoomLevel
    }
    
    /**
     * Reset zoom to default (100%)
     */
    fun resetZoom() {
        setZoom(MIN_ZOOM)
        android.util.Log.d("PdfReader", "Reset zoom to ${currentZoomLevel}x")
    }
    
    /**
     * Check if page is currently zoomed
     * @return true if zoom > 100%
     */
    fun isZoomed(): Boolean = currentZoomLevel > MIN_ZOOM

    override fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun emitEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }
    
    // ========== Page Navigation Methods ==========
    
    /**
     * Navigate to the next page
     * @return true if navigation was successful, false if already at last page
     */
    fun nextPage(): Boolean {
        if (!isOpen || pdfRenderer == null) {
            android.util.Log.w("PdfReader", "Cannot navigate: PDF not open")
            return false
        }
        
        if (currentPageIndex >= totalPages - 1) {
            android.util.Log.d("PdfReader", "Already at last page")
            return false
        }
        
        currentPageIndex++
        emitPageTurnEvent()
        return true
    }
    
    /**
     * Navigate to the previous page
     * @return true if navigation was successful, false if already at first page
     */
    fun previousPage(): Boolean {
        if (!isOpen || pdfRenderer == null) {
            android.util.Log.w("PdfReader", "Cannot navigate: PDF not open")
            return false
        }
        
        if (currentPageIndex <= 0) {
            android.util.Log.d("PdfReader", "Already at first page")
            return false
        }
        
        currentPageIndex--
        emitPageTurnEvent()
        return true
    }
    
    /**
     * Navigate to a specific page
     * @param pageIndex Zero-based page index
     */
    fun goToPage(pageIndex: Int) {
        if (!isOpen || pdfRenderer == null) {
            android.util.Log.w("PdfReader", "Cannot navigate: PDF not open")
            return
        }
        
        if (pageIndex < 0 || pageIndex >= totalPages) {
            android.util.Log.w("PdfReader", "Invalid page index: $pageIndex (total: $totalPages)")
            return
        }
        
        currentPageIndex = pageIndex
        emitPageTurnEvent()
    }
    
    /**
     * Get current page index
     * @return Zero-based current page index
     */
    fun getCurrentPage(): Int = currentPageIndex
    
    /**
     * Get total page count
     * @return Total number of pages in the PDF
     */
    fun getTotalPages(): Int = totalPages
    
    /**
     * Get reading progress as a percentage
     * @return Progress from 0.0 to 1.0
     */
    fun getProgress(): Double {
        if (totalPages == 0) return 0.0
        return (currentPageIndex + 1).toDouble() / totalPages.toDouble()
    }
    
    /**
     * Set reading progress
     * @param progress Progress from 0.0 to 1.0
     */
    fun setProgress(progress: Double) {
        val targetPage = (progress * totalPages).toInt().coerceIn(0, totalPages - 1)
        goToPage(targetPage)
    }
    
    // ========== Page Rendering Methods ==========
    
    /**
     * Render a specific page to a bitmap
     * @param pageIndex Zero-based page index
     * @return Rendered bitmap or null if rendering fails
     */
    fun renderPage(pageIndex: Int): Bitmap? {
        android.util.Log.d("PdfReader", "renderPage called for page $pageIndex")
        android.util.Log.d("PdfReader", "isOpen=$isOpen, pdfRenderer=${pdfRenderer != null}, totalPages=$totalPages")
        
        if (!isOpen || pdfRenderer == null) {
            android.util.Log.e("PdfReader", "Cannot render: PDF not open (isOpen=$isOpen, pdfRenderer=${pdfRenderer != null})")
            return null
        }
        
        if (pageIndex < 0 || pageIndex >= totalPages) {
            android.util.Log.e("PdfReader", "Invalid page index for rendering: $pageIndex (totalPages=$totalPages)")
            return null
        }
        
        // Check cache first
        pageCache[pageIndex]?.let { cachedBitmap ->
            if (!cachedBitmap.isRecycled) {
                android.util.Log.d("PdfReader", "Returning cached page $pageIndex")
                return cachedBitmap
            } else {
                pageCache.remove(pageIndex)
            }
        }
        
        var page: PdfRenderer.Page? = null
        try {
            // Close previous page if open
            currentPage?.close()
            currentPage = null
            
            // Open the requested page
            page = pdfRenderer?.openPage(pageIndex)
            
            page?.let {
                // Create bitmap with page dimensions using ARGB_8888 (required by PdfRenderer)
                val bitmap = Bitmap.createBitmap(
                    it.width,
                    it.height,
                    Bitmap.Config.ARGB_8888
                )
                
                // Render page to bitmap
                it.render(
                    bitmap,
                    null,
                    null,
                    PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
                )
                
                // Close the page immediately after rendering
                it.close()
                
                // Add to cache
                addToCache(pageIndex, bitmap)
                
                android.util.Log.d("PdfReader", "Rendered page $pageIndex (${it.width}x${it.height})")
                
                return bitmap
            }
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error rendering page $pageIndex: ${e.message}", e)
            android.util.Log.e("PdfReader", "Error type: ${e.javaClass.simpleName}")
            android.util.Log.e("PdfReader", "Stack trace: ${e.stackTraceToString()}")
            // Make sure to close the page even if there's an error
            try {
                page?.close()
            } catch (closeError: Exception) {
                android.util.Log.e("PdfReader", "Error closing page after render error", closeError)
            }
        }
        
        android.util.Log.e("PdfReader", "renderPage returning null for page $pageIndex")
        return null
    }
    
    /**
     * Render the current page
     * @return Rendered bitmap or null if rendering fails
     */
    fun renderCurrentPage(): Bitmap? {
        return renderPage(currentPageIndex)
    }
    
    /**
     * Pre-load adjacent pages for smoother navigation
     */
    fun preloadAdjacentPages() {
        coroutineScope.launch(Dispatchers.IO) {
            // Pre-load next page
            if (currentPageIndex < totalPages - 1) {
                renderPage(currentPageIndex + 1)
            }
            
            // Pre-load previous page
            if (currentPageIndex > 0) {
                renderPage(currentPageIndex - 1)
            }
        }
    }
    
    /**
     * Add a rendered page to the cache
     * Manages cache size by removing oldest entries
     */
    private fun addToCache(pageIndex: Int, bitmap: Bitmap) {
        // Remove oldest entry if cache is full
        if (pageCache.size >= maxCacheSize) {
            val oldestKey = pageCache.keys.minOrNull()
            oldestKey?.let { key ->
                pageCache[key]?.let { oldBitmap ->
                    if (!oldBitmap.isRecycled) {
                        oldBitmap.recycle()
                    }
                }
                pageCache.remove(key)
            }
        }
        
        pageCache[pageIndex] = bitmap
    }
    
    /**
     * Clear the page cache
     */
    fun clearCache() {
        pageCache.values.forEach { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        pageCache.clear()
        android.util.Log.d("PdfReader", "Page cache cleared")
    }
    
    // ========== Task 37: Performance Optimization Methods ==========
    
    /**
     * Clear the thumbnail cache
     * Task 37: Thumbnail cache management
     */
    private fun clearThumbnailCache() {
        thumbnailCache.values.forEach { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        thumbnailCache.clear()
        android.util.Log.d("PdfReader", "Thumbnail cache cleared")
    }
    
    /**
     * Render a thumbnail for a page
     * Task 37: Thumbnail cache for page navigation
     * 
     * @param pageIndex Zero-based page index
     * @return Thumbnail bitmap or null if rendering fails
     */
    fun renderThumbnail(pageIndex: Int): Bitmap? {
        if (!isOpen || pdfRenderer == null) {
            android.util.Log.w("PdfReader", "Cannot render thumbnail: PDF not open")
            return null
        }
        
        if (pageIndex < 0 || pageIndex >= totalPages) {
            android.util.Log.w("PdfReader", "Invalid page index for thumbnail: $pageIndex")
            return null
        }
        
        // Check cache first
        thumbnailCache[pageIndex]?.let { cachedThumbnail ->
            if (!cachedThumbnail.isRecycled) {
                return cachedThumbnail
            } else {
                thumbnailCache.remove(pageIndex)
            }
        }
        
        var page: PdfRenderer.Page? = null
        try {
            // Close any currently open page first
            currentPage?.close()
            currentPage = null
            
            page = pdfRenderer?.openPage(pageIndex) ?: return null
            
            // Calculate thumbnail dimensions
            val thumbnailWidth = (page.width * thumbnailScale).toInt()
            val thumbnailHeight = (page.height * thumbnailScale).toInt()
            
            // Create small bitmap for thumbnail
            // IMPORTANT: Must use ARGB_8888 - RGB_565 is not supported by PdfRenderer
            val thumbnail = Bitmap.createBitmap(
                thumbnailWidth,
                thumbnailHeight,
                Bitmap.Config.ARGB_8888  // Changed from RGB_565 to fix "Unsupported pixel format" error
            )
            
            // Render page to thumbnail
            page.render(
                thumbnail,
                null,
                null,
                PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
            )
            
            // Close the page immediately after rendering
            page.close()
            page = null
            
            // Add to cache
            addToThumbnailCache(pageIndex, thumbnail)
            
            return thumbnail
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error rendering thumbnail for page $pageIndex", e)
            // Make sure to close the page even if there's an error
            try {
                page?.close()
            } catch (closeError: Exception) {
                android.util.Log.e("PdfReader", "Error closing page after thumbnail error", closeError)
            }
            return null
        }
    }
    
    /**
     * Add a thumbnail to the cache
     * Task 37: Thumbnail cache management
     */
    private fun addToThumbnailCache(pageIndex: Int, thumbnail: Bitmap) {
        // Remove oldest entry if cache is full
        if (thumbnailCache.size >= maxThumbnailCacheSize) {
            val oldestKey = thumbnailCache.keys.minOrNull()
            oldestKey?.let { key ->
                thumbnailCache[key]?.let { oldThumbnail ->
                    if (!oldThumbnail.isRecycled) {
                        oldThumbnail.recycle()
                    }
                }
                thumbnailCache.remove(key)
            }
        }
        
        thumbnailCache[pageIndex] = thumbnail
    }
    
    /**
     * Start background thumbnail generation for fast navigation
     * Task 37: Thumbnail cache for page navigation
     */
    private fun startBackgroundThumbnailGeneration() {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                android.util.Log.i("PdfReader", "Starting background thumbnail generation for $totalPages pages")
                
                // Generate thumbnails in batches to avoid memory pressure
                val batchSize = 10
                var generatedCount = 0
                
                for (i in 0 until totalPages step batchSize) {
                    // Check memory before each batch
                    if (MemoryManager.isMemoryPressureDetected()) {
                        android.util.Log.w("PdfReader", "Stopping thumbnail generation due to memory pressure")
                        break
                    }
                    
                    // Generate batch
                    val endIndex = minOf(i + batchSize, totalPages)
                    for (pageIndex in i until endIndex) {
                        renderThumbnail(pageIndex)
                        generatedCount++
                    }
                    
                    // Small delay between batches to avoid blocking
                    kotlinx.coroutines.delay(100)
                }
                
                android.util.Log.i("PdfReader", "Background thumbnail generation complete: $generatedCount/$totalPages thumbnails")
            } catch (e: Exception) {
                android.util.Log.e("PdfReader", "Error in background thumbnail generation", e)
            }
        }
    }
    
    /**
     * Render page with progressive rendering (low-res first, then high-res)
     * Task 37: Progressive rendering (low-res first)
     * 
     * @param pageIndex Zero-based page index
     * @param onLowResReady Callback when low-res version is ready
     * @param onHighResReady Callback when high-res version is ready
     */
    fun renderPageProgressive(
        pageIndex: Int,
        onLowResReady: ((Bitmap) -> Unit)? = null,
        onHighResReady: ((Bitmap) -> Unit)? = null
    ) {
        if (!isOpen || pdfRenderer == null || !isProgressiveRenderingEnabled) {
            // Fall back to regular rendering
            val bitmap = renderPage(pageIndex)
            if (bitmap != null) {
                onHighResReady?.invoke(bitmap)
            }
            return
        }
        
        coroutineScope.launch(Dispatchers.IO) {
            try {
                val page = pdfRenderer?.openPage(pageIndex) ?: return@launch
                
                // Step 1: Render low-res version quickly
                val lowResWidth = (page.width * progressiveRenderScale).toInt()
                val lowResHeight = (page.height * progressiveRenderScale).toInt()
                
                val lowResBitmap = Bitmap.createBitmap(
                    lowResWidth,
                    lowResHeight,
                    Bitmap.Config.RGB_565 // Faster rendering
                )
                
                page.render(
                    lowResBitmap,
                    null,
                    null,
                    PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
                )
                
                // Notify low-res ready
                withContext(Dispatchers.Main) {
                    onLowResReady?.invoke(lowResBitmap)
                }
                
                // Step 2: Render high-res version
                val highResBitmap = Bitmap.createBitmap(
                    page.width,
                    page.height,
                    Bitmap.Config.ARGB_8888
                )
                
                page.render(
                    highResBitmap,
                    null,
                    null,
                    PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
                )
                
                page.close()
                
                // Add to cache
                addToCache(pageIndex, highResBitmap)
                
                // Notify high-res ready
                withContext(Dispatchers.Main) {
                    onHighResReady?.invoke(highResBitmap)
                }
                
                // Recycle low-res bitmap
                if (!lowResBitmap.isRecycled) {
                    lowResBitmap.recycle()
                }
                
            } catch (e: Exception) {
                android.util.Log.e("PdfReader", "Error in progressive rendering for page $pageIndex", e)
            }
        }
    }
    
    /**
     * Render a tile of a page for large pages
     * Task 37: Tile-based rendering for large pages
     * 
     * @param pageIndex Zero-based page index
     * @param tileX Tile X coordinate (in tile units)
     * @param tileY Tile Y coordinate (in tile units)
     * @param zoom Zoom level
     * @return Rendered tile bitmap or null if rendering fails
     */
    fun renderPageTile(pageIndex: Int, tileX: Int, tileY: Int, zoom: Float = 1.0f): Bitmap? {
        if (!isOpen || pdfRenderer == null || !isTileRenderingEnabled) {
            return null
        }
        
        if (pageIndex < 0 || pageIndex >= totalPages) {
            android.util.Log.w("PdfReader", "Invalid page index for tile rendering: $pageIndex")
            return null
        }
        
        try {
            val page = pdfRenderer?.openPage(pageIndex) ?: return null
            
            // Calculate tile dimensions with zoom
            val scaledTileSize = (tileSize * zoom).toInt()
            val pageWidth = (page.width * zoom).toInt()
            val pageHeight = (page.height * zoom).toInt()
            
            // Calculate tile bounds
            val tileLeft = tileX * scaledTileSize
            val tileTop = tileY * scaledTileSize
            val tileRight = minOf(tileLeft + scaledTileSize, pageWidth)
            val tileBottom = minOf(tileTop + scaledTileSize, pageHeight)
            
            // Check if tile is within page bounds
            if (tileLeft >= pageWidth || tileTop >= pageHeight) {
                page.close()
                return null
            }
            
            // Calculate actual tile dimensions
            val actualTileWidth = tileRight - tileLeft
            val actualTileHeight = tileBottom - tileTop
            
            // Create bitmap for tile
            val tileBitmap = Bitmap.createBitmap(
                actualTileWidth,
                actualTileHeight,
                Bitmap.Config.ARGB_8888
            )
            
            // Create clip rect for the tile
            val clipRect = android.graphics.Rect(tileLeft, tileTop, tileRight, tileBottom)
            
            // Render the tile
            page.render(
                tileBitmap,
                clipRect,
                null,
                PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
            )
            
            page.close()
            
            android.util.Log.d("PdfReader", "Rendered tile ($tileX, $tileY) for page $pageIndex at ${zoom}x zoom")
            
            return tileBitmap
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error rendering tile for page $pageIndex", e)
            return null
        }
    }
    
    /**
     * Check if a page should use tile-based rendering
     * Task 37: Tile-based rendering for large pages
     * 
     * @param pageIndex Zero-based page index
     * @return true if page is large enough to benefit from tiling
     */
    fun shouldUseTileRendering(pageIndex: Int): Boolean {
        if (!isOpen || pdfRenderer == null) {
            return false
        }
        
        try {
            val page = pdfRenderer?.openPage(pageIndex)
            val shouldTile = page != null && (page.width > 2048 || page.height > 2048)
            page?.close()
            return shouldTile
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error checking tile rendering for page $pageIndex", e)
            return false
        }
    }
    
    /**
     * Get page dimensions
     * Task 37: Helper for tile-based rendering
     * 
     * @param pageIndex Zero-based page index
     * @return Pair of (width, height) or null if page cannot be accessed
     */
    fun getPageDimensions(pageIndex: Int): Pair<Int, Int>? {
        if (!isOpen || pdfRenderer == null) {
            return null
        }
        
        if (pageIndex < 0 || pageIndex >= totalPages) {
            return null
        }
        
        try {
            val page = pdfRenderer?.openPage(pageIndex)
            val dimensions = page?.let { Pair(it.width, it.height) }
            page?.close()
            return dimensions
        } catch (e: Exception) {
            android.util.Log.e("PdfReader", "Error getting page dimensions for page $pageIndex", e)
            return null
        }
    }
    
    /**
     * Enable or disable progressive rendering
     * Task 37: Progressive rendering control
     */
    fun setProgressiveRenderingEnabled(enabled: Boolean) {
        isProgressiveRenderingEnabled = enabled
        android.util.Log.d("PdfReader", "Progressive rendering ${if (enabled) "enabled" else "disabled"}")
    }
    
    /**
     * Enable or disable tile-based rendering
     * Task 37: Tile-based rendering control
     */
    fun setTileRenderingEnabled(enabled: Boolean) {
        isTileRenderingEnabled = enabled
        android.util.Log.d("PdfReader", "Tile-based rendering ${if (enabled) "enabled" else "disabled"}")
    }
    
    /**
     * Get rendering performance statistics
     * Task 37: Monitor and manage memory usage
     */
    fun getRenderingStats(): Map<String, Any> {
        val memoryStats = MemoryManager.getMemoryStats()
        
        return mapOf(
            "total_pages" to totalPages,
            "current_page" to currentPageIndex,
            "page_cache_size" to pageCache.size,
            "thumbnail_cache_size" to thumbnailCache.size,
            "memory_used_mb" to memoryStats.usedMemoryMB,
            "memory_max_mb" to memoryStats.maxMemoryMB,
            "memory_usage_percent" to (memoryStats.usagePercentage * 100).toInt(),
            "memory_pressure_level" to memoryStats.pressureLevel.name,
            "progressive_rendering_enabled" to isProgressiveRenderingEnabled,
            "tile_rendering_enabled" to isTileRenderingEnabled
        )
    }
    
    /**
     * Log rendering performance statistics
     * Task 37: Monitor and manage memory usage
     */
    fun logRenderingStats() {
        val stats = getRenderingStats()
        android.util.Log.i("PdfReader", "=== PDF Rendering Statistics ===")
        android.util.Log.i("PdfReader", "Total Pages: ${stats["total_pages"]}")
        android.util.Log.i("PdfReader", "Current Page: ${stats["current_page"]}")
        android.util.Log.i("PdfReader", "Page Cache: ${stats["page_cache_size"]} pages")
        android.util.Log.i("PdfReader", "Thumbnail Cache: ${stats["thumbnail_cache_size"]} thumbnails")
        android.util.Log.i("PdfReader", "Memory: ${stats["memory_used_mb"]}MB / ${stats["memory_max_mb"]}MB (${stats["memory_usage_percent"]}%)")
        android.util.Log.i("PdfReader", "Memory Pressure: ${stats["memory_pressure_level"]}")
        android.util.Log.i("PdfReader", "Progressive Rendering: ${stats["progressive_rendering_enabled"]}")
        android.util.Log.i("PdfReader", "Tile Rendering: ${stats["tile_rendering_enabled"]}")
        android.util.Log.i("PdfReader", "================================")
    }
    
    // ========== Event Emission Methods ==========
    
    /**
     * Emit reader ready event to Flutter
     * Requirement 6.2: Emit onReaderReady with total page count
     */
    private fun emitReaderReadyEvent() {
        val event = mapOf(
            "type" to "ready",
            "session_id" to sessionId,
            "total_pages" to totalPages,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted reader ready event: $totalPages pages")
    }
    
    /**
     * Emit page turn event to Flutter
     * Requirement 6.3: Emit page_turn events for navigation tracking
     */
    private fun emitPageTurnEvent() {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "page_turn",
            "page_index" to currentPageIndex,
            "total_pages" to totalPages,
            "progress" to getProgress(),
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted page turn event: page $currentPageIndex of $totalPages")
    }
    
    /**
     * Emit session end event when closing the reader
     */
    private fun emitSessionEndEvent() {
        val sessionDuration = System.currentTimeMillis() - sessionStartTime
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "session_end",
            "final_page_index" to currentPageIndex,
            "session_duration" to sessionDuration,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted session end event: duration ${sessionDuration}ms")
    }
    
    /**
     * Emit open event when PDF is first opened
     */
    private fun emitOpenEvent() {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "open",
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted open event")
    }
    
    /**
     * Emit zoom change event
     * Tracks zoom level changes for analytics
     */
    private fun emitZoomChangeEvent() {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "zoom_change",
            "zoom_level" to currentZoomLevel,
            "page_index" to currentPageIndex,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted zoom change event: ${currentZoomLevel}x")
    }
    
    // ========== Text Selection Methods ==========
    
    /**
     * Check if current page contains selectable text
     * Requirement 6.9: Text selection support
     * 
     * Note: Android PdfRenderer does not provide direct text extraction.
     * For full text selection support, a library like PDFBox or MuPDF would be needed.
     * This is a placeholder implementation that indicates the feature is not fully supported.
     * 
     * @return false (PdfRenderer does not support text extraction)
     */
    fun hasSelectableText(): Boolean {
        // Android PdfRenderer renders pages as bitmaps and does not provide text extraction
        // To support text selection, we would need to integrate a different PDF library
        // such as PDFBox, MuPDF, or PSPDFKit
        android.util.Log.w("PdfReader", "Text selection not supported with PdfRenderer")
        return false
    }
    
    /**
     * Get text from current page
     * Requirement 6.9: Text selection support
     * 
     * Note: This is a placeholder. PdfRenderer does not support text extraction.
     * 
     * @return null (not supported)
     */
    fun getPageText(): String? {
        android.util.Log.w("PdfReader", "Text extraction not supported with PdfRenderer")
        return null
    }
    
    /**
     * Select text in a region
     * Requirement 6.9: Text selection support
     * 
     * Note: This is a placeholder. PdfRenderer does not support text selection.
     * 
     * @param startX Start X coordinate
     * @param startY Start Y coordinate
     * @param endX End X coordinate
     * @param endY End Y coordinate
     * @return null (not supported)
     */
    fun selectText(startX: Float, startY: Float, endX: Float, endY: Float): String? {
        android.util.Log.w("PdfReader", "Text selection not supported with PdfRenderer")
        return null
    }
    
    /**
     * Copy selected text to clipboard
     * Requirement 6.9: Text selection support
     * 
     * Note: This is a placeholder. PdfRenderer does not support text selection.
     * 
     * @return false (not supported)
     */
    fun copySelectedText(): Boolean {
        android.util.Log.w("PdfReader", "Text copying not supported with PdfRenderer")
        return false
    }
    
    /**
     * Emit text selection event
     * Tracks text selection for analytics
     */
    private fun emitTextSelectionEvent(selectedText: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "text_selection",
            "page_index" to currentPageIndex,
            "text_length" to selectedText.length,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
        android.util.Log.d("PdfReader", "Emitted text selection event")
    }
}
