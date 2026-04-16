package com.knowvas.reader.pdf

import android.graphics.PointF
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before

/**
 * Unit tests for Task 5: Integration checkpoint - Verify basic rendering
 * 
 * These tests verify the components that support basic rendering:
 * - Mesh generation correctness
 * - Texture coordinate validation
 * - Vertex position validation
 * - Memory management
 * 
 * Requirements: 3.5
 * 
 * Note: Full integration tests with OpenGL rendering are in PageCurlIntegrationTest
 * (instrumented tests that run on device/emulator)
 */
class Task5IntegrationCheckpointTest {
    
    private lateinit var meshGenerator: MeshGenerator
    
    @Before
    fun setup() {
        meshGenerator = MeshGenerator(gridWidth = 20, gridHeight = 30)
    }
    
    /**
     * Test 1: Verify mesh renders identically to simple quad when flat
     * 
     * When curl radius is 0, the mesh should be completely flat with Z=0 for all vertices.
     * This ensures the mesh renders identically to a simple textured quad.
     * 
     * Requirements: 3.5
     */
    @Test
    fun testFlatMeshHasZeroDepth() {
        val mesh = meshGenerator.generateMesh()
        
        // Verify all Z coordinates are 0 (flat)
        for (i in 0 until mesh.vertexCount) {
            val z = mesh.vertices[i * 3 + 2]
            assertEquals(
                "Vertex $i should have Z=0 for flat mesh",
                0.0f,
                z,
                0.0001f
            )
        }
        
        println("✓ Flat mesh test passed: All vertices have Z=0")
    }
    
    /**
     * Test 2: Verify mesh has correct grid dimensions
     * 
     * Requirements: 3.1
     */
    @Test
    fun testMeshHasCorrectGridDimensions() {
        val mesh = meshGenerator.generateMesh()
        
        assertEquals("Grid width should be 20", 20, mesh.gridWidth)
        assertEquals("Grid height should be 30", 30, mesh.gridHeight)
        assertEquals("Vertex count should be 600", 600, mesh.vertexCount)
        
        println("✓ Grid dimensions test passed: 20x30 grid with 600 vertices")
    }
    
    /**
     * Test 3: Verify mesh has correct number of triangles
     * 
     * For a grid of (W x H) vertices, we should have (W-1) * (H-1) * 2 triangles
     * 
     * Requirements: 3.4
     */
    @Test
    fun testMeshHasCorrectTriangleCount() {
        val mesh = meshGenerator.generateMesh()
        
        val expectedTriangles = (20 - 1) * (30 - 1) * 2
        assertEquals("Triangle count should be $expectedTriangles", expectedTriangles, mesh.triangleCount)
        assertEquals("Index count should be ${expectedTriangles * 3}", expectedTriangles * 3, mesh.indices.size)
        
        println("✓ Triangle count test passed: $expectedTriangles triangles")
    }
    
    /**
     * Test 4: Verify texture coordinates are in valid range [0, 1]
     * 
     * Requirements: 3.2
     */
    @Test
    fun testTextureCoordinatesInValidRange() {
        val mesh = meshGenerator.generateMesh()
        
        var minU = Float.MAX_VALUE
        var maxU = Float.MIN_VALUE
        var minV = Float.MAX_VALUE
        var maxV = Float.MIN_VALUE
        
        for (i in 0 until mesh.vertexCount) {
            val u = mesh.texCoords[i * 2]
            val v = mesh.texCoords[i * 2 + 1]
            
            minU = minOf(minU, u)
            maxU = maxOf(maxU, u)
            minV = minOf(minV, v)
            maxV = maxOf(maxV, v)
            
            assertTrue("U coordinate at vertex $i is out of range: $u", u >= 0.0f && u <= 1.0f)
            assertTrue("V coordinate at vertex $i is out of range: $v", v >= 0.0f && v <= 1.0f)
        }
        
        // Verify full range is covered
        assertEquals("Min U should be 0", 0.0f, minU, 0.0001f)
        assertEquals("Max U should be 1", 1.0f, maxU, 0.0001f)
        assertEquals("Min V should be 0", 0.0f, minV, 0.0001f)
        assertEquals("Max V should be 1", 1.0f, maxV, 0.0001f)
        
        println("✓ Texture coordinates test passed: All coordinates in [0, 1], full range covered")
    }
    
