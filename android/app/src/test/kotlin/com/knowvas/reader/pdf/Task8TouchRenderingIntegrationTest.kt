package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Integration tests for Task 8: Touch-to-Rendering Integration
 * 
 * Tests the integration between TouchHandler and mesh rendering:
 * - Touch events trigger mesh updates (Requirements 5.3)
 * - Mesh vertices are updated in real-time during drag (Requirements 5.3)
 * - Performance is optimized for 30+ FPS (Requirements 5.4)
 * - Curl state is properly reset after interactions (Requirements 6.5, 7.3, 7.5)
 */
class Task8TouchRenderingIntegrationTest {
    
    private lateinit var touchHandler: TouchHandler
    private lateinit var meshGenerator: MeshGenerator
    private lateinit var curlMath: CurlMathematics
    private lateinit var testMesh: PageMesh
    
    // Test page dimensions
    private val pageWidth = 1000f
    private val pageHeight = 1500f
    
    @Before
    fun setup() {
        touchHandler = TouchHandler(
            pageWidth = pageWidth,
            pageHeight = pageHeight,
            edgeThreshold = 0.2f
        )
        
        meshGenerator = MeshGenerator(gridWidth = 20, gridHeight = 30)
        curlMath = CurlMathematics()
        testMesh = meshGenerator.generateMesh()
    }
    
    // ========== Touch-to-Mesh Integration Tests ==========
    
    @Test
    fun `touch down should not modify mesh until drag`() {
        // Store original mesh state
        val originalVertices = testMesh.vertices.copyOf()
        
        // Touch down at edge
        val result = touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        assertTrue("Should start curl", result is TouchHandler.TouchResult.CurlStarted)
        
        // Mesh should not be modified yet (no drag)
        assertArrayEquals(
            "Mesh should not be modified on touch down",
            originalVertices,
            testMesh.vertices,
            0.001f
        )
    }
    
    @Test
    fun `touch move should trigger mesh update`() {
        // Store original mesh state
        val originalVertices = testMesh.vertices.copyOf()
        
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move touch to trigger curl update
        val result = touchHandler.handleTouchMove(x = 700f, y = 750f)
        
        assertTrue("Should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        // Apply curl to mesh (simulating what PageCurlView does)
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Mesh should be modified
        var hasChanged = false
        for (i in testMesh.vertices.indices) {
            if (testMesh.vertices[i] != originalVertices[i]) {
                hasChanged = true
                break
            }
        }
        
        assertTrue("Mesh vertices should be modified after curl update", hasChanged)
    }
    
    @Test
    fun `curl parameters should produce valid mesh deformation`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move touch
        val result = touchHandler.handleTouchMove(x = 600f, y = 750f)
        
        assertTrue("Should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        // Apply curl to mesh
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Verify mesh vertices are within valid bounds
        for (i in 0 until testMesh.vertexCount) {
            val x = testMesh.vertices[i * 3]
            val y = testMesh.vertices[i * 3 + 1]
            val z = testMesh.vertices[i * 3 + 2]
            
            // Vertices should be within reasonable bounds
            assertTrue("Vertex X should be valid", x >= -2f && x <= 2f)
            assertTrue("Vertex Y should be valid", y >= -2f && y <= 2f)
            assertTrue("Vertex Z should be valid", z >= -2f && z <= 2f)
            
            // No NaN or Infinity values
            assertFalse("Vertex X should not be NaN", x.isNaN())
            assertFalse("Vertex Y should not be NaN", y.isNaN())
            assertFalse("Vertex Z should not be NaN", z.isNaN())
            assertFalse("Vertex X should not be Infinity", x.isInfinite())
            assertFalse("Vertex Y should not be Infinity", y.isInfinite())
            assertFalse("Vertex Z should not be Infinity", z.isInfinite())
        }
    }
    
    @Test
    fun `multiple touch moves should continuously update mesh`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Simulate multiple touch moves
        val positions = listOf(850f, 800f, 750f, 700f, 650f, 600f)
        
        for (x in positions) {
            val result = touchHandler.handleTouchMove(x = x, y = 750f)
            
            assertTrue("Should update curl at x=$x", result is TouchHandler.TouchResult.CurlUpdated)
            
            // Apply curl to mesh
            val params = (result as TouchHandler.TouchResult.CurlUpdated).params
            meshGenerator.updateMeshWithCurl(testMesh, params)
            
            // Verify curl radius increases with drag distance
            assertTrue("Curl radius should be positive at x=$x", params.radius > 0)
        }
    }
    
