package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Unit tests for CurlMathematics
 * 
 * These tests verify the cylindrical curl transformation algorithm,
 * curl parameter calculation, and vertex deformation logic.
 * 
 * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
 */
class CurlMathematicsTest {
    
    private lateinit var curlMath: CurlMathematics
    
    @Before
    fun setup() {
        curlMath = CurlMathematics()
    }
    
    // ========== Curl Parameter Calculation Tests ==========
    
    @Test
    fun `calculateCurlParameters should calculate correct drag distance`() {
        val touchStart = PointF(100f, 100f)
        val touchCurrent = PointF(200f, 100f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Drag distance is 100 pixels
        // Radius should be approximately 50 (dragDistance * 0.5)
        assertTrue("Radius should be around 50", abs(params.radius - 50f) < 5f)
    }
    
    @Test
    fun `calculateCurlParameters should normalize direction vector`() {
        val touchStart = PointF(100f, 100f)
        val touchCurrent = PointF(200f, 200f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Direction should be normalized (length = 1)
        val length = sqrt(
            params.direction.x * params.direction.x + 
            params.direction.y * params.direction.y
        )
        assertEquals("Direction should be normalized", 1f, length, 0.01f)
    }
    
    @Test
    fun `calculateCurlParameters should handle zero drag distance`() {
        val touchStart = PointF(100f, 100f)
        val touchCurrent = PointF(100f, 100f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Should have minimum radius and zero angle
        assertTrue("Radius should be minimal", params.radius > 0f && params.radius < 0.01f)
        assertEquals("Angle should be zero", 0f, params.angle, 0.01f)
    }
    
    @Test
    fun `calculateCurlParameters should calculate angle based on drag distance`() {
        val touchStart = PointF(0f, 500f)
        val touchCurrent = PointF(1000f, 500f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Full width drag should give significant angle
        assertTrue("Angle should be positive", params.angle > 0f)
        assertTrue("Angle should be less than PI", params.angle <= PI.toFloat())
    }
    
    // ========== Vertex Transformation Tests ==========
    
    @Test
    fun `applyCurlToVertex should keep vertex flat when radius is zero`() {
        val vertex = PointF(0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Vertex should remain unchanged
        assertEquals("X should be unchanged", vertex.x, transformed.x, 0.001f)
        assertEquals("Y should be unchanged", vertex.y, transformed.y, 0.001f)
    }
    
    @Test
    fun `applyCurlToVertex should keep vertex flat when outside curl radius`() {
        val vertex = PointF(-0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.3f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Vertex is far from curl position, should remain unchanged
        assertEquals("X should be unchanged", vertex.x, transformed.x, 0.001f)
        assertEquals("Y should be unchanged", vertex.y, transformed.y, 0.001f)
    }
    
    @Test
    fun `applyCurlToVertex should transform vertex inside curl radius`() {
        val vertex = PointF(0.8f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Vertex should be transformed (moved from original position)
        val moved = abs(transformed.x - vertex.x) > 0.01f || 
                    abs(transformed.y - vertex.y) > 0.01f
        assertTrue("Vertex should be transformed", moved)
    }
    
    @Test
    fun `applyCurlToVertex3D should return original position when radius is zero`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex3D(0.5f, 0.5f, 0f, params)
        
        assertEquals("X should be unchanged", 0.5f, transformed[0], 0.001f)
        assertEquals("Y should be unchanged", 0.5f, transformed[1], 0.001f)
        assertEquals("Z should be unchanged", 0f, transformed[2], 0.001f)
    }
    
    @Test
    fun `applyCurlToVertex3D should add Z-depth for curled vertices`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex3D(0.8f, 0.5f, 0f, params)
        
        // Z coordinate should change for curled vertex
        assertNotEquals("Z should change", 0f, transformed[2], 0.001f)
    }
    
    // ========== Distance Calculation Tests ==========
    
    @Test
    fun `calculateDistanceFromCurlAxis should return correct distance`() {
        val point = PointF(0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val distance = curlMath.calculateDistanceFromCurlAxis(point, params)
        
        // Point is 0.5 units away from curl position along the curl direction
        // Perpendicular distance should be 0 (point is on the curl axis)
        assertEquals("Distance should be zero", 0f, distance, 0.01f)
    }
    
    @Test
    fun `calculateDistanceFromCurlAxis should handle perpendicular points`() {
        val point = PointF(1f, 1f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val distance = curlMath.calculateDistanceFromCurlAxis(point, params)
        
        // Point is 0.5 units perpendicular to curl axis
        assertEquals("Distance should be 0.5", 0.5f, distance, 0.01f)
    }
    
    @Test
    fun `isVertexInsideCurlRadius should return true for vertices inside radius`() {
        val vertex = PointF(0.8f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val isInside = curlMath.isVertexInsideCurlRadius(vertex, params)
        
        assertTrue("Vertex should be inside curl radius", isInside)
    }
    
    @Test
    fun `isVertexInsideCurlRadius should return false for vertices outside radius`() {
        val vertex = PointF(-0.5f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.3f,
            angle = PI.toFloat() / 2
        )
        
        val isInside = curlMath.isVertexInsideCurlRadius(vertex, params)
        
        assertFalse("Vertex should be outside curl radius", isInside)
    }
    
    // ========== Parameter Validation Tests ==========
    
    @Test
    fun `validateCurlParameters should accept valid parameters`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val isValid = curlMath.validateCurlParameters(params)
        
        assertTrue("Parameters should be valid", isValid)
    }
    
    @Test
    fun `validateCurlParameters should reject negative radius`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = -0.5f,
            angle = PI.toFloat() / 2
        )
        
        val isValid = curlMath.validateCurlParameters(params)
        
        assertFalse("Negative radius should be invalid", isValid)
    }
    
    @Test
    fun `validateCurlParameters should reject angle outside valid range`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() * 2 // Greater than PI
        )
        
        val isValid = curlMath.validateCurlParameters(params)
        
        assertFalse("Angle > PI should be invalid", isValid)
    }
    
    @Test
    fun `validateCurlParameters should accept zero radius`() {
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0f,
            angle = 0f
        )
        
        val isValid = curlMath.validateCurlParameters(params)
        
        assertTrue("Zero radius should be valid", isValid)
    }
    
    // ========== Interpolation Tests ==========
    
    @Test
    fun `interpolateCurlParameters should interpolate at t=0`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(1f, 1f),
            direction = PointF(-1f, 0f),
            radius = 1f,
            angle = PI.toFloat()
        )
        
        val interpolated = curlMath.interpolateCurlParameters(start, end, 0f)
        
        assertEquals("Position X should be start", start.position.x, interpolated.position.x, 0.001f)
        assertEquals("Position Y should be start", start.position.y, interpolated.position.y, 0.001f)
        assertEquals("Radius should be start", start.radius, interpolated.radius, 0.001f)
        assertEquals("Angle should be start", start.angle, interpolated.angle, 0.001f)
    }
    
