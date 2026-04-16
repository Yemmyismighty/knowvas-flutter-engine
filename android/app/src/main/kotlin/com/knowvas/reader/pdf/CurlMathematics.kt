package com.knowvas.reader.pdf

import android.graphics.PointF
import android.util.Log
import kotlin.math.*

/**
 * CurlMathematics - Implements cylindrical curl deformation for realistic page turning
 * 
 * This class provides the mathematical foundation for the page curl effect using
 * a cylindrical transformation model. The curl wraps the page around an imaginary
 * cylinder, creating a realistic 3D page turning effect.
 * 
 * Based on the cylindrical curl model described in:
 * "Turning Pages of 3D Electronic Books" by Hong et al.
 * 
 * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
 * 
 * Key Concepts:
 * - Curl Axis: The line around which the page curls (perpendicular to curl direction)
 * - Curl Radius: The radius of the cylindrical curl
 * - Curl Angle: How far the page has curled (0 to π radians)
 * - Inside/Outside: Vertices inside the curl radius are deformed, outside remain flat
 */
class CurlMathematics {
    
    companion object {
        private const val TAG = "CurlMathematics"
        
        // Smoothness threshold for curl boundary transitions
        // Vertices within this distance of the curl radius get smoothed
        private const val SMOOTHNESS_THRESHOLD = 0.05f
        
        // Minimum curl radius to avoid division by zero
        private const val MIN_CURL_RADIUS = 0.001f
        
        // Maximum curl radius to prevent extreme deformations
        // Requirements: 4.4 - Handle edge cases
        private const val MAX_CURL_RADIUS = 2000f
        
        // Radius calculation factor for natural feel
        // Requirements: 4.4 - Adjust curl radius for natural feel
        // Lower values = tighter curl, higher values = looser curl
        private const val RADIUS_FACTOR = 0.6f
        
        // Minimum radius multiplier for small drags
        // Ensures curl is visible even for small drag distances
        private const val MIN_RADIUS_MULTIPLIER = 20f
        
        // Corner detection threshold (distance from corner)
        // Requirements: 4.4 - Handle edge cases (corners)
        private const val CORNER_THRESHOLD = 100f
        
        // Maximum angle to prevent over-curling
        private const val MAX_CURL_ANGLE = PI.toFloat()
        
        // Angle scaling factor for more natural progression
        // Requirements: 4.4 - Natural feel
        private const val ANGLE_SCALE_FACTOR = 0.8f
    }
    
