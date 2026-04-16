package com.knowvas.reader.pdf

import org.junit.Test
import org.junit.Assert.*
import org.junit.Before

/**
 * Unit tests for performance optimization features
 * 
 * Task 15: Requirements 10.1, 10.2, 10.3, 10.4, 10.5
 * 
 * Tests:
 * - Frame rate tracking
 * - GPU memory tracking
 * - Vertex buffer update minimization
 * - Adaptive mesh resolution
 */
class PerformanceOptimizationTest {
    
    private lateinit var performanceMonitor: PerformanceMonitor
    
    @Before
    fun setup() {
        performanceMonitor = PerformanceMonitor()
    }
    
    /**
     * Test frame timing and FPS calculation
     * 
     * Requirement: 10.1, 10.2 - Track frame rates
     */
    @Test
    fun testFrameTimingAndFpsCalculation() {
        // Simulate 60 frames at 60 FPS (16.67ms per frame)
        val targetFrameTime = 16.67
        
        for (i in 0 until 60) {
            performanceMonitor.startFrame()
            Thread.sleep(16) // Simulate 16ms frame time
            performanceMonitor.endFrame()
        }
        
        // Wait for performance metrics to update
        Thread.sleep(1100) // Wait for 1 second + buffer
        
        val fps = performanceMonitor.getCurrentFps()
        val avgFrameTime = performanceMonitor.getAverageFrameTime()
        
        // FPS should be close to 60 (allow some variance)
        assertTrue("FPS should be between 50 and 70, got $fps", fps in 50.0..70.0)
        
        // Average frame time should be close to 16.67ms
        assertTrue("Avg frame time should be between 14 and 20ms, got $avgFrameTime", 
                   avgFrameTime in 14.0..20.0)
        
        println("Frame timing test: FPS=$fps, Avg frame time=${avgFrameTime}ms")
    }
    
    /**
     * Test GPU memory tracking
     * 
     * Requirement: 10.3 - Ensure GPU memory stays under 100MB
     */
    @Test
    fun testGpuMemoryTracking() {
        // Simulate texture allocation (16MB texture)
        val textureSize = 16 * 1024 * 1024L // 16MB
        
        performanceMonitor.trackGpuMemoryAllocation(textureSize)
        
        assertEquals("GPU memory should be 16MB", 16.0, performanceMonitor.getGpuMemoryUsageMB(), 0.1)
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        // Allocate more textures
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 32MB
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 48MB
        
        assertEquals("GPU memory should be 48MB", 48.0, performanceMonitor.getGpuMemoryUsageMB(), 0.1)
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        // Deallocate one texture
        performanceMonitor.trackGpuMemoryDeallocation(textureSize) // 32MB
        
        assertEquals("GPU memory should be 32MB", 32.0, performanceMonitor.getGpuMemoryUsageMB(), 0.1)
        
        println("GPU memory tracking test: ${performanceMonitor.getGpuMemoryUsageMB()}MB")
    }
    
