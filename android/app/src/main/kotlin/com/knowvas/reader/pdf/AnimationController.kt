package com.knowvas.reader.pdf

import android.graphics.PointF
import android.os.Handler
import android.os.Looper
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.sin

/**
 * AnimationController - Manages page turn and snap-back animations
 * 
 * This class handles the timing and interpolation of curl animations:
 * - Page turn completion animations (300-500ms with ease-out)
 * - Snap-back animations (200-300ms with elastic easing)
 * - Real-time animation updates via callbacks
 * 
 * Requirements: 6.2, 6.3, 7.2
 * 
 * The controller uses System.currentTimeMillis() for timing and provides
 * various easing functions for natural motion.
 */
class AnimationController {
    
    // Animation state
    private var isAnimating = false
    private var animationStartTime = 0L
    private var animationDuration = 0L
    private var animationType = AnimationType.NONE
    
    // Animation parameters
    private var startParams: CurlParameters = CurlParameters.FLAT
    private var targetParams: CurlParameters = CurlParameters.FLAT
    private var direction: TouchHandler.Direction = TouchHandler.Direction.FORWARD
    
    // Callbacks
    private var onUpdate: ((CurlParameters) -> Unit)? = null
    private var onComplete: (() -> Unit)? = null
    
    // Handler for animation loop
    private val handler = Handler(Looper.getMainLooper())
    private val animationRunnable = object : Runnable {
        override fun run() {
            if (isAnimating) {
                updateAnimation()
                handler.postDelayed(this, 16) // ~60 FPS
            }
        }
    }
    
    /**
     * Animation types
     */
    enum class AnimationType {
        NONE,
        PAGE_TURN,
        SNAP_BACK
    }
    
    /**
     * Start a page turn completion animation
     * 
     * Animates the curl from its current state to full completion,
     * using ease-out interpolation for natural deceleration.
     * 
     * Requirements: 6.2, 6.3
     * 
     * @param startParams Current curl parameters
     * @param direction Direction of page turn (FORWARD or BACKWARD)
     * @param duration Animation duration in milliseconds (300-500ms recommended)
     * @param onUpdate Callback invoked on each animation frame with interpolated parameters
     * @param onComplete Callback invoked when animation completes
     */
    fun startPageTurnAnimation(
        startParams: CurlParameters,
        direction: TouchHandler.Direction,
        duration: Long = 400L,
        onUpdate: (CurlParameters) -> Unit,
        onComplete: () -> Unit
    ) {
        // Cancel any existing animation
        cancelAnimation()
        
        // Validate duration (300-500ms as per requirements)
        val validDuration = duration.coerceIn(300L, 500L)
        
        // Set up animation state
        this.startParams = startParams
        this.direction = direction
        this.animationDuration = validDuration
        this.animationType = AnimationType.PAGE_TURN
        this.onUpdate = onUpdate
        this.onComplete = onComplete
        
        // Calculate target parameters (fully curled)
        this.targetParams = calculatePageTurnTarget(startParams, direction)
        
        // Start animation
        animationStartTime = System.currentTimeMillis()
        isAnimating = true
        handler.post(animationRunnable)
        
        android.util.Log.d("AnimationController", 
            "Started page turn animation: duration=${validDuration}ms, direction=$direction")
    }
    
    /**
     * Start a snap-back animation
     * 
     * Animates the curl back to flat position with elastic easing
     * for a natural bounce effect.
     * 
     * Requirements: 7.2
     * 
     * @param startParams Current curl parameters
     * @param duration Animation duration in milliseconds (200-300ms recommended)
     * @param onUpdate Callback invoked on each animation frame with interpolated parameters
     * @param onComplete Callback invoked when animation completes
     */
    fun startSnapBackAnimation(
        startParams: CurlParameters,
        duration: Long = 250L,
        onUpdate: (CurlParameters) -> Unit,
        onComplete: () -> Unit
    ) {
        // Cancel any existing animation
        cancelAnimation()
        
        // Validate duration (200-300ms as per requirements)
        val validDuration = duration.coerceIn(200L, 300L)
        
        // Set up animation state
        this.startParams = startParams
        this.animationDuration = validDuration
        this.animationType = AnimationType.SNAP_BACK
        this.onUpdate = onUpdate
        this.onComplete = onComplete
        
        // Target is always flat for snap-back
        this.targetParams = CurlParameters.FLAT
        
        // Start animation
        animationStartTime = System.currentTimeMillis()
        isAnimating = true
        handler.post(animationRunnable)
        
        android.util.Log.d("AnimationController", 
            "Started snap-back animation: duration=${validDuration}ms")
    }
    
    /**
     * Cancel the current animation
     * 
     * Stops the animation loop and clears callbacks.
     * Does not invoke the onComplete callback.
     */
    fun cancelAnimation() {
        if (isAnimating) {
            isAnimating = false
            handler.removeCallbacks(animationRunnable)
            animationType = AnimationType.NONE
            onUpdate = null
            onComplete = null
            
            android.util.Log.d("AnimationController", "Animation cancelled")
        }
    }
    
    /**
     * Check if an animation is currently running
     * 
     * @return True if animation is in progress
     */
    fun isAnimating(): Boolean {
        return isAnimating
    }
    
