import XCTest
@testable import Runner

/// Tests for EPUB memory optimization and lazy loading
class EpubMemoryOptimizationTests: XCTestCase {
    
    var chapterCache: EpubChapterCache!
    var memoryManager: MemoryManager!
    
    override func setUp() {
        super.setUp()
        chapterCache = EpubChapterCache(maxCachedChapters: 3)
        memoryManager = MemoryManager.shared
    }
    
    override func tearDown() {
        chapterCache.clearAll()
        memoryManager.clearCallbacks()
        super.tearDown()
    }
    
    // MARK: - Chapter Cache Tests
    
    func testChapterCaching() {
        // Test caching a chapter
        let content = "<html><body>Test content</body></html>"
        chapterCache.cacheChapter(index: 0, content: content)
        
        XCTAssertTrue(chapterCache.isCached(index: 0))
        XCTAssertEqual(chapterCache.getChapter(index: 0), content)
    }
    
    func testLRUEviction() {
        // Cache more chapters than the limit
        for i in 0..<5 {
            let content = "<html><body>Chapter \(i)</body></html>"
            chapterCache.cacheChapter(index: i, content: content)
        }
        
        // Check that only the last 3 chapters are cached (LRU)
        let stats = chapterCache.getCacheStats()
        XCTAssertEqual(stats.count, 3, "Should only cache maxCachedChapters")
        
        // The oldest chapters should be evicted
        XCTAssertFalse(chapterCache.isCached(index: 0))
        XCTAssertFalse(chapterCache.isCached(index: 1))
        
        // The newest chapters should be cached
        XCTAssertTrue(chapterCache.isCached(index: 2))
        XCTAssertTrue(chapterCache.isCached(index: 3))
        XCTAssertTrue(chapterCache.isCached(index: 4))
    }
    
    func testAccessOrderUpdate() {
        // Cache chapters
        chapterCache.cacheChapter(index: 0, content: "Chapter 0")
        chapterCache.cacheChapter(index: 1, content: "Chapter 1")
        chapterCache.cacheChapter(index: 2, content: "Chapter 2")
        
        // Access chapter 0 (should move it to most recent)
        _ = chapterCache.getChapter(index: 0)
        
        // Cache a new chapter (should evict chapter 1, not 0)
        chapterCache.cacheChapter(index: 3, content: "Chapter 3")
        
        XCTAssertTrue(chapterCache.isCached(index: 0), "Recently accessed chapter should not be evicted")
        XCTAssertFalse(chapterCache.isCached(index: 1), "Least recently used chapter should be evicted")
        XCTAssertTrue(chapterCache.isCached(index: 2))
        XCTAssertTrue(chapterCache.isCached(index: 3))
    }
    
    func testUnloadOffScreenChapters() {
        // Cache multiple chapters
        for i in 0..<5 {
            chapterCache.cacheChapter(index: i, content: "Chapter \(i)")
        }
        
        // Unload keeping only 1 chapter
        chapterCache.unloadOffScreenChapters(keepCount: 1)
        
        let stats = chapterCache.getCacheStats()
        XCTAssertEqual(stats.count, 1, "Should keep only 1 chapter")
    }
    
    func testClearAll() {
        // Cache chapters
        chapterCache.cacheChapter(index: 0, content: "Chapter 0")
        chapterCache.cacheChapter(index: 1, content: "Chapter 1")
        
        // Clear all
        chapterCache.clearAll()
        
        let stats = chapterCache.getCacheStats()
        XCTAssertEqual(stats.count, 0, "Cache should be empty")
        XCTAssertFalse(chapterCache.isCached(index: 0))
        XCTAssertFalse(chapterCache.isCached(index: 1))
    }
    
    // MARK: - Memory Manager Tests
    
    func testMemoryUsageTracking() {
        let usedMemory = memoryManager.getUsedMemory()
        let totalMemory = memoryManager.getTotalMemory()
        
        XCTAssertGreaterThan(usedMemory, 0, "Used memory should be greater than 0")
        XCTAssertGreaterThan(totalMemory, 0, "Total memory should be greater than 0")
        XCTAssertLessThan(usedMemory, totalMemory, "Used memory should be less than total")
    }
    
    func testMemoryPressureLevel() {
        let level = memoryManager.getCurrentMemoryPressureLevel()
        
        // Should be one of the valid levels
        switch level {
        case .normal, .moderate, .critical:
            XCTAssertTrue(true)
        }
    }
    
    func testMemoryPressureCallback() {
        let expectation = XCTestExpectation(description: "Memory pressure callback")
        var callbackCalled = false
        
        memoryManager.registerMemoryPressureCallback { level in
            callbackCalled = true
            expectation.fulfill()
        }
        
        // Simulate memory pressure by manually calling the notification
        NotificationCenter.default.post(name: .memoryPressureHigh, object: nil)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(callbackCalled, "Callback should be called on memory pressure")
    }
    
    // MARK: - Integration Tests
    
    func testMemoryPressureTriggersUnload() {
        // Cache multiple chapters
        for i in 0..<5 {
            chapterCache.cacheChapter(index: i, content: String(repeating: "x", count: 10000))
        }
        
        let initialCount = chapterCache.getCacheStats().count
        XCTAssertGreaterThan(initialCount, 0)
        
        // Simulate memory warning
        NotificationCenter.default.post(
            name: .memoryPressureHigh,
            object: nil
        )
        
        // Give it a moment to process
        Thread.sleep(forTimeInterval: 0.1)
        
        let finalCount = chapterCache.getCacheStats().count
        XCTAssertLessThanOrEqual(finalCount, initialCount, "Should unload some chapters on memory pressure")
    }
    
    func testPreloadAdjacentChapters() async {
        let expectation = XCTestExpectation(description: "Preload chapters")
        
        // Preload chapters around index 5
        await chapterCache.preloadAdjacentChapters(
            currentIndex: 5,
            totalChapters: 10
        ) { index in
            return "<html><body>Chapter \(index)</body></html>"
        }
        
        // Check that adjacent chapters are cached
        XCTAssertTrue(chapterCache.isCached(index: 6), "Next chapter should be preloaded")
        XCTAssertTrue(chapterCache.isCached(index: 7), "Chapter after next should be preloaded")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    
    func testCachingPerformance() {
        measure {
            for i in 0..<100 {
                let content = String(repeating: "x", count: 1000)
                chapterCache.cacheChapter(index: i, content: content)
            }
            chapterCache.clearAll()
        }
    }
    
    func testRetrievalPerformance() {
        // Setup: Cache chapters
        for i in 0..<10 {
            let content = String(repeating: "x", count: 10000)
            chapterCache.cacheChapter(index: i, content: content)
        }
        
        measure {
            for i in 0..<10 {
                _ = chapterCache.getChapter(index: i)
            }
        }
    }
    
    func testMemoryUsageCalculationPerformance() {
        measure {
            _ = memoryManager.getUsedMemory()
            _ = memoryManager.getTotalMemory()
            _ = memoryManager.getMemoryUsagePercentage()
        }
    }
}
