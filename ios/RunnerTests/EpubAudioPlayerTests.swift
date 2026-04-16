import XCTest
import AVFoundation
@testable import Runner

class EpubAudioPlayerTests: XCTestCase {
    
    var audioPlayer: EpubAudioPlayer!
    var mockEventSink: MockEventSink!
    let testSessionId = "test-session-123"
    
    override func setUp() {
        super.setUp()
        mockEventSink = MockEventSink()
        audioPlayer = EpubAudioPlayer(eventSink: mockEventSink.sink, sessionId: testSessionId)
    }
    
    override func tearDown() {
        audioPlayer.cleanup()
        audioPlayer = nil
        mockEventSink = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(audioPlayer)
        XCTAssertFalse(audioPlayer.isPlaying)
        XCTAssertEqual(audioPlayer.getCurrentTime(), 0)
        XCTAssertEqual(audioPlayer.getDuration(), 0)
    }
    
    // MARK: - Audio Loading Tests
    
    func testLoadAudioWithValidFile() {
        // Create a test audio file URL
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            
            // Verify audio loaded event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let type = dict["type"] as? String,
                      let eventType = dict["event"] as? String else {
                    return false
                }
                return type == "engagement" && eventType == "audio_loaded"
            })
            
            // Verify duration is set
            XCTAssertGreaterThan(audioPlayer.getDuration(), 0)
            
        } catch {
            XCTFail("Failed to load audio: \(error)")
        }
        
        // Cleanup
        cleanupTestAudioFile(audioUrl)
    }
    
    func testLoadAudioWithInvalidFile() {
        let invalidUrl = URL(fileURLWithPath: "/invalid/path/audio.mp3")
        
        XCTAssertThrowsError(try audioPlayer.loadAudio(from: invalidUrl)) { error in
            XCTAssertTrue(error is AudioPlayerError)
        }
    }
    
    func testLoadAudioWithSyncData() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        let syncData = [
            TextSyncPoint(timestamp: 0.5, textId: "text1", textContent: "First text"),
            TextSyncPoint(timestamp: 1.5, textId: "text2", textContent: "Second text"),
            TextSyncPoint(timestamp: 2.5, textId: "text3", textContent: "Third text")
        ]
        
        do {
            try audioPlayer.loadAudio(from: audioUrl, syncData: syncData)
            XCTAssertGreaterThan(audioPlayer.getDuration(), 0)
        } catch {
            XCTFail("Failed to load audio with sync data: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    // MARK: - Playback Control Tests
    
    func testPlayAudio() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            audioPlayer.play()
            
            // Give it a moment to start
            Thread.sleep(forTimeInterval: 0.1)
            
            XCTAssertTrue(audioPlayer.isPlaying)
            
            // Verify playback state event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String,
                      let state = dict["state"] as? String else {
                    return false
                }
                return eventType == "audio_playback" && state == "playing"
            })
            
        } catch {
            XCTFail("Failed to play audio: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    func testPauseAudio() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            audioPlayer.play()
            Thread.sleep(forTimeInterval: 0.1)
            
            audioPlayer.pause()
            
            XCTAssertFalse(audioPlayer.isPlaying)
            
            // Verify pause event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String,
                      let state = dict["state"] as? String else {
                    return false
                }
                return eventType == "audio_playback" && state == "paused"
            })
            
        } catch {
            XCTFail("Failed to pause audio: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    func testStopAudio() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            audioPlayer.play()
            Thread.sleep(forTimeInterval: 0.1)
            
            audioPlayer.stop()
            
            XCTAssertFalse(audioPlayer.isPlaying)
            XCTAssertEqual(audioPlayer.getCurrentTime(), 0)
            
            // Verify stop event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String,
                      let state = dict["state"] as? String else {
                    return false
                }
                return eventType == "audio_playback" && state == "stopped"
            })
            
        } catch {
            XCTFail("Failed to stop audio: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    func testSeekAudio() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            
            let seekTime: TimeInterval = 1.0
            audioPlayer.seek(to: seekTime)
            
            // Allow time for seek to complete
            Thread.sleep(forTimeInterval: 0.1)
            
            let currentTime = audioPlayer.getCurrentTime()
            XCTAssertEqual(currentTime, seekTime, accuracy: 0.1)
            
            // Verify seek event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String else {
                    return false
                }
                return eventType == "audio_seek"
            })
            
        } catch {
            XCTFail("Failed to seek audio: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    func testSetPlaybackRate() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            
            audioPlayer.setRate(1.5)
            
            // Verify rate change event was emitted
            XCTAssertTrue(mockEventSink.events.contains { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String,
                      let rate = dict["rate"] as? Float else {
                    return false
                }
                return eventType == "audio_rate_change" && rate == 1.5
            })
            
        } catch {
            XCTFail("Failed to set playback rate: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    func testSetVolume() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            
            // Should not throw
            audioPlayer.setVolume(0.5)
            audioPlayer.setVolume(0.0)
            audioPlayer.setVolume(1.0)
            
        } catch {
            XCTFail("Failed to set volume: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    // MARK: - Text Synchronization Tests
    
    func testTextSynchronization() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        let syncData = [
            TextSyncPoint(timestamp: 0.1, textId: "text1", textContent: "First"),
            TextSyncPoint(timestamp: 0.3, textId: "text2", textContent: "Second")
        ]
        
        do {
            try audioPlayer.loadAudio(from: audioUrl, syncData: syncData)
            audioPlayer.play()
            
            // Wait for sync events
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify text sync events were emitted
            let syncEvents = mockEventSink.events.filter { event in
                guard let dict = event as? [String: Any],
                      let eventType = dict["event"] as? String else {
                    return false
                }
                return eventType == "audio_text_sync"
            }
            
            XCTAssertGreaterThan(syncEvents.count, 0)
            
        } catch {
            XCTFail("Failed text synchronization test: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    // MARK: - Event Emission Tests
    
    func testEventEmission() {
        guard let audioUrl = createTestAudioFile() else {
            XCTFail("Failed to create test audio file")
            return
        }
        
        do {
            try audioPlayer.loadAudio(from: audioUrl)
            
            // Verify all events have required fields
            for event in mockEventSink.events {
                guard let dict = event as? [String: Any] else {
                    XCTFail("Event is not a dictionary")
                    continue
                }
                
                XCTAssertNotNil(dict["type"])
                XCTAssertNotNil(dict["session_id"])
                XCTAssertNotNil(dict["timestamp"])
                
                if let sessionId = dict["session_id"] as? String {
                    XCTAssertEqual(sessionId, testSessionId)
                }
            }
            
        } catch {
            XCTFail("Failed event emission test: \(error)")
        }
        
        cleanupTestAudioFile(audioUrl)
    }
    
    // MARK: - Helper Methods
    
    private func createTestAudioFile() -> URL? {
        // Create a simple audio file for testing
        // In a real test, you would use a bundled test audio file
        let tempDir = FileManager.default.temporaryDirectory
        let audioUrl = tempDir.appendingPathComponent("test_audio.m4a")
        
        // For testing purposes, we'll create a silent audio file
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            let audioFile = try AVAudioFile(forWriting: audioUrl, settings: settings)
            
            // Create a short silent buffer
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(format.sampleRate * 3.0) // 3 seconds
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return nil
            }
            buffer.frameLength = frameCount
            
            try audioFile.write(from: buffer)
            
            return audioUrl
        } catch {
            print("Failed to create test audio file: \(error)")
            return nil
        }
    }
    
    private func cleanupTestAudioFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Mock Event Sink

class MockEventSink {
    var events: [Any] = []
    
    var sink: FlutterEventSink {
        return { [weak self] event in
            self?.events.append(event)
        }
    }
    
    func reset() {
        events.removeAll()
    }
}
