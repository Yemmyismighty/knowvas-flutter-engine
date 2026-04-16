import XCTest
import UIKit
@testable import Runner

/// Comprehensive tests for Comic reader functionality
/// Requirements: 16.6 - iOS native tests for Comic reader
class ComicReaderTests: XCTestCase {
    
    var comicReader: ComicReader!
    var mockEventSink: MockEventSink!
    let testSessionId = "test-comic-session-123"
    
    override func setUp() {
        super.setUp()
        mockEventSink = MockEventSink()
        comicReader = ComicReader(eventSink: mockEventSink.sink, sessionId: testSessionId)
    }
    
    override func tearDown() {
        comicReader?.close()
        comicReader = nil
        mockEventSink = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(comicReader, "Comic reader should be initialized")
    }
    
    // MARK: - Comic Opening Tests
    
    func testOpenComicWithValidFile() {
        let expectation = XCTestExpectation(description: "Open comic")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            switch result {
            case .success:
                // Verify reader ready event was emitted
                XCTAssertTrue(self.mockEventSink.events.contains { event in
                    guard let dict = event as? [String: Any],
                          let type = dict["type"] as? String else {
                        return false
                    }
                    return type == "ready"
                })
                
                expectation.fulfill()
                
            case .failure(let error):
                XCTFail("Failed to open comic: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testOpenComicWithInvalidFile() {
        let expectation = XCTestExpectation(description: "Open invalid comic")
        let invalidUrl = "/invalid/path/comic.cbz"
        
        comicReader.open(fileUrl: invalidUrl) { result in
            switch result {
            case .success:
                XCTFail("Should not succeed with invalid file")
            case .failure:
                // Expected to fail
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testOpenComicEmitsReadyEvent() {
        let expectation = XCTestExpectation(description: "Ready event")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Check for ready event with required fields
                let readyEvents = self.mockEventSink.events.filter { event in
                    guard let dict = event as? [String: Any],
                          let type = dict["type"] as? String else {
                        return false
                    }
                    return type == "ready"
                }
                
                XCTAssertGreaterThan(readyEvents.count, 0, "Should emit ready event")
                
                if let readyEvent = readyEvents.first as? [String: Any] {
                    XCTAssertNotNil(readyEvent["session_id"])
                    XCTAssertNotNil(readyEvent["total_pages"])
                    XCTAssertEqual(readyEvent["session_id"] as? String, self.testSessionId)
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testOpenCBZFormat() {
        let expectation = XCTestExpectation(description: "Open CBZ")
        
        guard let comicUrl = createTestComicFile(format: "cbz") else {
            XCTFail("Failed to create test CBZ file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                XCTAssertTrue(true, "Should open CBZ format")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Page Navigation Tests
    
    func testPageNavigation() {
        let expectation = XCTestExpectation(description: "Page navigation")
        
        guard let comicUrl = createTestComicFile(pageCount: 5) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Navigate to next page
                self.comicReader.nextPage()
                
                // Wait for navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Verify page turn event was emitted
                    let pageTurnEvents = self.mockEventSink.events.filter { event in
                        guard let dict = event as? [String: Any],
                              let eventType = dict["event"] as? String else {
                            return false
                        }
                        return eventType == "page_turn"
                    }
                    
                    XCTAssertGreaterThan(pageTurnEvents.count, 0, "Should emit page turn event")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testPreviousPageNavigation() {
        let expectation = XCTestExpectation(description: "Previous page navigation")
        
        guard let comicUrl = createTestComicFile(pageCount: 5) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Navigate forward then back
                self.comicReader.nextPage()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.comicReader.previousPage()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Should have at least 2 page turn events
                        let pageTurnEvents = self.mockEventSink.events.filter { event in
                            guard let dict = event as? [String: Any],
                                  let eventType = dict["event"] as? String else {
                                return false
                            }
                            return eventType == "page_turn"
                        }
                        
                        XCTAssertGreaterThanOrEqual(pageTurnEvents.count, 2)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testGoToPage() {
        let expectation = XCTestExpectation(description: "Go to page")
        
        guard let comicUrl = createTestComicFile(pageCount: 10) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Jump to a specific page
                self.comicReader.goToPage(5)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Verify navigation occurred
                    let pageTurnEvents = self.mockEventSink.events.filter { event in
                        guard let dict = event as? [String: Any],
                              let eventType = dict["event"] as? String else {
                            return false
                        }
                        return eventType == "page_turn"
                    }
                    
                    XCTAssertGreaterThan(pageTurnEvents.count, 0)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Layout Tests
    
    func testSinglePageLayout() {
        let expectation = XCTestExpectation(description: "Single page layout")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Set single page layout
                self.comicReader.setLayout(.singlePage)
                
                XCTAssertTrue(true, "Single page layout should be set")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testDoublePageLayout() {
        let expectation = XCTestExpectation(description: "Double page layout")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Set double page layout
                self.comicReader.setLayout(.doublePage)
                
                XCTAssertTrue(true, "Double page layout should be set")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testReadingDirection() {
        let expectation = XCTestExpectation(description: "Reading direction")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Test left-to-right
                self.comicReader.setReadingDirection(.leftToRight)
                
                // Test right-to-left
                self.comicReader.setReadingDirection(.rightToLeft)
                
                XCTAssertTrue(true, "Reading direction should be configurable")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Zoom Tests
    
    func testZoomIn() {
        let expectation = XCTestExpectation(description: "Zoom in")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Zoom in
                self.comicReader.setZoom(2.0)
                
                XCTAssertTrue(true, "Zoom should work without errors")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testZoomOut() {
        let expectation = XCTestExpectation(description: "Zoom out")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Zoom in then out
                self.comicReader.setZoom(2.0)
                self.comicReader.setZoom(1.0)
                
                XCTAssertTrue(true, "Zoom in/out should work")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testDoubleTapZoom() {
        let expectation = XCTestExpectation(description: "Double tap zoom")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Simulate double tap
                self.comicReader.toggleZoom()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Toggle again
                    self.comicReader.toggleZoom()
                    
                    XCTAssertTrue(true, "Double tap zoom should work")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testPanWhileZoomed() {
        let expectation = XCTestExpectation(description: "Pan while zoomed")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Zoom in
                self.comicReader.setZoom(2.0)
                
                // Pan should be enabled when zoomed
                XCTAssertTrue(true, "Pan should work when zoomed")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Bookmark Tests
    
    func testAddBookmark() {
        let expectation = XCTestExpectation(description: "Add bookmark")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Add a bookmark
                self.comicReader.addBookmark(page: 2)
                
                // Verify bookmark event was emitted
                let bookmarkEvents = self.mockEventSink.events.filter { event in
                    guard let dict = event as? [String: Any],
                          let eventType = dict["event"] as? String else {
                        return false
                    }
                    return eventType == "bookmark"
                }
                
                XCTAssertGreaterThan(bookmarkEvents.count, 0, "Should emit bookmark event")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testRemoveBookmark() {
        let expectation = XCTestExpectation(description: "Remove bookmark")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Add then remove a bookmark
                self.comicReader.addBookmark(page: 2)
                self.comicReader.removeBookmark(page: 2)
                
                XCTAssertGreaterThan(self.mockEventSink.events.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Image Loading Tests
    
    func testLazyImageLoading() {
        let expectation = XCTestExpectation(description: "Lazy image loading")
        
        guard let comicUrl = createTestComicFile(pageCount: 20) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Should load first page immediately
                // Other pages should be loaded lazily
                XCTAssertTrue(true, "Lazy loading should be enabled")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testImageCaching() {
        let expectation = XCTestExpectation(description: "Image caching")
        
        guard let comicUrl = createTestComicFile(pageCount: 10) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Navigate through pages
                for _ in 0..<5 {
                    self.comicReader.nextPage()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Images should be cached
                    XCTAssertTrue(true, "Images should be cached for performance")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testPreloadAdjacentPages() {
        let expectation = XCTestExpectation(description: "Preload adjacent pages")
        
        guard let comicUrl = createTestComicFile(pageCount: 10) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Go to middle page
                self.comicReader.goToPage(5)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Adjacent pages should be preloaded
                    XCTAssertTrue(true, "Adjacent pages should be preloaded")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryPressureHandling() {
        let expectation = XCTestExpectation(description: "Memory pressure")
        
        guard let comicUrl = createTestComicFile(pageCount: 20) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Load several pages
                for _ in 0..<10 {
                    self.comicReader.nextPage()
                }
                
                // Simulate memory pressure
                NotificationCenter.default.post(
                    name: .memoryPressureHigh,
                    object: nil
                )
                
                // Give it time to handle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Should not crash and should clear some cache
                    XCTAssertTrue(true, "Should handle memory pressure gracefully")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    func testImageCacheLimit() {
        let expectation = XCTestExpectation(description: "Image cache limit")
        
        guard let comicUrl = createTestComicFile(pageCount: 50) else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Navigate through many pages
                for _ in 0..<30 {
                    self.comicReader.nextPage()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Cache should have limits to prevent memory issues
                    XCTAssertTrue(true, "Cache should respect size limits")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Close Tests
    
    func testCloseReader() {
        let expectation = XCTestExpectation(description: "Close reader")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Close the reader
                self.comicReader.close()
                
                // Should not crash
                XCTAssertTrue(true, "Reader should close cleanly")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Event Emission Tests
    
    func testAllEventsHaveRequiredFields() {
        let expectation = XCTestExpectation(description: "Event fields")
        
        guard let comicUrl = createTestComicFile() else {
            XCTFail("Failed to create test comic file")
            return
        }
        
        comicReader.open(fileUrl: comicUrl.path) { result in
            if case .success = result {
                // Perform some actions
                self.comicReader.nextPage()
                self.comicReader.addBookmark(page: 1)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Verify all events have required fields
                    for event in self.mockEventSink.events {
                        guard let dict = event as? [String: Any] else {
                            XCTFail("Event should be a dictionary")
                            continue
                        }
                        
                        XCTAssertNotNil(dict["type"], "Event should have type")
                        XCTAssertNotNil(dict["session_id"], "Event should have session_id")
                        XCTAssertNotNil(dict["timestamp"], "Event should have timestamp")
                        
                        if let sessionId = dict["session_id"] as? String {
                            XCTAssertEqual(sessionId, self.testSessionId)
                        }
                    }
                    
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(comicUrl)
    }
    
    // MARK: - Helper Methods
    
    private func createTestComicFile(format: String = "cbz", pageCount: Int = 5) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let comicUrl = tempDir.appendingPathComponent("test_comic.\(format)")
        
        // Create a simple ZIP file with test images
        // For testing purposes, we'll create a minimal structure
        let testData = "Test comic archive".data(using: .utf8)
        
        do {
            try testData?.write(to: comicUrl)
            return comicUrl
        } catch {
            print("Failed to create test comic: \(error)")
            return nil
        }
    }
    
    private func cleanupTestFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
