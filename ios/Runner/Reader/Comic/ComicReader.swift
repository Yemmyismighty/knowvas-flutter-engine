import Foundation
import Flutter
import UIKit
import ZIPFoundation

/// Comic reader implementation for image-based content (CBZ, CBR, image sequences)
/// Requirements: 7.1, 7.2, 7.3, 7.4
class ComicReader {
    private let eventSink: FlutterEventSink?
    private let sessionId: String
    
    // Comic properties
    private var imageExtractor: ImageExtractor?
    private var imageCache: ComicImageCache?
    private var currentPageIndex: Int = 0
    private var totalPages: Int = 0
    private var isOpen: Bool = false
    
    // Reader preferences
    private var preferences = ComicReaderPreferences()
    
    // Page view controller for UI presentation
    private var pageViewController: UIPageViewController?
    
    init(eventSink: FlutterEventSink?, sessionId: String) {
        self.eventSink = eventSink
        self.sessionId = sessionId
        
        // Register for memory pressure notifications
        MemoryManager.shared.registerMemoryPressureCallback { [weak self] level in
            self?.handleMemoryPressure(level: level)
        }
    }
    
    deinit {
        close()
    }
    
    /// Open a comic file (CBZ, CBR, or image sequence)
    /// Requirements: 7.1, 7.2
    func open(fileUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
            
            // Determine archive type and create appropriate extractor
            let extractor: ImageExtractor
            let fileExtension = validUrl.pathExtension.lowercased()
            
            switch fileExtension {
            case "cbz", "zip":
                extractor = ZipImageExtractor(url: validUrl)
            case "cbr", "rar":
                // For CBR, we'll use a basic implementation
                // In production, you'd use a RAR library
                extractor = RarImageExtractor(url: validUrl)
            default:
                DispatchQueue.main.async {
                    completion(.failure(ReaderError.unsupportedFormat))
                }
                return
            }
            
            // Initialize extractor and get page count
            do {
                let pageCount = try extractor.initialize()
                
                if pageCount == 0 {
                    DispatchQueue.main.async {
                        completion(.failure(ReaderError.failedToLoad))
                    }
                    return
                }
                
                self.imageExtractor = extractor
                self.totalPages = pageCount
                self.currentPageIndex = 0
                self.isOpen = true
                
                // Initialize image cache with the extractor
                // Requirement 7.10 - Lazy loading and caching
                self.imageCache = ComicImageCache(extractor: extractor, maxCacheSize: 10)
                
                // Start pre-loading first few pages
                self.imageCache?.preloadPages(around: 0, range: 3)
                
                // Start memory monitoring
                MemoryManager.shared.startMonitoring()
                
                DispatchQueue.main.async {
                    // Emit reader ready event with total page count
                    // Requirement 7.2
                    self.emitReaderReadyEvent(totalPages: pageCount)
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Close the comic reader
    /// Requirement 7.12
    func close() {
        if isOpen {
            emitSessionEndEvent()
            
            // Clean up image cache
            imageCache?.clearCache()
            imageCache = nil
            
            // Clean up extractor
            imageExtractor?.close()
            imageExtractor = nil
            
            // Stop memory monitoring
            MemoryManager.shared.stopMonitoring()
            
            isOpen = false
            totalPages = 0
            currentPageIndex = 0
            
            print("Comic Reader: Closed session \(sessionId)")
        }
    }
    
    /// Set reader preferences
    /// Requirements: 7.4, 7.8, 7.9
    func setPreferences(_ prefs: [String: Any]) {
        // Extract and apply preferences
        if let layout = prefs["layout"] as? String {
            preferences.layout = ComicReaderPreferences.Layout(rawValue: layout) ?? .single
        }
        
        if let readingDirection = prefs["reading_direction"] as? String {
            preferences.readingDirection = ComicReaderPreferences.ReadingDirection(rawValue: readingDirection) ?? .ltr
        }
        
        if let guidedView = prefs["guided_view"] as? Bool {
            preferences.guidedViewEnabled = guidedView
        }
        
        print("Comic Reader: Applied preferences - layout: \(preferences.layout.rawValue), direction: \(preferences.readingDirection.rawValue), guided: \(preferences.guidedViewEnabled)")
    }
    
    /// Get current preferences
    func getPreferences() -> ComicReaderPreferences {
        return preferences
    }

    /// Navigate to a specific page
    /// Requirements: 7.3 - Swipe gesture navigation
    func goToPage(_ pageIndex: Int) {
        guard isOpen, pageIndex >= 0, pageIndex < totalPages else { return }
        
        let previousPage = currentPageIndex
        currentPageIndex = pageIndex
        
        // Pre-load pages around the new current page
        // Requirement 7.10 - Pre-load next 2-3 pages for smooth navigation
        imageCache?.preloadPages(around: pageIndex, range: 3)
        
        // Clear cache for pages far from current position to save memory
        // Requirement 14.6 - Monitor memory usage and trigger cleanup
        if MemoryManager.shared.isMemoryPressureHigh() {
            imageCache?.clearCacheExcept(pageIndex: pageIndex, keepRange: 3)
        }
        
        // Emit page turn event
        emitPageTurnEvent(pageIndex: pageIndex, previousPage: previousPage)
    }
    
    /// Get the current page image(s)
    /// Returns single image for single-page layout, or two images for double-page layout
    /// Requirements: 7.4, 7.8
    func getCurrentPageImages() -> [UIImage?] {
        guard isOpen else { return [] }
        
        switch preferences.layout {
        case .double:
            // Return two pages for double-page spread
            let firstPage = imageCache?.getPage(at: currentPageIndex, thumbnail: false)
            let secondPage = (currentPageIndex + 1 < totalPages) ?
                imageCache?.getPage(at: currentPageIndex + 1, thumbnail: false) : nil
            
            // Order pages based on reading direction
            if preferences.readingDirection == .rtl {
                // RTL: right page first, then left page
                return [secondPage, firstPage]
            } else {
                // LTR: left page first, then right page
                return [firstPage, secondPage]
            }
            
        case .single:
            // Return single page
            return [imageCache?.getPage(at: currentPageIndex, thumbnail: false)]
        }
    }
    
    /// Get thumbnail for a specific page
    /// Requirement 14.5 - Image downsampling for thumbnails
    func getPageThumbnail(at pageIndex: Int) -> UIImage? {
        guard isOpen, pageIndex >= 0, pageIndex < totalPages else { return nil }
        return imageCache?.getPage(at: pageIndex, thumbnail: true)
    }
    
    /// Get total page count
    func getTotalPages() -> Int {
        return totalPages
    }
    
    /// Get current page index
    func getCurrentPageIndex() -> Int {
        return currentPageIndex
    }
    
    /// Navigate to next page
    func nextPage() {
        let nextIndex = currentPageIndex + 1
        if nextIndex < totalPages {
            goToPage(nextIndex)
        }
    }
    
    /// Navigate to previous page
    func previousPage() {
        let prevIndex = currentPageIndex - 1
        if prevIndex >= 0 {
            goToPage(prevIndex)
        }
    }
    
    /// Create UIPageViewController for UI presentation
    /// Requirement 7.3 - UIPageViewController for page viewing with swipe navigation
    func createPageViewController() -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        self.pageViewController = pageVC
        return pageVC
    }
    
    /// Get the page view controller
    func getPageViewController() -> UIPageViewController? {
        return pageViewController
    }
    
    // MARK: - Memory Management
    
    /// Handle memory pressure events
    /// Requirement 14.6 - Monitor memory usage and trigger cleanup
    private func handleMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        switch level {
        case .moderate:
            print("Comic Reader: Moderate memory pressure - clearing distant pages")
            imageCache?.clearCacheExcept(pageIndex: currentPageIndex, keepRange: 3)
            
        case .critical:
            print("Comic Reader: Critical memory pressure - aggressive cleanup")
            imageCache?.clearCacheExcept(pageIndex: currentPageIndex, keepRange: 1)
            MemoryManager.shared.logMemoryStatus()
            
        case .normal:
            break
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
    
    private func emitPageTurnEvent(pageIndex: Int, previousPage: Int) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "page_turn",
            "page_index": pageIndex,
            "previous_page": previousPage,
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
            "page_index": currentPageIndex,
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
}

// MARK: - Comic Reader Preferences

/// Preferences for comic reader
/// Requirements: 7.4, 7.8, 7.9
struct ComicReaderPreferences {
    enum Layout: String {
        case single = "single"
        case double = "double"
    }
    
    enum ReadingDirection: String {
        case ltr = "ltr"  // Left-to-right
        case rtl = "rtl"  // Right-to-left
    }
    
    var layout: Layout = .single
    var readingDirection: ReadingDirection = .ltr
    var guidedViewEnabled: Bool = false
}


// MARK: - Image Extractor Protocol

/// Base protocol for image extraction from comic archives
/// Requirement 7.1
protocol ImageExtractor {
    func initialize() throws -> Int
    func getPage(at index: Int) -> UIImage?
    func getPageData(at index: Int) -> Data?
    func close()
}

// MARK: - ZIP/CBZ Image Extractor

/// ZIP/CBZ image extractor using ZIPFoundation
/// Requirement 7.1
class ZipImageExtractor: ImageExtractor {
    private let url: URL
    private var archive: Archive?
    private var imageEntries: [Entry] = []
    
    init(url: URL) {
        self.url = url
    }
    
    func initialize() throws -> Int {
        // Open the ZIP archive
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ReaderError.failedToLoad
        }
        
        self.archive = archive
        
        // Get all image entries sorted by name
        imageEntries = archive.filter { entry in
            !entry.type.isDirectory && isImageFile(entry.path)
        }.sorted { $0.path < $1.path }
        
        return imageEntries.count
    }
    
    func getPage(at index: Int) -> UIImage? {
        guard let data = getPageData(at: index) else { return nil }
        return UIImage(data: data)
    }
    
    func getPageData(at index: Int) -> Data? {
        guard index >= 0, index < imageEntries.count else { return nil }
        guard let archive = archive else { return nil }
        
        let entry = imageEntries[index]
        var data = Data()
        
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
            return data
        } catch {
            print("Comic Reader: Failed to extract page \(index): \(error)")
            return nil
        }
    }
    
    func close() {
        archive = nil
        imageEntries.removeAll()
    }
    
    private func isImageFile(_ filename: String) -> Bool {
        let extension = (filename as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(extension)
    }
}

// MARK: - RAR/CBR Image Extractor

/// RAR/CBR image extractor
/// Basic implementation - in production, use a RAR library
/// Requirement 7.1
class RarImageExtractor: ImageExtractor {
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func initialize() throws -> Int {
        // TODO: Implement RAR extraction using a RAR library
        // For now, return 0 to indicate unsupported
        print("Comic Reader: RAR/CBR format not yet supported")
        throw ReaderError.unsupportedFormat
    }
    
    func getPage(at index: Int) -> UIImage? {
        return nil
    }
    
    func getPageData(at index: Int) -> Data? {
        return nil
    }
    
    func close() {
        // No-op
    }
}


// MARK: - Comic Image Cache

/// Cache for comic page images with lazy loading
/// Requirements: 7.10, 14.5, 14.6
class ComicImageCache {
    private let extractor: ImageExtractor
    private let maxCacheSize: Int
    private var cache: [Int: UIImage] = [:]
    private let queue = DispatchQueue(label: "com.knowvas.comic.imageCache", attributes: .concurrent)
    
    init(extractor: ImageExtractor, maxCacheSize: Int = 10) {
        self.extractor = extractor
        self.maxCacheSize = maxCacheSize
    }
    
    /// Get a page image (from cache or load)
    /// Requirement 7.10 - Lazy loading with caching
    func getPage(at index: Int, thumbnail: Bool) -> UIImage? {
        // Check cache first
        if let cachedImage = getCachedImage(at: index) {
            return thumbnail ? downsampleImage(cachedImage) : cachedImage
        }
        
        // Load from extractor
        guard let image = extractor.getPage(at: index) else { return nil }
        
        // Cache the full-size image
        cacheImage(image, at: index)
        
        // Return thumbnail or full image
        return thumbnail ? downsampleImage(image) : image
    }
    
    /// Preload pages around a specific index
    /// Requirement 7.10 - Pre-load next 2-3 pages for smooth navigation
    func preloadPages(around index: Int, range: Int) {
        let startIndex = max(0, index - range)
        let endIndex = index + range
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            for i in startIndex...endIndex {
                // Skip if already cached
                if self.getCachedImage(at: i) != nil { continue }
                
                // Load and cache
                if let image = self.extractor.getPage(at: i) {
                    self.cacheImage(image, at: i)
                }
            }
        }
    }
    
    /// Clear cache except for pages near the specified index
    /// Requirement 14.6 - Memory management
    func clearCacheExcept(pageIndex: Int, keepRange: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let keysToRemove = self.cache.keys.filter { cachedIndex in
                abs(cachedIndex - pageIndex) > keepRange
            }
            
            for key in keysToRemove {
                self.cache.removeValue(forKey: key)
            }
            
            print("Comic Cache: Cleared \(keysToRemove.count) pages, keeping \(self.cache.count)")
        }
    }
    
    /// Clear all cached images
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
    
    /// Get cached image
    private func getCachedImage(at index: Int) -> UIImage? {
        return queue.sync {
            return cache[index]
        }
    }
    
    /// Cache an image
    private func cacheImage(_ image: UIImage, at index: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.cache[index] = image
            
            // Clean up if cache is too large
            if self.cache.count > self.maxCacheSize {
                self.cleanupOldestImages()
            }
        }
    }
    
    /// Clean up oldest images when cache is full
    private func cleanupOldestImages() {
        let targetSize = maxCacheSize * 3 / 4 // Keep 75% of max size
        let removeCount = cache.count - targetSize
        
        if removeCount > 0 {
            let keysToRemove = Array(cache.keys.prefix(removeCount))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    /// Downsample image for thumbnail
    /// Requirement 14.5 - Image downsampling for thumbnails
    private func downsampleImage(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 200, height: 300)
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> [String: Any] {
        return queue.sync {
            return [
                "cached_pages": cache.count,
                "max_cache_size": maxCacheSize
            ]
        }
    }
}

// MARK: - Entry Type Extension

extension Entry.EntryType {
    var isDirectory: Bool {
        return self == .directory
    }
}
