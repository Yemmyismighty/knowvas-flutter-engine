package com.knowvas.reader.utils

import android.app.ActivityManager
import android.content.Context
import android.util.Log
import java.lang.ref.WeakReference

/**
 * Memory management utility for monitoring and managing memory usage
 * in the reader modules to prevent OOM crashes with large files.
 * 
 * This class provides:
 * - Memory usage monitoring
 * - Memory pressure detection
 * - Automatic cleanup triggers
 * - Memory statistics logging
 */
object MemoryManager {
    private const val TAG = "MemoryManager"
    
    // Memory thresholds
    private const val MEMORY_THRESHOLD_WARNING = 0.75 // 75% of max memory
    private const val MEMORY_THRESHOLD_CRITICAL = 0.85 // 85% of max memory
    private const val MEMORY_THRESHOLD_EMERGENCY = 0.95 // 95% of max memory
    
    // Cleanup listeners
    private val cleanupListeners = mutableListOf<WeakReference<MemoryCleanupListener>>()
    
    /**
     * Interface for components that need to respond to memory pressure
     */
    interface MemoryCleanupListener {
        /**
         * Called when memory pressure is detected
         * @param level The severity level (WARNING, CRITICAL, EMERGENCY)
         */
        fun onMemoryPressure(level: MemoryPressureLevel)
        
        /**
         * Called to request cleanup of non-essential resources
         */
        fun onCleanupRequested()
    }
    
    /**
     * Memory pressure levels
     */
    enum class MemoryPressureLevel {
        NORMAL,
        WARNING,    // 75-85% memory used
        CRITICAL,   // 85-95% memory used
        EMERGENCY   // >95% memory used
    }
    
    /**
     * Memory statistics
     */
    data class MemoryStats(
        val usedMemoryMB: Long,
        val maxMemoryMB: Long,
        val freeMemoryMB: Long,
        val usagePercentage: Double,
        val pressureLevel: MemoryPressureLevel
    )
    
    /**
     * Register a cleanup listener
     */
    fun registerCleanupListener(listener: MemoryCleanupListener) {
        synchronized(cleanupListeners) {
            // Remove any dead references
            cleanupListeners.removeAll { it.get() == null }
            
            // Add new listener
            cleanupListeners.add(WeakReference(listener))
        }
        Log.d(TAG, "Registered cleanup listener. Total listeners: ${cleanupListeners.size}")
    }
    
    /**
     * Unregister a cleanup listener
     */
    fun unregisterCleanupListener(listener: MemoryCleanupListener) {
        synchronized(cleanupListeners) {
            cleanupListeners.removeAll { it.get() == listener || it.get() == null }
        }
        Log.d(TAG, "Unregistered cleanup listener. Total listeners: ${cleanupListeners.size}")
    }
    
    /**
     * Get current memory statistics
     */
    fun getMemoryStats(): MemoryStats {
        val runtime = Runtime.getRuntime()
        val maxMemory = runtime.maxMemory()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        
        val usagePercentage = usedMemory.toDouble() / maxMemory.toDouble()
        val pressureLevel = getPressureLevel(usagePercentage)
        
        return MemoryStats(
            usedMemoryMB = usedMemory / (1024 * 1024),
            maxMemoryMB = maxMemory / (1024 * 1024),
            freeMemoryMB = freeMemory / (1024 * 1024),
            usagePercentage = usagePercentage,
            pressureLevel = pressureLevel
        )
    }
    
    /**
     * Check if memory usage exceeds the warning threshold
     */
    fun isMemoryPressureDetected(): Boolean {
        val stats = getMemoryStats()
        return stats.pressureLevel != MemoryPressureLevel.NORMAL
    }
    
    /**
     * Check memory and trigger cleanup if needed
     * @return true if cleanup was triggered
     */
    fun checkMemoryAndCleanup(): Boolean {
        val stats = getMemoryStats()
        
        Log.d(TAG, "Memory check: ${stats.usedMemoryMB}MB / ${stats.maxMemoryMB}MB " +
                "(${String.format("%.1f", stats.usagePercentage * 100)}%) - ${stats.pressureLevel}")
        
        if (stats.pressureLevel != MemoryPressureLevel.NORMAL) {
            Log.w(TAG, "Memory pressure detected: ${stats.pressureLevel}")
            notifyMemoryPressure(stats.pressureLevel)
            return true
        }
        
        return false
    }
    
