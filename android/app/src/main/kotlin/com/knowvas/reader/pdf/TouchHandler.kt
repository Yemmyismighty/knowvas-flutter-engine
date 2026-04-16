package com.knowvas.reader.pdf

import android.graphics.PointF
import android.util.Log
import kotlin.math.sqrt

/**
 * TouchHandler - Handles touch events for page curl interaction
 * 
 * This class is responsible for:
 * - Detecting touch events near page edges (edge detection)
 * - Tracking touch movement during curl
 * - Determining curl direction (forward/backward)
 * - Calculating curl parameters from touch input
 * - Deciding between page turn completion and snap-back
 * 
 * Requirements: 5.1, 5.2, 5.3, 5.5
 * 
 * @param pageWidth Width of the page in pixels
 * @param pageHeight Height of the page in pixels
 * @param edgeThreshold Percentage of page width that counts as "edge" (default 0.2 = 20%)
 */
class TouchHandler(
    private val pageWidth: Float,
    private val pageHeight: Float,
    private val edgeThreshold: Float = 0.2f
) {
    companion object {
        private const val TAG = "TouchHandler"
        
        // Minimum drag distance to be considered a drag (in pixels)
        private const val MIN_DRAG_DISTANCE = 10f
        
        // Page turn threshold as percentage of page width
        private const val PAGE_TURN_THRESHOLD = 0.3f
    }
    
    // Touch state tracking
    private var touchStartPoint = PointF()
    private var touchCurrentPoint = PointF()
    private var isTouchActive = false
    private var currentDirection: Direction? = null
    
    // Curl mathematics for parameter calculation
    private val curlMath = CurlMathematics()
    
    enum class Direction {
        FORWARD,  // Turn to next page (right to left)
        BACKWARD  // Turn to previous page (left to right)
    }
    
    /**
     * Sealed class representing the result of touch handling
     * 
     * This allows the PageCurlView to respond appropriately to different
     * touch events without tight coupling.
     */
    sealed class TouchResult {
        /**
         * Touch was ignored (not near edge or during animation)
         */
        object Ignored : TouchResult()
        
        /**
         * Curl interaction started
         * @param direction Direction of the curl (forward or backward)
         */
        data class CurlStarted(val direction: Direction) : TouchResult()
        
        /**
         * Curl parameters updated during drag
         * @param params Updated curl parameters
         */
        data class CurlUpdated(val params: CurlParameters) : TouchResult()
        
        /**
         * Page turn should be completed
         * @param direction Direction of the page turn
         */
        data class PageTurnTriggered(val direction: Direction) : TouchResult()
        
        /**
         * Page should snap back to original position
         */
        object SnapBackTriggered : TouchResult()
    }
    
    /**
     * Handle touch down event
     * 
     * Requirements: 5.1, 5.2 - Edge detection
     * 
     * Determines if the touch is near a page edge and should initiate curl.
     * Touches in the center of the page are ignored.
     * 
     * @param x Touch X coordinate
     * @param y Touch Y coordinate
     * @return TouchResult indicating what action should be taken
     */
    fun handleTouchDown(x: Float, y: Float): TouchResult {
        Log.d(TAG, "handleTouchDown: x=$x, y=$y")
        
        // Store touch start position
        touchStartPoint.set(x, y)
        touchCurrentPoint.set(x, y)
        
        // Calculate edge threshold distance
        val edgeDistance = pageWidth * edgeThreshold
        
        // Check if touch is near right edge (forward page turn)
        val isNearRightEdge = x > pageWidth - edgeDistance
        
        // Check if touch is near left edge (backward page turn)
        val isNearLeftEdge = x < edgeDistance
        
        // Requirements: 5.1 - Initiate curl when touch is within edge threshold
        // Requirements: 5.2 - Ignore touch in center of page
        if (isNearRightEdge) {
            isTouchActive = true
            currentDirection = Direction.FORWARD
            Log.d(TAG, "Curl started: FORWARD (right edge)")
            return TouchResult.CurlStarted(Direction.FORWARD)
        } else if (isNearLeftEdge) {
            isTouchActive = true
            currentDirection = Direction.BACKWARD
            Log.d(TAG, "Curl started: BACKWARD (left edge)")
            return TouchResult.CurlStarted(Direction.BACKWARD)
        }
        
        // Touch is in center - ignore
        Log.d(TAG, "Touch ignored: not near edge")
        return TouchResult.Ignored
    }
    
    /**
     * Handle touch move event
     * 
     * Requirements: 5.3 - Update curl parameters during drag
     * 
     * Calculates curl parameters based on the current touch position
     * and returns them for rendering.
     * 
     * @param x Touch X coordinate
     * @param y Touch Y coordinate
     * @return TouchResult with updated curl parameters
     */
    fun handleTouchMove(x: Float, y: Float): TouchResult {
        if (!isTouchActive) {
            return TouchResult.Ignored
        }
        
        // Update current touch position
        touchCurrentPoint.set(x, y)
        
        // Calculate drag distance
        val dragDistance = calculateDistance(touchStartPoint, touchCurrentPoint)
        
        // Ignore very small movements (touch jitter)
        if (dragDistance < MIN_DRAG_DISTANCE) {
            return TouchResult.Ignored
        }
        
        // Requirements: 5.3 - Calculate curl parameters from touch input
        val curlParams = curlMath.calculateCurlParameters(
            touchStart = touchStartPoint,
            touchCurrent = touchCurrentPoint,
            pageWidth = pageWidth,
            pageHeight = pageHeight
        )
        
        Log.d(TAG, "handleTouchMove: drag=$dragDistance, radius=${curlParams.radius}")
        
        return TouchResult.CurlUpdated(curlParams)
    }
    
    /**
     * Handle touch up event
     * 
     * Requirements: 5.5 - Determine forward vs backward page turn
     * Requirements: 6.1, 7.1 - Decide between page turn and snap-back
     * 
     * Determines whether the drag was sufficient to trigger a page turn
     * or if the page should snap back to its original position.
     * 
     * @param x Touch X coordinate
     * @param y Touch Y coordinate
     * @return TouchResult indicating page turn or snap-back
     */
    fun handleTouchUp(x: Float, y: Float): TouchResult {
        if (!isTouchActive) {
            return TouchResult.Ignored
        }
        
        // Update final touch position
        touchCurrentPoint.set(x, y)
        
        // Calculate total drag distance
        val dragDistance = calculateDistance(touchStartPoint, touchCurrentPoint)
        
        // Calculate page turn threshold
        val threshold = pageWidth * PAGE_TURN_THRESHOLD
        
        Log.d(TAG, "handleTouchUp: drag=$dragDistance, threshold=$threshold")
        
        // Reset touch state
        isTouchActive = false
        val direction = currentDirection
        currentDirection = null
        
        // Requirements: 6.1, 7.1 - Page turn threshold decision
        if (dragDistance > threshold && direction != null) {
            // Drag was sufficient - complete the page turn
            Log.d(TAG, "Page turn triggered: $direction")
            return TouchResult.PageTurnTriggered(direction)
        } else {
            // Drag was insufficient - snap back
            Log.d(TAG, "Snap back triggered")
            return TouchResult.SnapBackTriggered
        }
    }
    
    /**
     * Get the current curl direction
     * 
     * Requirements: 5.5 - Curl direction detection
     * 
     * @return Current direction or null if no curl is active
     */
    fun getCurrentDirection(): Direction? {
        return currentDirection
    }
    
    /**
     * Check if touch is currently active
     * 
     * @return True if a curl interaction is in progress
     */
    fun isTouchActive(): Boolean {
        return isTouchActive
    }
    
    /**
     * Reset touch handler state
     * 
     * Should be called when curl is cancelled or animation starts
     */
    fun reset() {
        isTouchActive = false
        currentDirection = null
        touchStartPoint.set(0f, 0f)
        touchCurrentPoint.set(0f, 0f)
        Log.d(TAG, "Touch handler reset")
    }
    
    /**
     * Calculate distance between two points
     * 
     * @param p1 First point
     * @param p2 Second point
     * @return Distance in pixels
     */
    private fun calculateDistance(p1: PointF, p2: PointF): Float {
        val dx = p2.x - p1.x
        val dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /**
     * Get the current drag distance
     * 
     * @return Distance from touch start to current position
     */
    fun getDragDistance(): Float {
        return calculateDistance(touchStartPoint, touchCurrentPoint)
    }
    
    /**
     * Get the current drag direction as a normalized vector
     * 
     * @return Normalized direction vector or null if no drag
     */
    fun getDragDirection(): PointF? {
        if (!isTouchActive) {
            return null
        }
        
        val dx = touchCurrentPoint.x - touchStartPoint.x
        val dy = touchCurrentPoint.y - touchStartPoint.y
        val length = sqrt(dx * dx + dy * dy)
        
        if (length < MIN_DRAG_DISTANCE) {
            return null
        }
        
        return PointF(dx / length, dy / length)
    }
    
    /**
     * Update page dimensions
     * 
     * Should be called when the view size changes
     * 
     * @param width New page width
     * @param height New page height
     */
    fun updatePageDimensions(width: Float, height: Float) {
        // Note: This would require making pageWidth and pageHeight mutable
        // For now, create a new TouchHandler instance when dimensions change
        Log.d(TAG, "Page dimensions update requested: ${width}x${height}")
        Log.w(TAG, "TouchHandler is immutable - create new instance for dimension changes")
    }
}
