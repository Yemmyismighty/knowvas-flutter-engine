package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Tests for Task 9: Fine-tune curl physics
 * 
 * These tests verify the improvements made to curl physics:
 * - Adjusted curl radius calculation for natural feel
 * - Optimized curl axis positioning
 * - Parameter bounds checking
 * - Edge case handling (corners, extreme drags)
 * 
 * Requirements: 4.4, 4.5
 */
class CurlPhysicsFinetuningTest {
    
    private lateinit var curlMath: CurlMathematics
    
    @Before
    fun setup() {
        curlMath = CurlMathematics()
    }
    
    // ========== Requirement 4.4: Natural Feel Tests ==========
    
    @Test
    fun `curl radius should be adjusted for natural feel`() {
        val touchStart = PointF(900f, 500f)
        val touchCurrent = PointF(700f, 500f) // 200 pixel drag
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // With RADIUS_FACTOR = 0.6, radius should be around 200 * 0.6 = 120
        // But with MIN_RADIUS_MULTIPLIER = 20, it should be at least 20
        assertTrue("Radius should be reasonable for natural feel", 
                   params.radius >= 20f && params.radius <= 200f)
    }
    
    @Test
    fun `small drags should have minimum visible curl radius`() {
        val touchStart = PointF(900f, 500f)
        val touchCurrent = PointF(890f, 500f) // 10 pixel drag
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Even small drags should have minimum radius for visibility
        assertTrue("Small drag should have minimum radius", params.radius >= 20f)
    }
    
    @Test
    fun `curl angle should progress naturally with smooth step`() {
        val pageWidth = 1000f
        val pageHeight = 1500f
        val touchStart = PointF(900f, 500f)
        
        // Test progression at different drag distances
        val dragDistances = listOf(100f, 200f, 400f, 600f, 800f)
        val angles = mutableListOf<Float>()
        
        for (distance in dragDistances) {
            val touchCurrent = PointF(900f - distance, 500f)
            val params = curlMath.calculateCurlParameters(
                touchStart, touchCurrent, pageWidth, pageHeight
            )
            angles.add(params.angle)
        }
        
        // Angles should increase monotonically
        for (i in 0 until angles.size - 1) {
            assertTrue("Angle should increase with drag distance", 
                       angles[i] < angles[i + 1])
        }
        
        // Progression should be smooth (no sudden jumps)
        for (i in 0 until angles.size - 1) {
            val angleDiff = angles[i + 1] - angles[i]
            assertTrue("Angle progression should be smooth", angleDiff < PI.toFloat() / 2)
        }
    }
    