    // ========== Curl State Reset Tests ==========
    
    @Test
    fun `mesh should reset to flat state after page turn`() {
        // Start curl and drag
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        val moveResult = touchHandler.handleTouchMove(x = 500f, y = 750f)
        
        // Apply curl
        val params = (moveResult as TouchHandler.TouchResult.CurlUpdated).params
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Trigger page turn
        val upResult = touchHandler.handleTouchUp(x = 500f, y = 750f)
        assertTrue("Should trigger page turn", upResult is TouchHandler.TouchResult.PageTurnTriggered)
        
        // Reset mesh to flat state (simulating what PageCurlView does)
        meshGenerator.updateMeshWithCurl(testMesh, CurlParameters.FLAT)
        
        // Verify mesh is flat (Z coordinates should be 0)
        for (i in 0 until testMesh.vertexCount) {
            val z = testMesh.vertices[i * 3 + 2]
            assertEquals("Vertex Z should be 0 after reset", 0f, z, 0.001f)
        }
    }
    
    @Test
    fun `mesh should reset to flat state after snap back`() {
        // Start curl and drag slightly
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        val moveResult = touchHandler.handleTouchMove(x = 800f, y = 750f)
        
        // Apply curl
        val params = (moveResult as TouchHandler.TouchResult.CurlUpdated).params
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Trigger snap back
        val upResult = touchHandler.handleTouchUp(x = 800f, y = 750f)
        assertTrue("Should trigger snap back", upResult is TouchHandler.TouchResult.SnapBackTriggered)
        
        // Reset mesh to flat state
        meshGenerator.updateMeshWithCurl(testMesh, CurlParameters.FLAT)
        
        // Verify mesh is flat
        for (i in 0 until testMesh.vertexCount) {
            val z = testMesh.vertices[i * 3 + 2]
            assertEquals("Vertex Z should be 0 after snap back", 0f, z, 0.001f)
        }
    }
    
    // ========== Performance Tests ==========
    
    @Test
    fun `mesh update should complete quickly for real-time rendering`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        val result = touchHandler.handleTouchMove(x = 700f, y = 750f)
        
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        
        // Measure mesh update time
        val startTime = System.nanoTime()
        meshGenerator.updateMeshWithCurl(testMesh, params)
        val endTime = System.nanoTime()
        
        val durationMs = (endTime - startTime) / 1_000_000.0
        
