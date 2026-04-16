import Foundation
import Flutter
import PDFKit
import UIKit

/// PDF reader implementation using PDFKit with performance optimizations
class PdfReader {
    private let eventSink: FlutterEventSink?
    private let sessionId: String
    
    // PDFKit components
    private var pdfDocument: PDFDocument?
    private var pdfView: PDFView?
    private var currentPageIndex: Int = 0
    
    // Notification observer
    private var pageChangeObserver: NSObjectProtocol?
    
    // Zoom configuration
    private let minZoomScale: CGFloat = 1.0  // 100%
    private let maxZoomScale: CGFloat = 4.0  // 400%
    private var isZoomedIn: Bool = false
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    // Bookmarks
    private var bookmarks: Set<Int> = []
    
    // Performance optimization components
    private let thumbnailCache = PDFThumbnailCache()
    private var memoryPressureObserver: NSObjectProtocol?
    private let renderQueue = DispatchQueue(label: "com.knowvas.pdf.render", qos: .userInitiated)
    
    // Progressive rendering state
    private var isProgressiveRenderingEnabled = true
    private var preloadedPages: Set<Int> = []
    private let preloadRange = 2 // Preload 2 pages ahead and behind
    
    init(eventSink: FlutterEventSink?, sessionId: String) {
        self.eventSink = eventSink
        self.sessionId = sessionId
        
        // Register for memory pressure notifications
        setupMemoryPressureObserver()
        
        // Start memory monitoring
        MemoryManager.shared.startMonitoring()
        MemoryManager.shared.registerMemoryPressureCallback { [weak self] level in
            self?.handleMemoryPressure(level: level)
        }
    }
    
    deinit {
        removePageChangeObserver()
        removeMemoryPressureObserver()
        MemoryManager.shared.stopMonitoring()
        thumbnailCache.clearCache()
    }
    
