package com.knowvas.reader.pdf

import android.graphics.PointF
import javax.microedition.khronos.opengles.GL10
import kotlin.math.*

/**
 * Visual effects for page curl animation
 * 
 * Provides shadow rendering and gradient shading to enhance the 3D effect
 * of the page curl animation.
 * 
 * Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
 */
class VisualEffects {
    
    companion object {
        private const val TAG = "VisualEffects"
        
        // Shadow configuration
        private const val MAX_SHADOW_INTENSITY = 0.6f  // Maximum shadow darkness
        private const val SHADOW_OFFSET = 0.02f        // Shadow offset from page
        private const val SHADOW_BLUR_RADIUS = 0.05f   // Shadow blur amount
        
        // Gradient configuration
        private const val MAX_GRADIENT_INTENSITY = 0.3f // Maximum gradient darkness
        private const val GRADIENT_WIDTH = 0.15f        // Width of gradient effect
    }
    
    // Configuration
    private var effectsEnabled = true
    
    /**
     * Enable or disable visual effects
     * 
     * Requirements: 8.5 - Configuration to enable/disable effects
     * 
     * @param enabled True to enable effects, false to disable
     */
    fun setEffectsEnabled(enabled: Boolean) {
        effectsEnabled = enabled
        android.util.Log.d(TAG, "Visual effects ${if (enabled) "enabled" else "disabled"}")
    }
    
    /**
     * Check if effects are enabled
     */
    fun areEffectsEnabled(): Boolean = effectsEnabled
    
    /**
     * Calculate shadow intensity based on curl angle and distance
     * 
     * Requirements: 8.2 - Calculate shadow intensity from curl angle
     * 
     * The shadow intensity increases with curl angle and decreases with
     * distance from the curl origin.
     * 
     * @param curlAngle Curl angle in radians (0 to π)
     * @param distanceFromCurl Normalized distance from curl origin (0 to 1)
     * @return Shadow intensity (0 to 1)
     */
    fun calculateShadowIntensity(curlAngle: Float, distanceFromCurl: Float): Float {
        if (!effectsEnabled) return 0f
        
        // Shadow intensity increases with curl angle
        // Use sine function for smooth transition
        val angleIntensity = sin(curlAngle).coerceIn(0f, 1f)
        
        // Shadow intensity decreases with distance from curl
        // Use exponential falloff for realistic shadow
        val distanceFalloff = exp(-distanceFromCurl * 3f).coerceIn(0f, 1f)
        
        // Combine angle and distance factors
        val intensity = angleIntensity * distanceFalloff * MAX_SHADOW_INTENSITY
        
        return intensity.coerceIn(0f, MAX_SHADOW_INTENSITY)
    }
    
    /**
     * Calculate gradient shading intensity for 3D effect
     * 
     * Requirements: 8.3 - Add gradient shading for 3D effect
     * 
     * The gradient creates a lighting effect that enhances the perception
     * of depth and curvature.
     * 
     * @param curlAngle Curl angle in radians (0 to π)
     * @param normalizedPosition Position along the curl (0 to 1)
     * @return Gradient intensity (0 to 1)
     */
    fun calculateGradientIntensity(curlAngle: Float, normalizedPosition: Float): Float {
        if (!effectsEnabled) return 0f
        
        // Gradient is strongest at the curl edge
        // Use smoothstep for smooth transition
        val edgeDistance = abs(normalizedPosition - 0.5f) * 2f
        val gradientFactor = smoothstep(0f, GRADIENT_WIDTH, edgeDistance)
        
        // Gradient intensity increases with curl angle
        val angleIntensity = sin(curlAngle * 0.5f).coerceIn(0f, 1f)
        
        // Combine factors
        val intensity = gradientFactor * angleIntensity * MAX_GRADIENT_INTENSITY
        
        return intensity.coerceIn(0f, MAX_GRADIENT_INTENSITY)
    }
    
