# iOS EPUB Audio Playback Implementation

## Overview

This document describes the implementation of audio playback for EPUB media overlays in the iOS native reader module. The implementation uses AVFoundation for audio playback and provides text synchronization capabilities.

## Architecture

### Components

1. **EpubAudioPlayer**: Core audio player class that handles playback, synchronization, and event emission
2. **EpubReader Integration**: Audio player is integrated into the EpubReader class
3. **ReaderManager**: Manages audio control method calls from Flutter
4. **ReaderPlugin**: Handles platform channel communication for audio methods

### Key Features

- Audio playback using AVFoundation (AVAudioPlayer)
- Text synchronization with audio timestamps
- Playback controls (play, pause, stop, seek)
- Playback rate adjustment (0.5x to 2.0x)
- Volume control
- Progress tracking and event emission
- Automatic text highlighting synchronized with audio

## API Reference

### Flutter to Native Methods

#### loadAudio

Load an audio file for the current EPUB.

```dart
await platform.invokeMethod('loadAudio', {
  'session_id': sessionId,
  'audio_url': audioFileUrl,
  'sync_data': [
    {
      'timestamp': 0.5,
      'text_id': 'para1',
      'text_content': 'First paragraph text'
    },
    {
      'timestamp': 2.3,
      'text_id': 'para2',
      'text_content': 'Second paragraph text'
    }
  ]
});
```

**Parameters:**
- `session_id` (String): Active reader session ID
- `audio_url` (String): URL to the audio file (local or remote)
- `sync_data` (Array, optional): Text synchronization data

**Sync Data Format:**
- `timestamp` (Double): Time in seconds when text should be highlighted
- `text_id` (String): Unique identifier for the text element
- `text_content` (String, optional): The actual text content

#### controlAudio

Control audio playback.

```dart
// Play
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'play'
});

// Pause
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'pause'
});

// Stop
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'stop'
});

// Seek
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'seek',
  'time': 5.0  // seconds
});

// Set playback rate
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'setRate',
  'rate': 1.5  // 0.5 to 2.0
});

// Set volume
await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'setVolume',
  'volume': 0.8  // 0.0 to 1.0
});

// Get status
final result = await platform.invokeMethod('controlAudio', {
  'session_id': sessionId,
  'action': 'getStatus'
});
// Returns: { is_playing, current_time, duration }
```

**Actions:**
- `play`: Start or resume playback
- `pause`: Pause playback
- `stop`: Stop playback and reset position
- `seek`: Seek to specific time (requires `time` parameter)
- `setRate`: Set playback rate (requires `rate` parameter, 0.5-2.0)
- `setVolume`: Set volume (requires `volume` parameter, 0.0-1.0)
- `getStatus`: Get current playback status

### Native to Flutter Events

All events are emitted through the event channel with the following structure:

```swift
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_playback",
  "timestamp": 1234567890.123,
  // ... event-specific fields
}
```

#### Audio Loaded Event

Emitted when audio file is successfully loaded.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_loaded",
  "duration": 120.5,
  "timestamp": 1234567890.123
}
```

#### Playback State Event

Emitted when playback state changes.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_playback",
  "state": "playing",  // "playing", "paused", "stopped"
  "current_time": 5.2,
  "timestamp": 1234567890.123
}
```

#### Seek Event

Emitted when user seeks to a different position.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_seek",
  "time": 10.5,
  "timestamp": 1234567890.123
}
```

#### Progress Event

Emitted periodically during playback (every 100ms).

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_progress",
  "current_time": 5.2,
  "duration": 120.5,
  "progress": 0.043,  // 0.0 to 1.0
  "timestamp": 1234567890.123
}
```

#### Text Sync Event

Emitted when audio reaches a text synchronization point.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_text_sync",
  "text_id": "para1",
  "text_content": "First paragraph text",
  "timestamp": 1234567890.123
}
```

#### Rate Change Event

Emitted when playback rate is changed.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_rate_change",
  "rate": 1.5,
  "timestamp": 1234567890.123
}
```

#### Completion Event

Emitted when audio playback completes.

```json
{
  "type": "engagement",
  "session_id": "session-123",
  "event": "audio_completed",
  "duration": 120.5,
  "timestamp": 1234567890.123
}
```

#### Error Event

Emitted when an error occurs.

```json
{
  "type": "error",
  "session_id": "session-123",
  "code": "AUDIO_LOAD_FAILED",
  "message": "Failed to load audio file",
  "timestamp": 1234567890.123
}
```

## Implementation Details

### Audio Session Configuration

The audio player configures the AVAudioSession with:
- Category: `.playback`
- Mode: `.spokenAudio`

