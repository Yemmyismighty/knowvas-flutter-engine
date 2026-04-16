# Android Reader Module Setup

This document describes the native Android module structure for the Knowvas Flutter client.

## Package Structure

```
android/app/src/main/kotlin/com/knowvas/
├── knowvas_flutter_client/
│   └── MainActivity.kt              # Main activity with ReaderPlugin registration
└── reader/
    ├── ReaderPlugin.kt              # FlutterPlugin with MethodChannel and EventChannel
    ├── ReaderManager.kt             # Manages reader sessions and coordinates reader types
    ├── epub/
    │   └── EpubReader.kt            # EPUB reader placeholder (to be implemented in task 29)
    ├── pdf/
    │   └── PdfReader.kt             # PDF reader placeholder (to be implemented in task 34)
    └── comic/
        └── ComicReader.kt           # Comic reader placeholder (to be implemented in task 38)
```

## Components

### ReaderPlugin
- Implements `FlutterPlugin`, `MethodChannel.MethodCallHandler`, and `EventChannel.StreamHandler`
- Handles platform channel communication between Flutter and native Android
- Method channel: `com.knowvas.reader/channel`
- Event channel: `com.knowvas.reader/events`
- Supports methods: `openReader`, `closeReader`, `setReaderPrefs`

### ReaderManager
- Coordinates between different reader types (EPUB, PDF, Comic)
- Manages active reading sessions
- Routes calls to appropriate reader implementations

### BaseReader Interface
- Common interface for all reader types
- Methods: `open()`, `close()`, `setPreferences()`

### Reader Implementations
- **EpubReader**: Placeholder for EPUB rendering (will use Readium in task 29)
- **PdfReader**: Placeholder for PDF rendering (will use PdfRenderer in task 34)
- **ComicReader**: Placeholder for comic/magazine rendering (will use image sequences in task 38)

## Dependencies (build.gradle)

### Android Configuration
- compileSdk: 34
- minSdk: 24 (Android 7.0)
- targetSdk: 34
- Java version: 17
- Kotlin JVM target: 17

### Dependencies Added
- Kotlin Coroutines (core and android): 1.7.3
- AndroidX Core KTX: 1.12.0
- AndroidX AppCompat: 1.6.1
- Coil (image loading): 2.5.0
- Lifecycle Runtime KTX: 2.6.2

### Future Dependencies (commented out)
- Readium Mobile Android (to be added in task 29)
  - readium-shared
  - readium-streamer
  - readium-navigator

## MainActivity Registration

The `ReaderPlugin` is registered in `MainActivity.configureFlutterEngine()`:

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.plugins.add(ReaderPlugin())
}
```

## Platform Channel Protocol

### Method Calls (Flutter → Native)

#### openReader
```dart
{
  "content_id": int,
  "type": "epub" | "pdf" | "comic",
  "file_url": string,
  "token": string,
  "session_id": string
}
```

#### closeReader
```dart
{
  "session_id": string
}
```

#### setReaderPrefs
```dart
{
  "session_id": string,
  "font_size": int?,
  "theme": string?,
  "layout": string?,
  "font_family": string?,
  "line_height": double?,
  "margin": double?
}
```

### Events (Native → Flutter)

#### Ready Event
```kotlin
{
  "type": "ready",
  "session_id": string,
  "total_pages": int,
  "timestamp": long
}
```

#### Engagement Event
```kotlin
{
  "type": "engagement",
  "session_id": string,
  "event": "page_turn" | "bookmark" | "highlight" | "session_end",
  "timestamp": long,
  "page_index": int? // for page_turn events
}
```

## Requirements Satisfied

This implementation satisfies the following requirements from the design document:

- **Requirement 13.1**: Platform channel communication with typed DTOs
- **Requirement 13.2**: Method channel for openReader, closeReader, setReaderPrefs
- **Requirement 13.3**: Event channel for reader events
- **Requirement 13.4**: Error handling with proper error codes and messages

## Next Steps

1. Task 29: Implement EPUB reader with Readium Mobile Android
2. Task 34: Implement PDF reader with Android PdfRenderer
3. Task 38: Implement Comic reader with image sequences
4. Add memory management utilities
5. Add file caching utilities
6. Implement full engagement event tracking