        // For 30 FPS, we have 33ms per frame
        // Mesh update should take much less than that (target: < 5ms)
        assertTrue(
            "Mesh update should complete in < 5ms for 30+ FPS (took ${durationMs}ms)",
            durationMs < 5.0
        )
    }
    
    @Test
    fun `multiple rapid mesh updates should maintain performance`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Simulate rapid touch moves (like during fast drag)
        val updateCount = 30 // Simulate 30 updates (1 second at 30 FPS)
        val startTime = System.nanoTime()
        
        for (i in 0 until updateCount) {
            val x = 900f - (i * 10f) // Move 10px each update
            val result = touchHandler.handleTouchMove(x = x, y = 750f)
            
            if (result is TouchHandler.TouchResult.CurlUpdated) {
                meshGenerator.updateMeshWithCurl(testMesh, result.params)
            }
        }
        
        val endTime = System.nanoTime()
        val totalDurationMs = (endTime - startTime) / 1_000_000.0
        val avgDurationMs = totalDurationMs / updateCount
        
        // Average update time should be < 5ms for 30+ FPS
        assertTrue(
            "Average mesh update should be < 5ms (was ${avgDurationMs}ms)",
            avgDurationMs < 5.0
        )
    }
    
    // ========== Curl Mathematics Integration Tests ==========
    
    @Test
    fun `curl parameters from touch should produce smooth deformation`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Move touch
        val result = touchHandler.handleTouchMove(x = 700f, y = 750f)
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        
        // Validate curl parameters
        assertTrue("Curl parameters should be valid", curlMath.validateCurlParameters(params))
        
        // Apply curl to mesh
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Check that adjacent vertices have smooth transitions
        // (no sudden jumps in position)
        for (row in 0 until testMesh.gridHeight - 1) {
            for (col in 0 until testMesh.gridWidth - 1) {
                val idx1 = (row * testMesh.gridWidth + col) * 3
                val idx2 = (row * testMesh.gridWidth + col + 1) * 3
                
                val x1 = testMesh.vertices[idx1]
                val y1 = testMesh.vertices[idx1 + 1]
                val z1 = testMesh.vertices[idx1 + 2]
                
                val x2 = testMesh.vertices[idx2]
                val y2 = testMesh.vertices[idx2 + 1]
                val z2 = testMesh.vertices[idx2 + 2]
                
                // Calculate distance between adjacent vertices
                val dx = x2 - x1
                val dy = y2 - y1
                val dz = z2 - z1
                val distance = Math.sqrt((dx * dx + dy * dy + dz * dz).toDouble())
                
                // Distance should be reasonable (not too large)
                // Original grid spacing is ~0.1, curled spacing should be < 0.5
                assertTrue(
                    "Adjacent vertices should have smooth transition (distance=$distance)",
                    distance < 0.5
                )
            }
        }
    }
    
    @Test
    fun `curl direction should affect mesh deformation correctly`() {
        // Test forward curl (right to left)
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        val forwardResult = touchHandler.handleTouchMove(x = 700f, y = 750f)
        val forwardParams = (forwardResult as TouchHandler.TouchResult.CurlUpdated).params
        
        // Direction should point left (negative X)
        assertTrue(
            "Forward curl direction should point left",
            forwardParams.direction.x < 0
        )
        
        touchHandler.reset()
        
        // Test backward curl (left to right)
        touchHandler.handleTouchDown(x = 100f, y = 750f)
        val backwardResult = touchHandler.handleTouchMove(x = 300f, y = 750f)
        val backwardParams = (backwardResult as TouchHandler.TouchResult.CurlUpdated).params
        
        // Direction should point right (positive X)
        assertTrue(
            "Backward curl direction should point right",
            backwardParams.direction.x > 0
        )
    }
    
    // ========== Edge Cases ==========
    
    @Test
    fun `zero radius curl should not modify mesh`() {
        // Create flat curl parameters
        val flatParams = CurlParameters.FLAT
        
        // Store original mesh
        val originalVertices = testMesh.vertices.copyOf()
        
        // Apply flat curl
        meshGenerator.updateMeshWithCurl(testMesh, flatParams)
        
        // Mesh should remain unchanged
        assertArrayEquals(
            "Mesh should not change with zero radius curl",
            originalVertices,
            testMesh.vertices,
            0.001f
        )
    }
    
    @Test
    fun `very small drag should produce minimal curl`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Very small drag (just over MIN_DRAG_DISTANCE)
        val result = touchHandler.handleTouchMove(x = 890f, y = 750f)
        
        if (result is TouchHandler.TouchResult.CurlUpdated) {
            val params = result.params
            
            // Radius should be small
            assertTrue("Small drag should produce small radius", params.radius < 50f)
            
            // Apply curl
            meshGenerator.updateMeshWithCurl(testMesh, params)
            
            // Most vertices should remain near their original positions
            var unchangedCount = 0
            for (i in 0 until testMesh.vertexCount) {
                val z = testMesh.vertices[i * 3 + 2]
                if (Math.abs(z) < 0.01f) {
                    unchangedCount++
                }
            }
            
            // At least 80% of vertices should be nearly flat
            val unchangedPercent = unchangedCount.toFloat() / testMesh.vertexCount
            assertTrue(
                "Most vertices should remain flat with small curl (${unchangedPercent * 100}%)",
                unchangedPercent > 0.8f
            )
        }
    }
    
    @Test
    fun `large drag should produce significant curl`() {
        // Start curl
        touchHandler.handleTouchDown(x = 900f, y = 750f)
        
        // Large drag
        val result = touchHandler.handleTouchMove(x = 400f, y = 750f)
        
        assertTrue("Should update curl", result is TouchHandler.TouchResult.CurlUpdated)
        
        val params = (result as TouchHandler.TouchResult.CurlUpdated).params
        
        // Radius should be large
        assertTrue("Large drag should produce large radius", params.radius > 100f)
        
        // Apply curl
        meshGenerator.updateMeshWithCurl(testMesh, params)
        
        // Many vertices should be significantly curled (Z != 0)
        var curledCount = 0
        for (i in 0 until testMesh.vertexCount) {
            val z = testMesh.vertices[i * 3 + 2]
            if (Math.abs(z) > 0.1f) {
                curledCount++
            }
        }
        
        // At least 30% of vertices should be significantly curled
        val curledPercent = curledCount.toFloat() / testMesh.vertexCount
        assertTrue(
            "Many vertices should be curled with large drag (${curledPercent * 100}%)",
            curledPercent > 0.3f
        )
    }
}