    @Test
    fun `interpolateCurlParameters should interpolate at t=1`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(1f, 1f),
            direction = PointF(-1f, 0f),
            radius = 1f,
            angle = PI.toFloat()
        )
        
        val interpolated = curlMath.interpolateCurlParameters(start, end, 1f)
        
        assertEquals("Position X should be end", end.position.x, interpolated.position.x, 0.001f)
        assertEquals("Position Y should be end", end.position.y, interpolated.position.y, 0.001f)
        assertEquals("Radius should be end", end.radius, interpolated.radius, 0.001f)
        assertEquals("Angle should be end", end.angle, interpolated.angle, 0.001f)
    }
    
    @Test
    fun `interpolateCurlParameters should interpolate at t=0_5`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(1f, 1f),
            direction = PointF(-1f, 0f),
            radius = 1f,
            angle = PI.toFloat()
        )
        
        val interpolated = curlMath.interpolateCurlParameters(start, end, 0.5f)
        
        assertEquals("Position X should be midpoint", 0.5f, interpolated.position.x, 0.001f)
        assertEquals("Position Y should be midpoint", 0.5f, interpolated.position.y, 0.001f)
        assertEquals("Radius should be midpoint", 0.5f, interpolated.radius, 0.001f)
        assertEquals("Angle should be midpoint", PI.toFloat() / 2, interpolated.angle, 0.001f)
    }
    
    @Test
    fun `interpolateCurlParameters should clamp t to valid range`() {
        val start = CurlParameters(
            position = PointF(0f, 0f),
            direction = PointF(1f, 0f),
            radius = 0f,
            angle = 0f
        )
        val end = CurlParameters(
            position = PointF(1f, 1f),
            direction = PointF(-1f, 0f),
            radius = 1f,
            angle = PI.toFloat()
        )
        
        // Test t > 1
        val interpolated1 = curlMath.interpolateCurlParameters(start, end, 2f)
        assertEquals("Should clamp to end", end.position.x, interpolated1.position.x, 0.001f)
        
        // Test t < 0
        val interpolated2 = curlMath.interpolateCurlParameters(start, end, -1f)
        assertEquals("Should clamp to start", start.position.x, interpolated2.position.x, 0.001f)
    }
    
    // ========== Edge Case Tests ==========
    
    @Test
    fun `applyCurlToVertex should handle vertex at curl position`() {
        val vertex = PointF(1f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() / 2
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Vertex at curl position should be on the curl axis (distance = 0)
        // Should remain relatively unchanged
        val distance = sqrt(
            (transformed.x - vertex.x) * (transformed.x - vertex.x) +
            (transformed.y - vertex.y) * (transformed.y - vertex.y)
        )
        assertTrue("Vertex at curl position should move minimally", distance < 0.1f)
    }
    
    @Test
    fun `applyCurlToVertex should handle maximum curl angle`() {
        val vertex = PointF(0.8f, 0.5f)
        val params = CurlParameters(
            position = PointF(1f, 0.5f),
            direction = PointF(-1f, 0f),
            radius = 0.5f,
            angle = PI.toFloat() // Maximum angle
        )
        
        val transformed = curlMath.applyCurlToVertex(vertex, params)
        
        // Should transform without errors
        assertNotNull("Transformed vertex should not be null", transformed)
    }
    
    @Test
    fun `calculateCurlParameters should handle diagonal drag`() {
        val touchStart = PointF(100f, 100f)
        val touchCurrent = PointF(200f, 200f)
        val pageWidth = 1000f
        val pageHeight = 1500f
        
        val params = curlMath.calculateCurlParameters(
            touchStart, touchCurrent, pageWidth, pageHeight
        )
        
        // Direction should be normalized diagonal
        val expectedLength = sqrt(2f) / 2f // Normalized diagonal component
        assertEquals("Direction X should be normalized", expectedLength, abs(params.direction.x), 0.01f)
        assertEquals("Direction Y should be normalized", expectedLength, abs(params.direction.y), 0.01f)
    }
}