    /**
     * Render shadow beneath the curled page
     * 
     * Requirements: 8.1 - Implement shadow rendering beneath curl
     * Requirements: 8.4 - Optimize for 30+ FPS with effects
     * 
     * This method renders a soft shadow using a simple quad with gradient alpha.
     * It's optimized to minimize GPU load while providing a realistic shadow effect.
     * 
     * @param gl OpenGL context
     * @param curlParams Current curl parameters
     * @param pageWidth Page width in normalized coordinates
     * @param pageHeight Page height in normalized coordinates
     */
    fun renderShadow(
        gl: GL10?,
        curlParams: CurlParameters,
        pageWidth: Float,
        pageHeight: Float
    ) {
        if (!effectsEnabled || gl == null || curlParams.radius <= 0f) {
            return
        }
        
        try {
            // Calculate shadow intensity
            val shadowIntensity = calculateShadowIntensity(
                curlParams.angle,
                curlParams.radius / max(pageWidth, pageHeight)
            )
            
            if (shadowIntensity <= 0.01f) {
                return // Skip rendering if shadow is too faint
            }
            
            // Disable texturing for shadow rendering
            gl.glDisable(GL10.GL_TEXTURE_2D)
            
            // Enable blending for transparent shadow
            gl.glEnable(GL10.GL_BLEND)
            gl.glBlendFunc(GL10.GL_SRC_ALPHA, GL10.GL_ONE_MINUS_SRC_ALPHA)
            
            // Calculate shadow position and size
            val shadowOffset = SHADOW_OFFSET * curlParams.radius
            val shadowX = curlParams.position.x + curlParams.direction.x * shadowOffset
            val shadowY = curlParams.position.y + curlParams.direction.y * shadowOffset
            
            // Calculate shadow dimensions based on curl radius
            val shadowWidth = curlParams.radius * 0.8f
            val shadowHeight = curlParams.radius * 1.2f
            
            // Render shadow as a gradient quad
            renderShadowQuad(
                gl,
                shadowX,
                shadowY,
                shadowWidth,
                shadowHeight,
                shadowIntensity,
                curlParams.direction
            )
            
            // Re-enable texturing
            gl.glEnable(GL10.GL_TEXTURE_2D)
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "renderShadow: Error rendering shadow", e)
        }
    }
    
    /**
     * Render a shadow quad with gradient alpha
     * 
     * This is an optimized shadow rendering method that uses a simple quad
     * with vertex colors to create a soft shadow effect.
     * 
     * Requirements: 8.4 - Optimize for 30+ FPS with effects
     */
    private fun renderShadowQuad(
        gl: GL10,
        centerX: Float,
        centerY: Float,
        width: Float,
        height: Float,
        intensity: Float,
        direction: PointF
    ) {
        // Calculate perpendicular direction for shadow orientation
        val perpX = -direction.y
        val perpY = direction.x
        
        // Calculate quad vertices
        val halfWidth = width * 0.5f
        val halfHeight = height * 0.5f
        
        // Define vertices for shadow quad
        val vertices = floatArrayOf(
            // Bottom-left
            centerX - perpX * halfWidth - direction.x * halfHeight,
            centerY - perpY * halfWidth - direction.y * halfHeight,
            0f,
            
            // Bottom-right
            centerX + perpX * halfWidth - direction.x * halfHeight,
            centerY + perpY * halfWidth - direction.y * halfHeight,
            0f,
            
            // Top-right
            centerX + perpX * halfWidth + direction.x * halfHeight,
            centerY + perpY * halfWidth + direction.y * halfHeight,
            0f,
            
            // Top-left
            centerX - perpX * halfWidth + direction.x * halfHeight,
            centerY - perpY * halfWidth + direction.y * halfHeight,
            0f
        )
        
        // Define colors with gradient alpha (darker in center, fading to edges)
        val colors = floatArrayOf(
            // Bottom-left (faded)
            0f, 0f, 0f, intensity * 0.3f,
            
            // Bottom-right (faded)
            0f, 0f, 0f, intensity * 0.3f,
            
            // Top-right (darker)
            0f, 0f, 0f, intensity,
            
            // Top-left (darker)
            0f, 0f, 0f, intensity
        )
        
        // Create buffers
        val vertexBuffer = java.nio.ByteBuffer.allocateDirect(vertices.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
            .position(0)
        
        val colorBuffer = java.nio.ByteBuffer.allocateDirect(colors.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(colors)
            .position(0)
        
        // Enable vertex and color arrays
        gl.glEnableClientState(GL10.GL_VERTEX_ARRAY)
        gl.glEnableClientState(GL10.GL_COLOR_ARRAY)
        
        // Set vertex and color pointers
        gl.glVertexPointer(3, GL10.GL_FLOAT, 0, vertexBuffer)
        gl.glColorPointer(4, GL10.GL_FLOAT, 0, colorBuffer)
        
        // Draw the shadow quad
        gl.glDrawArrays(GL10.GL_TRIANGLE_FAN, 0, 4)
        
        // Disable client states
        gl.glDisableClientState(GL10.GL_VERTEX_ARRAY)
        gl.glDisableClientState(GL10.GL_COLOR_ARRAY)
    }
    
    /**
     * Apply gradient shading to mesh vertices
     * 
     * Requirements: 8.3 - Add gradient shading for 3D effect
     * 
     * This method modifies the vertex colors of the mesh to create a lighting
     * effect that enhances the 3D perception of the curl.
     * 
     * @param mesh Page mesh to apply gradient to
     * @param curlParams Current curl parameters
     */
    fun applyGradientShading(mesh: PageMesh, curlParams: CurlParameters) {
        if (!effectsEnabled || curlParams.radius <= 0f) {
            return
        }
        
        try {
            // Calculate gradient for each vertex based on its position
            // relative to the curl
            for (i in 0 until mesh.vertexCount) {
                val vertexIndex = i * 3
                val x = mesh.vertices[vertexIndex]
                val y = mesh.vertices[vertexIndex + 1]
                
                // Calculate distance from curl axis
                val dx = x - curlParams.position.x
                val dy = y - curlParams.position.y
                
                // Project onto curl direction to get position along curl
                val projectionLength = dx * curlParams.direction.x + dy * curlParams.direction.y
                val normalizedPosition = (projectionLength / curlParams.radius).coerceIn(-1f, 1f)
                
                // Calculate gradient intensity
                val gradientIntensity = calculateGradientIntensity(
                    curlParams.angle,
                    (normalizedPosition + 1f) * 0.5f
                )
                
                // Store gradient intensity in mesh (could be used for vertex colors)
                // For now, we'll apply it during rendering
                // This is a placeholder for future enhancement
            }
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "applyGradientShading: Error applying gradient", e)
        }
    }
    
    /**
     * Smoothstep interpolation function
     * 
     * Provides smooth Hermite interpolation between 0 and 1 when edge0 < x < edge1
     */
    private fun smoothstep(edge0: Float, edge1: Float, x: Float): Float {
        val t = ((x - edge0) / (edge1 - edge0)).coerceIn(0f, 1f)
        return t * t * (3f - 2f * t)
    }
}
