package com.knowvas.reader.pdf

import android.graphics.PointF
import kotlin.math.PI

/**
 * CurlParameters - Data class representing curl deformation parameters
 * 
 * This class encapsulates all the parameters needed to define a page curl:
 * - Position: Where the curl originates on the page
 * - Direction: Which way the page is curling
 * - Radius: How tight or loose the curl is
 * - Angle: How far the page has curled
 * 
 * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
 * 
 * @property position Curl origin point in screen coordinates
 * @property direction Normalized direction vector indicating curl direction
 * @property radius Curl cylinder radius in pixels (larger = looser curl)
 * @property angle Curl angle in radians (0 to π, where π is fully curled)
 */
data class CurlParameters(
    val position: PointF,
    val direction: PointF,
    val radius: Float,
    val angle: Float
) {
    companion object {
        /**
         * Flat state with no curl
         * 
         * This represents a page in its natural, uncurled state.
         * Used as the default/initial state and after curl animations complete.
         */
        val FLAT = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        
        /**
         * Maximum curl angle (180 degrees)
         * 
         * Represents a fully curled page where the curl has wrapped
         * completely around the cylinder.
         */
        const val MAX_ANGLE = PI.toFloat()
        
        /**
         * Minimum curl radius to avoid mathematical errors
         * 
         * Very small radii can cause division by zero or numerical
         * instability in the curl calculations.
         */
        const val MIN_RADIUS = 0.001f
    }
    
    /**
     * Check if this represents a flat (no curl) state
     * 
     * @return True if radius is effectively zero
     */
    fun isFlat(): Boolean {
        return radius < MIN_RADIUS
    }
    
    /**
     * Check if this represents a fully curled state
     * 
     * @return True if angle is at or near maximum
     */
    fun isFullyCurled(): Boolean {
        return angle >= MAX_ANGLE * 0.95f
    }
    
    /**
     * Get curl progress as a percentage (0 to 1)
     * 
     * @return Curl progress from 0 (flat) to 1 (fully curled)
     */
    fun getCurlProgress(): Float {
        return (angle / MAX_ANGLE).coerceIn(0f, 1f)
    }
    
    /**
     * Create a copy with validated parameters
     * 
     * Ensures all parameters are within valid ranges:
     * - Radius >= 0
     * - Angle in [0, π]
     * - Direction is normalized
     * 
     * @return Validated copy of curl parameters
     */
    fun validated(): CurlParameters {
        // Clamp radius to valid range
        val validRadius = radius.coerceAtLeast(0f)
        
        // Clamp angle to valid range
        val validAngle = angle.coerceIn(0f, MAX_ANGLE)
        
        // Normalize direction if needed
        val dirLength = kotlin.math.sqrt(
            direction.x * direction.x + direction.y * direction.y
        )
        val validDirection = if (dirLength > 0.001f) {
            PointF(direction.x / dirLength, direction.y / dirLength)
        } else {
            PointF(1f, 0f) // Default direction
        }
        
        return CurlParameters(
            position = position,
            direction = validDirection,
            radius = validRadius,
            angle = validAngle
        )
    }
    
    override fun toString(): String {
        return "CurlParameters(pos=(${position.x}, ${position.y}), " +
               "dir=(${direction.x}, ${direction.y}), " +
               "radius=$radius, angle=${Math.toDegrees(angle.toDouble())}°)"
    }
}
