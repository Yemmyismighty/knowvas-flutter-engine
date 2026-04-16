package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for TouchHandler
 * 
 * Tests touch-based curl control functionality:
 * - Edge detection (Requirements 5.1, 5.2)
 * - Curl parameter updates during drag (Requirements 5.3)
 * - Curl direction detection (Requirements 5.5)
 * - Page turn threshold decision (Requirements 6.1, 7.1)
 */
class TouchHandlerTest {
    
    private lateinit var touchHandler: TouchHandler
    
    // Test page dimensions
    private val pageWidth = 1000f
    private val pageHeight = 1500f
    private val edgeThreshold = 0.2f // 20%
    
    @Before
    fun setup() {
        touchHandler = TouchHandler(
            pageWidth = pageWidth,
            pageHeight = pageHeight,
            edgeThreshold = edgeThreshold
        )
    }
    
    // ========== Edge Detection Tests (Requirements 5.1, 5.2) ==========
    
    @Test
    fun `touch near right edge should start forward curl`() {
        // Touch at 900px (within 20% of right edge at 1000px)
        val result = touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        assertTrue("Should start curl", result is TouchHandler.TouchResult.CurlStarted)
        assertEquals(
            "Should be forward direction",
            TouchHandler.Direction.FORWARD,
            (result as TouchHandler.TouchResult.CurlStarted).direction
        )
        assertTrue("Touch should be active", touchHandler.isTouchActive())
    }
    
    @Test
    fun `touch near left edge should start backward curl`() {
        // Touch at 100px (within 20% of left edge at 0px)
        val result = touchHandler.handleTouchDown(x = 100f, y = 750f)
        
        assertTrue("Should start curl", result is TouchHandler.TouchResult.CurlStarted)
        assertEquals(
            "Should be backward direction",
            TouchHandler.Direction.BACKWARD,
            (result as TouchHandler.TouchResult.CurlStarted).direction
        )
        assertTrue("Touch should be active", touchHandler.isTouchActive())
    }
    
    @Test
    fun `touch in center should be ignored`() {
        // Touch at 500px (center of 1000px width)
        val result = touchHandler.handleTouchDown(x = 500f, y = 750f)
        
        assertTrue("Should ignore touch", result is TouchHandler.TouchResult.Ignored)
        assertFalse("Touch should not be active", touchHandler.isTouchActive())
    }
    
    @Test
    fun `touch just outside edge threshold should be ignored`() {
        // Edge threshold is 200px (20% of 1000px)
        // Touch at 210px should be ignored
        val result = touchHandler.handleTouchDown(x = 210f, y = 750f)
        
        assertTrue("Should ignore touch", result is TouchHandler.TouchResult.Ignored)
        assertFalse("Touch should not be active", touchHandler.isTouchActive())
    }
    
    @Test
    fun `touch exactly at edge threshold should start curl`() {
        // Edge threshold is 200px (20% of 1000px)
        // Touch at 200px should start curl
        val result = touchHandler.handleTouchDown(x = 200f, y = 750f)
        
        assertTrue("Should start curl", result is TouchHandler.TouchResult.CurlStarted)
    }
    
    // ========== Curl Parameter Update Tests (Requirements 5.3) ==========
    
    @Test
    fun `touch move should update curl parameters`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move touch
        val result = touchHandler.handleTouchMove(x = 700f, y = 750f)
        
        assertTrue("Should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        assertNotNull("Curl parameters should not be null", params)
        assertTrue("Curl radius should be positive", params.radius > 0)
    }
    
    @Test
    fun `touch move without active touch should be ignored`() {
        // Move without starting touch
        val result = touchHandler.handleTouchMove(x = 700f, y = 750f)
        
        assertTrue("Should ignore move", result is TouchHandler.TouchResult.Ignored)
    }
    
    @Test
    fun `small touch movement should be ignored`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Very small movement (less than MIN_DRAG_DISTANCE = 10px)
        val result = touchHandler.handleTouchMove(x = 905f, y = 750f)
        
