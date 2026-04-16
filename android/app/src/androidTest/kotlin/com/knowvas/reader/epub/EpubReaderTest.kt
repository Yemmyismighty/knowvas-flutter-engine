package com.knowvas.reader.epub

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
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Instrumented tests for EpubReader
 * Requirements: 16.5 - Test EPUB opening and page navigation
 */
@RunWith(AndroidJUnit4::class)
class EpubReaderTest {

    private lateinit var context: Context
    private lateinit var epubReader: EpubReader
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
        epubReader = EpubReader(context, mockEventSink)
        testEvents.clear()
    }

    @After
    fun tearDown() {
        // Clean up resources
        runBlocking {
            try {
                epubReader.close("test_session") { _, _ -> }
            } catch (e: Exception) {
                // Ignore cleanup errors
            }
        }
    }

    @Test
    fun testEpubReaderInitialization() {
        // Test that EpubReader can be instantiated
        assertNotNull(epubReader)
    }

    @Test
    fun testOpenEpubWithInvalidFile() {
        // Test opening with non-existent file
        eventLatch = CountDownLatch(1)
        var callbackSuccess = false
        var callbackError: String? = null

        epubReader.open(
            contentId = 1,
            fileUrl = "/invalid/path/to/file.epub",
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
    fun testNavigateToPageWithoutOpening() {
        // Test navigation without opening a file first
        epubReader.navigateToPage(0)

        // Should not crash, but won't navigate
        // No assertions needed, just verify no crash
    }

    @Test
    fun testGetCurrentPageWithoutOpening() {
        // Test getting current page without opening
        val currentPage = epubReader.getCurrentPage()

        // Should return 0 (default)
        assertEquals(0, currentPage)
    }

    @Test
    fun testSetPreferencesWithoutOpening() {
        // Test setting preferences before opening
        var callbackSuccess = false

        val prefs = com.knowvas.reader.ReaderPreferences(
            fontSize = 18,
            theme = "dark",
            fontFamily = "serif"
        )

        epubReader.setPreferences(prefs) { success, error ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed even without opening
        assertTrue("Expected setPreferences to succeed", callbackSuccess)
    }

    @Test
    fun testAudioControlsWithoutOpening() {
        // Test audio controls without opening
        epubReader.playAudio()
        epubReader.pauseAudio()
        epubReader.toggleAudio()

        val hasAudio = epubReader.hasAudio()
        val isPlaying = epubReader.isAudioPlaying()
        val position = epubReader.getAudioPosition()
        val duration = epubReader.getAudioDuration()

        // Should return default values without crashing
        assertFalse("Expected no audio without opening", hasAudio)
        assertFalse("Expected not playing without opening", isPlaying)
        assertEquals(0, position)
        assertEquals(0, duration)
    }

    @Test
    fun testSeekAudioWithoutOpening() {
        // Test seeking audio without opening
        epubReader.seekAudio(5000)

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testCloseWithoutOpening() {
        // Test closing without opening
        var callbackSuccess = false

        epubReader.close("test_session") { success, error ->
            callbackSuccess = success
        }

        // Wait for callback
        Thread.sleep(500)

        // Should succeed
        assertTrue("Expected close to succeed", callbackSuccess)
    }

    @Test
    fun testGetCacheStats() {
        // Test getting cache statistics
        val stats = epubReader.getCacheStats()

        // Should return stats object
        assertNotNull("Expected cache stats", stats)
        assertEquals(0, stats.cachedChapters)
    }

    @Test
    fun testMemoryOptimizationToggle() {
        // Test enabling/disabling memory optimization
        epubReader.setMemoryOptimization(true)
        epubReader.setMemoryOptimization(false)

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testMultipleCloseCallsDoNotCrash() {
        // Test that multiple close calls don't cause issues
        epubReader.close("test_session_1") { _, _ -> }
        Thread.sleep(200)
        epubReader.close("test_session_2") { _, _ -> }
        Thread.sleep(200)
        epubReader.close("test_session_3") { _, _ -> }

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testNavigateToNegativePageIndex() {
        // Test navigation with negative index
        epubReader.navigateToPage(-1)

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testNavigateToLargePageIndex() {
        // Test navigation with very large index
        epubReader.navigateToPage(999999)

        // Should not crash
        // No assertions needed
    }

    @Test
    fun testSetPreferencesWithNullValues() {
        // Test setting preferences with null values
        val prefs = com.knowvas.reader.ReaderPreferences(
            fontSize = null,
            theme = null,
            fontFamily = null
        )

        var callbackSuccess = false
        epubReader.setPreferences(prefs) { success, _ ->
            callbackSuccess = success
        }

        Thread.sleep(500)

        // Should handle null values gracefully
        assertTrue("Expected setPreferences to handle nulls", callbackSuccess)
    }

    @Test
    fun testGetNavigatorFragmentWithoutOpening() {
        // Test getting navigator fragment before opening
        val fragment = epubReader.getNavigatorFragment()

        // Should return null
        assertNull("Expected null fragment before opening", fragment)
    }
}