    /**
     * Calculate curl parameters from touch input
     * 
     * Converts touch coordinates and drag distance into curl parameters
     * that can be used to deform the mesh.
     * 
     * Requirements: 5.3
     * 
     * @param touchStart Initial touch position
     * @param touchCurrent Current touch position
     * @param pageWidth Width of the page in pixels
     * @param pageHeight Height of the page in pixels
     * @return CurlParameters containing position, direction, radius, and angle
     */
    fun calculateCurlParameters(
        touchStart: PointF,
        touchCurrent: PointF,
        pageWidth: Float,
        pageHeight: Float
    ): CurlParameters {
        // Requirements: 4.4, 4.5 - Fine-tuned curl physics
        
        // Calculate drag vector
        val dragX = touchCurrent.x - touchStart.x
        val dragY = touchCurrent.y - touchStart.y
        val dragDistance = sqrt(dragX * dragX + dragY * dragY)
        
        // Handle zero drag distance edge case
        if (dragDistance < MIN_CURL_RADIUS) {
            return CurlParameters.FLAT
        }
        
        // Normalize drag direction
        val directionX = dragX / dragDistance
        val directionY = dragY / dragDistance
        
        // Requirements: 4.4 - Adjust curl radius for natural feel
        // Use improved radius calculation with configurable factor
        // Ensures minimum visible curl even for small drags
        val baseRadius = dragDistance * RADIUS_FACTOR
        val minRadius = MIN_RADIUS_MULTIPLIER
        val radius = max(baseRadius, minRadius).coerceIn(MIN_CURL_RADIUS, MAX_CURL_RADIUS)
        
        // Requirements: 4.4 - Handle edge cases (corners)
        // Detect if touch is near a corner and adjust curl behavior
        val isNearCorner = isNearCorner(touchStart, pageWidth, pageHeight)
        val cornerAdjustment = if (isNearCorner) 0.8f else 1.0f
        
        // Requirements: 4.4 - Natural angle progression
        // Calculate curl angle with improved scaling for more natural feel
        val maxDragDistance = sqrt(pageWidth * pageWidth + pageHeight * pageHeight)
        val normalizedDrag = (dragDistance / maxDragDistance).coerceIn(0f, 1f)
        
        // Apply non-linear scaling for more natural curl progression
        // Slower start, faster middle, slower end (ease-in-out)
        val scaledProgress = smoothStep(normalizedDrag)
        val angle = (scaledProgress * PI * ANGLE_SCALE_FACTOR * cornerAdjustment)
            .toFloat()
            .coerceIn(0f, MAX_CURL_ANGLE)
        
        // Requirements: 4.4 - Optimize curl axis positioning
        // Position curl slightly ahead of touch point for better visual effect
        val positionOffset = 0.1f * dragDistance
        val position = PointF(
            touchCurrent.x + directionX * positionOffset,
            touchCurrent.y + directionY * positionOffset
        )
        
        // Ensure position stays within reasonable bounds
        val clampedPosition = PointF(
            position.x.coerceIn(-pageWidth * 0.5f, pageWidth * 1.5f),
            position.y.coerceIn(-pageHeight * 0.5f, pageHeight * 1.5f)
        )
        
        // Curl direction is the normalized drag direction
        val direction = PointF(directionX, directionY)
        
        Log.d(TAG, "calculateCurlParameters: drag=$dragDistance, radius=$radius, " +
                   "angle=${Math.toDegrees(angle.toDouble())}°, corner=$isNearCorner")
        
        // Requirements: 4.5 - Parameter bounds checking
        val params = CurlParameters(
            position = clampedPosition,
            direction = direction,
            radius = radius,
            angle = angle
        )
        
        // Validate parameters before returning
        return if (validateCurlParameters(params)) {
            params
        } else {
            Log.w(TAG, "Invalid curl parameters generated, returning FLAT")
            CurlParameters.FLAT
        }
    }
    
    /**
     * Check if a point is near a corner of the page
     * 
     * Requirements: 4.4 - Handle edge cases (corners)
     * 
     * @param point Point to check
     * @param pageWidth Page width
     * @param pageHeight Page height
     * @return True if point is near any corner
     */
    private fun isNearCorner(point: PointF, pageWidth: Float, pageHeight: Float): Boolean {
        // Check distance to each corner
        val corners = listOf(
            PointF(0f, 0f),                    // Top-left
            PointF(pageWidth, 0f),             // Top-right
            PointF(0f, pageHeight),            // Bottom-left
            PointF(pageWidth, pageHeight)      // Bottom-right
        )
        
        return corners.any { corner ->
            val dx = point.x - corner.x
            val dy = point.y - corner.y
            val distance = sqrt(dx * dx + dy * dy)
            distance < CORNER_THRESHOLD
        }
    }
    
    /**
     * Smooth step interpolation function
     * 
     * Requirements: 4.4 - Natural feel
     * 
     * Provides smooth ease-in-out interpolation for more natural curl progression.
     * Uses the smoothstep function: 3t² - 2t³
     * 
     * @param t Input value (0 to 1)
     * @return Smoothed value (0 to 1)
     */
    private fun smoothStep(t: Float): Float {
        val clamped = t.coerceIn(0f, 1f)
        return clamped * clamped * (3f - 2f * clamped)
    }
    
