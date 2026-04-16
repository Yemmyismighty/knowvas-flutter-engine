package com.knowvas.reader.pdf

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Instrumented tests for PdfReader
 * Requirements: 16.5 - Test PDF rendering and zoom
 */
@RunWith(AndroidJUnit4::class)
class PdfReaderTest {

    private lateinit var context: Context
    private lateinit var pdfReader: PdfReader
    private val testEvents = mutableListOf<Map<String, Any>>()
    private var eventLatch: CountDownLatch? = null

    private val mockEventSink = object : EventChannel.EventSink {
        override fun success(event: Any?) {
            @Suppress("UNCHECKED_CAST")
            val eventMap = event as? Map<String, Any>
            eventMap?.let {
                testEvents.add(it)
                eventLatch?.countDown()
            }
        }

        override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
            testEvents.add(
                mapOf(
                    "type" to "error",
                    "code" to (errorCode ?: "UNKNOWN"),
                    "message" to (errorMessage ?: "Unknown error")
                )
            )
            eventLatch?.countDown()
        }

        override fun endOfStream() {
            // Not used in tests
        }
    }

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        pdfReader = PdfReader(context, mockEventSink)
        testEvents.clear()
    }

    @After
    fun tearDown() {
        // Clean up resources
        runBlocking {
            try {
                pdfReader.close("test_session") { _, _ -> }
            } catch (e: Exception) {
                // Ignore cleanup errors
            }
        }
    }

    @Test
    fun testPdfReaderInitialization() {
        // Test that PdfReader can be instantiated
        assertNotNull(pdfReader)
    }

    @Test
    fun testOpenPdfWithInvalidFile() {
        // Test opening with non-existent file
        eventLatch = CountDownLatch(1)
        var callbackSuccess = false
        var callbackError: String? = null

        pdfReader.open(
            contentId = 1,
            fileUrl = "/invalid/path/to/file.pdf",
            token = "test_token",
            sessionId = "test_session"
        ) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(2000)

        // Should fail with invalid file
        assertFalse("Expected open to fail with invalid file", callbackSuccess)
        assertNotNull("Expected error message", callbackError)
    }

    @Test
    fun testGetCurrentPageIndexWithoutOpening() {
        // Test getting current page without opening
        val currentPage = pdfReader.getCurrentPageIndex()

        // Should return 0 (default)
        assertEquals(0, currentPage)
    }

    @Test
    fun testGetTotalPagesWithoutOpening() {
        // Test getting total pages without opening
        val totalPages = pdfReader.getTotalPages()

        // Should return 0 (default)
        assertEquals(0, totalPages)
    }

    @Test
    fun testGoToPageWithoutOpening() {
        // Test navigation without opening a file first
        var callbackSuccess = false
        var callbackError: String? = null

        pdfReader.goToPage(0) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail without opening
        assertFalse("Expected goToPage to fail without opening", callbackSuccess)
        assertNotNull("Expected error message", callbackError)
    }

    @Test
    fun testNextPageWithoutOpening() {
        // Test next page without opening
        var callbackSuccess = false

        pdfReader.nextPage { success, _ ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail without opening
        assertFalse("Expected nextPage to fail without opening", callbackSuccess)
    }

    @Test
    fun testPreviousPageWithoutOpening() {
        // Test previous page without opening
        var callbackSuccess = false

        pdfReader.previousPage { success, _ ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail without opening
        assertFalse("Expected previousPage to fail without opening", callbackSuccess)
    }

    @Test
    fun testRenderCurrentPageWithoutOpening() {
        // Test rendering without opening
        val bitmap = pdfReader.renderCurrentPage(800, 600)

        // Should return null
        assertNull("Expected null bitmap without opening", bitmap)
    }

    @Test
    fun testGetCurrentPageDimensionsWithoutOpening() {
        // Test getting dimensions without opening
        val dimensions = pdfReader.getCurrentPageDimensions()

        // Should return null
        assertNull("Expected null dimensions without opening", dimensions)
    }

    @Test
    fun testSetPreferencesWithoutOpening() {
        // Test setting preferences before opening
        var callbackSuccess = false

        val prefs = com.knowvas.reader.ReaderPreferences(
            theme = "dark",
            layout = "single"
        )

        pdfReader.setPreferences(prefs) { success, error ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed even without opening
        assertTrue("Expected setPreferences to succeed", callbackSuccess)
    }

    @Test
    fun testGetPreferencesWithoutOpening() {
        // Test getting preferences without opening
        val prefs = pdfReader.getPreferences()

        // Should return null (no preferences set)
        assertNull("Expected null preferences", prefs)
    }

    @Test
    fun testAddBookmarkWithoutOpening() {
        // Test adding bookmark without opening
        var callbackSuccess = false
        var callbackError: String? = null

        pdfReader.addBookmark(0) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail with invalid page index
        assertFalse("Expected addBookmark to fail without opening", callbackSuccess)
    }

    @Test
    fun testRemoveBookmarkWithoutOpening() {
        // Test removing bookmark without opening
        var callbackSuccess = false

        pdfReader.removeBookmark(0) { success, _ ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed (removing non-existent bookmark)
        assertTrue("Expected removeBookmark to succeed", callbackSuccess)
    }

    @Test
    fun testIsBookmarkedWithoutOpening() {
        // Test checking bookmark status without opening
        val isBookmarked = pdfReader.isBookmarked(0)

        // Should return false
        assertFalse("Expected not bookmarked", isBookmarked)
    }

    @Test
    fun testGetBookmarksWithoutOpening() {
        // Test getting bookmarks without opening
        val bookmarks = pdfReader.getBookmarks()

        // Should return empty set
        assertTrue("Expected empty bookmarks", bookmarks.isEmpty())
    }

    @Test
    fun testHasSelectableText() {
        // Test text selection support
        val hasText = pdfReader.hasSelectableText()

        // PdfRenderer doesn't support text extraction
        assertFalse("Expected no text selection support", hasText)
    }

    @Test
    fun testCloseWithoutOpening() {
        // Test closing without opening
        var callbackSuccess = false

        pdfReader.close("test_session") { success, error ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed
        assertTrue("Expected close to succeed", callbackSuccess)
    }

    @Test
    fun testGoToPageWithNegativeIndex() {
        // Test navigation with negative index
        var callbackSuccess = false
        var callbackError: String? = null

        pdfReader.goToPage(-1) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail
        assertFalse("Expected goToPage to fail with negative index", callbackSuccess)
        assertNotNull("Expected error message", callbackError)
    }

    @Test
    fun testGoToPageWithLargeIndex() {
        // Test navigation with very large index
        var callbackSuccess = false

        pdfReader.goToPage(999999) { success, _ ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail
        assertFalse("Expected goToPage to fail with large index", callbackSuccess)
    }

    @Test
    fun testMultipleCloseCallsDoNotCrash() {
        // Test that multiple close calls don't cause issues
        pdfReader.close("test_session_1") { _, _ -> }
        Thread.sleep(200)
        pdfReader.close("test_session_2") { _, _ -> }
        Thread.sleep(200)
        pdfReader.close("test_session_3") { _, _ -> }

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testRenderWithInvalidDimensions() {
        // Test rendering with invalid dimensions
        val bitmap1 = pdfReader.renderCurrentPage(0, 600)
        val bitmap2 = pdfReader.renderCurrentPage(800, 0)
        val bitmap3 = pdfReader.renderCurrentPage(-100, -100)

        // Should return null for all invalid dimensions
        assertNull("Expected null for zero width", bitmap1)
        assertNull("Expected null for zero height", bitmap2)
        assertNull("Expected null for negative dimensions", bitmap3)
    }

    @Test
    fun testBookmarkOperations() {
        // Test bookmark operations without opening
        // Add bookmark
        pdfReader.addBookmark(5) { _, _ -> }
        Thread.sleep(200)

        // Check if bookmarked (should be false since PDF not opened)
        val isBookmarked = pdfReader.isBookmarked(5)
        assertFalse("Expected not bookmarked without valid PDF", isBookmarked)

        // Remove bookmark
        pdfReader.removeBookmark(5) { _, _ -> }
        Thread.sleep(200)

        // Get all bookmarks
        val bookmarks = pdfReader.getBookmarks()
        assertTrue("Expected empty bookmarks", bookmarks.isEmpty())
    }

    @Test
    fun testSetPreferencesWithNullValues() {
        // Test setting preferences with null values
        val prefs = com.knowvas.reader.ReaderPreferences(
            theme = null,
            layout = null
        )

        var callbackSuccess = false
        pdfReader.setPreferences(prefs) { success, _ ->
            callbackSuccess = success
        }

        Thread.sleep(500)

        // Should handle null values gracefully
        assertTrue("Expected setPreferences to handle nulls", callbackSuccess)
    }
}
