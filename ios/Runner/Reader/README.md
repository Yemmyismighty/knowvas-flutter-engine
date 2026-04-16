# iOS Reader Module

This directory contains the native iOS implementation of the Knowvas reader functionality.

## Structure

```
Reader/
├── ReaderPlugin.swift          # Main Flutter plugin interface
├── ReaderManager.swift         # Manages reader instances
├── Epub/
│   └── EpubReader.swift       # EPUB reader implementation
├── Pdf/
│   └── PdfReader.swift        # PDF reader using PDFKit
├── Comic/
│   └── ComicReader.swift      # Comic/Magazine reader
├── Models/
│   └── ReaderModels.swift     # Shared data models
└── Utils/
    ├── MemoryManager.swift    # Memory management utilities
    └── FileCache.swift        # File caching utilities
```

## Components

### ReaderPlugin
- Handles Flutter method channel and event channel communication
- Routes calls to appropriate reader implementations
- Manages event streaming to Flutter

### ReaderManager
- Coordinates between different reader types (EPUB, PDF, Comic)
- Maintains active reader sessions
- Handles reader lifecycle (open, close, preferences)

### Reader Implementations

#### EpubReader
- **Status**: Placeholder (ready for Readium integration)
- **Features**: 
  - EPUB parsing and rendering
  - Text customization (font, size, theme)
  - Navigation and progress tracking
  - Bookmark and highlight support

#### PdfReader
- **Status**: Implemented using PDFKit
- **Features**:
  - PDF rendering with zoom and pan
  - Page navigation
  - Text selection (if available)
  - Bookmark support

#### ComicReader
- **Status**: Placeholder
- **Features**:
  - Image sequence viewing
  - CBZ/CBR archive support
  - Single/double page layouts
  - Zoom and pan gestures

## Dependencies

### Current
- PDFKit (built-in iOS framework)

### Planned
- Readium Mobile iOS (for EPUB support)
  - Can be integrated via Swift Package Manager
  - URL: https://github.com/readium/swift-toolkit

## Integration with Flutter

### Method Channel
Channel name: `com.knowvas.reader/channel`

Methods:
- `openReader(args)` - Open content in native reader
- `closeReader(sessionId)` - Close active reader session
- `setReaderPrefs(prefs)` - Update reader preferences

### Event Channel
Channel name: `com.knowvas.reader/events`

Events:
- `ready` - Reader initialized and ready
- `engagement` - User interaction events (page turns, bookmarks, etc.)
- `error` - Error occurred in reader

## Usage

The plugin is automatically registered in `AppDelegate.swift`:

```swift
ReaderPlugin.register(with: registrar(forPlugin: "ReaderPlugin")!)
```

## Next Steps

1. **Integrate Readium**: Add Readium Swift toolkit for full EPUB support
2. **Implement Comic Archive Extraction**: Add CBZ/CBR parsing
3. **Add UI Components**: Create native view controllers for reader UI
4. **Implement Preferences**: Complete preference handling for all readers
5. **Add Tests**: Create unit tests for reader functionality

## Notes

- All readers emit events through the event channel for engagement tracking
- Memory management is handled by `MemoryManager` to prevent crashes with large files
- File caching is managed by `FileCache` for offline support
- Error handling follows the `ReaderError` enum pattern
