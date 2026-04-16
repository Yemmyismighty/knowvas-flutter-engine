import Foundation
import AVFoundation

/// Audio player for EPUB media overlays
/// Handles audio playback synchronized with text highlighting
class EpubAudioPlayer: NSObject {
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession
    private let eventSink: FlutterEventSink?
    private let sessionId: String
    
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    
    // Text synchronization
    private var textSyncData: [TextSyncPoint] = []
    private var currentSyncIndex: Int = 0
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    
    init(eventSink: FlutterEventSink?, sessionId: String) {
        self.eventSink = eventSink
        self.sessionId = sessionId
        self.audioSession = AVAudioSession.sharedInstance()
        
        super.init()
        
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio)
            try audioSession.setActive(true)
        } catch {
            print("EpubAudioPlayer: Failed to setup audio session - \(error.localizedDescription)")
            emitError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load audio file from URL
    func loadAudio(from url: URL, syncData: [TextSyncPoint]? = nil) throws {
        // Stop current playback if any
        stop()
        
        // Load audio file
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            
            // Store text sync data if provided
            if let syncData = syncData {
                self.textSyncData = syncData.sorted { $0.timestamp < $1.timestamp }
            }
            
            emitAudioLoadedEvent()
            
        } catch {
            print("EpubAudioPlayer: Failed to load audio - \(error.localizedDescription)")
            throw AudioPlayerError.loadFailed(error.localizedDescription)
        }
    }
    
    /// Play audio
    func play() {
        guard let player = audioPlayer else {
            emitError(code: "NO_AUDIO_LOADED", message: "No audio file loaded")
            return
        }
        
        guard !isPlaying else { return }
        
        if player.play() {
            isPlaying = true
            startSyncTimer()
            emitPlaybackStateEvent(state: "playing")
        } else {
            emitError(code: "PLAYBACK_FAILED", message: "Failed to start playback")
        }
    }
    
    /// Pause audio
    func pause() {
        guard let player = audioPlayer, isPlaying else { return }
        
        player.pause()
        isPlaying = false
        stopSyncTimer()
        emitPlaybackStateEvent(state: "paused")
    }
    
    /// Stop audio and reset position
    func stop() {
        guard let player = audioPlayer else { return }
        
        player.stop()
        player.currentTime = 0
        isPlaying = false
        currentTime = 0
        currentSyncIndex = 0
        stopSyncTimer()
        emitPlaybackStateEvent(state: "stopped")
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let validTime = min(max(time, 0), duration)
        player.currentTime = validTime
        currentTime = validTime
        
        // Update sync index based on new time
        updateSyncIndexForTime(validTime)
        
        emitSeekEvent(time: validTime)
    }
    
    /// Get current playback time
    func getCurrentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Get audio duration
    func getDuration() -> TimeInterval {
        return duration
    }
    
    /// Set playback rate
    func setRate(_ rate: Float) {
        guard let player = audioPlayer else { return }
        
        let validRate = min(max(rate, 0.5), 2.0) // Limit between 0.5x and 2.0x
        player.enableRate = true
        player.rate = validRate
        
        emitRateChangeEvent(rate: validRate)
    }
    
    /// Set volume
    func setVolume(_ volume: Float) {
        guard let player = audioPlayer else { return }
        
        let validVolume = min(max(volume, 0.0), 1.0)
        player.volume = validVolume
    }
    
    /// Cleanup resources
    func cleanup() {
        stop()
        audioPlayer = nil
        textSyncData.removeAll()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("EpubAudioPlayer: Failed to deactivate audio session - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Text Synchronization
    
    private func startSyncTimer() {
        stopSyncTimer()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTextSync()
        }
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func updateTextSync() {
        guard let player = audioPlayer, !textSyncData.isEmpty else { return }
        
        currentTime = player.currentTime
        
        // Check if we need to highlight new text
        while currentSyncIndex < textSyncData.count {
            let syncPoint = textSyncData[currentSyncIndex]
            
            if currentTime >= syncPoint.timestamp {
                // Highlight this text
                emitTextHighlightEvent(syncPoint: syncPoint)
                currentSyncIndex += 1
            } else {
                break
            }
        }
        
        // Emit progress update
        emitProgressEvent(currentTime: currentTime, duration: duration)
    }
    
    private func updateSyncIndexForTime(_ time: TimeInterval) {
        // Find the appropriate sync index for the given time
        currentSyncIndex = 0
        
        for (index, syncPoint) in textSyncData.enumerated() {
            if time >= syncPoint.timestamp {
                currentSyncIndex = index + 1
            } else {
                break
            }
        }
    }
    
    // MARK: - Event Emission
    
    private func emitAudioLoadedEvent() {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_loaded",
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitPlaybackStateEvent(state: String) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_playback",
            "state": state,
            "current_time": currentTime,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitSeekEvent(time: TimeInterval) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_seek",
            "time": time,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitProgressEvent(currentTime: TimeInterval, duration: TimeInterval) {
        guard let eventSink = eventSink else { return }
        
        let progress = duration > 0 ? currentTime / duration : 0
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_progress",
            "current_time": currentTime,
            "duration": duration,
            "progress": progress,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitTextHighlightEvent(syncPoint: TextSyncPoint) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_text_sync",
            "text_id": syncPoint.textId,
            "text_content": syncPoint.textContent ?? "",
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitRateChangeEvent(rate: Float) {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_rate_change",
            "rate": rate,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitCompletionEvent() {
        guard let eventSink = eventSink else { return }
        
        let event: [String: Any] = [
            "type": "engagement",
            "session_id": sessionId,
            "event": "audio_completed",
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink(event)
    }
    
    private func emitError(code: String, message: String) {
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

// MARK: - AVAudioPlayerDelegate

extension EpubAudioPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopSyncTimer()
        
        if flag {
            emitCompletionEvent()
        } else {
            emitError(code: "PLAYBACK_INTERRUPTED", message: "Audio playback was interrupted")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        stopSyncTimer()
        
        let errorMessage = error?.localizedDescription ?? "Unknown decode error"
        emitError(code: "DECODE_ERROR", message: errorMessage)
    }
}

// MARK: - Supporting Types

/// Represents a point in time where text should be highlighted
struct TextSyncPoint {
    let timestamp: TimeInterval
    let textId: String
    let textContent: String?
    
    init(timestamp: TimeInterval, textId: String, textContent: String? = nil) {
        self.timestamp = timestamp
        self.textId = textId
        self.textContent = textContent
    }
}

/// Audio player errors
enum AudioPlayerError: Error {
    case loadFailed(String)
    case playbackFailed(String)
    case noAudioLoaded
    
    var localizedDescription: String {
        switch self {
        case .loadFailed(let message):
            return "Failed to load audio: \(message)"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        case .noAudioLoaded:
            return "No audio file loaded"
        }
    }
}
