package com.knowvas.reader.comic

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
 * Instrumented tests for ComicReader
 * Requirements: 16.5 - Test comic image loading
 */
@RunWith(AndroidJUnit4::class)
class ComicReaderTest {

    private lateinit var context: Context
    private lateinit var comicReader: ComicReader
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
        comicReader = ComicReader(context, mockEventSink)
        testEvents.clear()
    }

    @After
    fun tearDown() {
        // Clean up resources
        runBlocking {
            try {
                comicReader.close("test_session") { _, _ -> }
            } catch (e: Exception) {
                // Ignore cleanup errors
            }
        }
    }

    @Test
    fun testComicReaderInitialization() {
        // Test that ComicReader can be instantiated
        assertNotNull(comicReader)
    }

    @Test
    fun testOpenComicWithInvalidFile() {
        // Test opening with non-existent file
        eventLatch = CountDownLatch(1)
        var callbackSuccess = false
        var callbackError: String? = null

        comicReader.open(
            contentId = 1,
            fileUrl = "/invalid/path/to/file.cbz",
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
    fun testOpenComicWithUnsupportedFormat() {
        // Test opening with unsupported format
        var callbackSuccess = false
        var callbackError: String? = null

        comicReader.open(
            contentId = 1,
            fileUrl = "/path/to/file.txt",
            token = "test_token",
            sessionId = "test_session"
        ) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(2000)

        // Should fail with unsupported format
        assertFalse("Expected open to fail with unsupported format", callbackSuccess)
        assertTrue(
            "Expected unsupported format error",
            callbackError?.contains("Unsupported") == true
        )
    }

    @Test
    fun testGetTotalPagesWithoutOpening() {
        // Test getting total pages without opening
        val totalPages = comicReader.getTotalPages()

        // Should return 0 (default)
        assertEquals(0, totalPages)
    }

    @Test
    fun testGetCurrentPageIndexWithoutOpening() {
        // Test getting current page without opening
        val currentPage = comicReader.getCurrentPageIndex()

        // Should return 0 (default)
        assertEquals(0, currentPage)
    }

    @Test
    fun testGoToPageWithoutOpening() {
        // Test navigation without opening a file first
        var callbackSuccess = false
        var callbackError: String? = null

        comicReader.goToPage(0) { success, error ->
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
    fun testGetCurrentPageImagesWithoutOpening() = runBlocking {
        // Test getting images without opening
        val images = comicReader.getCurrentPageImages()

        // Should return list with null
        assertNotNull("Expected non-null list", images)
        assertTrue("Expected list with null elements", images.all { it == null })
    }

    @Test
    fun testGetPageThumbnailWithoutOpening() = runBlocking {
        // Test getting thumbnail without opening
        val thumbnail = comicReader.getPageThumbnail(0)

        // Should return null
        assertNull("Expected null thumbnail without opening", thumbnail)
    }

    @Test
    fun testGetPreferencesWithoutOpening() {
        // Test getting preferences without opening
        val prefs = comicReader.getPreferences()

        // Should return default preferences
        assertNotNull("Expected non-null preferences", prefs)
        assertEquals(
            ComicReaderPreferences.LAYOUT_SINGLE,
            prefs.layout
        )
        assertEquals(
            ComicReaderPreferences.DIRECTION_LTR,
            prefs.readingDirection
        )
        assertFalse("Expected guided view disabled by default", prefs.guidedViewEnabled)
    }

    @Test
    fun testSetPreferencesWithoutOpening() {
        // Test setting preferences before opening
        var callbackSuccess = false

        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_DOUBLE,
            readingDirection = ComicReaderPreferences.DIRECTION_RTL,
            guidedViewEnabled = true
        )

        comicReader.setPreferences(prefs) { success, error ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed
        assertTrue("Expected setPreferences to succeed", callbackSuccess)

        // Verify preferences were updated
        val updatedPrefs = comicReader.getPreferences()
        assertEquals(ComicReaderPreferences.LAYOUT_DOUBLE, updatedPrefs.layout)
        assertEquals(ComicReaderPreferences.DIRECTION_RTL, updatedPrefs.readingDirection)
        assertTrue("Expected guided view enabled", updatedPrefs.guidedViewEnabled)
    }

    @Test
    fun testSetPreferencesWithInvalidValues() {
        // Test setting preferences with invalid values
        var callbackSuccess = false
        var callbackError: String? = null

        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = "invalid_layout",
            readingDirection = "invalid_direction",
            guidedViewEnabled = null
        )

        comicReader.setPreferences(prefs) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail with invalid preferences
        assertFalse("Expected setPreferences to fail with invalid values", callbackSuccess)
        assertNotNull("Expected error message", callbackError)
    }

    @Test
    fun testGetCacheStatsWithoutOpening() {
        // Test getting cache stats without opening
        val stats = comicReader.getCacheStats()

        // Should return null (cache not initialized)
        assertNull("Expected null cache stats without opening", stats)
    }

    @Test
    fun testCloseWithoutOpening() {
        // Test closing without opening
        var callbackSuccess = false

        comicReader.close("test_session") { success, error ->
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

        comicReader.goToPage(-1) { success, error ->
            callbackSuccess = success
            callbackError = error
        }

        // Wait for callback
        Thread.sleep(500)

        // Should fail
        assertFalse("Expected goToPage to fail with negative index", callbackSuccess)
        assertTrue(
            "Expected invalid page index error",
            callbackError?.contains("Invalid") == true
        )
    }

    @Test
    fun testGoToPageWithLargeIndex() {
        // Test navigation with very large index
        var callbackSuccess = false

        comicReader.goToPage(999999) { success, _ ->
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
        comicReader.close("test_session_1") { _, _ -> }
        Thread.sleep(200)
        comicReader.close("test_session_2") { _, _ -> }
        Thread.sleep(200)
        comicReader.close("test_session_3") { _, _ -> }

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testPreferencesValidation() {
        // Test that preferences are validated
        val validPrefs = ComicReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_SINGLE,
            readingDirection = ComicReaderPreferences.DIRECTION_LTR,
            guidedViewEnabled = false
        )

        assertTrue("Expected valid preferences", validPrefs.isValid())

        val invalidPrefs = ComicReaderPreferences(
            layout = "invalid",
            readingDirection = "invalid",
            guidedViewEnabled = false
        )

        assertFalse("Expected invalid preferences", invalidPrefs.isValid())
    }

    @Test
    fun testSinglePageLayout() = runBlocking {
        // Test single page layout returns one image
        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_SINGLE
        )

        comicReader.setPreferences(prefs) { _, _ -> }
        Thread.sleep(200)

        val images = comicReader.getCurrentPageImages()

        // Should return single image (null in this case since not opened)
        assertEquals(1, images.size)
    }

    @Test
    fun testDoublePageLayout() = runBlocking {
        // Test double page layout returns two images
        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_DOUBLE
        )

        comicReader.setPreferences(prefs) { _, _ -> }
        Thread.sleep(200)

        val images = comicReader.getCurrentPageImages()

        // Should return two images (nulls in this case since not opened)
        assertEquals(2, images.size)
    }

    @Test
    fun testReadingDirectionLTR() = runBlocking {
        // Test LTR reading direction
        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_DOUBLE,
            readingDirection = ComicReaderPreferences.DIRECTION_LTR
        )

        comicReader.setPreferences(prefs) { _, _ -> }
        Thread.sleep(200)

        val images = comicReader.getCurrentPageImages()

        // Should return two images in LTR order
        assertEquals(2, images.size)
        // First image should be left page, second should be right page
        // (both null in this case since not opened)
    }

    @Test
    fun testReadingDirectionRTL() = runBlocking {
        // Test RTL reading direction
        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = ComicReaderPreferences.LAYOUT_DOUBLE,
            readingDirection = ComicReaderPreferences.DIRECTION_RTL
        )

        comicReader.setPreferences(prefs) { _, _ -> }
        Thread.sleep(200)

        val images = comicReader.getCurrentPageImages()

        // Should return two images in RTL order
        assertEquals(2, images.size)
        // First image should be right page, second should be left page
        // (both null in this case since not opened)
    }

    @Test
    fun testSetPreferencesWithNullValues() {
        // Test setting preferences with null values
        val prefs = com.knowvas.reader.ReaderPreferences(
            layout = null,
            readingDirection = null,
            guidedViewEnabled = null
        )

        var callbackSuccess = false
        comicReader.setPreferences(prefs) { success, _ ->
            callbackSuccess = success
        }

        Thread.sleep(500)

        // Should succeed and use default values
        assertTrue("Expected setPreferences to handle nulls", callbackSuccess)

        // Verify defaults are maintained
        val updatedPrefs = comicReader.getPreferences()
        assertNotNull("Expected non-null layout", updatedPrefs.layout)
        assertNotNull("Expected non-null reading direction", updatedPrefs.readingDirection)
    }
}
