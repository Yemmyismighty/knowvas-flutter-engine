package com.knowvas.reader

import org.readium.r2.shared.publication.Publication

/**
 * Singleton to manage active reader sessions
 * Stores publications and readers temporarily for access by ReaderActivity
 */
object ReaderManager {
    private val activeSessions = mutableMapOf<String, Publication>()
    private val activeReaders = mutableMapOf<String, BaseReader>()
    
    /**
     * Store a publication for a session (EPUB)
     */
    fun storePublication(sessionId: String, publication: Publication) {
        activeSessions[sessionId] = publication
        android.util.Log.d("ReaderManager", "Stored publication for session: $sessionId")
    }
    
    /**
     * Retrieve a publication for a session (EPUB)
     */
    fun getPublication(sessionId: String): Publication? {
        return activeSessions[sessionId]
    }
    
    /**
     * Store a reader for a session (PDF, Comic, etc.)
     */
    fun addReader(sessionId: String, reader: BaseReader) {
        activeReaders[sessionId] = reader
        android.util.Log.d("ReaderManager", "Stored reader for session: $sessionId")
    }
    
    /**
     * Retrieve a reader for a session
     */
    fun getReader(sessionId: String): BaseReader? {
        return activeReaders[sessionId]
    }
    
    /**
     * Remove a publication when session ends
     */
    fun removePublication(sessionId: String) {
        activeSessions.remove(sessionId)
        activeReaders.remove(sessionId)?.close()
        android.util.Log.d("ReaderManager", "Removed publication/reader for session: $sessionId")
    }
    
    /**
     * Clear all sessions
     */
    fun clearAll() {
        activeReaders.values.forEach { it.close() }
        activeSessions.clear()
        activeReaders.clear()
    }
}
