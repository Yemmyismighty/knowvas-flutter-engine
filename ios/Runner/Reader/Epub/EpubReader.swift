import Foundation
import Flutter
import WebKit

/// EPUB reader implementation with memory optimization and lazy loading
class EpubReader {
    private let eventSink: FlutterEventSink?
    private let sessionId: String
    
    // Placeholder properties - will be replaced with Readium components
    private var isOpen: Bool = false
    private var currentPage: Int = 0
    private var totalPages: Int = 0
    
    // Settings management
    private var settings: EpubSettings
    
    // WebView for rendering (placeholder until Readium is integrated)
    private weak var webView: WKWebView?
    
    // Audio player for media overlays
    private var audioPlayer: EpubAudioPlayer?
    
    // Memory management
    private let memoryManager = MemoryManager.shared
    private let chapterCache: EpubChapterCache
    
    // Chapter management
    private var chapters: [EpubChapter] = []
    private var currentChapterIndex: Int = 0
    private var fileUrl: String?
    
    // Loading state
    private var isLoading: Bool = false
    private var loadStartTime: Date?
    
    // MARK: - Types
    
    struct EpubChapter {
        let index: Int
        let title: String
        let href: String
        var isLoaded: Bool = false
    }
    
    init(eventSink: FlutterEventSink?, sessionId: String) {
        self.eventSink = eventSink
        self.sessionId = sessionId
        self.settings = EpubSettings()
        self.audioPlayer = EpubAudioPlayer(eventSink: eventSink, sessionId: sessionId)
        self.chapterCache = EpubChapterCache(maxCachedChapters: 5)
        
        // Start memory monitoring
        memoryManager.startMonitoring(interval: 2.0)
        
        // Register for memory pressure notifications
        memoryManager.registerMemoryPressureCallback { [weak self] level in
            self?.handleMemoryPressure(level: level)
        }
    }
    
    deinit {
        memoryManager.stopMonitoring()
        memoryManager.clearCallbacks()
    }
    
    /// Open an EPUB file with lazy loading and memory optimization
    func open(fileUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isLoading else {
            completion(.failure(NSError(domain: "EpubReader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Already loading"])))
            return
        }
        
        isLoading = true
        loadStartTime = Date()
        self.fileUrl = fileUrl
        
        // Log memory status before opening
        memoryManager.logMemoryStatus()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Parse EPUB structure (lazy - don't load content yet)
                try self.parseEpubStructure(fileUrl: fileUrl)
                
                // Load only the first chapter initially
                try self.loadChapter(index: 0)
                
                // Mark as open
                self.isOpen = true
                
                // Calculate load time
                let loadTime = Date().timeIntervalSince(self.loadStartTime ?? Date())
                print("EpubReader: Opened in \(String(format: "%.2f", loadTime))s")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.emitReaderReadyEvent()
                    
                    // Apply initial settings if WebView is available
                    if let webView = self.webView {
                        self.applySettingsToWebView(webView)
                    }
                    
                    // Preload adjacent chapters asynchronously
                    Task {
                        await self.preloadAdjacentChapters()
                    }
                    
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("EpubReader: Failed to open - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Parse EPUB structure without loading content
    private func parseEpubStructure(fileUrl: String) throws {
        // TODO: Implement actual EPUB parsing with Readium
        // For now, create placeholder chapters
        
        chapters = (0..<20).map { index in
            EpubChapter(
                index: index,
                title: "Chapter \(index + 1)",
                href: "chapter\(index).xhtml",
                isLoaded: false
            )
        }
        
        totalPages = chapters.count
        
        print("EpubReader: Parsed \(chapters.count) chapters")
    }
    
    /// Load a specific chapter
    private func loadChapter(index: Int) throws {
        guard index >= 0 && index < chapters.count else {
            throw NSError(domain: "EpubReader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid chapter index"])
        }
        
        // Check if already cached
        if chapterCache.isCached(index: index) {
            print("EpubReader: Chapter \(index) already cached")
            return
        }
        
        // Check memory pressure before loading
        if memoryManager.isMemoryPressureHigh() {
            print("EpubReader: High memory pressure - unloading off-screen chapters")
            chapterCache.unloadOffScreenChapters(keepCount: 2)
        }
        
        // TODO: Load actual chapter content from EPUB
        // For now, create placeholder content
        let content = generatePlaceholderContent(for: index)
        
        // Cache the chapter
        chapterCache.cacheChapter(index: index, content: content)
        
        // Mark as loaded
        if index < chapters.count {
            chapters[index].isLoaded = true
        }
        
        print("EpubReader: Loaded chapter \(index)")
    }
    
    /// Generate placeholder content for testing
    private func generatePlaceholderContent(for index: Int) -> String {
        return """
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body>
            <h1>Chapter \(index + 1)</h1>
            <p>This is placeholder content for chapter \(index + 1).</p>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit...</p>
        </body>
        </html>
        """
    }
    
    /// Preload adjacent chapters for smooth navigation
    private func preloadAdjacentChapters() async {
        await chapterCache.preloadAdjacentChapters(
            currentIndex: currentChapterIndex,
            totalChapters: chapters.count
        ) { [weak self] index in
            guard let self = self else {
                throw NSError(domain: "EpubReader", code: -3, userInfo: [NSLocalizedDescriptionKey: "Reader deallocated"])
            }
            
            // Load chapter content
            return self.generatePlaceholderContent(for: index)
        }
    }
    
    /// Handle memory pressure events
    private func handleMemoryPressure(level: MemoryManager.MemoryPressureLevel) {
        print("EpubReader: Memory pressure level - \(level)")
        
        switch level {
        case .normal:
            break
            
        case .moderate:
            // Unload chapters except current and adjacent
            chapterCache.unloadOffScreenChapters(keepCount: 3)
            
        case .critical:
            // Unload all except current chapter
            chapterCache.unloadOffScreenChapters(keepCount: 1)
            
            // Clear WebView cache
            clearWebViewCache()
        }
        
        // Log status after cleanup
        chapterCache.logCacheStatus()
        memoryManager.logMemoryStatus()
    }
    
    /// Clear WebView cache to free memory
    private func clearWebViewCache() {
        guard let webView = webView else { return }
        
        let dataStore = webView.configuration.websiteDataStore
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            print("EpubReader: Cleared WebView cache")
        }
    }
    