    /**
     * Apply cylindrical curl transformation to a vertex
     * 
     * This is the core curl deformation algorithm. It transforms a flat vertex
     * into a curled position using cylindrical coordinates.
     * 
     * Requirements: 4.1, 4.2, 4.3, 4.4
     * 
     * Algorithm:
     * 1. Calculate distance from vertex to curl axis
     * 2. If distance < curl radius: apply cylindrical transformation
     * 3. If distance >= curl radius: keep vertex flat
     * 4. Apply smoothing at the boundary for seamless transitions
     * 
     * @param vertex Original vertex position (normalized coordinates -1 to 1)
     * @param curlParams Curl parameters (position, direction, radius, angle)
     * @return Transformed vertex position in 3D space (x, y, z)
     */
    fun applyCurlToVertex(
        vertex: PointF,
        curlParams: CurlParameters
    ): PointF {
        // Requirements: 4.4, 4.5 - Handle edge cases and ensure continuity
        
        // If no curl, return original vertex
        if (curlParams.radius < MIN_CURL_RADIUS || curlParams.angle < 0.001f) {
            return PointF(vertex.x, vertex.y)
        }
        
        // Requirements: 4.5 - Parameter bounds checking
        // Validate curl parameters before applying transformation
        if (!validateCurlParameters(curlParams)) {
            Log.w(TAG, "Invalid curl parameters in applyCurlToVertex, returning original vertex")
            return PointF(vertex.x, vertex.y)
        }
        
        // Calculate curl axis (perpendicular to curl direction)
        // The axis is the line around which the page curls
        val axisX = -curlParams.direction.y
        val axisY = curlParams.direction.x
        
        // Calculate vector from curl position to vertex
        val toVertexX = vertex.x - curlParams.position.x
        val toVertexY = vertex.y - curlParams.position.y
        
        // Project vertex onto curl direction to find position along curl axis
        val alongCurl = toVertexX * curlParams.direction.x + toVertexY * curlParams.direction.y
        
        // Calculate perpendicular distance from vertex to curl axis
        // This determines if the vertex is inside or outside the curl radius
        val perpX = toVertexX - alongCurl * curlParams.direction.x
        val perpY = toVertexY - alongCurl * curlParams.direction.y
        val distanceFromAxis = sqrt(perpX * perpX + perpY * perpY)
        
        // Requirements: 4.2, 4.3 - Handle vertices inside and outside curl radius
        if (distanceFromAxis >= curlParams.radius) {
            // Vertex is outside curl radius - keep it flat
            return PointF(vertex.x, vertex.y)
        }
        
        // Vertex is inside curl radius - apply cylindrical transformation
        // Requirements: 4.1 - Cylindrical curl transformation
        
        // Requirements: 4.4 - Handle edge cases (extreme values)
        // Clamp distance ratio to prevent numerical issues
        val distanceRatio = (distanceFromAxis / curlParams.radius).coerceIn(0f, 1f)
        
        // Calculate angle around the cylinder based on distance from axis
        val theta = distanceRatio * curlParams.angle
        
        // Requirements: 4.4 - Handle edge cases (extreme angles)
        // Ensure theta is within valid range
        val clampedTheta = theta.coerceIn(0f, MAX_CURL_ANGLE)
        
        // Calculate new position on cylinder surface
        // The cylinder wraps the page in 3D space
        val cylinderX = curlParams.radius * sin(clampedTheta)
        val cylinderY = curlParams.radius * (1 - cos(clampedTheta))
        
        // Transform back to world coordinates
        // Rotate the cylinder coordinates by the curl direction
        val worldX = curlParams.position.x + 
                     alongCurl * curlParams.direction.x + 
                     cylinderX * axisX
        val worldY = curlParams.position.y + 
                     alongCurl * curlParams.direction.y + 
                     cylinderX * axisY
        
        // Requirements: 4.4 - Smooth transitions at curl boundary
        // Requirements: 4.5 - Continuous curl updates
        // Apply smoothing near the boundary to avoid visual discontinuities
        val smoothFactor = calculateSmoothFactor(distanceFromAxis, curlParams.radius)
        
        // Requirements: 4.4 - Handle edge cases (extreme drags)
        // Ensure final position is reasonable (not NaN or infinite)
        val deltaX = worldX - vertex.x
        val deltaY = worldY - vertex.y
        
        if (deltaX.isNaN() || deltaX.isInfinite() || deltaY.isNaN() || deltaY.isInfinite()) {
            Log.w(TAG, "Invalid transformation result, returning original vertex")
            return PointF(vertex.x, vertex.y)
        }
        
        val finalX = vertex.x + deltaX * smoothFactor
        val finalY = vertex.y + deltaY * smoothFactor
        
        return PointF(finalX, finalY)
    }
    
