package com.knowvas.reader.utils

import org.junit.Test
import org.junit.Assert.*
import org.junit.Before

/**
 * Unit tests for MemoryManager
 * 
 * Tests:
 * - Memory statistics calculation
 * - Pressure level detection
 * - Memory requirement estimation
 * - Leak detection
 */
class MemoryManagerTest {
    
    @Before
    fun setup() {
        // Clear any existing listeners
        MemoryManager.registerCleanupListener(object : MemoryManager.MemoryCleanupListener {
            override fun onMemoryPressure(level: MemoryManager.MemoryPressureLevel) {}
            override fun onCleanupRequested() {}
        })
    }
    
    @Test
    fun testGetMemoryStats() {
        val stats = MemoryManager.getMemoryStats()
        
        assertNotNull(stats)
        assertTrue(stats.usedMemoryMB > 0)
        assertTrue(stats.maxMemoryMB > 0)
        assertTrue(stats.freeMemoryMB >= 0)
        assertTrue(stats.usagePercentage >= 0.0 && stats.usagePercentage <= 1.0)
        assertNotNull(stats.pressureLevel)
    }
    
    @Test
    fun testGetAvailableMemory() {
        val availableMB = MemoryManager.getAvailableMemoryMB()
        
        assertTrue(availableMB > 0)
        assertTrue(availableMB < 10000) // Sanity check - should be less than 10GB
    }
    
    @Test
    fun testHasEnoughMemory() {
        // Should have enough memory for small allocation
        assertTrue(MemoryManager.hasEnoughMemory(1))
        
        // Should not have enough memory for huge allocation
        assertFalse(MemoryManager.hasEnoughMemory(100000))
    }
    
    @Test
    fun testEstimateMemoryRequirement() {
        val fileSizeBytes = 10 * 1024 * 1024L // 10 MB
        
        // Default overhead (1.5x)
        val estimatedMB = MemoryManager.estimateMemoryRequirement(fileSizeBytes)
        assertEquals(15L, estimatedMB) // 10 MB * 1.5 = 15 MB
        
        // Custom overhead (2.0x)
        val estimatedMB2 = MemoryManager.estimateMemoryRequirement(fileSizeBytes, 2.0)
        assertEquals(20L, estimatedMB2) // 10 MB * 2.0 = 20 MB
    }
    
    @Test
    fun testCanLoadFile() {
        // Small file should be loadable
        val smallFile = 1 * 1024 * 1024L // 1 MB
        assertTrue(MemoryManager.canLoadFile(smallFile))
        
        // Huge file should not be loadable
        val hugeFile = 10000 * 1024 * 1024L // 10 GB
        assertFalse(MemoryManager.canLoadFile(hugeFile))
    }
    
    @Test
    fun testMemoryPressureDetection() {
        val stats = MemoryManager.getMemoryStats()
        
        // Pressure level should match usage percentage
        when (stats.pressureLevel) {
            MemoryManager.MemoryPressureLevel.NORMAL -> {
                assertTrue(stats.usagePercentage < 0.75)
            }
            MemoryManager.MemoryPressureLevel.WARNING -> {
                assertTrue(stats.usagePercentage >= 0.75 && stats.usagePercentage < 0.85)
            }
            MemoryManager.MemoryPressureLevel.CRITICAL -> {
                assertTrue(stats.usagePercentage >= 0.85 && stats.usagePercentage < 0.95)
            }
            MemoryManager.MemoryPressureLevel.EMERGENCY -> {
                assertTrue(stats.usagePercentage >= 0.95)
            }
        }
    }
    
    @Test
    fun testIsMemoryPressureDetected() {
        val isPressure = MemoryManager.isMemoryPressureDetected()
        val stats = MemoryManager.getMemoryStats()
        
        // Should match the pressure level
        assertEquals(
            stats.pressureLevel != MemoryManager.MemoryPressureLevel.NORMAL,
            isPressure
        )
    }
    
    @Test
    fun testRecordMemoryUsage() {
        // Record some memory usage samples
        MemoryManager.recordMemoryUsage()
        MemoryManager.recordMemoryUsage()
        MemoryManager.recordMemoryUsage()
        
        // Should not throw any exceptions
        // Actual history is private, so we can't verify directly
    }
    
    @Test
    fun testGetMemoryTrend() {
        // Record some samples
        for (i in 0 until 5) {
            MemoryManager.recordMemoryUsage()
            Thread.sleep(10) // Small delay between samples
        }
        
        val trend = MemoryManager.getMemoryTrend()
        
        assertNotNull(trend)
        assertTrue(
            trend.contains("INCREASING") || 
            trend.contains("DECREASING") || 
            trend.contains("STABLE") ||
            trend.contains("INSUFFICIENT_DATA")
        )
    }
    
    @Test
    fun testCleanupListenerRegistration() {
        var pressureCalled = false
        var cleanupCalled = false
        
        val listener = object : MemoryManager.MemoryCleanupListener {
            override fun onMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
                pressureCalled = true
            }
            
            override fun onCleanupRequested() {
                cleanupCalled = true
            }
        }
        
        // Register listener
        MemoryManager.registerCleanupListener(listener)
        
        // Trigger cleanup
        MemoryManager.forceCleanup()
        
        // Cleanup should have been called
        assertTrue(cleanupCalled)
        
        // Unregister listener
        MemoryManager.unregisterCleanupListener(listener)
    }
    
    @Test
    fun testForceCleanup() {
        val statsBefore = MemoryManager.getMemoryStats()
        
        // Force cleanup
        MemoryManager.forceCleanup()
        
        val statsAfter = MemoryManager.getMemoryStats()
        
        // Memory usage should be same or lower after cleanup
        assertTrue(statsAfter.usedMemoryMB <= statsBefore.usedMemoryMB + 10) // Allow small variance
    }
    
    @Test
    fun testCheckMemoryAndCleanup() {
        val triggered = MemoryManager.checkMemoryAndCleanup()
        
        // Should return true if cleanup was triggered (memory pressure detected)
        // Should return false if no cleanup needed (normal memory)
        val stats = MemoryManager.getMemoryStats()
        assertEquals(
            stats.pressureLevel != MemoryManager.MemoryPressureLevel.NORMAL,
            triggered
        )
    }
    
    @Test
    fun testPeriodicMonitoring() {
        var callbackCount = 0
        
        // Start monitoring with short interval
        val timer = MemoryManager.startPeriodicMonitoring(100) { stats ->
            callbackCount++
            assertNotNull(stats)
        }
        
        // Wait for a few callbacks
        Thread.sleep(350)
        
        // Stop monitoring
        timer.cancel()
        
        // Should have been called at least 2-3 times
        assertTrue(callbackCount >= 2)
    }
    
    @Test
    fun testMemoryStatsConsistency() {
        val stats = MemoryManager.getMemoryStats()
        
        // Used + Free should be less than or equal to Max
        assertTrue(stats.usedMemoryMB + stats.freeMemoryMB <= stats.maxMemoryMB + 10) // Allow small variance
        
        // Usage percentage should match the ratio
        val calculatedPercentage = stats.usedMemoryMB.toDouble() / stats.maxMemoryMB.toDouble()
        assertEquals(calculatedPercentage, stats.usagePercentage, 0.05) // 5% tolerance
    }
}