    /// Open an EPUB file with initial preferences
    func open(fileUrl: String, preferences: ReaderPreferences?, completion: @escaping (Result<Void, Error>) -> Void) {
        // Update settings before opening if preferences provided
        if let prefs = preferences {
            settings.updatePreferences(prefs)
        }
        
        open(fileUrl: fileUrl, completion: completion)
    }
    
    /// Close the EPUB reader
    func close() {
        if isOpen {
            emitSessionEndEvent()
            audioPlayer?.cleanup()
            
            // Clear chapter cache
            chapterCache.clearAll()
            
            // Clear WebView cache
            clearWebViewCache()
            
            // Reset state
            isOpen = false
            currentPage = 0
            totalPages = 0
            chapters.removeAll()
            currentChapterIndex = 0
            fileUrl = nil
            
            print("EpubReader: Closed and cleaned up")
        }
    }
    
    /// Set reader preferences
    func setPreferences(_ preferences: [String: Any]) {
        let readerPrefs = ReaderPreferences(from: preferences)
        let hasChanges = settings.updatePreferences(readerPrefs)
        
        if hasChanges {
            print("EPUB Reader: Updated settings - \(settings.description)")
            applySettingsToReader()
        } else {
            print("EPUB Reader: No changes to settings")
        }
    }
    
    /// Set reader preferences from ReaderPreferences object
    func setPreferences(_ preferences: ReaderPreferences) {
        let hasChanges = settings.updatePreferences(preferences)
        
        if hasChanges {
            print("EPUB Reader: Updated settings - \(settings.description)")
            applySettingsToReader()
        }
    }
    
    /// Get current settings
    func getSettings() -> EpubSettings {
        return settings
    }
    
    /// Apply current settings to the reader
    private func applySettingsToReader() {
        guard isOpen else {
            print("EPUB Reader: Cannot apply settings - reader is not open")
            return
        }
        
        // Apply settings to WebView if available
        if let webView = webView {
            applySettingsToWebView(webView)
        }
        
        // TODO: When Readium is integrated, apply settings to Readium navigator
        // For now, we'll use WebKit-based rendering with CSS injection
    }
    