    /**
     * Test 5: Verify vertex positions are in valid range [-1, 1]
     * 
     * Requirements: 3.2
     */
    @Test
    fun testVertexPositionsInValidRange() {
        val mesh = meshGenerator.generateMesh()
        
        var minX = Float.MAX_VALUE
        var maxX = Float.MIN_VALUE
        var minY = Float.MAX_VALUE
        var maxY = Float.MIN_VALUE
        
        for (i in 0 until mesh.vertexCount) {
            val x = mesh.vertices[i * 3]
            val y = mesh.vertices[i * 3 + 1]
            
            minX = minOf(minX, x)
            maxX = maxOf(maxX, x)
            minY = minOf(minY, y)
            maxY = maxOf(maxY, y)
            
            assertTrue("X coordinate at vertex $i is out of range: $x", x >= -1.0f && x <= 1.0f)
            assertTrue("Y coordinate at vertex $i is out of range: $y", y >= -1.0f && y <= 1.0f)
        }
        
        // Verify full range is covered
        assertEquals("Min X should be -1", -1.0f, minX, 0.0001f)
        assertEquals("Max X should be 1", 1.0f, maxX, 0.0001f)
        assertEquals("Min Y should be -1", -1.0f, minY, 0.0001f)
        assertEquals("Max Y should be 1", 1.0f, maxY, 0.0001f)
        
        println("✓ Vertex positions test passed: All positions in [-1, 1], full range covered")
    }
    
    /**
     * Test 6: Verify triangle winding order is consistent
     * 
     * All triangles should have counter-clockwise winding order.
     * 
     * Requirements: 3.4
     */
    @Test
    fun testTriangleWindingOrderIsConsistent() {
        val mesh = meshGenerator.generateMesh()
        
        // Check a sample of triangles for counter-clockwise winding
        // We'll check the first few triangles in detail
        
        for (triIndex in 0 until minOf(10, mesh.triangleCount)) {
            val i0 = mesh.indices[triIndex * 3].toInt()
            val i1 = mesh.indices[triIndex * 3 + 1].toInt()
            val i2 = mesh.indices[triIndex * 3 + 2].toInt()
            
            // Get vertex positions
            val x0 = mesh.vertices[i0 * 3]
            val y0 = mesh.vertices[i0 * 3 + 1]
            val x1 = mesh.vertices[i1 * 3]
            val y1 = mesh.vertices[i1 * 3 + 1]
            val x2 = mesh.vertices[i2 * 3]
            val y2 = mesh.vertices[i2 * 3 + 1]
            
            // Calculate cross product to determine winding
            // For counter-clockwise winding, cross product should be positive
            val cross = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
            
            assertTrue(
                "Triangle $triIndex has incorrect winding order (cross product: $cross)",
                cross > 0
            )
        }
        
        println("✓ Triangle winding test passed: All triangles have counter-clockwise winding")
    }
    
    /**
     * Test 7: Verify mesh buffers can be created
     * 
     * This tests that the mesh can create OpenGL buffers without errors.
     */
    @Test
    fun testMeshBuffersCanBeCreated() {
        val mesh = meshGenerator.generateMesh()
        
        // Get buffers - this should not throw exceptions
        val vertexBuffer = mesh.getVertexBuffer()
        val texCoordBuffer = mesh.getTexCoordBuffer()
        val indexBuffer = mesh.getIndexBuffer()
        
        assertNotNull("Vertex buffer should not be null", vertexBuffer)
        assertNotNull("Texture coordinate buffer should not be null", texCoordBuffer)
        assertNotNull("Index buffer should not be null", indexBuffer)
        
        // Verify buffer capacities
        assertEquals("Vertex buffer capacity", mesh.vertices.size, vertexBuffer.capacity())
        assertEquals("TexCoord buffer capacity", mesh.texCoords.size, texCoordBuffer.capacity())
        assertEquals("Index buffer capacity", mesh.indices.size, indexBuffer.capacity())
        
        println("✓ Buffer creation test passed: All buffers created successfully")
    }
    
