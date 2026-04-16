import XCTest
@testable import Runner

/// Unit tests for EpubReaderViewController
class EpubReaderViewControllerTests: XCTestCase {
    
    var epubReader: EpubReader!
    var viewController: EpubReaderViewController!
    let testSessionId = "test-session-123"
    
    override func setUp() {
        super.setUp()
        
        // Create mock event sink
        let mockEventSink: FlutterEventSink = { event in
            print("Event emitted: \(event)")
        }
        
        epubReader = EpubReader(eventSink: mockEventSink, sessionId: testSessionId)
        viewController = EpubReaderViewController(epubReader: epubReader, sessionId: testSessionId)
        
        // Load view
        _ = viewController.view
    }
    
    override func tearDown() {
        viewController = nil
        epubReader = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController.view)
    }
    
    func testInitialState() {
        // Verify initial state
        XCTAssertEqual(viewController.value(forKey: "currentPage") as? Int, 0)
        XCTAssertEqual(viewController.value(forKey: "totalPages") as? Int, 0)
        XCTAssertEqual(viewController.value(forKey: "controlsVisible") as? Bool, true)
    }
    
    // MARK: - Navigation Tests
    
    func testGoToPage() {
        // Set total pages
        viewController.updateTotalPages(100)
        
        // Navigate to page 50
        viewController.goToPage(50)
        
        // Verify current page updated
        XCTAssertEqual(viewController.value(forKey: "currentPage") as? Int, 50)
    }
    
    func testGoToPageOutOfBounds() {
        // Set total pages
        viewController.updateTotalPages(100)
        
        // Try to navigate to invalid page
        viewController.goToPage(150)
        
        // Current page should not change
        XCTAssertEqual(viewController.value(forKey: "currentPage") as? Int, 0)
    }
    
    func testUpdateTotalPages() {
        viewController.updateTotalPages(200)
        
        XCTAssertEqual(viewController.value(forKey: "totalPages") as? Int, 200)
    }
    
    // MARK: - Bookmark Tests
    
    func testBookmarkToggle() {
        // Set total pages and navigate
        viewController.updateTotalPages(100)
        viewController.goToPage(25)
        
        // Get bookmarks set
        let bookmarks = viewController.value(forKey: "bookmarks") as? Set<Int>
        XCTAssertNotNil(bookmarks)
        
        // Initially no bookmarks
        XCTAssertEqual(bookmarks?.count, 0)
    }
    
    // MARK: - Settings Tests
    
    func testSettingsIntegration() {
        let settings = epubReader.getSettings()
        
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings.fontSize, EpubSettings.Constants.defaultFontSize)
        XCTAssertEqual(settings.theme, .light)
    }
    
    func testSettingsUpdate() {
        let preferences = ReaderPreferences(from: [
            "font_size": 20,
            "theme": "dark"
        ])
        
        epubReader.setPreferences(preferences)
        
        let settings = epubReader.getSettings()
        XCTAssertEqual(settings.fontSize, 20)
        XCTAssertEqual(settings.theme, .dark)
    }
    
    // MARK: - Event Emission Tests
    
    func testBookmarkEventEmission() {
        var eventEmitted = false
        var eventData: [String: Any]?
        
        let mockEventSink: FlutterEventSink = { event in
            eventEmitted = true
            eventData = event as? [String: Any]
        }
        
        let reader = EpubReader(eventSink: mockEventSink, sessionId: testSessionId)
        reader.emitBookmarkEvent(pageNumber: 42, added: true)
        
        XCTAssertTrue(eventEmitted)
        XCTAssertEqual(eventData?["type"] as? String, "engagement")
        XCTAssertEqual(eventData?["event"] as? String, "bookmark")
        XCTAssertEqual(eventData?["page_number"] as? Int, 42)
        XCTAssertEqual(eventData?["action"] as? String, "add")
    }
    
    func testHighlightEventEmission() {
        var eventEmitted = false
        var eventData: [String: Any]?
        
        let mockEventSink: FlutterEventSink = { event in
            eventEmitted = true
            eventData = event as? [String: Any]
        }
        
        let reader = EpubReader(eventSink: mockEventSink, sessionId: testSessionId)
        reader.emitHighlightEvent(pageNumber: 42, text: "Test text", color: "#FFFF00")
        
        XCTAssertTrue(eventEmitted)
        XCTAssertEqual(eventData?["type"] as? String, "engagement")
        XCTAssertEqual(eventData?["event"] as? String, "highlight")
        XCTAssertEqual(eventData?["page_number"] as? Int, 42)
        XCTAssertEqual(eventData?["highlighted_text"] as? String, "Test text")
        XCTAssertEqual(eventData?["color"] as? String, "#FFFF00")
    }
    
    func testNoteEventEmission() {
        var eventEmitted = false
        var eventData: [String: Any]?
        
        let mockEventSink: FlutterEventSink = { event in
            eventEmitted = true
            eventData = event as? [String: Any]
        }
        
        let reader = EpubReader(eventSink: mockEventSink, sessionId: testSessionId)
        reader.emitNoteEvent(pageNumber: 42, text: "Selected text", note: "My note")
        
        XCTAssertTrue(eventEmitted)
        XCTAssertEqual(eventData?["type"] as? String, "engagement")
        XCTAssertEqual(eventData?["event"] as? String, "note")
        XCTAssertEqual(eventData?["page_number"] as? Int, 42)
        XCTAssertEqual(eventData?["selected_text"] as? String, "Selected text")
        XCTAssertEqual(eventData?["note_text"] as? String, "My note")
    }
    
    // MARK: - Performance Tests
    
    func testViewLoadingPerformance() {
        measure {
            let vc = EpubReaderViewController(epubReader: epubReader, sessionId: testSessionId)
            _ = vc.view
        }
    }
}
