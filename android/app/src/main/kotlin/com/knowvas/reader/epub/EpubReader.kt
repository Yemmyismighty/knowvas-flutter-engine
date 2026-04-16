package com.knowvas.reader.epub

import android.content.Context
import io.flutter.plugin.common.EventChannel
import com.knowvas.reader.BaseReader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.readium.r2.shared.publication.Publication
import org.readium.r2.shared.publication.asset.FileAsset
import org.readium.r2.streamer.Streamer
import java.io.File

/**
 * EPUB reader implementation using Readium Mobile Android
 * Handles EPUB parsing, rendering, and user interactions
 */
class EpubReader(
    private val context: Context,
    private var eventSink: EventChannel.EventSink?,
    private val sessionId: String
) : BaseReader {

    private var publication: Publication? = null
    private var streamer: Streamer? = null
    private var currentPage: Int = 0
    private var totalPages: Int = 0
    private var isOpen: Boolean = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    // Reader settings manager
    private val settings: EpubSettings = EpubSettings()
    
    // Chapter cache for lazy loading and memory optimization
    private var chapterCache: ChapterCache? = null
    
    // Memory monitoring timer
    private var memoryMonitor: java.util.Timer? = null
    
    // Interaction handler for bookmarks, highlights, and notes
    private val interactionHandler: EpubInteractionHandler by lazy {
        EpubInteractionHandler(context, sessionId) { event ->
            emitEvent(event)
        }
    }
    
    // Audio player for media overlays - TEMPORARILY DISABLED
    // TODO: Re-enable after fixing EpubAudioPlayer compilation issues
    // private val audioPlayer: EpubAudioPlayer by lazy {
    //     EpubAudioPlayer(context, sessionId) { event ->
    //         emitEvent(event)
    //     }
    // }
    
    // Controls visibility state
    private var controlsVisible: Boolean = false

    override fun open(fileUrl: String, token: String, callback: (Boolean, String?) -> Unit) {
        coroutineScope.launch {
            val startTime = System.currentTimeMillis()
            
            try {
                // Log initial memory state
                com.knowvas.reader.utils.MemoryManager.logMemoryStats("EpubReader-Open")
                
                // Check if file can be safely loaded
                val file = File(fileUrl)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        callback(false, "File not found: $fileUrl")
                    }
                    return@launch
                }
                
                val fileSizeBytes = file.length()
                val fileSizeMB = fileSizeBytes / (1024 * 1024)
                android.util.Log.i("EpubReader", "Opening EPUB file: ${fileSizeMB}MB")
                
                // Check memory availability for large files
                if (fileSizeMB > 50 && !com.knowvas.reader.utils.MemoryManager.canLoadFile(fileSizeBytes)) {
                    android.util.Log.w("EpubReader", "Insufficient memory for large EPUB, triggering cleanup")
                    com.knowvas.reader.utils.MemoryManager.forceCleanup()
                    
                    // Check again after cleanup
                    if (!com.knowvas.reader.utils.MemoryManager.canLoadFile(fileSizeBytes)) {
                        withContext(Dispatchers.Main) {
                            callback(false, "Insufficient memory to open this EPUB (${fileSizeMB}MB)")
                        }
                        return@launch
                    }
                }

                // Initialize Readium Streamer
                streamer = Streamer(context)

                // Open the EPUB using Readium Streamer
                try {
                    android.util.Log.i("EpubReader", "Opening EPUB with Readium Streamer...")
                    
                    // Open the EPUB file with Readium
                    // Readium returns a Try<Publication> which is a Result wrapper
                    val result = withContext(Dispatchers.IO) {
                        streamer!!.open(
                            asset = FileAsset(file),
                            allowUserInteraction = false
                        )
                    }
                    
                    // Check if opening was successful
                    if (result == null) {
                        android.util.Log.e("EpubReader", "Streamer returned null")
                        withContext(Dispatchers.Main) {
                            callback(false, "Failed to open EPUB file")
                        }
                        return@launch
                    }
                    
                    // Extract publication from Try<Publication> result
                    publication = result.getOrNull()
                    
                    if (publication == null) {
                        val error = result.exceptionOrNull()
                        android.util.Log.e("EpubReader", "Failed to open EPUB", error)
                        withContext(Dispatchers.Main) {
                            callback(false, "Failed to parse EPUB: ${error?.message ?: "Unknown error"}")
                        }
                        return@launch
                    }
                    
                    android.util.Log.i("EpubReader", "EPUB opened successfully: ${publication?.metadata?.title}")
                    
                    // Store publication in ReaderManager for ReaderActivity to access
                    publication?.let { pub ->
                        com.knowvas.reader.ReaderManager.storePublication(sessionId, pub)
                    }
                    
                } catch (e: Exception) {
                    android.util.Log.e("EpubReader", "Exception opening EPUB", e)
                    withContext(Dispatchers.Main) {
                        callback(false, "Failed to open EPUB: ${e.message}")
                    }
                    return@launch
                }

                // Get total page count (reading order items)
                totalPages = publication?.readingOrder?.size ?: 0
                currentPage = 0
                isOpen = true
                
                // Initialize chapter cache for lazy loading
                publication?.let { pub ->
                    chapterCache = ChapterCache(pub, coroutineScope)
                    android.util.Log.i("EpubReader", "Chapter cache initialized for $totalPages chapters")
                }
                
                // Initialize audio player with publication - TEMPORARILY DISABLED
                // publication?.let { pub ->
                //     audioPlayer.initialize(pub)
                // }
                
                // Start memory monitoring for large EPUBs
                if (fileSizeMB > 50) {
                    startMemoryMonitoring()
                }

                // Calculate and log open time
                val openTime = System.currentTimeMillis() - startTime
                android.util.Log.i("EpubReader", "EPUB opened in ${openTime}ms (target: 2000-4000ms)")
                
                // Emit reader ready event
                emitReaderReadyEvent()
                
                // Log final memory state
                com.knowvas.reader.utils.MemoryManager.logMemoryStats("EpubReader-Ready")

                withContext(Dispatchers.Main) {
                    callback(true, null)
                }
            } catch (e: Exception) {
                android.util.Log.e("EpubReader", "Error opening EPUB", e)
                withContext(Dispatchers.Main) {
                    callback(false, "Exception opening EPUB: ${e.message}")
                }
            }
        }
    }

    override fun close() {
        if (isOpen) {
            emitSessionEndEvent()
            
            // Stop memory monitoring
            stopMemoryMonitoring()
            
            // Log cache statistics before closing
            chapterCache?.logCacheStats()
            
            // Release chapter cache
            chapterCache?.release()
            chapterCache = null
            
            // Release audio player - TEMPORARILY DISABLED
            // // audioPlayer.release() // Temporarily disabled
            
            // Clean up resources
            publication = null
            streamer = null
            isOpen = false
            currentPage = 0
            totalPages = 0
            
            // Clear interactions
            interactionHandler.clearAll()
            
            // Log final memory state
            com.knowvas.reader.utils.MemoryManager.logMemoryStats("EpubReader-Close")
        }
    }

    override fun setPreferences(preferences: Map<*, *>) {
        // Update settings from the preferences map
        settings.updateFromMap(preferences)
        
        // Apply settings to the reader in real-time
        applySettings()
        
        // Emit event to notify Flutter that settings were applied
        emitSettingsChangedEvent()
    }
    
    /**
     * Apply current settings to the Readium navigator
     * This updates the rendering in real-time without closing the reader
     */
    private fun applySettings() {
        if (!isOpen || publication == null) {
            return
        }
        
        coroutineScope.launch {
            try {
                // Generate CSS from current settings
                val customCSS = settings.generateCSS()
                
                // In a full implementation, this would inject the CSS into the Readium navigator
                // For now, we log the settings that would be applied
                android.util.Log.d("EpubReader", "Applying settings: $settings")
                android.util.Log.d("EpubReader", "Generated CSS: $customCSS")
                
                // Note: Actual CSS injection would require access to the navigator's WebView
                // This would typically be done through Readium's preferences API or
                // by injecting JavaScript into the WebView
                
                // Example of what the full implementation would look like:
                // navigator?.apply {
                //     injectCSS(customCSS)
                //     setBackgroundColor(settings.theme.backgroundColor)
                //     setTextColor(settings.theme.textColor)
                // }
                
            } catch (e: Exception) {
                android.util.Log.e("EpubReader", "Error applying settings: ${e.message}")
                emitError("SETTINGS_ERROR", "Failed to apply settings: ${e.message}")
            }
        }
    }
    
    /**
     * Get current settings
     */
    fun getSettings(): EpubSettings = settings.copy()
    
    /**
     * Get settings as a map
     */
    fun getSettingsMap(): Map<String, Any> = settings.toMap()

    override fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    /**
     * Navigate to a specific page
     * Uses lazy loading to load chapter content on demand
     */
    fun goToPage(pageIndex: Int) {
        if (!isOpen || pageIndex < 0 || pageIndex >= totalPages) {
            return
        }

        currentPage = pageIndex
        
        // Lazy load chapter content in background
        coroutineScope.launch {
            try {
                val content = loadChapterContent(pageIndex)
                if (content != null) {
                    android.util.Log.d("EpubReader", "Chapter $pageIndex loaded (${content.length} chars)")
                } else {
                    android.util.Log.w("EpubReader", "Failed to load chapter $pageIndex")
                }
            } catch (e: Exception) {
                android.util.Log.e("EpubReader", "Error in lazy loading for page $pageIndex", e)
            }
        }
        
        emitPageTurnEvent(pageIndex)
    }

    /**
     * Get the current publication
     */
    fun getPublication(): Publication? = publication

    /**
     * Get current page index
     */
    fun getCurrentPage(): Int = currentPage

    /**
     * Get total page count
     */
    fun getTotalPages(): Int = totalPages

    // Event emission methods

    private fun emitReaderReadyEvent() {
        val event = mapOf(
            "type" to "ready",
            "session_id" to sessionId,
            "total_pages" to totalPages,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    private fun emitPageTurnEvent(pageIndex: Int) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "page_turn",
            "page_index" to pageIndex,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    private fun emitSessionEndEvent() {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "session_end",
            "page_index" to currentPage,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    fun emitBookmarkEvent(pageNumber: Int, action: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "bookmark",
            "page_number" to pageNumber,
            "action" to action,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    fun emitHighlightEvent(pageNumber: Int, text: String, color: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "highlight",
            "page_number" to pageNumber,
            "highlighted_text" to text,
            "color" to color,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    fun emitError(code: String, message: String) {
        val event = mapOf(
            "type" to "error",
            "session_id" to sessionId,
            "code" to code,
            "message" to message,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }
    
    private fun emitSettingsChangedEvent() {
        val event = mapOf(
            "type" to "settings_changed",
            "session_id" to sessionId,
            "settings" to settings.toMap(),
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }

    override fun emitEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }
    
    // ========== Control Methods ==========
    
    /**
     * Toggle controls visibility
     * Emits event to notify Flutter about visibility change
     */
    fun toggleControls(): Boolean {
        controlsVisible = !controlsVisible
        emitControlsVisibilityEvent(controlsVisible)
        return controlsVisible
    }
    
    /**
     * Set controls visibility explicitly
     */
    fun setControlsVisible(visible: Boolean) {
        if (controlsVisible != visible) {
            controlsVisible = visible
            emitControlsVisibilityEvent(visible)
        }
    }
    
    /**
     * Get current controls visibility state
     */
    fun areControlsVisible(): Boolean = controlsVisible
    
    // ========== Bookmark Methods ==========
    
    /**
     * Add bookmark at current page
     */
    fun addBookmark(): Boolean {
        if (!isOpen) return false
        
        val locator = getCurrentLocator()
        interactionHandler.addBookmark(currentPage, locator)
        return true
    }
    
    /**
     * Add bookmark at specific page
     */
    fun addBookmarkAtPage(pageNumber: Int): Boolean {
        if (!isOpen || pageNumber < 0 || pageNumber >= totalPages) return false
        
        val locator = getLocatorForPage(pageNumber)
        interactionHandler.addBookmark(pageNumber, locator)
        return true
    }
    
    /**
     * Remove bookmark at current page
     */
    fun removeBookmark(): Boolean {
        if (!isOpen) return false
        return interactionHandler.removeBookmarkAtPage(currentPage)
    }
    
    /**
     * Remove bookmark at specific page
     */
    fun removeBookmarkAtPage(pageNumber: Int): Boolean {
        return interactionHandler.removeBookmarkAtPage(pageNumber)
    }
    
    /**
     * Toggle bookmark at current page
     */
    fun toggleBookmark(): Boolean {
        if (!isOpen) return false
        
        return if (interactionHandler.hasBookmarkAtPage(currentPage)) {
            removeBookmark()
            false
        } else {
            addBookmark()
            true
        }
    }
    
    /**
     * Check if current page has a bookmark
     */
    fun hasBookmark(): Boolean {
        if (!isOpen) return false
        return interactionHandler.hasBookmarkAtPage(currentPage)
    }
    
    /**
     * Get all bookmarks
     */
    fun getBookmarks(): List<Map<String, Any>> {
        return interactionHandler.getBookmarks().map { bookmark ->
            mapOf(
                "id" to bookmark.id,
                "page_number" to bookmark.pageNumber,
                "timestamp" to bookmark.timestamp
            )
        }
    }
    
    // ========== Highlight Methods ==========
    
    /**
     * Add highlight for selected text
     */
    fun addHighlight(
        selectedText: String,
        color: String = "#FFFF00",
        startPosition: Int = 0,
        endPosition: Int = selectedText.length
    ): String? {
        if (!isOpen) return null
        
        val locator = getCurrentLocator()
        val highlight = interactionHandler.addHighlight(
            pageNumber = currentPage,
            selectedText = selectedText,
            color = color,
            locator = locator,
            startPosition = startPosition,
            endPosition = endPosition
        )
        
        return highlight.id
    }
    
    /**
     * Remove highlight by ID
     */
    fun removeHighlight(highlightId: String): Boolean {
        return interactionHandler.removeHighlight(highlightId)
    }
    
    /**
     * Get all highlights
     */
    fun getHighlights(): List<Map<String, Any>> {
        return interactionHandler.getHighlights().map { highlight ->
            mapOf(
                "id" to highlight.id,
                "page_number" to highlight.pageNumber,
                "selected_text" to highlight.selectedText,
                "color" to highlight.color,
                "start_position" to highlight.startPosition,
                "end_position" to highlight.endPosition,
                "timestamp" to highlight.timestamp
            )
        }
    }
    
    /**
     * Get highlights for current page
     */
    fun getHighlightsForCurrentPage(): List<Map<String, Any>> {
        if (!isOpen) return emptyList()
        
        return interactionHandler.getHighlightsForPage(currentPage).map { highlight ->
            mapOf(
                "id" to highlight.id,
                "page_number" to highlight.pageNumber,
                "selected_text" to highlight.selectedText,
                "color" to highlight.color,
                "start_position" to highlight.startPosition,
                "end_position" to highlight.endPosition,
                "timestamp" to highlight.timestamp
            )
        }
    }
    
    // ========== Note Methods ==========
    
    /**
     * Add note at current page
     */
    fun addNote(noteText: String): String? {
        if (!isOpen) return null
        
        val locator = getCurrentLocator()
        val note = interactionHandler.addNote(currentPage, noteText, locator)
        return note.id
    }
    
    /**
     * Remove note by ID
     */
    fun removeNote(noteId: String): Boolean {
        return interactionHandler.removeNote(noteId)
    }
    
    /**
     * Get all notes
     */
    fun getNotes(): List<Map<String, Any>> {
        return interactionHandler.getNotes().map { note ->
            mapOf(
                "id" to note.id,
                "page_number" to note.pageNumber,
                "note_text" to note.noteText,
                "timestamp" to note.timestamp
            )
        }
    }
    
    // ========== Text Selection Methods ==========
    
    /**
     * Handle text selection and return available actions
     */
    fun handleTextSelection(
        selectedText: String,
        startPosition: Int,
        endPosition: Int
    ): List<String> {
        if (!isOpen) return emptyList()
        
        val locator = getCurrentLocator()
        return interactionHandler.handleTextSelection(
            pageNumber = currentPage,
            selectedText = selectedText,
            locator = locator,
            startPosition = startPosition,
            endPosition = endPosition
        )
    }
    
    // ========== Navigation Methods ==========
    
    /**
     * Navigate to next page
     */
    fun nextPage(): Boolean {
        if (!isOpen || currentPage >= totalPages - 1) return false
        
        currentPage++
        emitPageTurnEvent(currentPage)
        return true
    }
    
    /**
     * Navigate to previous page
     */
    fun previousPage(): Boolean {
        if (!isOpen || currentPage <= 0) return false
        
        currentPage--
        emitPageTurnEvent(currentPage)
        return true
    }
    
    /**
     * Get reading progress as percentage (0.0 to 1.0)
     */
    fun getProgress(): Double {
        if (!isOpen || totalPages == 0) return 0.0
        return currentPage.toDouble() / totalPages.toDouble()
    }
    
    /**
     * Set reading progress (0.0 to 1.0)
     */
    fun setProgress(progress: Double) {
        if (!isOpen || totalPages == 0) return
        
        val targetPage = (progress * totalPages).toInt().coerceIn(0, totalPages - 1)
        goToPage(targetPage)
    }
    
    // ========== Audio Playback Methods - TEMPORARILY DISABLED ==========
    // TODO: Re-enable after fixing EpubAudioPlayer compilation issues
    
    /**
     * Check if current page has audio (media overlay)
     */
    fun hasAudio(): Boolean {
        // if (!isOpen) return false
        // val locator = getCurrentLocator()
        // return locator?.let { audioPlayer.hasAudio(it) } ?: false
        return false // Temporarily disabled
    }
    
    /**
     * Check if a specific page has audio
     */
    fun hasAudioAtPage(pageNumber: Int): Boolean {
        // if (!isOpen || pageNumber < 0 || pageNumber >= totalPages) return false
        // val locator = getLocatorForPage(pageNumber)
        // return locator?.let { audioPlayer.hasAudio(it) } ?: false
        return false // Temporarily disabled
    }
    
    /**
     * Load audio for current page
     * Returns true if audio was found and loading started
     */
    fun loadAudio(): Boolean {
        // Temporarily disabled
        return false
    }
    
    /**
     * Load audio for a specific page
     */
    fun loadAudioForPage(pageNumber: Int): Boolean {
        // Temporarily disabled
        return false
    }
    
    /**
     * Play audio
     */
    fun playAudio() {
        // audioPlayer.play() // Temporarily disabled
    }
    
    /**
     * Pause audio
     */
    fun pauseAudio() {
        // audioPlayer.pause() // Temporarily disabled
    }
    
    /**
     * Toggle audio play/pause
     */
    fun toggleAudioPlayPause() {
        // audioPlayer.togglePlayPause() // Temporarily disabled
    }
    
    /**
     * Seek audio to position in milliseconds
     */
    fun seekAudio(positionMs: Int) {
        // audioPlayer.seekTo(positionMs) // Temporarily disabled
    }
    
    /**
     * Get current audio playback position in milliseconds
     */
    fun getAudioPosition(): Int {
        return 0 // Temporarily disabled
    }
    
    /**
     * Get audio duration in milliseconds
     */
    fun getAudioDuration(): Int {
        return 0 // Temporarily disabled
    }
    
    /**
     * Check if audio is currently playing
     */
    fun isAudioPlaying(): Boolean {
        return false // Temporarily disabled
    }
    
    /**
     * Get audio playback progress (0.0 to 1.0)
     */
    fun getAudioProgress(): Double {
        return 0.0 // Temporarily disabled
    }
    
    /**
     * Set audio playback speed (0.5 to 2.0)
     */
    fun setAudioPlaybackSpeed(speed: Float) {
        // audioPlayer.setPlaybackSpeed(speed) // Temporarily disabled
    }
    
    /**
     * Stop audio playback and release resources
     */
    fun stopAudio() {
        // audioPlayer.release() // Temporarily disabled
    }
    
    /**
     * Get audio URL for a locator
     * This extracts the audio URL from media overlay or alternate links
     */
    private fun getAudioUrlForLocator(locator: org.readium.r2.shared.publication.Locator): String? {
        if (publication == null) return null
        
        // Find the link for this locator
        val link = publication?.readingOrder?.find { it.href == locator.href }
        
        // Check for media overlay property
        val mediaOverlay = link?.properties?.get("media-overlay")
        if (mediaOverlay != null) {
            // Media overlay typically references a SMIL file
            // In a full implementation, we would parse the SMIL file to get audio URLs
            // For now, we'll look for direct audio references
            
            // Try to find the media overlay resource
            val overlayHref = mediaOverlay.toString()
            val overlayLink = publication?.resources?.find { it.href == overlayHref }
            
            // In practice, you would parse the SMIL file here to extract audio URLs
            // For this implementation, we'll check for alternate audio links
        }
        
        // Check for alternate audio links
        val audioAlternate = link?.alternates?.find { 
            it.type?.contains("audio") == true 
        }
        
        if (audioAlternate != null) {
            // Construct full URL from the alternate link
            // This might need to be resolved relative to the publication
            return audioAlternate.href
        }
        
        // Check if there's a direct audio resource with the same base name
        val baseName = locator.href.substringBeforeLast(".")
        val audioResource = publication?.resources?.find { resource ->
            resource.href.startsWith(baseName) && 
            (resource.type?.contains("audio") == true)
        }
        
        return audioResource?.href
    }
    
    // ========== Helper Methods ==========
    
    /**
     * Get current locator (position in the publication)
     */
    private fun getCurrentLocator(): org.readium.r2.shared.publication.Locator? {
        if (!isOpen || publication == null) return null
        
        // In a full implementation, this would return the actual locator
        // from the Readium navigator. For now, we create a basic locator.
        val readingOrderItem = publication?.readingOrder?.getOrNull(currentPage)
        return readingOrderItem?.let { link ->
            org.readium.r2.shared.publication.Locator(
                href = link.href,
                type = link.type ?: "application/xhtml+xml",
                locations = org.readium.r2.shared.publication.Locator.Locations(
                    position = currentPage
                )
            )
        }
    }
    
    /**
     * Get locator for a specific page
     */
    private fun getLocatorForPage(pageNumber: Int): org.readium.r2.shared.publication.Locator? {
        if (!isOpen || publication == null) return null
        
        val readingOrderItem = publication?.readingOrder?.getOrNull(pageNumber)
        return readingOrderItem?.let { link ->
            org.readium.r2.shared.publication.Locator(
                href = link.href,
                type = link.type ?: "application/xhtml+xml",
                locations = org.readium.r2.shared.publication.Locator.Locations(
                    position = pageNumber
                )
            )
        }
    }
    
    // ========== Additional Event Emission Methods ==========
    
    private fun emitControlsVisibilityEvent(visible: Boolean) {
        val event = mapOf(
            "type" to "controls_visibility",
            "session_id" to sessionId,
            "visible" to visible,
            "timestamp" to System.currentTimeMillis()
        )
        emitEvent(event)
    }
    
    // ========== Memory Management Methods ==========
    
    /**
     * Start periodic memory monitoring
     * This monitors memory usage and triggers cleanup when needed
     */
    private fun startMemoryMonitoring() {
        if (memoryMonitor != null) {
            return // Already monitoring
        }
        
        android.util.Log.i("EpubReader", "Starting memory monitoring")
        
        memoryMonitor = com.knowvas.reader.utils.MemoryManager.startPeriodicMonitoring(
            intervalMs = 5000 // Check every 5 seconds
        ) { stats ->
            android.util.Log.d("EpubReader", "Memory: ${stats.usedMemoryMB}MB / ${stats.maxMemoryMB}MB " +
                    "(${String.format("%.1f", stats.usagePercentage * 100)}%) - ${stats.pressureLevel}")
            
            // Log cache stats periodically
            if (stats.pressureLevel != com.knowvas.reader.utils.MemoryManager.MemoryPressureLevel.NORMAL) {
                chapterCache?.logCacheStats()
            }
            
            // Check for memory leaks
            com.knowvas.reader.utils.MemoryManager.recordMemoryUsage()
            if (com.knowvas.reader.utils.MemoryManager.isMemoryLeaking()) {
                android.util.Log.w("EpubReader", "Potential memory leak detected! Trend: ${
                    com.knowvas.reader.utils.MemoryManager.getMemoryTrend()
                }")
            }
        }
    }
    
    /**
     * Stop memory monitoring
     */
    private fun stopMemoryMonitoring() {
        memoryMonitor?.cancel()
        memoryMonitor = null
        android.util.Log.i("EpubReader", "Stopped memory monitoring")
    }
    
    /**
     * Load chapter content using lazy loading
     * This is called when navigating to a page
     */
    private suspend fun loadChapterContent(chapterIndex: Int): String? {
        if (!isOpen || chapterCache == null) {
            return null
        }
        
        return try {
            val cachedChapter = chapterCache?.getChapter(chapterIndex)
            cachedChapter?.content
        } catch (e: Exception) {
            android.util.Log.e("EpubReader", "Error loading chapter $chapterIndex", e)
            null
        }
    }
    
    /**
     * Get chapter cache statistics
     */
    fun getChapterCacheStats(): Map<String, Any>? {
        return chapterCache?.getCacheStats()
    }
    
    /**
     * Manually trigger cache cleanup
     * Useful for testing or when app receives memory warning
     */
    fun triggerCacheCleanup() {
        android.util.Log.i("EpubReader", "Manual cache cleanup triggered")
        chapterCache?.onCleanupRequested()
    }
    
    /**
     * Clear chapter cache completely
     */
    fun clearChapterCache() {
        android.util.Log.i("EpubReader", "Clearing chapter cache")
        chapterCache?.clearCache()
    }
}
