package com.knowvas.reader.pdf

import android.os.Debug
import android.util.Log
import java.util.concurrent.atomic.AtomicLong

/**
 * PerformanceMonitor - Monitors and optimizes page curl rendering performance
 * 
 * This class tracks frame rates, GPU memory usage, and provides adaptive
 * mesh resolution to maintain target frame rates.
 * 
 * Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 12.3
 */
class PerformanceMonitor {
    companion object {
        private const val TAG = "PerformanceMonitor"
        
        // Frame rate targets (Requirements: 10.1, 10.2)
        private const val TARGET_FPS_HIGH_END = 60.0
        private const val TARGET_FPS_MID_RANGE = 30.0
        private const val MIN_ACCEPTABLE_FPS = 25.0
        
        // Frame time targets in milliseconds
        private const val TARGET_FRAME_TIME_60FPS = 16.67 // ~16.67ms for 60 FPS
        private const val TARGET_FRAME_TIME_30FPS = 33.33 // ~33.33ms for 30 FPS
        
        // GPU memory target (Requirement: 10.3)
        private const val MAX_GPU_MEMORY_MB = 100
        private const val MAX_GPU_MEMORY_BYTES = MAX_GPU_MEMORY_MB * 1024 * 1024L
        
        // Performance monitoring window
        private const val FPS_SAMPLE_SIZE = 60 // Sample 60 frames for FPS calculation
        private const val PERFORMANCE_CHECK_INTERVAL = 1000L // Check every 1 second
    }
    
    // Frame timing
    private val frameTimes = LongArray(FPS_SAMPLE_SIZE)
    private var frameIndex = 0
    private var lastFrameTime = 0L
    private var frameCount = 0L
    
    // Performance metrics
    private var currentFps = 0.0
    private var averageFrameTime = 0.0
    private var lastPerformanceCheck = 0L
    
    // GPU memory tracking (Requirement: 10.3)
    private val gpuMemoryUsage = AtomicLong(0)
    
    // Adaptive mesh resolution (Requirement: 10.5)
    private var currentMeshResolution = MeshResolution.HIGH
    private var consecutiveLowFpsFrames = 0
    private val LOW_FPS_THRESHOLD = 3 // Reduce resolution after 3 consecutive low FPS frames
    
    // Vertex buffer update tracking (Requirement: 10.4)
    private var vertexBufferUpdateCount = 0L
    private var lastVertexBufferUpdateTime = 0L
    
    /**
     * Mesh resolution levels for adaptive performance
     * Requirement: 10.5 - Implement adaptive mesh resolution
     */
    enum class MeshResolution(val width: Int, val height: Int) {
        HIGH(20, 30),      // Default: 20x30 vertices
        MEDIUM(15, 22),    // Reduced: 15x22 vertices
        LOW(10, 15)        // Minimum: 10x15 vertices
    }
    
    /**
     * Device performance tier
     * Used to set appropriate frame rate targets
     */
    enum class DeviceTier {
        HIGH_END,    // Target 60 FPS
        MID_RANGE,   // Target 30 FPS
        LOW_END      // Target 25 FPS minimum
    }
    
    private var deviceTier = DeviceTier.HIGH_END
    
    /**
     * Start frame timing
     * Call this at the beginning of each frame render
     * 
     * Requirement: 12.3 - Performance metrics logging
     */
    fun startFrame() {
        lastFrameTime = System.nanoTime()
    }
    
    /**
     * End frame timing and update metrics
     * Call this at the end of each frame render
     * 
     * Requirements: 10.1, 10.2, 10.5 - Track FPS and adapt mesh resolution
     */
    fun endFrame() {
        val currentTime = System.nanoTime()
        val frameTime = (currentTime - lastFrameTime) / 1_000_000.0 // Convert to milliseconds
        
        // Store frame time
        frameTimes[frameIndex] = frameTime.toLong()
        frameIndex = (frameIndex + 1) % FPS_SAMPLE_SIZE
        frameCount++
        
        // Calculate FPS every second
        if (currentTime - lastPerformanceCheck >= PERFORMANCE_CHECK_INTERVAL * 1_000_000) {
            updatePerformanceMetrics()
            lastPerformanceCheck = currentTime
            
            // Check if we need to adapt mesh resolution
            checkAndAdaptMeshResolution()
            
            // Log performance metrics
            logPerformanceMetrics()
        }
    }
    
