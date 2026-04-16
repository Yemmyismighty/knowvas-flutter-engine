import Foundation

/// Manages file caching for reader content
class FileCache {
    static let shared = FileCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: UInt64 = 500 * 1024 * 1024 // 500 MB
    
    private init() {
        // Get cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ReaderCache", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        createCacheDirectoryIfNeeded()
    }
    
    /// Create cache directory if it doesn't exist
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// Cache a file
    func cacheFile(data: Data, forKey key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try data.write(to: fileURL)
        
        // Check cache size and clean if needed
        cleanCacheIfNeeded()
    }
    
    /// Retrieve cached file
    func getCachedFile(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: fileURL)
    }
    
    /// Check if file is cached
    func isCached(key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Remove cached file
    func removeCachedFile(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Get cache size in bytes
    func getCacheSize() -> UInt64 {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        var totalSize: UInt64 = 0
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += UInt64(fileSize)
        }
        
        return totalSize
    }
    
    /// Clear all cached files
    func clearCache() {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            try? fileManager.removeItem(at: fileURL)
        }
        
        print("FileCache: Cache cleared")
    }
    
    /// Clean cache if size exceeds limit
    private func cleanCacheIfNeeded() {
        let currentSize = getCacheSize()
        
        if currentSize > maxCacheSize {
            // Remove oldest files until under limit
            removeOldestFiles(targetSize: maxCacheSize * 80 / 100) // Keep at 80% of max
        }
    }
    
    /// Remove oldest files to reach target size
    private func removeOldestFiles(targetSize: UInt64) {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        // Collect file info
        var files: [(url: URL, size: UInt64, date: Date)] = []
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey]
            ),
                  let fileSize = resourceValues.fileSize,
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }
            
            files.append((url: fileURL, size: UInt64(fileSize), date: modificationDate))
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        // Remove files until under target size
        var currentSize = getCacheSize()
        
        for file in files {
            if currentSize <= targetSize {
                break
            }
            
            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
        
        print("FileCache: Cleaned cache to \(formatBytes(currentSize))")
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
