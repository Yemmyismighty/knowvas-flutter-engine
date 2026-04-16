import Foundation
import UIKit

/// Manages memory usage and cleanup for reader modules
class MemoryManager {
    static let shared = MemoryManager()
    
    private let memoryThreshold: Double = 0.8 // 80% of available memory
    private let criticalMemoryThreshold: Double = 0.9 // 90% - critical level
    
    // Memory monitoring
    private var monitoringTimer: Timer?
    private var isMonitoring = false
    
    // Callbacks for memory pressure
    private var memoryPressureCallbacks: [(MemoryPressureLevel) -> Void] = []
    
    enum MemoryPressureLevel {
        case normal
        case moderate
        case critical
    }
    
    private init() {
        // Register for memory warning notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMonitoring()
    }
    
    /// Start monitoring memory usage
    func startMonitoring(interval: TimeInterval = 2.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkMemoryPressure()
        }
        
        print("MemoryManager: Started monitoring with \(interval)s interval")
    }
    
    /// Stop monitoring memory usage
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        
        print("MemoryManager: Stopped monitoring")
    }
    
    /// Register callback for memory pressure events
    func registerMemoryPressureCallback(_ callback: @escaping (MemoryPressureLevel) -> Void) {
        memoryPressureCallbacks.append(callback)
    }
    
    /// Clear all registered callbacks
    func clearCallbacks() {
        memoryPressureCallbacks.removeAll()
    }
    
    /// Check current memory pressure level
    private func checkMemoryPressure() {
        let level = getCurrentMemoryPressureLevel()
        
        // Notify callbacks if pressure is not normal
        if level != .normal {
            notifyMemoryPressure(level: level)
        }
    }
    
    /// Get current memory pressure level
    func getCurrentMemoryPressureLevel() -> MemoryPressureLevel {
        let usedMemory = getUsedMemory()
        let totalMemory = getTotalMemory()
        
        guard totalMemory > 0 else { return .normal }
        
        let usageRatio = Double(usedMemory) / Double(totalMemory)
        
        if usageRatio >= criticalMemoryThreshold {
            return .critical
        } else if usageRatio >= memoryThreshold {
            return .moderate
        } else {
            return .normal
        }
    }
    
    /// Check if memory pressure is high
    func isMemoryPressureHigh() -> Bool {
        let level = getCurrentMemoryPressureLevel()
        return level == .moderate || level == .critical
    }
    
    /// Notify all registered callbacks of memory pressure
    private func notifyMemoryPressure(level: MemoryPressureLevel) {
        for callback in memoryPressureCallbacks {
            callback(level)
        }
    }
    
    /// Get current memory usage in bytes
    func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        
        return 0
    }
    
    /// Get total available memory in bytes
    func getTotalMemory() -> UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }
    
    /// Get memory usage percentage
    func getMemoryUsagePercentage() -> Double {
        let used = getUsedMemory()
        let total = getTotalMemory()
        
        guard total > 0 else { return 0 }
        
        return (Double(used) / Double(total)) * 100
    }
    
    /// Clear image caches and temporary data
    func clearCaches() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image cache if using a caching library
        // ImageCache.shared.clearCache() // Uncomment when using Kingfisher or similar
        
        print("MemoryManager: Caches cleared")
    }
    
    /// Handle memory warning from system
    @objc private func handleMemoryWarning() {
        print("MemoryManager: Memory warning received")
        clearCaches()
        
        // Notify observers to unload non-essential resources
        NotificationCenter.default.post(
            name: .memoryPressureHigh,
            object: nil
        )
    }
    
    /// Log current memory status
    func logMemoryStatus() {
        let used = getUsedMemory()
        let total = getTotalMemory()
        let percentage = getMemoryUsagePercentage()
        
        print("""
        MemoryManager Status:
        - Used: \(formatBytes(used))
        - Total: \(formatBytes(total))
        - Usage: \(String(format: "%.2f", percentage))%
        """)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryPressureHigh = Notification.Name("memoryPressureHigh")
}