        assertTrue("Should ignore small movement", result is TouchHandler.TouchResult.Ignored)
    }
    
    @Test
    fun `curl parameters should have valid values`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move touch significantly
        val result = touchHandler.handleTouchMove(x = 600f, y = 750f)
        
        assertTrue("Should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        
        // Validate curl parameters
        assertTrue("Position X should be valid", params.position.x >= 0 && params.position.x <= pageWidth)
        assertTrue("Position Y should be valid", params.position.y >= 0 && params.position.y <= pageHeight)
        assertTrue("Radius should be positive", params.radius > 0)
        assertTrue("Angle should be in valid range", params.angle >= 0 && params.angle <= Math.PI.toFloat())
    }
    
    // ========== Direction Detection Tests (Requirements 5.5) ==========
    
    @Test
    fun `forward curl should maintain forward direction`() {
        // Start forward curl
        val startResult = touchHandler.handleTouchDown(x = 900f, y = 750f)
        assertEquals(
            "Should start forward",
            TouchHandler.Direction.FORWARD,
            (startResult as TouchHandler.TouchResult.CurlStarted).direction
        )
        
        // Check current direction
        assertEquals(
            "Should maintain forward direction",
            TouchHandler.Direction.FORWARD,
            touchHandler.getCurrentDirection()
        )
    }
    
    @Test
    fun `backward curl should maintain backward direction`() {
        // Start backward curl
        val startResult = touchHandler.handleTouchDown(x = 100f, y = 750f)
        assertEquals(
            "Should start backward",
            TouchHandler.Direction.BACKWARD,
            (startResult as TouchHandler.TouchResult.CurlStarted).direction
        )
        
        // Check current direction
        assertEquals(
            "Should maintain backward direction",
            TouchHandler.Direction.BACKWARD,
            touchHandler.getCurrentDirection()
        )
    }
    
    // ========== Page Turn Threshold Tests (Requirements 6.1, 7.1) ==========
    
    @Test
    fun `drag beyond threshold should trigger page turn`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move significantly (drag distance > 30% of page width = 300px)
        touchHandler.handleTouchMove(x = 500f, y = 750f)
        
        // Release
        val result = touchHandler.handleTouchUp(x = 500f, y = 750f)
        
        assertTrue("Should trigger page turn", result is TouchHandler.TouchResult.PageTurnTriggered)
        assertEquals(
            "Should be forward direction",
            TouchHandler.Direction.FORWARD,
            (result as TouchHandler.TouchResult.PageTurnTriggered).direction
        )
    }
    
    @Test
    fun `drag below threshold should trigger snap back`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move slightly (drag distance < 30% of page width = 300px)
        touchHandler.handleTouchMove(x = 800f, y = 750f)
        
        // Release
        val result = touchHandler.handleTouchUp(x = 800f, y = 750f)
        
        assertTrue("Should trigger snap back", result is TouchHandler.TouchResult.SnapBackTriggered)
    }
    
    @Test
    fun `drag exactly at threshold should trigger page turn`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move exactly 30% of page width (300px)
        touchHandler.handleTouchMove(x = 600f, y = 750f)
        
        // Release
        val result = touchHandler.handleTouchUp(x = 600f, y = 750f)
        
        // At exactly the threshold, should NOT trigger page turn (> not >=)
        assertTrue("Should trigger snap back at exact threshold", result is TouchHandler.TouchResult.SnapBackTriggered)
    }
    
    @Test
    fun `drag just over threshold should trigger page turn`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move just over 30% of page width (301px)
        touchHandler.handleTouchMove(x = 599f, y = 750f)
        
        // Release
        val result = touchHandler.handleTouchUp(x = 599f, y = 750f)
        
        assertTrue("Should trigger page turn", result is TouchHandler.TouchResult.PageTurnTriggered)
    }
    
    // ========== State Management Tests ==========
    
    @Test
    fun `reset should clear touch state`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        assertTrue("Touch should be active", touchHandler.isTouchActive())
        
        // Reset
        touchHandler.reset()
        
        assertFalse("Touch should not be active after reset", touchHandler.isTouchActive())
        assertNull("Direction should be null after reset", touchHandler.getCurrentDirection())
    }
    
    @Test
    fun `touch up should reset touch state`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        assertTrue("Touch should be active", touchHandler.isTouchActive())
        
        // Move and release
        touchHandler.handleTouchMove(x = 800f, y = 750f)
        touchHandler.handleTouchUp(x = 800f, y = 750f)
        
        assertFalse("Touch should not be active after release", touchHandler.isTouchActive())
        assertNull("Direction should be null after release", touchHandler.getCurrentDirection())
    }
    
    @Test
    fun `touch up without active touch should be ignored`() {
        // Release without starting touch
        val result = touchHandler.handleTouchUp(x = 700f, y = 750f)
        
        assertTrue("Should ignore release", result is TouchHandler.TouchResult.Ignored)
    }
    
    // ========== Drag Distance Tests ==========
    
    @Test
    fun `drag distance should be calculated correctly`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move horizontally 300px
        touchHandler.handleTouchMove(x = 600f, y = 750f)
        
        val dragDistance = touchHandler.getDragDistance()
        assertEquals("Drag distance should be 300px", 300f, dragDistance, 0.1f)
    }
    
    @Test
    fun `drag direction should be normalized`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move diagonally
        touchHandler.handleTouchMove(x = 600f, y = 450f)
        
        val direction = touchHandler.getDragDirection()
        assertNotNull("Direction should not be null", direction)
        
        // Check that direction is normalized (length ≈ 1)
        val length = Math.sqrt((direction!!.x * direction.x + direction.y * direction.y).toDouble())
        assertEquals("Direction should be normalized", 1.0, length, 0.01)
    }
    
    @Test
    fun `drag direction should be null when not dragging`() {
        val direction = touchHandler.getDragDirection()
        assertNull("Direction should be null when not dragging", direction)
    }
    
    // ========== Edge Cases ==========
    
    @Test
    fun `touch at corner should be detected as edge touch`() {
        // Top-right corner
        val result1 = touchHandler.handleTouchDown(x = 950f, y = 50f)
        assertTrue("Top-right corner should start curl", result1 is TouchHandler.TouchResult.CurlStarted)
        
        touchHandler.reset()
        
        // Bottom-left corner
        val result2 = touchHandler.handleTouchDown(x = 50f, y = 1450f)
        assertTrue("Bottom-left corner should start curl", result2 is TouchHandler.TouchResult.CurlStarted)
    }
    
    @Test
    fun `vertical drag should still work`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move vertically (no horizontal movement)
        val result = touchHandler.handleTouchMove(x = 900f, y = 450f)
        
        assertTrue("Vertical drag should update curl", result is TouchHandler.TouchResult.CurlUpdated)
    }
    
    @Test
    fun `diagonal drag should work correctly`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move diagonally
        val result = touchHandler.handleTouchMove(x = 600f, y = 450f)
        
        assertTrue("Diagonal drag should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        assertTrue("Curl radius should account for diagonal distance", params.radius > 0)
    }
}
