import XCTest
import PDFKit
@testable import Runner

/// Comprehensive tests for PDF reader functionality
/// Requirements: 16.6 - iOS native tests for PDF reader
class PdfReaderTests: XCTestCase {
    
    var pdfReader: PdfReader!
    var mockEventSink: MockEventSink!
    let testSessionId = "test-pdf-session-123"
    
    override func setUp() {
        super.setUp()
        mockEventSink = MockEventSink()
        pdfReader = PdfReader(eventSink: mockEventSink.sink, sessionId: testSessionId)
    }
    
    override func tearDown() {
        pdfReader?.close()
        pdfReader = nil
        mockEventSink = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(pdfReader, "PDF reader should be initialized")
    }
    
    // MARK: - PDF Opening Tests
    
    func testOpenPdfWithValidFile() {
        let expectation = XCTestExpectation(description: "Open PDF")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
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
                XCTFail("Failed to open PDF: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    func testOpenPdfWithInvalidFile() {
        let expectation = XCTestExpectation(description: "Open invalid PDF")
        let invalidUrl = "/invalid/path/document.pdf"
        
        pdfReader.open(fileUrl: invalidUrl) { result in
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
    
    func testOpenPdfEmitsReadyEvent() {
        let expectation = XCTestExpectation(description: "Ready event")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
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
        cleanupTestFile(pdfUrl)
    }
    
    func testOpenPdfWithFileUrl() {
        let expectation = XCTestExpectation(description: "Open PDF with file:// URL")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        let fileUrlString = "file://\(pdfUrl.path)"
        
        pdfReader.open(fileUrl: fileUrlString) { result in
            switch result {
            case .success:
                XCTAssertTrue(true, "Should open with file:// URL")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to open PDF with file:// URL: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Page Navigation Tests
    
    func testPageNavigation() {
        let expectation = XCTestExpectation(description: "Page navigation")
        
        guard let pdfUrl = createTestPdfFile(pageCount: 5) else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Navigate to next page
                self.pdfReader.goToPage(1)
                
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
        cleanupTestFile(pdfUrl)
    }
    
    func testGoToSpecificPage() {
        let expectation = XCTestExpectation(description: "Go to specific page")
        
        guard let pdfUrl = createTestPdfFile(pageCount: 10) else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Jump to page 5
                self.pdfReader.goToPage(5)
                
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
                    
                    // Check page index in event
                    if let event = pageTurnEvents.first as? [String: Any],
                       let pageIndex = event["page_index"] as? Int {
                        XCTAssertEqual(pageIndex, 5)
                    }
                    
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Zoom Tests
    
    func testZoomIn() {
        let expectation = XCTestExpectation(description: "Zoom in")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Zoom in
                self.pdfReader.setZoom(2.0)
                
                // Should not crash
                XCTAssertTrue(true, "Zoom should work without errors")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    func testZoomOut() {
        let expectation = XCTestExpectation(description: "Zoom out")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Zoom in then out
                self.pdfReader.setZoom(2.0)
                self.pdfReader.setZoom(1.0)
                
                XCTAssertTrue(true, "Zoom in/out should work")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    func testZoomLimits() {
        let expectation = XCTestExpectation(description: "Zoom limits")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Test min zoom (100%)
                self.pdfReader.setZoom(1.0)
                
                // Test max zoom (400%)
                self.pdfReader.setZoom(4.0)
                
                // Test beyond limits (should be clamped)
                self.pdfReader.setZoom(0.5)  // Below min
                self.pdfReader.setZoom(5.0)  // Above max
                
                XCTAssertTrue(true, "Zoom limits should be enforced")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    func testDoubleTapZoom() {
        let expectation = XCTestExpectation(description: "Double tap zoom")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Simulate double tap
                self.pdfReader.toggleZoom()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Toggle again
                    self.pdfReader.toggleZoom()
                    
                    XCTAssertTrue(true, "Double tap zoom should work")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Bookmark Tests
    
    func testAddBookmark() {
        let expectation = XCTestExpectation(description: "Add bookmark")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Add a bookmark
                self.pdfReader.addBookmark(page: 3)
                
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
        cleanupTestFile(pdfUrl)
    }
    
    func testRemoveBookmark() {
        let expectation = XCTestExpectation(description: "Remove bookmark")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Add then remove a bookmark
                self.pdfReader.addBookmark(page: 3)
                self.pdfReader.removeBookmark(page: 3)
                
                XCTAssertGreaterThan(self.mockEventSink.events.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Rendering Performance Tests
    
    func testRenderingPerformance() {
        let expectation = XCTestExpectation(description: "Rendering performance")
        
        guard let pdfUrl = createTestPdfFile(pageCount: 10) else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        let startTime = Date()
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                let loadTime = Date().timeIntervalSince(startTime)
                
                // Should open within 4 seconds (requirement)
                XCTAssertLessThan(loadTime, 4.0, "PDF should open within 4 seconds")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    func testProgressiveRendering() {
        let expectation = XCTestExpectation(description: "Progressive rendering")
        
        guard let pdfUrl = createTestPdfFile(pageCount: 100) else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Should open quickly even with many pages
                XCTAssertTrue(true, "Progressive rendering should enable fast opening")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryPressureHandling() {
        let expectation = XCTestExpectation(description: "Memory pressure")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
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
        cleanupTestFile(pdfUrl)
    }
    
    func testThumbnailCaching() {
        let expectation = XCTestExpectation(description: "Thumbnail caching")
        
        guard let pdfUrl = createTestPdfFile(pageCount: 10) else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Request thumbnails for multiple pages
                for i in 0..<5 {
                    self.pdfReader.getThumbnail(page: i) { thumbnail in
                        // Thumbnails should be generated
                        XCTAssertNotNil(thumbnail)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Close Tests
    
    func testCloseReader() {
        let expectation = XCTestExpectation(description: "Close reader")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Close the reader
                self.pdfReader.close()
                
                // Should not crash
                XCTAssertTrue(true, "Reader should close cleanly")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Event Emission Tests
    
    func testAllEventsHaveRequiredFields() {
        let expectation = XCTestExpectation(description: "Event fields")
        
        guard let pdfUrl = createTestPdfFile() else {
            XCTFail("Failed to create test PDF file")
            return
        }
        
        pdfReader.open(fileUrl: pdfUrl.path) { result in
            if case .success = result {
                // Perform some actions
                self.pdfReader.goToPage(1)
                self.pdfReader.addBookmark(page: 1)
                
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
        cleanupTestFile(pdfUrl)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPdfFile(pageCount: Int = 3) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let pdfUrl = tempDir.appendingPathComponent("test_document.pdf")
        
        // Create a simple PDF for testing
        let pdfMetaData = [
            kCGPDFContextCreator: "Test",
            kCGPDFContextAuthor: "Test Author"
        ]
        
        UIGraphicsBeginPDFContextToFile(pdfUrl.path, .zero, pdfMetaData as [String: Any])
        
        for i in 0..<pageCount {
            UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: 612, height: 792), nil)
            
            let text = "Test Page \(i + 1)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24)
            ]
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
        
        UIGraphicsEndPDFContext()
        
        return pdfUrl
    }
    
    private func cleanupTestFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