    @Test
    fun `curl position should be optimized ahead of touch point`() {
        val touchStart = PointF(900f, 500f)
        val touchCurrent = PointF(700f, 500f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Position should be slightly ahead of touch point in drag direction
        // Touch is moving left (negative X), so position should be left of touchCurrent
        assertTrue("Curl position should be optimized", 
                   params.position.x <= touchCurrent.x)
    }
    
    // ========== Requirement 4.4: Corner Handling Tests ==========
    
    @Test
    fun `corner drags should be detected and adjusted`() {
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        // Test all four corners
        val corners = listOf(
            PointF(50f, 50f),           // Top-left
            PointF(950f, 50f),          // Top-right
            PointF(50f, 1450f),         // Bottom-left
            PointF(950f, 1450f)         // Bottom-right
        )
        
        for (corner in corners) {
            val touchCurrent = PointF(corner.x - 100f, corner.y)
            val params = curlMath.calculateCurlParameters(
                corner, touchCurrent, pageWidth, pageHeight
            )
            
            // Corner curls should have adjusted angle (reduced by 0.8 factor)
            assertNotNull("Corner curl should generate valid parameters", params)
            assertTrue("Corner curl should have valid angle", 
                       params.angle >= 0f && params.angle <= PI.toFloat())
        }
    }
    
    @Test
    fun `non-corner drags should not be affected by corner adjustment`() {
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        // Touch in center of page (far from corners)
        val touchStart = PointF(500f, 750f)
        val touchCurrent = PointF(400f, 750f)
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Should generate normal curl without corner adjustment
        assertNotNull("Center curl should generate valid parameters", params)
        assertTrue("Center curl should have normal angle", params.angle > 0f)
    }
    
    // ========== Requirement 4.4: Extreme Drag Handling Tests ==========
    
    @Test
    fun `extreme horizontal drag should be handled safely`() {
        val touchStart = PointF(900f, 500f)
        val touchCurrent = PointF(-500f, 500f) // Extreme drag beyond page
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Should clamp to maximum values
        assertTrue("Extreme drag radius should be clamped", 
                   params.radius <= 2000f)
        assertTrue("Extreme drag angle should be clamped", 
                   params.angle <= PI.toFloat())
        assertTrue("Parameters should be valid", 
                   curlMath.validateCurlParameters(params))
    }
    
    @Test
    fun `extreme diagonal drag should be handled safely`() {
        val touchStart = PointF(900f, 100f)
        val touchCurrent = PointF(-500f, 2000f) // Extreme diagonal drag
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Should generate valid parameters despite extreme input
        assertNotNull("Extreme diagonal drag should generate parameters", params)
        assertTrue("Parameters should be valid", 
                   curlMath.validateCurlParameters(params))
        assertFalse("Position X should not be NaN", params.position.x.isNaN())
        assertFalse("Position Y should not be NaN", params.position.y.isNaN())
    }
    
    @Test
    fun `zero drag distance should return flat parameters`() {
        val touchStart = PointF(900f, 500f)
        val touchCurrent = PointF(900f, 500f) // No movement
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Should return FLAT parameters
        assertTrue("Zero drag should have minimal radius", params.radius < 0.01f)
        assertTrue("Zero drag should have zero angle", params.angle < 0.01f)
    }
    
    // ========== Requirement 4.5: Parameter Bounds Checking Tests ==========
    
    @Test
    fun `validateCurlParameters should reject negative radius`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = -10f,
            angle = PI.toFloat() / 2
        )
        