    /**
     * Apply curl transformation to a 3D vertex
     * 
     * This version returns a 3D point with Z-depth for proper 3D rendering.
     * 
     * Requirements: 4.1, 4.2, 4.3, 4.4
     * 
     * @param vertex Original vertex position (x, y, z)
     * @param curlParams Curl parameters
     * @return Transformed vertex position (x, y, z)
     */
    fun applyCurlToVertex3D(
        vertexX: Float,
        vertexY: Float,
        vertexZ: Float,
        curlParams: CurlParameters
    ): FloatArray {
        // Requirements: 4.4, 4.5 - Handle edge cases and ensure continuity
        
        // If no curl, return original vertex
        if (curlParams.radius < MIN_CURL_RADIUS || curlParams.angle < 0.001f) {
            return floatArrayOf(vertexX, vertexY, vertexZ)
        }
        
        // Requirements: 4.5 - Parameter bounds checking
        if (!validateCurlParameters(curlParams)) {
            Log.w(TAG, "Invalid curl parameters in applyCurlToVertex3D, returning original vertex")
            return floatArrayOf(vertexX, vertexY, vertexZ)
        }
        
        // Calculate curl axis (perpendicular to curl direction)
        val axisX = -curlParams.direction.y
        val axisY = curlParams.direction.x
        
        // Calculate vector from curl position to vertex
        val toVertexX = vertexX - curlParams.position.x
        val toVertexY = vertexY - curlParams.position.y
        
        // Project vertex onto curl direction
        val alongCurl = toVertexX * curlParams.direction.x + toVertexY * curlParams.direction.y
        
        // Calculate perpendicular distance from vertex to curl axis
        val perpX = toVertexX - alongCurl * curlParams.direction.x
        val perpY = toVertexY - alongCurl * curlParams.direction.y
        val distanceFromAxis = sqrt(perpX * perpX + perpY * perpY)
        
        // Requirements: 4.2, 4.3 - Handle vertices inside and outside curl radius
        if (distanceFromAxis >= curlParams.radius) {
            // Vertex is outside curl radius - keep it flat
            return floatArrayOf(vertexX, vertexY, vertexZ)
        }
        
        // Vertex is inside curl radius - apply cylindrical transformation
        // Requirements: 4.1 - Cylindrical curl transformation
        
        // Requirements: 4.4 - Handle edge cases (extreme values)
        val distanceRatio = (distanceFromAxis / curlParams.radius).coerceIn(0f, 1f)
        
        // Calculate angle around the cylinder
        val theta = distanceRatio * curlParams.angle
        val clampedTheta = theta.coerceIn(0f, MAX_CURL_ANGLE)
        
        // Calculate new position on cylinder surface
        val cylinderX = curlParams.radius * sin(clampedTheta)
        val cylinderY = curlParams.radius * (1 - cos(clampedTheta))
        val cylinderZ = -curlParams.radius * sin(clampedTheta) * 0.5f // Z-depth for 3D effect
        
        // Transform back to world coordinates
        val worldX = curlParams.position.x + 
                     alongCurl * curlParams.direction.x + 
                     cylinderX * axisX
        val worldY = curlParams.position.y + 
                     alongCurl * curlParams.direction.y + 
                     cylinderX * axisY
        val worldZ = vertexZ + cylinderZ
        
        // Requirements: 4.4 - Smooth transitions at curl boundary
        // Requirements: 4.5 - Continuous curl updates
        val smoothFactor = calculateSmoothFactor(distanceFromAxis, curlParams.radius)
        
        // Requirements: 4.4 - Handle edge cases (extreme drags)
        val deltaX = worldX - vertexX
        val deltaY = worldY - vertexY
        val deltaZ = worldZ - vertexZ
        
        if (deltaX.isNaN() || deltaX.isInfinite() || 
            deltaY.isNaN() || deltaY.isInfinite() ||
            deltaZ.isNaN() || deltaZ.isInfinite()) {
            Log.w(TAG, "Invalid 3D transformation result, returning original vertex")
            return floatArrayOf(vertexX, vertexY, vertexZ)
        }
        
        val finalX = vertexX + deltaX * smoothFactor
        val finalY = vertexY + deltaY * smoothFactor
        val finalZ = vertexZ + deltaZ * smoothFactor
        
        return floatArrayOf(finalX, finalY, finalZ)
    }
    