    /// Open a PDF file with performance optimizations
    func open(fileUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let startTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Parse URL - handle both file:// and regular paths
            let url: URL?
            if fileUrl.hasPrefix("file://") {
                url = URL(string: fileUrl)
            } else if fileUrl.hasPrefix("http://") || fileUrl.hasPrefix("https://") {
                url = URL(string: fileUrl)
            } else {
                url = URL(fileURLWithPath: fileUrl)
            }
            
            guard let validUrl = url else {
                DispatchQueue.main.async {
                    completion(.failure(ReaderError.invalidUrl))
                }
                return
            }
            
            // Load PDF document with optimized settings
            guard let document = self.loadPDFDocumentOptimized(url: validUrl) else {
                DispatchQueue.main.async {
                    completion(.failure(ReaderError.failedToLoad))
                }
                return
            }
            
            self.pdfDocument = document
            let pageCount = document.pageCount
            
            DispatchQueue.main.async {
                // Create and configure PDFView for rendering
                self.createPDFView(with: document)
                
                // Set up page change notification observer
                self.setupPageChangeObserver()
                
                // Start progressive rendering for first few pages
                if self.isProgressiveRenderingEnabled {
                    self.preloadInitialPages()
                }
                
                // Emit reader ready event
                self.emitReaderReadyEvent(totalPages: pageCount)
                
                let loadTime = Date().timeIntervalSince(startTime)
                print("PDF Reader: Document loaded in \(String(format: "%.2f", loadTime))s with \(pageCount) pages")
                
                completion(.success(()))
            }
        }
    }
    
    /// Load PDF document with optimized settings
    private func loadPDFDocumentOptimized(url: URL) -> PDFDocument? {
        // Create PDF document
        guard let document = PDFDocument(url: url) else {
            return nil
        }
        
        // Enable page caching for better performance
        document.delegate = self
        
        return document
    }
    
    /// Close the PDF reader
    func close() {
        if pdfDocument != nil {
            emitSessionEndEvent()
            
            // Clean up
            removePageChangeObserver()
            removeDoubleTapGesture()
            
            // Clear caches
            thumbnailCache.clearCache()
            preloadedPages.removeAll()
            
            pdfView?.document = nil
            pdfView = nil
            pdfDocument = nil
            currentPageIndex = 0
            isZoomedIn = false
            
            // Log memory status
            MemoryManager.shared.logMemoryStatus()
        }
    }
    
    /// Set reader preferences
    func setPreferences(_ preferences: [String: Any]) {
        guard let pdfView = pdfView else { return }
        
        // Apply theme preference
        if let theme = preferences["theme"] as? String {
            applyTheme(theme)
        }
        
        // Apply page transition preference
        if let pageTransition = preferences["page_transition"] as? String {
            applyPageTransition(pageTransition)
        }
        
        // Apply display mode
        if let layout = preferences["layout"] as? String {
            applyLayout(layout)
        }
        
        print("PDF Reader: Applied preferences: \(preferences)")
    }
    
    /// Navigate to a specific page
    func goToPage(_ pageIndex: Int) {
        guard let document = pdfDocument,
              let pdfView = pdfView,
              pageIndex >= 0,
              pageIndex < document.pageCount else { return }
        
        if let page = document.page(at: pageIndex) {
            pdfView.go(to: page)
            currentPageIndex = pageIndex
            // Note: Page turn event will be emitted by the notification observer
        }
    }
    
    /// Get the current page
    func getCurrentPage() -> PDFPage? {
        guard let document = pdfDocument,
              currentPageIndex < document.pageCount else { return nil }
        return document.page(at: currentPageIndex)
    }
    
    /// Get total page count
    func getTotalPages() -> Int {
        return pdfDocument?.pageCount ?? 0
    }
    
    /// Get the PDFView instance for embedding in UI
    func getPDFView() -> PDFView? {
        return pdfView
    }
    
    /// Add a bookmark at the specified page
    func addBookmark(at pageIndex: Int) {
        guard pageIndex >= 0, pageIndex < getTotalPages() else { return }
        
        bookmarks.insert(pageIndex)
        emitBookmarkEvent(pageIndex: pageIndex, action: "add")
    }
    
    /// Remove a bookmark at the specified page
    func removeBookmark(at pageIndex: Int) {
        bookmarks.remove(pageIndex)
        emitBookmarkEvent(pageIndex: pageIndex, action: "remove")
    }
    
    /// Check if a page is bookmarked
    func isBookmarked(pageIndex: Int) -> Bool {
        return bookmarks.contains(pageIndex)
    }
    
    /// Get all bookmarks
    func getBookmarks() -> [Int] {
        return Array(bookmarks).sorted()
    }
    
    /// Toggle bookmark at current page
    func toggleBookmark() {
        if isBookmarked(pageIndex: currentPageIndex) {
            removeBookmark(at: currentPageIndex)
        } else {
            addBookmark(at: currentPageIndex)
        }
    }
    
    // MARK: - Private Methods
    
    /// Create and configure PDFView for rendering with performance optimizations
    private func createPDFView(with document: PDFDocument) {
        pdfView = PDFView()
        
        guard let pdfView = pdfView else { return }
        
        // Set the document
        pdfView.document = document
        
        // Configure display settings for optimal performance
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Enable user interactions
        pdfView.isUserInteractionEnabled = true
        
        // Configure background color
        pdfView.backgroundColor = .white
        
        // Performance optimizations
        pdfView.displaysPageBreaks = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        // Enable interpolation for smoother rendering
        pdfView.interpolationQuality = .high
        
        // Configure rendering quality based on device capabilities
        if #available(iOS 14.0, *) {
            // Use high quality rendering on newer devices
            pdfView.pageShadowsEnabled = true
        } else {
            // Disable shadows on older devices for better performance
            pdfView.pageShadowsEnabled = false
        }
        
        // Configure zoom and pan functionality
        configureZoomAndPan(for: pdfView)
        
        // Set initial page if available
        if let firstPage = document.page(at: 0) {
            pdfView.go(to: firstPage)
        }
    }
    
    /// Configure zoom and pan functionality for PDFView
    private func configureZoomAndPan(for pdfView: PDFView) {
        // Set zoom scale limits (100% to 400%)
        pdfView.minScaleFactor = minZoomScale
        pdfView.maxScaleFactor = maxZoomScale
        
        // Enable smooth scaling
        pdfView.scaleFactor = minZoomScale
        
        // PDFView automatically handles pinch-to-zoom gestures
        // and pan gestures when zoomed in
        
        // Add double-tap gesture for zoom toggle
        setupDoubleTapGesture(for: pdfView)
    }
    
    /// Set up double-tap gesture recognizer for zoom toggle
    private func setupDoubleTapGesture(for pdfView: PDFView) {
        // Remove existing gesture if any
        removeDoubleTapGesture()
        
        // Create double-tap gesture recognizer
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        
        pdfView.addGestureRecognizer(doubleTap)
        doubleTapGestureRecognizer = doubleTap
    }
    
    /// Remove double-tap gesture recognizer
    private func removeDoubleTapGesture() {
        if let gesture = doubleTapGestureRecognizer, let pdfView = pdfView {
            pdfView.removeGestureRecognizer(gesture)
            doubleTapGestureRecognizer = nil
        }
    }
    
    /// Handle double-tap gesture for zoom toggle
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let pdfView = pdfView else { return }
        
        let currentScale = pdfView.scaleFactor
        let targetScale: CGFloat
        
        // Toggle between fit-to-width (min scale) and 2x zoom
        if currentScale <= minZoomScale + 0.1 {
            // Currently at minimum zoom, zoom in to 2x
            targetScale = 2.0
            isZoomedIn = true
        } else {
            // Currently zoomed in, zoom out to fit-to-width
            targetScale = minZoomScale
            isZoomedIn = false
        }
        
        // Get the tap location in the PDF view
        let tapLocation = gesture.location(in: pdfView)
        
        // Animate the zoom with smooth transition
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            pdfView.scaleFactor = targetScale
            
            // Center the zoom on the tap location if zooming in
            if targetScale > self.minZoomScale {
                // Calculate the center point for the zoom
                let scrollView = pdfView.subviews.first as? UIScrollView
                if let scrollView = scrollView {
                    let zoomScale = targetScale / currentScale
                    let x = tapLocation.x * zoomScale - scrollView.bounds.width / 2
                    let y = tapLocation.y * zoomScale - scrollView.bounds.height / 2
                    scrollView.contentOffset = CGPoint(x: max(0, x), y: max(0, y))
                }
            }
        }
    }
    
    /// Set up page change notification observer
    private func setupPageChangeObserver() {
        guard let pdfView = pdfView else { return }
        
        // Remove existing observer if any
        removePageChangeObserver()
        
        // Add observer for page change notifications
        pageChangeObserver = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] notification in
            self?.handlePageChanged(notification)
        }
    }
    
    /// Remove page change notification observer
    private func removePageChangeObserver() {
        if let observer = pageChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            pageChangeObserver = nil
        }
    }
    
    /// Handle page change notification
    private func handlePageChanged(_ notification: Notification) {
        guard let pdfView = notification.object as? PDFView,
              let currentPage = pdfView.currentPage,
              let document = pdfDocument,
              let pageIndex = document.index(for: currentPage) else {
            return
        }
        
        // Update current page index
        currentPageIndex = pageIndex
        
        // Emit page turn event
        emitPageTurnEvent(pageIndex: pageIndex)
        
        // Preload adjacent pages for smooth navigation
        if isProgressiveRenderingEnabled {
            preloadAdjacentPages()
        }
    }
    
    /// Apply theme to PDF view
    private func applyTheme(_ theme: String) {
        guard let pdfView = pdfView else { return }
        
        switch theme.lowercased() {
        case "dark":
            pdfView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        case "sepia":
            pdfView.backgroundColor = UIColor(red: 0.96, green: 0.93, blue: 0.85, alpha: 1.0)
        case "light":
            fallthrough
        default:
            pdfView.backgroundColor = .white
        }
    }
    
    /// Apply page transition mode
    private func applyPageTransition(_ transition: String) {
        guard let pdfView = pdfView else { return }
        
        switch transition.lowercased() {
        case "continuous":
            pdfView.displayMode = .singlePageContinuous
        case "swipe":
            fallthrough
        default:
            pdfView.displayMode = .singlePage
        }
    }
    
    /// Apply layout mode
    private func applyLayout(_ layout: String) {
        guard let pdfView = pdfView else { return }
        
        switch layout.lowercased() {
        case "double":
            pdfView.displayMode = .twoUp
        case "double_continuous":
            pdfView.displayMode = .twoUpContinuous
        case "single":
            fallthrough
        default:
            pdfView.displayMode = .singlePage
        }
    }
    
    // MARK: - Event Emission
    
    private func emitReaderReadyEvent(totalPages: Int) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "ready",
            "session_id": sessionId,
            "total_pages": totalPages,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitPageTurnEvent(pageIndex: Int) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "page_turn",
            "page_index": pageIndex,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitSessionEndEvent() {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "session_end",
            "final_page": currentPageIndex,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitBookmarkEvent(pageIndex: Int, action: String) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "bookmark",
            "action": action,
            "page_index": pageIndex,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    func emitError(code: String, message: String) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "error",
            "session_id": sessionId,
            "code": code,
            "message": message,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    // MARK: - Performance Optimization Methods
    
    /// Preload initial pages for faster navigation
    private func preloadInitialPages() {
        guard let document = pdfDocument else { return }
        
        let pagesToPreload = min(5, document.pageCount) // Preload first 5 pages
        
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            
            for i in 0..<pagesToPreload {
                self.preloadPage(at: i)
            }
        }
    }
    
    /// Preload a specific page and generate thumbnail
    private func preloadPage(at index: Int) {
        guard let document = pdfDocument,
              index >= 0,
              index < document.pageCount,
              !preloadedPages.contains(index) else {
            return
        }
        
        guard let page = document.page(at: index) else { return }
        
        // Generate and cache thumbnail
        let thumbnail = generateThumbnail(for: page, size: CGSize(width: 200, height: 300))
        thumbnailCache.cacheThumbnail(thumbnail, forPage: index)
        
        preloadedPages.insert(index)
    }
    
    /// Preload pages around current page for smooth navigation
    private func preloadAdjacentPages() {
        guard let document = pdfDocument else { return }
        
        let startIndex = max(0, currentPageIndex - preloadRange)
        let endIndex = min(document.pageCount - 1, currentPageIndex + preloadRange)
        
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            
            for i in startIndex...endIndex {
                self.preloadPage(at: i)
            }
            
            // Clean up pages that are far from current position
            self.cleanupDistantPages()
        }
    }
    
    /// Clean up preloaded pages that are far from current position
    private func cleanupDistantPages() {
        let cleanupThreshold = preloadRange * 3
        
        preloadedPages = preloadedPages.filter { pageIndex in
            abs(pageIndex - currentPageIndex) <= cleanupThreshold
        }
        
        // Clean thumbnails for pages outside the threshold
        thumbnailCache.cleanupDistantThumbnails(
            currentPage: currentPageIndex,
            threshold: cleanupThreshold
        )
    }
    
    /// Generate thumbnail for a PDF page
    private func generateThumbnail(for page: PDFPage, size: CGSize) -> UIImage {
        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(size.width / pageRect.width, size.height / pageRect.height)
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: scaledSize))
            
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        return thumbnail
    }
    
    /// Get thumbnail for a page (from cache or generate)
    func getThumbnail(forPage index: Int, size: CGSize) -> UIImage? {
        // Check cache first
        if let cachedThumbnail = thumbnailCache.getThumbnail(forPage: index) {
            return cachedThumbnail
        }
        
        // Generate if not cached
        guard let document = pdfDocument,
              let page = document.page(at: index) else {
            return nil
        }
        
        let thumbnail = generateThumbnail(for: page, size: size)
        thumbnailCache.cacheThumbnail(thumbnail, forPage: index)
        
        return thumbnail
    }
    
    /// Setup memory pressure observer
    private func setupMemoryPressureObserver() {
        memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: .memoryPressureHigh,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    /// Remove memory pressure observer
    private func removeMemoryPressureObserver() {
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryPressureObserver = nil
        }
    }
    
    /// Handle memory pressure events
    private func handleMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        switch level {
        case .moderate:
            print("PDF Reader: Moderate memory pressure detected")
            // Clean up distant pages
            cleanupDistantPages()
            
        case .critical:
            print("PDF Reader: Critical memory pressure detected")
            // Aggressive cleanup
            thumbnailCache.clearCache()
            preloadedPages.removeAll()
            
            // Clear PDFView cache if possible
            pdfView?.clearSelection()
            
        case .normal:
            break
        }
    }
    
    /// Handle memory warning
    private func handleMemoryWarning() {
        print("PDF Reader: Memory warning received")
        
        // Clear caches
        thumbnailCache.clearCache()
        preloadedPages.removeAll()
        
        // Log memory status
        MemoryManager.shared.logMemoryStatus()
    }
}