    /**
     * Test GPU memory limit detection
     * 
     * Requirement: 10.3 - Ensure GPU memory stays under 100MB
     */
    @Test
    fun testGpuMemoryLimitDetection() {
        // Allocate textures up to the limit
        val textureSize = 25 * 1024 * 1024L // 25MB per texture
        
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 25MB
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 50MB
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 75MB
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 100MB
        assertTrue("GPU memory should be within limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        // Exceed the limit
        performanceMonitor.trackGpuMemoryAllocation(textureSize) // 125MB
        assertFalse("GPU memory should exceed limits", performanceMonitor.isGpuMemoryWithinLimits())
        
        println("GPU memory limit test: ${performanceMonitor.getGpuMemoryUsageMB()}MB (limit: 100MB)")
    }
    
    /**
     * Test vertex buffer update throttling
     * 
     * Requirement: 10.4 - Minimize vertex buffer updates
     */
    @Test
    fun testVertexBufferUpdateThrottling() {
        // First update should be allowed
        assertTrue("First update should be allowed", performanceMonitor.shouldUpdateVertexBuffer())
        
        performanceMonitor.recordVertexBufferUpdate()
        
        // Immediate second update should be throttled
        assertFalse("Immediate update should be throttled", performanceMonitor.shouldUpdateVertexBuffer())
        
        // Wait for throttle period (16ms for 60 FPS)
        Thread.sleep(20)
        
        // Update should now be allowed
        assertTrue("Update should be allowed after throttle period", performanceMonitor.shouldUpdateVertexBuffer())
        
        println("Vertex buffer update throttling test passed")
    }
    
    /**
     * Test vertex buffer update counting
     * 
     * Requirement: 10.4 - Track vertex buffer updates
     */
    @Test
    fun testVertexBufferUpdateCounting() {
        assertEquals("Initial update count should be 0", 0, performanceMonitor.getVertexBufferUpdateCount())
        
        performanceMonitor.recordVertexBufferUpdate()
        assertEquals("Update count should be 1", 1, performanceMonitor.getVertexBufferUpdateCount())
        
        performanceMonitor.recordVertexBufferUpdate()
        assertEquals("Update count should be 2", 2, performanceMonitor.getVertexBufferUpdateCount())
        
        println("Vertex buffer update counting test: ${performanceMonitor.getVertexBufferUpdateCount()} updates")
    }
    
    /**
     * Test adaptive mesh resolution
     * 
     * Requirement: 10.5 - Implement adaptive mesh resolution
     */
    @Test
    fun testAdaptiveMeshResolution() {
        // Set device tier to high-end
        performanceMonitor.setDeviceTier(PerformanceMonitor.DeviceTier.HIGH_END)
        
        // Initial resolution should be HIGH
        assertEquals("Initial resolution should be HIGH", 
                     PerformanceMonitor.MeshResolution.HIGH, 
                     performanceMonitor.getCurrentMeshResolution())
        
        println("Adaptive mesh resolution test: Initial resolution = ${performanceMonitor.getCurrentMeshResolution()}")
    }
    
    /**
     * Test mesh resolution levels
     * 
     * Requirement: 10.5 - Verify mesh resolution dimensions
     */
    @Test
    fun testMeshResolutionLevels() {
        val high = PerformanceMonitor.MeshResolution.HIGH
        val medium = PerformanceMonitor.MeshResolution.MEDIUM
        val low = PerformanceMonitor.MeshResolution.LOW
        
        // Verify HIGH resolution (20x30)
        assertEquals("HIGH width should be 20", 20, high.width)
        assertEquals("HIGH height should be 30", 30, high.height)
        
        // Verify MEDIUM resolution (15x22)
        assertEquals("MEDIUM width should be 15", 15, medium.width)
        assertEquals("MEDIUM height should be 22", 22, medium.height)
        
        // Verify LOW resolution (10x15)
        assertEquals("LOW width should be 10", 10, low.width)
        assertEquals("LOW height should be 15", 15, low.height)
        
        println("Mesh resolution levels: HIGH=${high.width}x${high.height}, " +
                "MEDIUM=${medium.width}x${medium.height}, LOW=${low.width}x${low.height}")
    }
    
    /**
     * Test device tier detection
     * 
     * Requirements: 10.1, 10.2 - Device-specific frame rate targets
     */
    @Test
    fun testDeviceTierDetection() {
        val tier = performanceMonitor.detectDeviceTier()
        
        assertNotNull("Device tier should be detected", tier)
        assertTrue("Device tier should be valid", 
                   tier in listOf(
                       PerformanceMonitor.DeviceTier.HIGH_END,
                       PerformanceMonitor.DeviceTier.MID_RANGE,
                       PerformanceMonitor.DeviceTier.LOW_END
                   ))
        
        println("Device tier detection test: Detected tier = $tier")
    }
    
    /**
     * Test performance report generation
     * 
     * Requirement: 12.3 - Performance metrics logging
     */
    @Test
    fun testPerformanceReportGeneration() {
        // Simulate some activity
        performanceMonitor.trackGpuMemoryAllocation(16 * 1024 * 1024L)
        performanceMonitor.recordVertexBufferUpdate()
        
        val report = performanceMonitor.getPerformanceReport()
        
        // Verify report contains expected keys
        assertTrue("Report should contain fps", report.containsKey("fps"))
        assertTrue("Report should contain average_frame_time_ms", report.containsKey("average_frame_time_ms"))
        assertTrue("Report should contain gpu_memory_mb", report.containsKey("gpu_memory_mb"))
        assertTrue("Report should contain mesh_resolution", report.containsKey("mesh_resolution"))
        assertTrue("Report should contain vertex_buffer_updates", report.containsKey("vertex_buffer_updates"))
        assertTrue("Report should contain device_tier", report.containsKey("device_tier"))
        
        // Verify report values
        assertEquals("GPU memory should be 16MB", 16.0, report["gpu_memory_mb"] as Double, 0.1)
        assertEquals("Vertex buffer updates should be 1", 1L, report["vertex_buffer_updates"])
        
        println("Performance report: $report")
    }
    
    /**
     * Test performance metrics reset
     */
    @Test
    fun testPerformanceMetricsReset() {
        // Set up some state
        performanceMonitor.trackGpuMemoryAllocation(16 * 1024 * 1024L)
        performanceMonitor.recordVertexBufferUpdate()
        
        // Verify state is set
        assertTrue("GPU memory should be > 0", performanceMonitor.getGpuMemoryUsageMB() > 0)
        assertTrue("Update count should be > 0", performanceMonitor.getVertexBufferUpdateCount() > 0)
        
        // Reset
        performanceMonitor.reset()
        
        // Verify state is reset
        assertEquals("FPS should be 0", 0.0, performanceMonitor.getCurrentFps(), 0.01)
        assertEquals("Avg frame time should be 0", 0.0, performanceMonitor.getAverageFrameTime(), 0.01)
        assertEquals("Update count should be 0", 0, performanceMonitor.getVertexBufferUpdateCount())
        
        // Note: GPU memory is not reset because it tracks actual allocations
        // Only frame timing and update counts are reset
        
        println("Performance metrics reset test passed")
    }
}