    /**
     * Update animation state and invoke callbacks
     * 
     * Called on each animation frame (~60 FPS).
     * Calculates interpolated curl parameters and invokes update callback.
     */
    private fun updateAnimation() {
        val currentTime = System.currentTimeMillis()
        val elapsed = currentTime - animationStartTime
        
        // Calculate progress (0 to 1)
        val rawProgress = (elapsed.toFloat() / animationDuration.toFloat()).coerceIn(0f, 1f)
        
        // Apply easing function based on animation type
        val easedProgress = when (animationType) {
            AnimationType.PAGE_TURN -> easeOut(rawProgress)
            AnimationType.SNAP_BACK -> elasticEaseOut(rawProgress)
            AnimationType.NONE -> rawProgress
        }
        
        // Interpolate curl parameters
        val interpolatedParams = interpolateParams(startParams, targetParams, easedProgress)
        
        // Invoke update callback
        onUpdate?.invoke(interpolatedParams)
        
        // Check if animation is complete
        if (rawProgress >= 1f) {
            completeAnimation()
        }
    }
    
    /**
     * Complete the animation
     * 
     * Stops the animation loop and invokes the completion callback.
     */
    private fun completeAnimation() {
        isAnimating = false
        handler.removeCallbacks(animationRunnable)
        
        val type = animationType
        animationType = AnimationType.NONE
        
        // Invoke completion callback
        val callback = onComplete
        onUpdate = null
        onComplete = null
        
        android.util.Log.d("AnimationController", "Animation completed: type=$type")
        
        callback?.invoke()
    }
    
    /**
     * Calculate target parameters for page turn completion
     * 
     * @param startParams Current curl parameters
     * @param direction Page turn direction
     * @return Target curl parameters (fully curled)
     */
    private fun calculatePageTurnTarget(
        startParams: CurlParameters,
        direction: TouchHandler.Direction
    ): CurlParameters {
        // For page turn, we want to curl to maximum angle
        return CurlParameters(
            position = startParams.position,
            direction = startParams.direction,
            radius = startParams.radius.coerceAtLeast(100f), // Ensure minimum radius
            angle = CurlParameters.MAX_ANGLE // Fully curled
        )
    }
    
    /**
     * Interpolate between two curl parameter sets
     * 
     * @param start Starting parameters
     * @param target Target parameters
     * @param progress Interpolation progress (0 to 1)
     * @return Interpolated parameters
     */
    private fun interpolateParams(
        start: CurlParameters,
        target: CurlParameters,
        progress: Float
    ): CurlParameters {
        return CurlParameters(
            position = PointF(
                lerp(start.position.x, target.position.x, progress),
                lerp(start.position.y, target.position.y, progress)
            ),
            direction = PointF(
                lerp(start.direction.x, target.direction.x, progress),
                lerp(start.direction.y, target.direction.y, progress)
            ),
            radius = lerp(start.radius, target.radius, progress),
            angle = lerp(start.angle, target.angle, progress)
        )
    }
    
    /**
     * Linear interpolation
     * 
     * @param start Start value
     * @param end End value
     * @param t Interpolation factor (0 to 1)
     * @return Interpolated value
     */
    private fun lerp(start: Float, end: Float, t: Float): Float {
        return start + (end - start) * t
    }
    
    // ========== Easing Functions ==========
    
    /**
     * Ease-out interpolation
     * 
     * Starts fast and decelerates towards the end.
     * Uses cubic easing for smooth, natural motion.
     * 
     * Requirements: 6.3
     * 
     * @param t Input progress (0 to 1)
     * @return Eased progress (0 to 1)
     */
    private fun easeOut(t: Float): Float {
        // Cubic ease-out: 1 - (1-t)^3
        val invT = 1f - t
        return 1f - invT * invT * invT
    }
    
    /**
     * Elastic ease-out interpolation
     * 
     * Creates a bouncing effect at the end of the animation.
     * Perfect for snap-back animations.
     * 
     * Requirements: 7.2
     * 
     * @param t Input progress (0 to 1)
     * @return Eased progress (0 to 1, may slightly overshoot)
     */
    private fun elasticEaseOut(t: Float): Float {
        if (t == 0f || t == 1f) return t
        
        val p = 0.3f
        val s = p / 4f
        
        return (2f.pow(-10f * t) * sin((t - s) * (2f * PI.toFloat()) / p) + 1f).toFloat()
    }
    
    /**
     * Ease-in-out interpolation
     * 
     * Accelerates at the start and decelerates at the end.
     * Useful for smooth, symmetric animations.
     * 
     * @param t Input progress (0 to 1)
     * @return Eased progress (0 to 1)
     */
    private fun easeInOut(t: Float): Float {
        return if (t < 0.5f) {
            // Ease in (first half)
            2f * t * t
        } else {
            // Ease out (second half)
            val invT = 1f - t
            1f - 2f * invT * invT
        }
    }
    
    /**
     * Bounce ease-out interpolation
     * 
     * Creates a bouncing ball effect.
     * Alternative to elastic easing for snap-back.
     * 
     * @param t Input progress (0 to 1)
     * @return Eased progress (0 to 1)
     */
    private fun bounceEaseOut(t: Float): Float {
        return when {
            t < 1f / 2.75f -> {
                7.5625f * t * t
            }
            t < 2f / 2.75f -> {
                val t2 = t - 1.5f / 2.75f
                7.5625f * t2 * t2 + 0.75f
            }
            t < 2.5f / 2.75f -> {
                val t2 = t - 2.25f / 2.75f
                7.5625f * t2 * t2 + 0.9375f
            }
            else -> {
                val t2 = t - 2.625f / 2.75f
                7.5625f * t2 * t2 + 0.984375f
            }
        }
    }
}