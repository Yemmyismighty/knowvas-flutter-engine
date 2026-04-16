import Foundation

// MARK: - Reader Request Models

struct OpenReaderRequest {
    let contentId: Int
    let type: String
    let fileUrl: String
    let token: String?
    let sessionId: String
    
    init?(from args: [String: Any]) {
        guard let contentId = args["content_id"] as? Int,
              let type = args["type"] as? String,
              let fileUrl = args["file_url"] as? String,
              let sessionId = args["session_id"] as? String else {
            return nil
        }
        
        self.contentId = contentId
        self.type = type
        self.fileUrl = fileUrl
        self.token = args["token"] as? String
        self.sessionId = sessionId
    }
}

// MARK: - Reader Preferences

struct ReaderPreferences {
    let fontSize: Int?
    let fontFamily: String?
    let theme: String?
    let lineHeight: Double?
    let margin: Double?
    let layout: String?
    let readingDirection: String?
    let pageTransition: String?
    
    init(from args: [String: Any]) {
        self.fontSize = args["font_size"] as? Int
        self.fontFamily = args["font_family"] as? String
        self.theme = args["theme"] as? String
        self.lineHeight = args["line_height"] as? Double
        self.margin = args["margin"] as? Double
        self.layout = args["layout"] as? String
        self.readingDirection = args["reading_direction"] as? String
        self.pageTransition = args["page_transition"] as? String
    }
}

// MARK: - Reader Events

enum ReaderEventType: String {
    case ready = "ready"
    case engagement = "engagement"
    case error = "error"
}

enum EngagementEventType: String {
    case pageTurn = "page_turn"
    case bookmark = "bookmark"
    case highlight = "highlight"
    case sessionEnd = "session_end"
}

struct ReaderEvent {
    let type: ReaderEventType
    let sessionId: String
    let timestamp: Double
    let payload: [String: Any]
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": type.rawValue,
            "session_id": sessionId,
            "timestamp": timestamp
        ]
        
        dict.merge(payload) { (_, new) in new }
        return dict
    }
}

// MARK: - Reader Response

struct ReaderResponse {
    let status: String
    let errorCode: String?
    let errorMessage: String?
    
    static func success() -> [String: Any] {
        return ["status": "ok"]
    }
    
    static func error(code: String, message: String) -> [String: Any] {
        return [
            "status": "error",
            "error_code": code,
            "error_message": message
        ]
    }
}

// MARK: - Content Types

enum ContentType: String {
    case epub = "epub"
    case pdf = "pdf"
    case comic = "comic"
    case magazine = "magazine"
    case audiobook = "audiobook"
    
    var isSupported: Bool {
        switch self {
        case .epub, .pdf, .comic:
            return true
        case .magazine, .audiobook:
            return false // Not yet implemented
        }
    }
}