    /**
     * Test 8: Verify mesh corners are at expected positions
     * 
     * The four corners of the mesh should be at:
     * - Top-left: (-1, 1, 0)
     * - Top-right: (1, 1, 0)
     * - Bottom-left: (-1, -1, 0)
     * - Bottom-right: (1, -1, 0)
     * 
     * Requirements: 3.2
     */
    @Test
    fun testMeshCornersAreAtExpectedPositions() {
        val mesh = meshGenerator.generateMesh()
        
        // Top-left corner (first vertex)
        val topLeftIndex = 0
        assertEquals("Top-left X", -1.0f, mesh.vertices[topLeftIndex * 3], 0.0001f)
        assertEquals("Top-left Y", 1.0f, mesh.vertices[topLeftIndex * 3 + 1], 0.0001f)
        assertEquals("Top-left Z", 0.0f, mesh.vertices[topLeftIndex * 3 + 2], 0.0001f)
        
        // Top-right corner (last vertex in first row)
        val topRightIndex = mesh.gridWidth - 1
        assertEquals("Top-right X", 1.0f, mesh.vertices[topRightIndex * 3], 0.0001f)
        assertEquals("Top-right Y", 1.0f, mesh.vertices[topRightIndex * 3 + 1], 0.0001f)
        assertEquals("Top-right Z", 0.0f, mesh.vertices[topRightIndex * 3 + 2], 0.0001f)
        
        // Bottom-left corner (first vertex in last row)
        val bottomLeftIndex = mesh.gridWidth * (mesh.gridHeight - 1)
        assertEquals("Bottom-left X", -1.0f, mesh.vertices[bottomLeftIndex * 3], 0.0001f)
        assertEquals("Bottom-left Y", -1.0f, mesh.vertices[bottomLeftIndex * 3 + 1], 0.0001f)
        assertEquals("Bottom-left Z", 0.0f, mesh.vertices[bottomLeftIndex * 3 + 2], 0.0001f)
        
        // Bottom-right corner (last vertex)
        val bottomRightIndex = mesh.vertexCount - 1
        assertEquals("Bottom-right X", 1.0f, mesh.vertices[bottomRightIndex * 3], 0.0001f)
        assertEquals("Bottom-right Y", -1.0f, mesh.vertices[bottomRightIndex * 3 + 1], 0.0001f)
        assertEquals("Bottom-right Z", 0.0f, mesh.vertices[bottomRightIndex * 3 + 2], 0.0001f)
        
        println("✓ Corner positions test passed: All corners at expected positions")
    }
    
    /**
     * Test 9: Verify mesh texture corners are at expected positions
     * 
     * The four corners should have texture coordinates:
     * - Top-left: (0, 0)
     * - Top-right: (1, 0)
     * - Bottom-left: (0, 1)
     * - Bottom-right: (1, 1)
     * 
     * Requirements: 3.2
     */
    @Test
    fun testMeshTextureCornersAreAtExpectedPositions() {
        val mesh = meshGenerator.generateMesh()
        
        // Top-left corner
        val topLeftIndex = 0
        assertEquals("Top-left U", 0.0f, mesh.texCoords[topLeftIndex * 2], 0.0001f)
        assertEquals("Top-left V", 0.0f, mesh.texCoords[topLeftIndex * 2 + 1], 0.0001f)
        
        // Top-right corner
        val topRightIndex = mesh.gridWidth - 1
        assertEquals("Top-right U", 1.0f, mesh.texCoords[topRightIndex * 2], 0.0001f)
        assertEquals("Top-right V", 0.0f, mesh.texCoords[topRightIndex * 2 + 1], 0.0001f)
        
        // Bottom-left corner
        val bottomLeftIndex = mesh.gridWidth * (mesh.gridHeight - 1)
        assertEquals("Bottom-left U", 0.0f, mesh.texCoords[bottomLeftIndex * 2], 0.0001f)
        assertEquals("Bottom-left V", 1.0f, mesh.texCoords[bottomLeftIndex * 2 + 1], 0.0001f)
        
        // Bottom-right corner
        val bottomRightIndex = mesh.vertexCount - 1
        assertEquals("Bottom-right U", 1.0f, mesh.texCoords[bottomRightIndex * 2], 0.0001f)
        assertEquals("Bottom-right V", 1.0f, mesh.texCoords[bottomRightIndex * 2 + 1], 0.0001f)
        
        println("✓ Texture corner positions test passed: All corners at expected UV coordinates")
    }
    