    /**
     * Calculate smooth factor for curl boundary transitions
     * 
     * Requirements: 4.4 - Maintain smooth transitions between curled and flat regions
     * 
     * Uses a smoothstep function to create seamless transitions at the curl boundary.
     * This prevents visible discontinuities or "popping" at the edge of the curl.
     * 
     * @param distance Distance from curl axis
     * @param radius Curl radius
     * @return Smooth factor (0 to 1)
     */
    private fun calculateSmoothFactor(distance: Float, radius: Float): Float {
        // Calculate how close we are to the boundary
        val boundaryDistance = radius - distance
        
        // If we're far from the boundary, full curl effect
        if (boundaryDistance > SMOOTHNESS_THRESHOLD) {
            return 1f
        }
        
        // If we're at or past the boundary, no curl effect
        if (boundaryDistance <= 0) {
            return 0f
        }
        
        // We're near the boundary - apply smoothstep interpolation
        // This creates a smooth S-curve transition
        val t = boundaryDistance / SMOOTHNESS_THRESHOLD
        return t * t * (3f - 2f * t) // Smoothstep formula
    }
    
    /**
     * Calculate distance from a point to the curl axis
     * 
     * Helper method for testing and debugging.
     * 
     * @param point Point to measure from
     * @param curlParams Curl parameters
     * @return Distance from point to curl axis
     */
    fun calculateDistanceFromCurlAxis(
        point: PointF,
        curlParams: CurlParameters
    ): Float {
        // Calculate vector from curl position to point
        val toPointX = point.x - curlParams.position.x
        val toPointY = point.y - curlParams.position.y
        
        // Project point onto curl direction
        val alongCurl = toPointX * curlParams.direction.x + toPointY * curlParams.direction.y
        
        // Calculate perpendicular distance
        val perpX = toPointX - alongCurl * curlParams.direction.x
        val perpY = toPointY - alongCurl * curlParams.direction.y
        
        return sqrt(perpX * perpX + perpY * perpY)
    }
    
    /**
     * Check if a vertex is inside the curl radius
     * 
     * Requirements: 4.2, 4.3
     * 
     * @param vertex Vertex position
     * @param curlParams Curl parameters
     * @return True if vertex is inside curl radius
     */
    fun isVertexInsideCurlRadius(
        vertex: PointF,
        curlParams: CurlParameters
    ): Boolean {
        val distance = calculateDistanceFromCurlAxis(vertex, curlParams)
        return distance < curlParams.radius
    }
    
    /**
     * Validate curl parameters
     * 
     * Requirements: 4.5 - Parameter bounds checking
     * 
     * Ensures curl parameters are within valid ranges to prevent
     * mathematical errors or visual artifacts.
     * 
     * @param curlParams Curl parameters to validate
     * @return True if parameters are valid
     */
    fun validateCurlParameters(curlParams: CurlParameters): Boolean {
        // Check radius is positive and within bounds
        if (curlParams.radius < 0) {
            Log.w(TAG, "Invalid curl radius: ${curlParams.radius} (negative)")
            return false
        }
        
        if (curlParams.radius > MAX_CURL_RADIUS) {
            Log.w(TAG, "Invalid curl radius: ${curlParams.radius} (exceeds maximum)")
            return false
        }
        
        // Check angle is in valid range (0 to π)
        if (curlParams.angle < 0 || curlParams.angle > PI) {
            Log.w(TAG, "Invalid curl angle: ${curlParams.angle}")
            return false
        }
        
        // Check for NaN or infinite values
        if (curlParams.radius.isNaN() || curlParams.radius.isInfinite() ||
            curlParams.angle.isNaN() || curlParams.angle.isInfinite() ||
            curlParams.position.x.isNaN() || curlParams.position.x.isInfinite() ||
            curlParams.position.y.isNaN() || curlParams.position.y.isInfinite() ||
            curlParams.direction.x.isNaN() || curlParams.direction.x.isInfinite() ||
            curlParams.direction.y.isNaN() || curlParams.direction.y.isInfinite()) {
            Log.w(TAG, "Invalid curl parameters: contains NaN or Infinite values")
            return false
        }
        
        // Check direction is normalized (length ≈ 1)
        val dirLength = sqrt(
            curlParams.direction.x * curlParams.direction.x + 
            curlParams.direction.y * curlParams.direction.y
        )
        if (abs(dirLength - 1f) > 0.1f && dirLength > 0) {
            Log.w(TAG, "Curl direction not normalized: length=$dirLength")
            return false
        }
        
        return true
    }
    
