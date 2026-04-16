package com.knowvas.reader.epub

import android.content.Context
import android.util.Log
import org.readium.r2.shared.publication.Locator
import org.readium.r2.shared.publication.Publication

/**
 * Handles user interactions with EPUB content
 * Manages text selection, bookmarks, highlights, and notes
 */
class EpubInteractionHandler(
    private val context: Context,
    private val sessionId: String,
    private val eventEmitter: (Map<String, Any>) -> Unit
) {
    
    private val bookmarks = mutableListOf<Bookmark>()
    private val highlights = mutableListOf<Highlight>()
    private val notes = mutableListOf<Note>()
    
    /**
     * Data class for bookmarks
     */
    data class Bookmark(
        val id: String,
        val pageNumber: Int,
        val locator: Locator?,
        val timestamp: Long = System.currentTimeMillis()
    )
    
    /**
     * Data class for highlights
     */
    data class Highlight(
        val id: String,
        val pageNumber: Int,
        val selectedText: String,
        val color: String,
        val locator: Locator?,
        val startPosition: Int,
        val endPosition: Int,
        val timestamp: Long = System.currentTimeMillis()
    )
    
    /**
     * Data class for notes
     */
    data class Note(
        val id: String,
        val pageNumber: Int,
        val noteText: String,
        val locator: Locator?,
        val timestamp: Long = System.currentTimeMillis()
    )
    
    /**
     * Add a bookmark at the current page
     */
    fun addBookmark(pageNumber: Int, locator: Locator?): Bookmark {
        val bookmark = Bookmark(
            id = generateId(),
            pageNumber = pageNumber,
            locator = locator
        )
        
        bookmarks.add(bookmark)
        
        // Emit bookmark event
        emitBookmarkEvent(bookmark, "add")
        
        Log.d(TAG, "Bookmark added at page $pageNumber")
        return bookmark
    }
    
    /**
     * Remove a bookmark
     */
    fun removeBookmark(bookmarkId: String): Boolean {
        val bookmark = bookmarks.find { it.id == bookmarkId }
        if (bookmark != null) {
            bookmarks.remove(bookmark)
            emitBookmarkEvent(bookmark, "remove")
            Log.d(TAG, "Bookmark removed: $bookmarkId")
            return true
        }
        return false
    }
    
    /**
     * Remove bookmark at specific page
     */
    fun removeBookmarkAtPage(pageNumber: Int): Boolean {
        val bookmark = bookmarks.find { it.pageNumber == pageNumber }
        return if (bookmark != null) {
            removeBookmark(bookmark.id)
        } else {
            false
        }
    }
    
    /**
     * Check if a page has a bookmark
     */
    fun hasBookmarkAtPage(pageNumber: Int): Boolean {
        return bookmarks.any { it.pageNumber == pageNumber }
    }
    
    /**
     * Get all bookmarks
     */
    fun getBookmarks(): List<Bookmark> = bookmarks.toList()
    
    /**
     * Add a highlight for selected text
     */
    fun addHighlight(
        pageNumber: Int,
        selectedText: String,
        color: String,
        locator: Locator?,
        startPosition: Int,
        endPosition: Int
    ): Highlight {
        val highlight = Highlight(
            id = generateId(),
            pageNumber = pageNumber,
            selectedText = selectedText,
            color = color,
            locator = locator,
            startPosition = startPosition,
            endPosition = endPosition
        )
        
        highlights.add(highlight)
        
        // Emit highlight event
        emitHighlightEvent(highlight, "add")
        
        Log.d(TAG, "Highlight added at page $pageNumber: $selectedText")
        return highlight
    }
    
    /**
     * Remove a highlight
     */
    fun removeHighlight(highlightId: String): Boolean {
        val highlight = highlights.find { it.id == highlightId }
        if (highlight != null) {
            highlights.remove(highlight)
            emitHighlightEvent(highlight, "remove")
            Log.d(TAG, "Highlight removed: $highlightId")
            return true
        }
        return false
    }
    
    /**
     * Get all highlights
     */
    fun getHighlights(): List<Highlight> = highlights.toList()
    
    /**
     * Get highlights for a specific page
     */
    fun getHighlightsForPage(pageNumber: Int): List<Highlight> {
        return highlights.filter { it.pageNumber == pageNumber }
    }
    
    /**
     * Add a note
     */
    fun addNote(pageNumber: Int, noteText: String, locator: Locator?): Note {
        val note = Note(
            id = generateId(),
            pageNumber = pageNumber,
            noteText = noteText,
            locator = locator
        )
        
        notes.add(note)
        
        // Emit note event
        emitNoteEvent(note, "add")
        
        Log.d(TAG, "Note added at page $pageNumber")
        return note
    }
    
    /**
     * Remove a note
     */
    fun removeNote(noteId: String): Boolean {
        val note = notes.find { it.id == noteId }
        if (note != null) {
            notes.remove(note)
            emitNoteEvent(note, "remove")
            Log.d(TAG, "Note removed: $noteId")
            return true
        }
        return false
    }
    
    /**
     * Get all notes
     */
    fun getNotes(): List<Note> = notes.toList()
    
    /**
     * Get notes for a specific page
     */
    fun getNotesForPage(pageNumber: Int): List<Note> {
        return notes.filter { it.pageNumber == pageNumber }
    }
    
    /**
     * Handle text selection
     * Returns available actions for the selected text
     */
    fun handleTextSelection(
        pageNumber: Int,
        selectedText: String,
        locator: Locator?,
        startPosition: Int,
        endPosition: Int
    ): List<String> {
        // Emit text selection event
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "text_selected",
            "page_number" to pageNumber,
            "selected_text" to selectedText,
            "start_position" to startPosition,
            "end_position" to endPosition,
            "timestamp" to System.currentTimeMillis()
        )
        eventEmitter(event)
        
        // Return available actions
        return listOf("highlight", "note", "copy", "share")
    }
    
    /**
     * Clear all interactions
     */
    fun clearAll() {
        bookmarks.clear()
        highlights.clear()
        notes.clear()
    }
    
    // Event emission methods
    
    private fun emitBookmarkEvent(bookmark: Bookmark, action: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "bookmark",
            "action" to action,
            "bookmark_id" to bookmark.id,
            "page_number" to bookmark.pageNumber,
            "timestamp" to bookmark.timestamp
        )
        eventEmitter(event)
    }
    
    private fun emitHighlightEvent(highlight: Highlight, action: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "highlight",
            "action" to action,
            "highlight_id" to highlight.id,
            "page_number" to highlight.pageNumber,
            "highlighted_text" to highlight.selectedText,
            "color" to highlight.color,
            "start_position" to highlight.startPosition,
            "end_position" to highlight.endPosition,
            "timestamp" to highlight.timestamp
        )
        eventEmitter(event)
    }
    
    private fun emitNoteEvent(note: Note, action: String) {
        val event = mapOf(
            "type" to "engagement",
            "session_id" to sessionId,
            "event" to "note",
            "action" to action,
            "note_id" to note.id,
            "page_number" to note.pageNumber,
            "note_text" to note.noteText,
            "timestamp" to note.timestamp
        )
        eventEmitter(event)
    }
    
    // Utility methods
    
    private fun generateId(): String {
        return "${System.currentTimeMillis()}_${(0..9999).random()}"
    }
    
    companion object {
        private const val TAG = "EpubInteractionHandler"
    }
}