// MARK: - PDFDocument Delegate

extension PdfReader: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return PDFPage.self
    }
}

// MARK: - PDF Thumbnail Cache

/// Cache for PDF page thumbnails
private class PDFThumbnailCache {
    private var cache: [Int: UIImage] = [:]
    private let maxCacheSize = 50 // Maximum number of thumbnails to cache
    private let queue = DispatchQueue(label: "com.knowvas.pdf.thumbnailCache", attributes: .concurrent)
    
    /// Cache a thumbnail for a page
    func cacheThumbnail(_ thumbnail: UIImage, forPage index: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.cache[index] = thumbnail
            
            // Clean up if cache is too large
            if self.cache.count > self.maxCacheSize {
                self.cleanupOldestThumbnails()
            }
        }
    }
    
    /// Get cached thumbnail for a page
    func getThumbnail(forPage index: Int) -> UIImage? {
        return queue.sync {
            return cache[index]
        }
    }
    
    /// Clear all cached thumbnails
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
    
    /// Clean up thumbnails for pages far from current position
    func cleanupDistantThumbnails(currentPage: Int, threshold: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let keysToRemove = self.cache.keys.filter { pageIndex in
                abs(pageIndex - currentPage) > threshold
            }
            
            for key in keysToRemove {
                self.cache.removeValue(forKey: key)
            }
        }
    }
    
    /// Clean up oldest thumbnails when cache is full
    private func cleanupOldestThumbnails() {
        let targetSize = maxCacheSize * 3 / 4 // Keep 75% of max size
        let removeCount = cache.count - targetSize
        
        if removeCount > 0 {
            let keysToRemove = Array(cache.keys.prefix(removeCount))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    /// Get cache size
    func getCacheSize() -> Int {
        return queue.sync {
            return cache.count
        }
    }
}

// MARK: - Reader Errors

enum ReaderError: Error {
    case invalidUrl
    case failedToLoad
    case fileNotFound
    case unsupportedFormat
    
    var localizedDescription: String {
        switch self {
        case .invalidUrl:
            return "Invalid file URL"
        case .failedToLoad:
            return "Failed to load document"
        case .fileNotFound:
            return "File not found"
        case .unsupportedFormat:
            return "Unsupported file format"
        }
    }
}
