package com.knowvas.reader

import io.flutter.plugin.common.EventChannel

/**
 * Base interface for all reader types (EPUB, PDF, Comic)
 * Defines common methods that all readers must implement
 */
interface BaseReader {
    /**
     * Open content from the specified file URL
     * @param fileUrl Path to the content file (local or remote)
     * @param token Authentication token for remote files
     * @param callback Callback with success status and optional error message
     */
    fun open(fileUrl: String, token: String, callback: (Boolean, String?) -> Unit)

    /**
     * Close the reader and clean up resources
     */
    fun close()

    /**
     * Set reader preferences (font size, theme, layout, etc.)
     * @param preferences Map of preference key-value pairs
     */
    fun setPreferences(preferences: Map<*, *>)

    /**
     * Set the event sink for emitting events to Flutter
     * @param sink EventChannel.EventSink for sending events
     */
    fun setEventSink(sink: EventChannel.EventSink?)

    /**
     * Emit an event to Flutter through the event channel
     * @param event Map containing event data
     */
    fun emitEvent(event: Map<String, Any>) {
        // Default implementation - subclasses can override if needed
    }
}