    /**
     * Clamp curl parameters to safe ranges
     * 
     * Requirements: 4.4, 4.5 - Handle edge cases and parameter bounds
     * 
     * Takes potentially invalid curl parameters and clamps them to safe,
     * valid ranges. This is useful for handling extreme user input.
     * 
     * @param curlParams Curl parameters to clamp
     * @return Clamped curl parameters
     */
    fun clampCurlParameters(curlParams: CurlParameters): CurlParameters {
        // Clamp radius to valid range
        val clampedRadius = curlParams.radius.coerceIn(MIN_CURL_RADIUS, MAX_CURL_RADIUS)
        
        // Clamp angle to valid range
        val clampedAngle = curlParams.angle.coerceIn(0f, MAX_CURL_ANGLE)
        
        // Normalize direction
        val dirLength = sqrt(
            curlParams.direction.x * curlParams.direction.x + 
            curlParams.direction.y * curlParams.direction.y
        )
        val clampedDirection = if (dirLength > 0.001f) {
            PointF(
                curlParams.direction.x / dirLength,
                curlParams.direction.y / dirLength
            )
        } else {
            PointF(1f, 0f) // Default direction
        }
        
        // Handle NaN or infinite values in position
        val clampedPosition = PointF(
            if (curlParams.position.x.isNaN() || curlParams.position.x.isInfinite()) 0f 
            else curlParams.position.x,
            if (curlParams.position.y.isNaN() || curlParams.position.y.isInfinite()) 0f 
            else curlParams.position.y
        )
        
        return CurlParameters(
            position = clampedPosition,
            direction = clampedDirection,
            radius = clampedRadius,
            angle = clampedAngle
        )
    }
    
    /**
     * Interpolate between two curl parameters
     * 
     * Used for smooth animations between curl states.
     * Requirements: 4.5 - Continuous curl updates
     * 
     * @param start Starting curl parameters
     * @param end Ending curl parameters
     * @param t Interpolation factor (0 to 1)
     * @return Interpolated curl parameters
     */
    fun interpolateCurlParameters(
        start: CurlParameters,
        end: CurlParameters,
        t: Float
    ): CurlParameters {
        // Requirements: 4.5 - Ensure continuous updates
        val clampedT = t.coerceIn(0f, 1f)
        
        // Apply smooth interpolation for more natural animation
        val smoothT = smoothStep(clampedT)
        
        // Interpolate position
        val position = PointF(
            start.position.x + (end.position.x - start.position.x) * smoothT,
            start.position.y + (end.position.y - start.position.y) * smoothT
        )
        
        // Interpolate direction with normalization
        val dirX = start.direction.x + (end.direction.x - start.direction.x) * smoothT
        val dirY = start.direction.y + (end.direction.y - start.direction.y) * smoothT
        val dirLength = sqrt(dirX * dirX + dirY * dirY)
        val direction = if (dirLength > 0.001f) {
            PointF(dirX / dirLength, dirY / dirLength)
        } else {
            PointF(start.direction.x, start.direction.y)
        }
        
        // Interpolate radius with minimum bounds
        val radius = (start.radius + (end.radius - start.radius) * smoothT)
            .coerceAtLeast(MIN_CURL_RADIUS)
        
        // Interpolate angle with bounds checking
        val angle = (start.angle + (end.angle - start.angle) * smoothT)
            .coerceIn(0f, MAX_CURL_ANGLE)
        
        val params = CurlParameters(
            position = position,
            direction = direction,
            radius = radius,
            angle = angle
        )
        
        // Requirements: 4.5 - Validate interpolated parameters
        return if (validateCurlParameters(params)) {
            params
        } else {
            Log.w(TAG, "Invalid interpolated parameters, returning start")
            start
        }
    }
}