    /**
     * Force garbage collection and cleanup
     * This should be used sparingly as it can impact performance
     */
    fun forceCleanup() {
        Log.i(TAG, "Forcing memory cleanup")
        
        // Notify all listeners to clean up
        notifyCleanupRequested()
        
        // Suggest garbage collection
        System.gc()
        
        // Log results
        val stats = getMemoryStats()
        Log.i(TAG, "After cleanup: ${stats.usedMemoryMB}MB / ${stats.maxMemoryMB}MB " +
                "(${String.format("%.1f", stats.usagePercentage * 100)}%)")
    }
    
    /**
     * Get available memory in MB
     */
    fun getAvailableMemoryMB(): Long {
        val runtime = Runtime.getRuntime()
        val maxMemory = runtime.maxMemory()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        val availableMemory = maxMemory - usedMemory
        
        return availableMemory / (1024 * 1024)
    }
    
    /**
     * Check if there's enough memory for an operation
     * @param requiredMB Required memory in megabytes
     * @return true if there's enough memory available
     */
    fun hasEnoughMemory(requiredMB: Long): Boolean {
        val availableMB = getAvailableMemoryMB()
        val hasEnough = availableMB >= requiredMB
        
        if (!hasEnough) {
            Log.w(TAG, "Insufficient memory: required ${requiredMB}MB, available ${availableMB}MB")
        }
        
        return hasEnough
    }
    
    /**
     * Get device memory info using ActivityManager
     */
    fun getDeviceMemoryInfo(context: Context): ActivityManager.MemoryInfo {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo
    }
    
    /**
     * Check if device is in low memory state
     */
    fun isDeviceLowMemory(context: Context): Boolean {
        val memoryInfo = getDeviceMemoryInfo(context)
        return memoryInfo.lowMemory
    }
    
    /**
     * Log detailed memory statistics
     */
    fun logMemoryStats(tag: String = TAG) {
        val stats = getMemoryStats()
        val runtime = Runtime.getRuntime()
        
        Log.d(tag, "=== Memory Statistics ===")
        Log.d(tag, "Used Memory: ${stats.usedMemoryMB} MB")
        Log.d(tag, "Max Memory: ${stats.maxMemoryMB} MB")
        Log.d(tag, "Free Memory: ${stats.freeMemoryMB} MB")
        Log.d(tag, "Usage: ${String.format("%.1f", stats.usagePercentage * 100)}%")
        Log.d(tag, "Pressure Level: ${stats.pressureLevel}")
        Log.d(tag, "Total Memory: ${runtime.totalMemory() / (1024 * 1024)} MB")
        Log.d(tag, "========================")
    }
    
    /**
     * Determine pressure level from usage percentage
     */
    private fun getPressureLevel(usagePercentage: Double): MemoryPressureLevel {
        return when {
            usagePercentage >= MEMORY_THRESHOLD_EMERGENCY -> MemoryPressureLevel.EMERGENCY
            usagePercentage >= MEMORY_THRESHOLD_CRITICAL -> MemoryPressureLevel.CRITICAL
            usagePercentage >= MEMORY_THRESHOLD_WARNING -> MemoryPressureLevel.WARNING
            else -> MemoryPressureLevel.NORMAL
        }
    }
    
    /**
     * Notify all listeners of memory pressure
     */
    private fun notifyMemoryPressure(level: MemoryPressureLevel) {
        synchronized(cleanupListeners) {
            val iterator = cleanupListeners.iterator()
            while (iterator.hasNext()) {
                val ref = iterator.next()
                val listener = ref.get()
                
                if (listener == null) {
                    // Remove dead reference
                    iterator.remove()
                } else {
                    try {
                        listener.onMemoryPressure(level)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error notifying listener of memory pressure", e)
                    }
                }
            }
        }
    }
    
    /**
     * Notify all listeners to clean up
     */
    private fun notifyCleanupRequested() {
        synchronized(cleanupListeners) {
            val iterator = cleanupListeners.iterator()
            while (iterator.hasNext()) {
                val ref = iterator.next()
                val listener = ref.get()
                
                if (listener == null) {
                    // Remove dead reference
                    iterator.remove()
                } else {
                    try {
                        listener.onCleanupRequested()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error notifying listener of cleanup request", e)
                    }
                }
            }
        }
    }
    
