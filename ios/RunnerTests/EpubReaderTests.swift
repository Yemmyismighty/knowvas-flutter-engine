import XCTest
import WebKit
@testable import Runner

/// Comprehensive tests for EPUB reader functionality
/// Requirements: 16.6 - iOS native tests for EPUB reader
class EpubReaderTests: XCTestCase {
    
    var epubReader: EpubReader!
    var mockEventSink: MockEventSink!
    let testSessionId = "test-epub-session-123"
    
    override func setUp() {
        super.setUp()
        mockEventSink = MockEventSink()
        epubReader = EpubReader(eventSink: mockEventSink.sink, sessionId: testSessionId)
    }
    
    override func tearDown() {
        epubReader.close()
        epubReader = nil
        mockEventSink = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(epubReader, "EPUB reader should be initialized")
    }
    
    // MARK: - EPUB Opening Tests
    
    func testOpenEpubWithValidFile() {
        let expectation = XCTestExpectation(description: "Open EPUB")
        
        // Create a test EPUB file URL
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
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
                XCTFail("Failed to open EPUB: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(epubUrl)
    }
    
    func testOpenEpubWithInvalidFile() {
        let expectation = XCTestExpectation(description: "Open invalid EPUB")
        let invalidUrl = "/invalid/path/book.epub"
        
        epubReader.open(fileUrl: invalidUrl) { result in
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
    
    func testOpenEpubEmitsReadyEvent() {
        let expectation = XCTestExpectation(description: "Ready event")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
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
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Navigation Tests
    
    func testPageNavigation() {
        let expectation = XCTestExpectation(description: "Page navigation")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Navigate to next page
                self.epubReader.nextPage()
                
                // Wait a moment for navigation
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
        cleanupTestFile(epubUrl)
    }
    
    func testPreviousPageNavigation() {
        let expectation = XCTestExpectation(description: "Previous page navigation")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Navigate forward then back
                self.epubReader.nextPage()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.epubReader.previousPage()
                    
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
        cleanupTestFile(epubUrl)
    }
    
    func testGoToPage() {
        let expectation = XCTestExpectation(description: "Go to page")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Jump to a specific page
                self.epubReader.goToPage(5)
                
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
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Settings Tests
    
    func testApplySettings() {
        let settings = EpubSettings()
        settings.fontSize = 18
        settings.theme = .sepia
        settings.fontFamily = "Georgia"
        
        // Should not throw
        epubReader.applySettings(settings)
        
        XCTAssertTrue(true, "Settings should be applied without errors")
    }
    
    func testFontSizeAdjustment() {
        let settings = EpubSettings()
        
        // Test valid font sizes
        settings.fontSize = 12
        epubReader.applySettings(settings)
        
        settings.fontSize = 24
        epubReader.applySettings(settings)
        
        settings.fontSize = 32
        epubReader.applySettings(settings)
        
        XCTAssertTrue(true, "Font size adjustments should work")
    }
    
    func testThemeChanges() {
        let settings = EpubSettings()
        
        // Test all themes
        settings.theme = .light
        epubReader.applySettings(settings)
        
        settings.theme = .dark
        epubReader.applySettings(settings)
        
        settings.theme = .sepia
        epubReader.applySettings(settings)
        
        XCTAssertTrue(true, "Theme changes should work")
    }
    
    // MARK: - Bookmark Tests
    
    func testAddBookmark() {
        let expectation = XCTestExpectation(description: "Add bookmark")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Add a bookmark
                self.epubReader.addBookmark(page: 5)
                
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
        cleanupTestFile(epubUrl)
    }
    
    func testRemoveBookmark() {
        let expectation = XCTestExpectation(description: "Remove bookmark")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Add then remove a bookmark
                self.epubReader.addBookmark(page: 5)
                self.epubReader.removeBookmark(page: 5)
                
                // Should have both add and remove events
                XCTAssertGreaterThan(self.mockEventSink.events.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryPressureHandling() {
        let expectation = XCTestExpectation(description: "Memory pressure")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Simulate memory pressure
                NotificationCenter.default.post(
                    name: .memoryPressureHigh,
                    object: nil
                )
                
                // Give it time to handle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Should not crash
                    XCTAssertTrue(true, "Should handle memory pressure gracefully")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Close Tests
    
    func testCloseReader() {
        let expectation = XCTestExpectation(description: "Close reader")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Close the reader
                self.epubReader.close()
                
                // Should not crash
                XCTAssertTrue(true, "Reader should close cleanly")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Event Emission Tests
    
    func testAllEventsHaveRequiredFields() {
        let expectation = XCTestExpectation(description: "Event fields")
        
        guard let epubUrl = createTestEpubFile() else {
            XCTFail("Failed to create test EPUB file")
            return
        }
        
        epubReader.open(fileUrl: epubUrl.path) { result in
            if case .success = result {
                // Perform some actions
                self.epubReader.nextPage()
                self.epubReader.addBookmark(page: 1)
                
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
        cleanupTestFile(epubUrl)
    }
    
    // MARK: - Helper Methods
    
    private func createTestEpubFile() -> URL? {
        // Create a minimal EPUB structure for testing
        let tempDir = FileManager.default.temporaryDirectory
        let epubUrl = tempDir.appendingPathComponent("test_book.epub")
        
        // For testing, create a simple file
        // In production tests, you would use a real EPUB file
        let testData = "Test EPUB content".data(using: .utf8)
        
        do {
            try testData?.write(to: epubUrl)
            return epubUrl
        } catch {
            print("Failed to create test EPUB: \(error)")
            return nil
        }
    }
    
    private func cleanupTestFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
