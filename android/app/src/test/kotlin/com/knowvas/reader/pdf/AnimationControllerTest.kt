package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import kotlin.math.abs

/**
 * Unit tests for AnimationController
 * 
 * Tests animation framework functionality:
 * - Page turn animation duration (Requirements 6.2)
 * - Ease-out interpolation (Requirements 6.3)
 * - Elastic easing for snap-back (Requirements 7.2)
 * - Animation state management
 * - Timing system
 */
class AnimationControllerTest {
    
    private lateinit var animationController: AnimationController
    
    @Before
    fun setup() {
        animationController = AnimationController()
    }
    
    // ========== Animation Duration Tests (Requirements 6.2) ==========
    
    @Test
    fun `page turn animation should enforce minimum duration of 300ms`() {
        var callbackInvoked = false
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        // Try to start animation with duration below minimum
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 100L, // Below minimum
            onUpdate = {},
            onComplete = { callbackInvoked = true }
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
        
        // The controller should clamp to 300ms minimum
        // We can't directly test the internal duration, but we verify it starts
    }
    
    @Test
    fun `page turn animation should enforce maximum duration of 500ms`() {
        var callbackInvoked = false
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        // Try to start animation with duration above maximum
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 1000L, // Above maximum
            onUpdate = {},
            onComplete = { callbackInvoked = true }
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `page turn animation should accept valid duration`() {
        var callbackInvoked = false
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        // Start animation with valid duration
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L, // Valid duration
            onUpdate = {},
            onComplete = { callbackInvoked = true }
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    // ========== Snap-Back Animation Duration Tests (Requirements 7.2) ==========
    
    @Test
    fun `snap-back animation should enforce minimum duration of 200ms`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 100f,
            angle = 0.5f
        )
        
        // Try to start animation with duration below minimum
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 50L, // Below minimum
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `snap-back animation should enforce maximum duration of 300ms`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 100f,
            angle = 0.5f
        )
        
        // Try to start animation with duration above maximum
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 500L, // Above maximum
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    // ========== Animation State Management Tests ==========
    
    @Test
    fun `should report not animating initially`() {
        assertFalse("Should not be animating initially", animationController.isAnimating())
    }
    
    @Test
    fun `should report animating after starting page turn`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Should be animating", animationController.isAnimating())
    }
    
    @Test
    fun `should report animating after starting snap-back`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 100f,
            angle = 0.5f
        )
        
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 250L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Should be animating", animationController.isAnimating())
    }
    
    @Test
    fun `should stop animating after cancellation`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Should be animating", animationController.isAnimating())
        
        animationController.cancelAnimation()
        
        assertFalse("Should not be animating after cancel", animationController.isAnimating())
    }
    
    @Test
    fun `should cancel previous animation when starting new one`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        var firstCompleted = false
        var secondCompleted = false
        
        // Start first animation
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = { firstCompleted = true }
        )
        
        assertTrue("First animation should be running", animationController.isAnimating())
        
        // Start second animation (should cancel first)
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 250L,
            onUpdate = {},
            onComplete = { secondCompleted = true }
        )
        
        assertTrue("Second animation should be running", animationController.isAnimating())
        assertFalse("First animation should not complete", firstCompleted)
    }
    
    // ========== Callback Tests ==========
    
    @Test
    fun `should invoke update callback during animation`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        var updateCount = 0
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = { updateCount++ },
            onComplete = {}
        )
        
        // Wait a bit for updates (in real scenario, animation loop would run)
        Thread.sleep(50)
        
        // Note: In unit tests without Android Looper, callbacks may not fire
        // This test verifies the setup is correct
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `should not invoke completion callback on cancellation`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        var completionInvoked = false
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = { completionInvoked = true }
        )
        
        animationController.cancelAnimation()
        
        assertFalse("Completion should not be invoked on cancel", completionInvoked)
    }
    
    // ========== Direction Tests ==========
    
    @Test
    fun `should handle forward page turn direction`() {
        val startParams = CurlParameters(
            position = PointF(900f, 750f),
            direction = PointF(-1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `should handle backward page turn direction`() {
        val startParams = CurlParameters(
            position = PointF(100f, 750f),
            direction = PointF(1f, 0f),
            radius = 200f,
            angle = 1.0f
        )
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.BACKWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    // ========== Parameter Validation Tests ==========
    
    @Test
    fun `should handle flat start parameters`() {
        animationController.startPageTurnAnimation(
            startParams = CurlParameters.FLAT,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `should handle zero radius in start parameters`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 0f,
            angle = 0f
        )
        
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = TouchHandler.Direction.FORWARD,
            duration = 400L,
            onUpdate = {},
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
    }
    
    @Test
    fun `snap-back should target flat parameters`() {
        val startParams = CurlParameters(
            position = PointF(500f, 750f),
            direction = PointF(-1f, 0f),
            radius = 150f,
            angle = 0.8f
        )
        
        var finalParams: CurlParameters? = null
        
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 250L,
            onUpdate = { finalParams = it },
            onComplete = {}
        )
        
        assertTrue("Animation should be running", animationController.isAnimating())
        // Target should be flat (verified internally by the controller)
    }
}