    /**
     * Start periodic memory monitoring
     * @param intervalMs Monitoring interval in milliseconds
     * @param callback Callback invoked with memory stats
     */
    fun startPeriodicMonitoring(
        intervalMs: Long = 5000,
        callback: (MemoryStats) -> Unit
    ): java.util.Timer {
        val timer = java.util.Timer("MemoryMonitor", true)
        timer.scheduleAtFixedRate(object : java.util.TimerTask() {
            override fun run() {
                val stats = getMemoryStats()
                callback(stats)
                
                // Auto-trigger cleanup if needed
                if (stats.pressureLevel != MemoryPressureLevel.NORMAL) {
                    checkMemoryAndCleanup()
                }
            }
        }, 0, intervalMs)
        
        Log.i(TAG, "Started periodic memory monitoring (interval: ${intervalMs}ms)")
        return timer
    }
    
    /**
     * Estimate memory required for a file
     * @param fileSizeBytes File size in bytes
     * @param overhead Overhead multiplier (default 1.5x for parsing/rendering)
     * @return Estimated memory requirement in MB
     */
    fun estimateMemoryRequirement(fileSizeBytes: Long, overhead: Double = 1.5): Long {
        return ((fileSizeBytes * overhead) / (1024 * 1024)).toLong()
    }
    
    /**
     * Check if a file can be safely loaded
     * @param fileSizeBytes File size in bytes
     * @return true if file can be loaded without memory issues
     */
    fun canLoadFile(fileSizeBytes: Long): Boolean {
        val requiredMB = estimateMemoryRequirement(fileSizeBytes)
        val availableMB = getAvailableMemoryMB()
        
        // Require at least 2x the estimated memory to be safe
        val canLoad = availableMB >= (requiredMB * 2)
        
        if (!canLoad) {
            Log.w(TAG, "Cannot safely load file: requires ~${requiredMB}MB, " +
                    "available ${availableMB}MB")
        }
        
        return canLoad
    }
    
    /**
     * Get memory usage trend
     * Tracks memory usage over time to detect leaks or growing usage
     */
    private val memoryHistory = mutableListOf<Pair<Long, Long>>() // timestamp to usedMemory
    private const val MAX_HISTORY_SIZE = 100
    
    fun recordMemoryUsage() {
        val stats = getMemoryStats()
        val timestamp = System.currentTimeMillis()
        
        synchronized(memoryHistory) {
            memoryHistory.add(timestamp to stats.usedMemoryMB)
            
            // Keep only recent history
            if (memoryHistory.size > MAX_HISTORY_SIZE) {
                memoryHistory.removeAt(0)
            }
        }
    }
    
    /**
     * Detect if memory usage is trending upward (potential leak)
     * @return true if memory usage is consistently increasing
     */
    fun isMemoryLeaking(): Boolean {
        synchronized(memoryHistory) {
            if (memoryHistory.size < 10) {
                return false // Not enough data
            }
            
            // Check if memory is consistently increasing
            val recent = memoryHistory.takeLast(10)
            var increasingCount = 0
            
            for (i in 1 until recent.size) {
                if (recent[i].second > recent[i - 1].second) {
                    increasingCount++
                }
            }
            
            // If 80% of samples show increase, likely a leak
            return increasingCount >= 8
        }
    }
    
    /**
     * Get memory usage trend as a string
     */
    fun getMemoryTrend(): String {
        synchronized(memoryHistory) {
            if (memoryHistory.size < 2) {
                return "INSUFFICIENT_DATA"
            }
            
            val first = memoryHistory.first().second
            val last = memoryHistory.last().second
            val change = last - first
            val percentChange = (change.toDouble() / first.toDouble()) * 100
            
            return when {
                percentChange > 20 -> "INCREASING (${String.format("%.1f", percentChange)}%)"
                percentChange < -20 -> "DECREASING (${String.format("%.1f", percentChange)}%)"
                else -> "STABLE (${String.format("%.1f", percentChange)}%)"
            }
        }
    }
}