    /**
     * Update performance metrics (FPS, average frame time)
     */
    private fun updatePerformanceMetrics() {
        // Calculate average frame time from samples
        var totalFrameTime = 0L
        var sampleCount = 0
        
        for (i in 0 until FPS_SAMPLE_SIZE) {
            if (frameTimes[i] > 0) {
                totalFrameTime += frameTimes[i]
                sampleCount++
            }
        }
        
        if (sampleCount > 0) {
            averageFrameTime = totalFrameTime.toDouble() / sampleCount
            currentFps = 1000.0 / averageFrameTime // FPS = 1000ms / avg frame time
        }
    }
    
    /**
     * Check performance and adapt mesh resolution if needed
     * Requirement: 10.5 - Implement adaptive mesh resolution
     */
    private fun checkAndAdaptMeshResolution() {
        val targetFps = when (deviceTier) {
            DeviceTier.HIGH_END -> TARGET_FPS_HIGH_END
            DeviceTier.MID_RANGE -> TARGET_FPS_MID_RANGE
            DeviceTier.LOW_END -> MIN_ACCEPTABLE_FPS
        }
        
        // Check if FPS is below target
        if (currentFps < targetFps) {
            consecutiveLowFpsFrames++
            
            // Reduce mesh resolution after consecutive low FPS frames
            if (consecutiveLowFpsFrames >= LOW_FPS_THRESHOLD) {
                reduceMeshResolution()
                consecutiveLowFpsFrames = 0
            }
        } else {
            // Reset counter if FPS is good
            consecutiveLowFpsFrames = 0
            
            // Gradually increase resolution if performance is good
            if (currentFps > targetFps * 1.2) { // 20% above target
                increaseMeshResolution()
            }
        }
    }
    
    /**
     * Reduce mesh resolution to improve performance
     * Requirement: 10.5 - Adaptive mesh resolution
     */
    private fun reduceMeshResolution() {
        val newResolution = when (currentMeshResolution) {
            MeshResolution.HIGH -> MeshResolution.MEDIUM
            MeshResolution.MEDIUM -> MeshResolution.LOW
            MeshResolution.LOW -> return // Already at minimum
        }
        
        currentMeshResolution = newResolution
        Log.i(TAG, "Reduced mesh resolution to $newResolution (FPS: $currentFps)")
    }
    
    /**
     * Increase mesh resolution when performance allows
     * Requirement: 10.5 - Adaptive mesh resolution
     */
    private fun increaseMeshResolution() {
        val newResolution = when (currentMeshResolution) {
            MeshResolution.LOW -> MeshResolution.MEDIUM
            MeshResolution.MEDIUM -> MeshResolution.HIGH
            MeshResolution.HIGH -> return // Already at maximum
        }
        
        currentMeshResolution = newResolution
        Log.i(TAG, "Increased mesh resolution to $newResolution (FPS: $currentFps)")
    }
    
    /**
     * Get current mesh resolution
     * Requirement: 10.5 - Adaptive mesh resolution
     */
    fun getCurrentMeshResolution(): MeshResolution {
        return currentMeshResolution
    }
    
    /**
     * Track vertex buffer update
     * Requirement: 10.4 - Minimize vertex buffer updates
     */
    fun recordVertexBufferUpdate() {
        vertexBufferUpdateCount++
        lastVertexBufferUpdateTime = System.nanoTime()
    }
    
    /**
     * Check if vertex buffer update is needed
     * Requirement: 10.4 - Minimize vertex buffer updates
     * 
     * Returns true if enough time has passed since last update
     * to avoid excessive updates
     */
    fun shouldUpdateVertexBuffer(): Boolean {
        val currentTime = System.nanoTime()
        val timeSinceLastUpdate = (currentTime - lastVertexBufferUpdateTime) / 1_000_000.0
        
        // Update at most every 16ms (60 FPS) to avoid excessive updates
        return timeSinceLastUpdate >= TARGET_FRAME_TIME_60FPS
    }
    
    /**
     * Track GPU memory allocation
     * Requirement: 10.3 - Ensure GPU memory stays under 100MB
     */
    fun trackGpuMemoryAllocation(bytes: Long) {
        val newTotal = gpuMemoryUsage.addAndGet(bytes)
        
        if (newTotal > MAX_GPU_MEMORY_BYTES) {
            Log.w(TAG, "GPU memory usage exceeded target: ${newTotal / 1024 / 1024}MB / ${MAX_GPU_MEMORY_MB}MB")
        }
    }
    
    /**
     * Track GPU memory deallocation
     * Requirement: 10.3 - Ensure GPU memory stays under 100MB
     */
    fun trackGpuMemoryDeallocation(bytes: Long) {
        gpuMemoryUsage.addAndGet(-bytes)
    }
    