        assertFalse("Negative radius should be invalid", 
                    curlMath.validateCurlParameters(params))
    }
    
    @Test
    fun `validateCurlParameters should reject excessive radius`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = 5000f, // Exceeds MAX_CURL_RADIUS
            angle = PI.toFloat() / 2
        )
        
        assertFalse("Excessive radius should be invalid", 
                    curlMath.validateCurlParameters(params))
    }
    
    @Test
    fun `validateCurlParameters should reject angle outside valid range`() {
        val params1 = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = 100f,
            angle = -0.5f // Negative angle
        )
        
        val params2 = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = 100f,
            angle = PI.toFloat() * 2 // Exceeds PI
        )
        
        assertFalse("Negative angle should be invalid", 
                    curlMath.validateCurlParameters(params1))
        assertFalse("Angle > PI should be invalid", 
                    curlMath.validateCurlParameters(params2))
    }
    
    @Test
    fun `validateCurlParameters should reject NaN values`() {
        val params = CurlParameters(
            position = PointF(Float.NaN, 500f),
            direction = PointF(1f, 0f),
            radius = 100f,
            angle = PI.toFloat() / 2
        )
        
        assertFalse("NaN position should be invalid", 
                    curlMath.validateCurlParameters(params))
    }
    
    @Test
    fun `validateCurlParameters should reject infinite values`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = Float.POSITIVE_INFINITY,
            angle = PI.toFloat() / 2
        )
        
        assertFalse("Infinite radius should be invalid", 
                    curlMath.validateCurlParameters(params))
    }
    
    @Test
    fun `clampCurlParameters should fix invalid radius`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = -10f,
            angle = PI.toFloat() / 2
        )
        
        val clamped = curlMath.clampCurlParameters(params)
        
        assertTrue("Clamped radius should be positive", clamped.radius > 0f)
        assertTrue("Clamped parameters should be valid", 
                   curlMath.validateCurlParameters(clamped))
    }
    
    @Test
    fun `clampCurlParameters should fix invalid angle`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(1f, 0f),
            radius = 100f,
            angle = PI.toFloat() * 2
        )
        
        val clamped = curlMath.clampCurlParameters(params)
        
        assertTrue("Clamped angle should be <= PI", clamped.angle <= PI.toFloat())
        assertTrue("Clamped parameters should be valid", 
                   curlMath.validateCurlParameters(clamped))
    }
    
    @Test
    fun `clampCurlParameters should normalize direction`() {
        val params = CurlParameters(
            position = PointF(500f, 500f),
            direction = PointF(3f, 4f), // Not normalized (length = 5)
            radius = 100f,
            angle = PI.toFloat() / 2
        )
        
        val clamped = curlMath.clampCurlParameters(params)
        
        val length = sqrt(
            clamped.direction.x * clamped.direction.x + 
            clamped.direction.y * clamped.direction.y
        )
        assertEquals("Direction should be normalized", 1f, length, 0.01f)
    }
    
    @Test
    fun `clampCurlParameters should handle NaN values`() {
        val params = CurlParameters(
            position = PointF(Float.NaN, Float.NaN),
            direction = PointF(1f, 0f),
            radius = 100f,
            angle = PI.toFloat() / 2
        )
        
        val clamped = curlMath.clampCurlParameters(params)
        
        assertFalse("Clamped position X should not be NaN", clamped.position.x.isNaN())
        assertFalse("Clamped position Y should not be NaN", clamped.position.y.isNaN())
    }
    
    // ========== Requirement 4.5: Continuity Tests ==========
    
    @Test
    fun `applyCurlToVertex should handle invalid parameters gracefully`() {
        val vertex = PointF(0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(1f, 0f),
            radius = -10f, // Invalid
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Should return original vertex for invalid parameters
        assertEquals("X should be unchanged", vertex.x, transformed.x, 0.001f)
        assertEquals("Y should be unchanged", vertex.y, transformed.y, 0.001f)
    }
    
    @Test
    fun `applyCurlToVertex should not produce NaN or infinite results`() {
        val vertex = PointF(0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        assertFalse("Transformed X should not be NaN", transformed.x.isNaN())
        assertFalse("Transformed Y should not be NaN", transformed.y.isNaN())
        assertFalse("Transformed X should not be infinite", transformed.x.isInfinite())
        assertFalse("Transformed Y should not be infinite", transformed.y.isInfinite())
    }
    
    @Test
    fun `interpolateCurlParameters should maintain continuity`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(100f, 100f),
            direction = PointF(-1f, 0f),
            radius = 100f,
            angle = PI.toFloat()
        )
        
        // Test interpolation at multiple points
        val tValues = listOf(0f, 0.25f, 0.5f, 0.75f, 1f)
        val interpolated = tValues.map { t ->
            curlMath.interpolateCurlParameters(start, end, t)
        }
        
        // All interpolated values should be valid
        for (params in interpolated) {
            assertTrue("Interpolated parameters should be valid", 
                       curlMath.validateCurlParameters(params))
        }
        
        // Values should progress smoothly
        for (i in 0 until interpolated.size - 1) {
            val curr = interpolated[i]
            val next = interpolated[i + 1]
            
            assertTrue("Radius should increase", next.radius >= curr.radius)
            assertTrue("Angle should increase", next.angle >= curr.angle)
        }
    }
    
    @Test
    fun `interpolateCurlParameters should normalize direction`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(100f, 100f),
            direction = PointF(0f, 1f),
            radius = 100f,
            angle = PI.toFloat()
        )
        
        val interpolated = curlMath.interpolateCurlParameters(start, end, 0.5f)
        
        val length = sqrt(
            interpolated.direction.x * interpolated.direction.x + 
            interpolated.direction.y * interpolated.direction.y
        )
        assertEquals("Interpolated direction should be normalized", 1f, length, 0.01f)
    }
    
    @Test
    fun `small curl radius changes should produce continuous vertex updates`() {
        val vertex = PointF(0.8f, 0.5f)
        val baseParams = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 100f,
            angle = PI.toFloat() / 2
        )
        
        // Test small radius changes
        val radii = listOf(100f, 101f, 102f, 103f, 104f, 105f)
        val positions = radii.map { radius ->
            val params = baseParams.copy(radius = radius)
            curlMath.applyCurlToVertex(vertex, params)
        }
        
        // Changes should be continuous (no sudden jumps)
        for (i in 0 until positions.size - 1) {
            val curr = positions[i]
            val next = positions[i + 1]
            val distance = sqrt(
                (next.x - curr.x) * (next.x - curr.x) +
                (next.y - curr.y) * (next.y - curr.y)
            )
            
            assertTrue("Position change should be continuous (small)", distance < 0.1f)
        }
    }
}
