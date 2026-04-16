import Foundation
import Flutter

/// Manages reader instances and coordinates between different reader types
class ReaderManager {
    private var activeReaders: [String: Any] = [:]
    
    /// Open a reader based on content type
    func openReader(args: [String: Any], eventSink: FlutterEventSink?, completion: @escaping (Any) -> Void) {
        guard let contentId = args["content_id"] as? Int,
              let type = args["type"] as? String,
              let fileUrl = args["file_url"] as? String,
              let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing required arguments"))
            return
        }
        
        let token = args["token"] as? String
        
        // Create appropriate reader based on type
        switch type.lowercased() {
        case "epub":
            openEpubReader(
                contentId: contentId,
                fileUrl: fileUrl,
                token: token,
                sessionId: sessionId,
                eventSink: eventSink,
                completion: completion
            )
            
        case "pdf":
            openPdfReader(
                contentId: contentId,
                fileUrl: fileUrl,
                token: token,
                sessionId: sessionId,
                eventSink: eventSink,
                completion: completion
            )
            
        case "comic":
            openComicReader(
                contentId: contentId,
                fileUrl: fileUrl,
                token: token,
                sessionId: sessionId,
                eventSink: eventSink,
                completion: completion
            )
            
        default:
            completion(createErrorResponse(
                code: "UNSUPPORTED_TYPE",
                message: "Unsupported content type: \(type)"
            ))
        }
    }
    
    /// Close a reader by session ID
    func closeReader(sessionId: String, completion: @escaping (Any) -> Void) {
        guard let reader = activeReaders[sessionId] else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No active reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Close the appropriate reader
        if let epubReader = reader as? EpubReader {
            epubReader.close()
        } else if let pdfReader = reader as? PdfReader {
            pdfReader.close()
        } else if let comicReader = reader as? ComicReader {
            comicReader.close()
        }
        
        activeReaders.removeValue(forKey: sessionId)
        completion(createSuccessResponse())
    }
    
    /// Set reader preferences
    func setPreferences(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let reader = activeReaders[sessionId] else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No active reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Apply preferences to the appropriate reader
        if let epubReader = reader as? EpubReader {
            epubReader.setPreferences(args)
        } else if let pdfReader = reader as? PdfReader {
            pdfReader.setPreferences(args)
        } else if let comicReader = reader as? ComicReader {
            comicReader.setPreferences(args)
        }
        
        completion(createSuccessResponse())
    }
    
    // MARK: - Bookmark Methods
    
    /// Add a bookmark at the current page
    func addBookmark(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let pageIndex = args["page_index"] as? Int else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing page_index"))
            return
        }
        
        guard let reader = activeReaders[sessionId] else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No active reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Add bookmark to the appropriate reader
        if let pdfReader = reader as? PdfReader {
            pdfReader.addBookmark(at: pageIndex)
            completion(createSuccessResponse())
        } else {
            completion(createErrorResponse(
                code: "UNSUPPORTED_OPERATION",
                message: "Bookmark operation not supported for this reader type"
            ))
        }
    }
    
    /// Remove a bookmark at the specified page
    func removeBookmark(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let pageIndex = args["page_index"] as? Int else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing page_index"))
            return
        }
        
        guard let reader = activeReaders[sessionId] else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No active reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Remove bookmark from the appropriate reader
        if let pdfReader = reader as? PdfReader {
            pdfReader.removeBookmark(at: pageIndex)
            completion(createSuccessResponse())
        } else {
            completion(createErrorResponse(
                code: "UNSUPPORTED_OPERATION",
                message: "Bookmark operation not supported for this reader type"
            ))
        }
    }
    
    /// Get all bookmarks for the current reader
    func getBookmarks(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let reader = activeReaders[sessionId] else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No active reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Get bookmarks from the appropriate reader
        if let pdfReader = reader as? PdfReader {
            var response = createSuccessResponse()
            response["bookmarks"] = pdfReader.getBookmarks()
            completion(response)
        } else {
            completion(createErrorResponse(
                code: "UNSUPPORTED_OPERATION",
                message: "Bookmark operation not supported for this reader type"
            ))
        }
    }
    
    // MARK: - Audio Playback Methods
    
    /// Control audio playback for EPUB readers
    func controlAudio(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let action = args["action"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing action"))
            return
        }
        
        guard let reader = activeReaders[sessionId] as? EpubReader else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No EPUB reader found for session: \(sessionId)"
            ))
            return
        }
        
        switch action {
        case "play":
            reader.playAudio()
            completion(createSuccessResponse())
            
        case "pause":
            reader.pauseAudio()
            completion(createSuccessResponse())
            
        case "stop":
            reader.stopAudio()
            completion(createSuccessResponse())
            
        case "seek":
            guard let time = args["time"] as? Double else {
                completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing time parameter"))
                return
            }
            reader.seekAudio(to: time)
            completion(createSuccessResponse())
            
        case "setRate":
            guard let rate = args["rate"] as? Float else {
                completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing rate parameter"))
                return
            }
            reader.setAudioRate(rate)
            completion(createSuccessResponse())
            
        case "setVolume":
            guard let volume = args["volume"] as? Float else {
                completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing volume parameter"))
                return
            }
            reader.setAudioVolume(volume)
            completion(createSuccessResponse())
            
        case "getStatus":
            let status: [String: Any] = [
                "is_playing": reader.isAudioPlaying(),
                "current_time": reader.getAudioCurrentTime(),
                "duration": reader.getAudioDuration()
            ]
            var response = createSuccessResponse()
            response["status_data"] = status
            completion(response)
            
        default:
            completion(createErrorResponse(
                code: "INVALID_ACTION",
                message: "Unknown audio action: \(action)"
            ))
        }
    }
    
    /// Load audio file for EPUB reader
    func loadAudio(args: [String: Any], completion: @escaping (Any) -> Void) {
        guard let sessionId = args["session_id"] as? String else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Missing session_id"))
            return
        }
        
        guard let audioUrlString = args["audio_url"] as? String,
              let audioUrl = URL(string: audioUrlString) else {
            completion(createErrorResponse(code: "INVALID_ARGS", message: "Invalid audio_url"))
            return
        }
        
        guard let reader = activeReaders[sessionId] as? EpubReader else {
            completion(createErrorResponse(
                code: "READER_NOT_FOUND",
                message: "No EPUB reader found for session: \(sessionId)"
            ))
            return
        }
        
        // Parse sync data if provided
        var syncData: [TextSyncPoint]? = nil
        if let syncArray = args["sync_data"] as? [[String: Any]] {
            syncData = syncArray.compactMap { dict in
                guard let timestamp = dict["timestamp"] as? Double,
                      let textId = dict["text_id"] as? String else {
                    return nil
                }
                let textContent = dict["text_content"] as? String
                return TextSyncPoint(timestamp: timestamp, textId: textId, textContent: textContent)
            }
        }
        
        reader.loadAudio(from: audioUrl, syncData: syncData)
        completion(createSuccessResponse())
    }
    
    // MARK: - Private Methods
    
    private func openEpubReader(
        contentId: Int,
        fileUrl: String,
        token: String?,
        sessionId: String,
        eventSink: FlutterEventSink?,
        completion: @escaping (Any) -> Void
    ) {
        let reader = EpubReader(eventSink: eventSink, sessionId: sessionId)
        activeReaders[sessionId] = reader
        
        reader.open(fileUrl: fileUrl) { result in
            switch result {
            case .success:
                completion(self.createSuccessResponse())
            case .failure(let error):
                completion(self.createErrorResponse(
                    code: "EPUB_OPEN_FAILED",
                    message: error.localizedDescription
                ))
            }
        }
    }
    
    private func openPdfReader(
        contentId: Int,
        fileUrl: String,
        token: String?,
        sessionId: String,
        eventSink: FlutterEventSink?,
        completion: @escaping (Any) -> Void
    ) {
        let reader = PdfReader(eventSink: eventSink, sessionId: sessionId)
        activeReaders[sessionId] = reader
        
        reader.open(fileUrl: fileUrl) { result in
            switch result {
            case .success:
                completion(self.createSuccessResponse())
            case .failure(let error):
                completion(self.createErrorResponse(
                    code: "PDF_OPEN_FAILED",
                    message: error.localizedDescription
                ))
            }
        }
    }
    
    private func openComicReader(
        contentId: Int,
        fileUrl: String,
        token: String?,
        sessionId: String,
        eventSink: FlutterEventSink?,
        completion: @escaping (Any) -> Void
    ) {
        let reader = ComicReader(eventSink: eventSink, sessionId: sessionId)
        activeReaders[sessionId] = reader
        
        reader.open(fileUrl: fileUrl) { result in
            switch result {
            case .success:
                completion(self.createSuccessResponse())
            case .failure(let error):
                completion(self.createErrorResponse(
                    code: "COMIC_OPEN_FAILED",
                    message: error.localizedDescription
                ))
            }
        }
    }
    
    // MARK: - Response Helpers
    
    private func createSuccessResponse() -> [String: Any] {
        return ["status": "ok"]
    }
    
    private func createErrorResponse(code: String, message: String) -> [String: Any] {
        return [
            "status": "error",
            "error_code": code,
            "error_message": message
        ]
    }
}