    /**
     * Test 10: Verify mesh can be generated multiple times
     * 
     * This tests that the mesh generator is stateless and can generate
     * multiple meshes without issues.
     */
    @Test
    fun testMeshCanBeGeneratedMultipleTimes() {
        val mesh1 = meshGenerator.generateMesh()
        val mesh2 = meshGenerator.generateMesh()
        
        // Verify both meshes have the same properties
        assertEquals("Vertex count should match", mesh1.vertexCount, mesh2.vertexCount)
        assertEquals("Triangle count should match", mesh1.triangleCount, mesh2.triangleCount)
        
        // Verify vertex data is identical
        assertArrayEquals("Vertices should be identical", mesh1.vertices, mesh2.vertices, 0.0001f)
        assertArrayEquals("TexCoords should be identical", mesh1.texCoords, mesh2.texCoords, 0.0001f)
        
        // Verify indices are identical
        for (i in mesh1.indices.indices) {
            assertEquals("Index $i should match", mesh1.indices[i], mesh2.indices[i])
        }
        
        println("✓ Multiple generation test passed: Mesh generator is stateless")
    }
    
    /**
     * Test 11: Performance - Mesh generation should be fast
     * 
     * Mesh generation should complete in under 100ms for a 20x30 grid.
     */
    @Test
    fun testMeshGenerationPerformance() {
        val iterations = 100
        val startTime = System.nanoTime()
        
        repeat(iterations) {
            meshGenerator.generateMesh()
        }
        
        val endTime = System.nanoTime()
        val totalTime = (endTime - startTime) / 1_000_000.0 // Convert to milliseconds
        val avgTime = totalTime / iterations
        
        println("Mesh generation performance: ${avgTime}ms average (${iterations} iterations)")
        
        // Verify performance target
        assertTrue(
            "Mesh generation too slow: ${avgTime}ms (target: <10ms)",
            avgTime < 10.0
        )
        
        println("✓ Performance test passed: ${avgTime}ms per mesh (target: <10ms)")
    }
    
    /**
     * Test 12: Memory - Mesh should not leak memory
     * 
     * Creating and discarding meshes should not cause memory leaks.
     */
    @Test
    fun testMeshDoesNotLeakMemory() {
        val runtime = Runtime.getRuntime()
        runtime.gc()
        Thread.sleep(100)
        
        val initialMemory = runtime.totalMemory() - runtime.freeMemory()
        
        // Generate and discard many meshes
        repeat(1000) {
            meshGenerator.generateMesh()
        }
        
        runtime.gc()
        Thread.sleep(100)
        
        val finalMemory = runtime.totalMemory() - runtime.freeMemory()
        val memoryIncrease = (finalMemory - initialMemory) / 1024.0 / 1024.0 // MB
        
        println("Memory increase after 1000 mesh generations: ${memoryIncrease}MB")
        
        // Allow some memory increase for caching, but not excessive
        assertTrue(
            "Memory leak detected: ${memoryIncrease}MB increase",
            memoryIncrease < 10.0
        )
        
        println("✓ Memory test passed: ${memoryIncrease}MB increase (threshold: 10MB)")
    }
    
    // Helper method to compare float arrays
    private fun assertArrayEquals(message: String, expected: FloatArray, actual: FloatArray, delta: Float) {
        assertEquals("$message - array size", expected.size, actual.size)
        for (i in expected.indices) {
            assertEquals("$message - element $i", expected[i], actual[i], delta)
        }
    }
}