This ensures:
- Audio continues in background (if app supports it)
- Optimized for spoken word content
- Proper audio routing

### Text Synchronization

Text synchronization works by:

1. Loading sync data with timestamps and text IDs
2. Starting a timer (100ms interval) when playback begins
3. Checking current playback time against sync points
4. Emitting text sync events when timestamps are reached
5. Stopping timer when playback pauses or stops

The sync data is sorted by timestamp on load to ensure correct ordering.

### Memory Management

- Audio player is created when EpubReader is initialized
- Cleanup is called when reader is closed
- Audio session is deactivated on cleanup
- Timers are properly invalidated

### Error Handling

Errors are handled at multiple levels:

1. **Load Errors**: Thrown as AudioPlayerError and emitted as error events
2. **Playback Errors**: Caught by AVAudioPlayerDelegate and emitted as error events
3. **Decode Errors**: Caught by delegate and emitted with error code

## Usage Example

### Flutter Side

```dart
// In your reader state management
class ReaderNotifier extends StateNotifier<ReaderState> {
  final ReaderChannel _channel;
  
  Future<void> loadAndPlayAudio(String audioUrl, List<SyncPoint> syncData) async {
    try {
      // Load audio
      await _channel.loadAudio(
        sessionId: state.sessionId,
        audioUrl: audioUrl,
        syncData: syncData,
      );
      
      // Play audio
      await _channel.controlAudio(
        sessionId: state.sessionId,
        action: AudioAction.play,
      );
      
    } catch (e) {
      // Handle error
      print('Failed to load/play audio: $e');
    }
  }
  
  Future<void> pauseAudio() async {
    await _channel.controlAudio(
      sessionId: state.sessionId,
      action: AudioAction.pause,
    );
  }
  
  Future<void> seekAudio(double time) async {
    await _channel.controlAudio(
      sessionId: state.sessionId,
      action: AudioAction.seek,
      time: time,
    );
  }
}
```

### Handling Events

```dart
// Listen to reader events
_channel.readerEvents.listen((event) {
  if (event is AudioTextSyncEvent) {
    // Highlight text in UI
    highlightText(event.textId);
  } else if (event is AudioProgressEvent) {
    // Update progress UI
    updateProgress(event.currentTime, event.duration);
  } else if (event is AudioPlaybackEvent) {
    // Update playback state UI
    updatePlaybackState(event.state);
  }
});
```

## Testing

Unit tests are provided in `EpubAudioPlayerTests.swift` covering:

- Audio loading with valid and invalid files
- Playback controls (play, pause, stop)
- Seeking functionality
- Playback rate adjustment
- Volume control
- Text synchronization
- Event emission
- Error handling

Run tests with:
```bash
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Requirements Satisfied

This implementation satisfies **Requirement 5.10**:

> WHEN an EPUB contains embedded audio THEN the system SHALL provide playback controls (play, pause, seek) using platform audio APIs

✅ Audio playback using AVFoundation (AVAudioPlayer)
✅ Playback controls: play, pause, stop, seek
✅ Additional controls: rate adjustment, volume control
✅ Text synchronization with audio
✅ Comprehensive event emission for engagement tracking
✅ Error handling and reporting
✅ Unit tests for all functionality

## Future Enhancements

Potential improvements for future iterations:

1. **Background Playback**: Enable audio to continue when app is backgrounded
2. **Remote Control**: Support iOS media controls (lock screen, control center)
3. **Streaming Support**: Add support for streaming audio URLs
4. **Caching**: Cache downloaded audio files for offline playback
5. **Advanced Sync**: Support for SMIL (Synchronized Multimedia Integration Language)
6. **Accessibility**: VoiceOver support for audio controls
7. **Analytics**: More detailed playback analytics

## Troubleshooting

### Audio Not Playing

1. Check audio session configuration
2. Verify audio file format is supported (MP3, M4A, WAV)
3. Check file permissions and URL validity
4. Review error events for specific error codes

### Text Sync Not Working

1. Verify sync data is properly formatted
2. Check timestamp values are in seconds
3. Ensure text IDs match EPUB content
4. Verify timer is running during playback

### Memory Issues

1. Ensure cleanup() is called when reader closes
2. Check for retain cycles in closures
3. Monitor audio file sizes
4. Consider streaming for large audio files

## References

- [AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)
- [AVAudioPlayer Class Reference](https://developer.apple.com/documentation/avfoundation/avaudioplayer)
- [EPUB Media Overlays Specification](http://www.idpf.org/epub/30/spec/epub30-mediaoverlays.html)