    /**
     * Get current GPU memory usage in bytes
     * Requirement: 10.3 - Track GPU memory usage
     */
    fun getGpuMemoryUsage(): Long {
        return gpuMemoryUsage.get()
    }
    
    /**
     * Get current GPU memory usage in MB
     * Requirement: 10.3 - Track GPU memory usage
     */
    fun getGpuMemoryUsageMB(): Double {
        return gpuMemoryUsage.get() / 1024.0 / 1024.0
    }
    
    /**
     * Check if GPU memory is within acceptable limits
     * Requirement: 10.3 - Ensure GPU memory stays under 100MB
     */
    fun isGpuMemoryWithinLimits(): Boolean {
        return gpuMemoryUsage.get() <= MAX_GPU_MEMORY_BYTES
    }
    
    /**
     * Set device performance tier
     * This affects target frame rates
     * 
     * Requirements: 10.1, 10.2 - Target 60 FPS on high-end, 30 FPS on mid-range
     */
    fun setDeviceTier(tier: DeviceTier) {
        deviceTier = tier
        Log.i(TAG, "Device tier set to $tier")
    }
    
    /**
     * Get current FPS
     * Requirement: 12.3 - Performance metrics logging
     */
    fun getCurrentFps(): Double {
        return currentFps
    }
    
    /**
     * Get average frame time in milliseconds
     * Requirement: 12.3 - Performance metrics logging
     */
    fun getAverageFrameTime(): Double {
        return averageFrameTime
    }
    
    /**
     * Get vertex buffer update count
     * Requirement: 10.4 - Track vertex buffer updates
     */
    fun getVertexBufferUpdateCount(): Long {
        return vertexBufferUpdateCount
    }
    
    /**
     * Log performance metrics
     * Requirement: 12.3 - Performance metrics logging
     */
    private fun logPerformanceMetrics() {
        Log.d(TAG, """
            Performance Metrics:
            - FPS: ${"%.2f".format(currentFps)}
            - Avg Frame Time: ${"%.2f".format(averageFrameTime)}ms
            - GPU Memory: ${"%.2f".format(getGpuMemoryUsageMB())}MB / ${MAX_GPU_MEMORY_MB}MB
            - Mesh Resolution: $currentMeshResolution
            - Vertex Buffer Updates: $vertexBufferUpdateCount
            - Device Tier: $deviceTier
        """.trimIndent())
    }
    
    /**
     * Get comprehensive performance report
     * Requirement: 12.3 - Performance metrics logging
     */
    fun getPerformanceReport(): Map<String, Any> {
        return mapOf(
            "fps" to currentFps,
            "average_frame_time_ms" to averageFrameTime,
            "gpu_memory_mb" to getGpuMemoryUsageMB(),
            "gpu_memory_within_limits" to isGpuMemoryWithinLimits(),
            "mesh_resolution" to currentMeshResolution.name,
            "mesh_width" to currentMeshResolution.width,
            "mesh_height" to currentMeshResolution.height,
            "vertex_buffer_updates" to vertexBufferUpdateCount,
            "device_tier" to deviceTier.name,
            "frame_count" to frameCount
        )
    }
    
    /**
     * Reset performance metrics
     */
    fun reset() {
        frameTimes.fill(0)
        frameIndex = 0
        frameCount = 0
        currentFps = 0.0
        averageFrameTime = 0.0
        consecutiveLowFpsFrames = 0
        vertexBufferUpdateCount = 0
        lastVertexBufferUpdateTime = 0
        lastPerformanceCheck = 0
        
        Log.d(TAG, "Performance metrics reset")
    }
    
    /**
     * Detect device tier based on available memory and CPU
     * This is a simplified heuristic - real implementation would use more factors
     */
    fun detectDeviceTier(): DeviceTier {
        val runtime = Runtime.getRuntime()
        val maxMemory = runtime.maxMemory() / 1024 / 1024 // MB
        
        // Simple heuristic based on available memory
        // High-end devices typically have 512MB+ heap
        // Mid-range devices have 256-512MB heap
        // Low-end devices have <256MB heap
        return when {
            maxMemory >= 512 -> DeviceTier.HIGH_END
            maxMemory >= 256 -> DeviceTier.MID_RANGE
            else -> DeviceTier.LOW_END
        }.also {
            Log.i(TAG, "Detected device tier: $it (max memory: ${maxMemory}MB)")
        }
    }
}