    /// Apply settings to WebKit WebView
    private func applySettingsToWebView(_ webView: WKWebView) {
        let cssInjectionScript = settings.generateCSSInjectionScript()
        
        webView.evaluateJavaScript(cssInjectionScript) { result, error in
            if let error = error {
                print("EPUB Reader: Error applying settings - \(error.localizedDescription)")
            } else {
                print("EPUB Reader: Settings applied successfully")
            }
        }
        
        // Update WebView background color
        webView.backgroundColor = settings.theme.backgroundColor
        webView.isOpaque = true
    }
    
    /// Set WebView reference for settings application
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
        
        // Apply current settings immediately
        if isOpen {
            applySettingsToWebView(webView)
        }
    }
    
    /// Navigate to a specific page/chapter
    func goToPage(_ pageIndex: Int) {
        guard isOpen, pageIndex >= 0, pageIndex < totalPages else { return }
        
        currentPage = pageIndex
        currentChapterIndex = pageIndex // In this implementation, page = chapter
        
        // Load chapter if not already loaded
        if !chapterCache.isCached(index: pageIndex) {
            do {
                try loadChapter(index: pageIndex)
            } catch {
                print("EpubReader: Failed to load chapter \(pageIndex) - \(error)")
                emitError(code: "CHAPTER_LOAD_FAILED", message: error.localizedDescription)
                return
            }
        }
        
        // Preload adjacent chapters
        Task {
            await preloadAdjacentChapters()
        }
        
        emitPageTurnEvent(pageIndex: pageIndex)
        
        // Log cache status
        chapterCache.logCacheStatus()
    }
    
    /// Get current chapter content
    func getCurrentChapterContent() -> String? {
        return chapterCache.getChapter(index: currentChapterIndex)
    }
    
    /// Get chapter content by index
    func getChapterContent(index: Int) -> String? {
        // Load if not cached
        if !chapterCache.isCached(index: index) {
            do {
                try loadChapter(index: index)
            } catch {
                print("EpubReader: Failed to load chapter \(index) - \(error)")
                return nil
            }
        }
        
        return chapterCache.getChapter(index: index)
    }
    
    // MARK: - Audio Playback Methods
    
    /// Load audio file for media overlay
    /// - Parameters:
    ///   - audioUrl: URL to the audio file
    ///   - syncData: Optional text synchronization data
    func loadAudio(from audioUrl: URL, syncData: [TextSyncPoint]? = nil) {
        guard isOpen else {
            print("EPUB Reader: Cannot load audio - reader is not open")
            return
        }
        
        do {
            try audioPlayer?.loadAudio(from: audioUrl, syncData: syncData)
        } catch {
            print("EPUB Reader: Failed to load audio - \(error.localizedDescription)")
            emitError(code: "AUDIO_LOAD_FAILED", message: error.localizedDescription)
        }
    }
    
    /// Play audio
    func playAudio() {
        audioPlayer?.play()
    }
    
    /// Pause audio
    func pauseAudio() {
        audioPlayer?.pause()
    }
    
    /// Stop audio
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    /// Seek audio to specific time
    /// - Parameter time: Time in seconds
    func seekAudio(to time: TimeInterval) {
        audioPlayer?.seek(to: time)
    }
    
    /// Set audio playback rate
    /// - Parameter rate: Playback rate (0.5 to 2.0)
    func setAudioRate(_ rate: Float) {
        audioPlayer?.setRate(rate)
    }
    
    /// Set audio volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setAudioVolume(_ volume: Float) {
        audioPlayer?.setVolume(volume)
    }
    
    /// Get current audio playback time
    /// - Returns: Current time in seconds
    func getAudioCurrentTime() -> TimeInterval {
        return audioPlayer?.getCurrentTime() ?? 0
    }
    
    /// Get audio duration
    /// - Returns: Duration in seconds
    func getAudioDuration() -> TimeInterval {
        return audioPlayer?.getDuration() ?? 0
    }
    
    /// Check if audio is currently playing
    /// - Returns: True if audio is playing
    func isAudioPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    // MARK: - Event Emission
    
    private func emitReaderReadyEvent() {
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
            "final_page": currentPage,
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
    
    func emitBookmarkEvent(pageNumber: Int, added: Bool) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "bookmark",
            "page_number": pageNumber,
            "action": added ? "add" : "remove",
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    func emitHighlightEvent(pageNumber: Int, text: String, color: String) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "highlight",
            "page_number": pageNumber,
            "highlighted_text": text,
            "color": color,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    func emitNoteEvent(pageNumber: Int, text: String, note: String) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "note",
            "page_number": pageNumber,
            "selected_text": text,
            "note_text": note,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
}
