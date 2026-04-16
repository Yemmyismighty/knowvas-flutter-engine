import Foundation

/// Manages EPUB chapter loading and caching with LRU strategy
class EpubChapterCache {
    
    // MARK: - Properties
    
    private var cache: [Int: CachedChapter] = [:]
    private var accessOrder: [Int] = [] // LRU tracking
    private let maxCachedChapters: Int
    private let memoryManager = MemoryManager.shared
    
    // MARK: - Types
    
    struct CachedChapter {
        let chapterIndex: Int
        let content: String
        let size: Int
        var lastAccessed: Date
    }
    
    // MARK: - Initialization
    
    init(maxCachedChapters: Int = 5) {
        self.maxCachedChapters = maxCachedChapters
        
        // Register for memory pressure notifications
        memoryManager.registerMemoryPressureCallback { [weak self] level in
            self?.handleMemoryPressure(level: level)
        }
        
        // Register for system memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: .memoryPressureHigh,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Cache Management
    
    /// Cache a chapter
    func cacheChapter(index: Int, content: String) {
        let size = content.utf8.count
        let chapter = CachedChapter(
            chapterIndex: index,
            content: content,
            size: size,
            lastAccessed: Date()
        )
        
        cache[index] = chapter
        updateAccessOrder(for: index)
        
        // Enforce cache size limit
        enforceCacheLimit()
        
        print("EpubChapterCache: Cached chapter \(index) (\(formatBytes(size)))")
    }
    
    /// Get cached chapter
    func getChapter(index: Int) -> String? {
        guard var chapter = cache[index] else {
            return nil
        }
        
        // Update last accessed time
        chapter.lastAccessed = Date()
        cache[index] = chapter
        updateAccessOrder(for: index)
        
        return chapter.content
    }
    
    /// Check if chapter is cached
    func isCached(index: Int) -> Bool {
        return cache[index] != nil
    }
    
    /// Remove chapter from cache
    func removeChapter(index: Int) {
        cache.removeValue(forKey: index)
        accessOrder.removeAll { $0 == index }
        
        print("EpubChapterCache: Removed chapter \(index)")
    }
    
    /// Clear all cached chapters
    func clearAll() {
        let count = cache.count
        cache.removeAll()
        accessOrder.removeAll()
        
        print("EpubChapterCache: Cleared all \(count) chapters")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (count: Int, totalSize: Int) {
        let count = cache.count
        let totalSize = cache.values.reduce(0) { $0 + $1.size }
        return (count, totalSize)
    }
    
    // MARK: - LRU Management
    
    private func updateAccessOrder(for index: Int) {
        // Remove from current position
        accessOrder.removeAll { $0 == index }
        
        // Add to end (most recently used)
        accessOrder.append(index)
    }
    
    private func enforceCacheLimit() {
        // Check if we need to evict chapters
        while cache.count > maxCachedChapters {
            evictLeastRecentlyUsed()
        }
    }
    
    private func evictLeastRecentlyUsed() {
        guard let lruIndex = accessOrder.first else { return }
        
        removeChapter(index: lruIndex)
        print("EpubChapterCache: Evicted LRU chapter \(lruIndex)")
    }
    
    // MARK: - Memory Pressure Handling
    
    private func handleMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        switch level {
        case .normal:
            break
            
        case .moderate:
            // Unload half of cached chapters
            unloadOffScreenChapters(keepCount: maxCachedChapters / 2)
            
        case .critical:
            // Unload all but the most recent chapter
            unloadOffScreenChapters(keepCount: 1)
        }
    }
    
    @objc private func handleMemoryWarning() {
        print("EpubChapterCache: Memory warning - unloading chapters")
        unloadOffScreenChapters(keepCount: 1)
    }
    
    /// Unload off-screen chapters, keeping only the most recent ones
    func unloadOffScreenChapters(keepCount: Int) {
        let chaptersToKeep = Array(accessOrder.suffix(keepCount))
        let chaptersToRemove = cache.keys.filter { !chaptersToKeep.contains($0) }
        
        for index in chaptersToRemove {
            removeChapter(index: index)
        }
        
        print("EpubChapterCache: Unloaded \(chaptersToRemove.count) chapters, kept \(keepCount)")
    }
    
    /// Preload adjacent chapters for smooth navigation
    func preloadAdjacentChapters(
        currentIndex: Int,
        totalChapters: Int,
        loader: (Int) async throws -> String
    ) async {
        // Preload next 2 chapters
        let nextIndices = [currentIndex + 1, currentIndex + 2]
            .filter { $0 < totalChapters && !isCached(index: $0) }
        
        for index in nextIndices {
            do {
                let content = try await loader(index)
                cacheChapter(index: index, content: content)
            } catch {
                print("EpubChapterCache: Failed to preload chapter \(index) - \(error)")
            }
        }
    }
    
    // MARK: - Utilities
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func logCacheStatus() {
        let stats = getCacheStats()
        print("""
        EpubChapterCache Status:
        - Cached chapters: \(stats.count)/\(maxCachedChapters)
        - Total size: \(formatBytes(stats.totalSize))
        - Access order: \(accessOrder)
        """)
    }
}
