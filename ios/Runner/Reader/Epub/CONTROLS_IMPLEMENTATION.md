# iOS EPUB Reader Controls and Interactions Implementation

## Overview

This document describes the implementation of iOS EPUB reader controls and interactions, including tap gestures, toolbars, text selection, bookmarks, highlights, and engagement event emission.

## Components

### 1. EpubReaderViewController

The main view controller that manages the EPUB reading experience with full UI controls.

**Key Features:**
- WebView-based EPUB rendering
- Top and bottom toolbars with controls
- Tap gesture to toggle control visibility
- Progress slider and page navigation
- Text selection with context menu
- Bookmark management
- Highlight functionality with color picker
- Note-taking capability

**UI Components:**

#### Top Toolbar
- Close button (dismiss reader)
- Title label (content title)
- Bookmark button (add/remove bookmark)
- Settings button (open settings panel)

#### Bottom Toolbar
- Progress slider (navigate through pages)
- Page label (current page / total pages)

### 2. EpubSettingsViewController

A modal settings panel for customizing the reading experience.

**Settings Available:**
- Font size (12-32px with slider)
- Font family (Serif, Sans Serif, Monospace)
- Theme (Light, Sepia, Dark)
- Line height (1.0-2.5 with slider)
- Margin (0.5-2.0 with slider)

**Features:**
- Real-time preview of changes
- Delegate pattern to notify parent view controller
- Scrollable interface for all settings
- Sheet presentation style with medium detent

### 3. Enhanced EpubReader

Extended the EpubReader class with engagement event emission methods.

**New Methods:**
- `emitBookmarkEvent(pageNumber:added:)` - Emits bookmark add/remove events
- `emitHighlightEvent(pageNumber:text:color:)` - Emits highlight creation events
- `emitNoteEvent(pageNumber:text:note:)` - Emits note creation events

## Interactions

### Tap Gesture for Control Toggle

**Implementation:**
```swift
@objc private func handleTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: webView)
    
    // Check if tap is in center area (not on toolbars)
    let centerRect = CGRect(
        x: 0,
        y: topToolbar.frame.maxY,
        width: webView.bounds.width,
        height: webView.bounds.height - topToolbar.frame.height - bottomToolbar.frame.height
    )
    
    if centerRect.contains(location) {
        toggleControls()
    }
}
```

**Behavior:**
- Tap in center area toggles toolbar visibility
- Smooth fade animation (0.3s duration)
- Taps on toolbars don't trigger toggle

### Text Selection

**Implementation:**
- Long press gesture triggers text selection check
- JavaScript evaluation to get selected text from WebView
- Context menu with multiple actions

**Available Actions:**
1. **Highlight** - Choose color and apply highlight
2. **Add Note** - Attach a note to selected text
3. **Copy** - Copy text to clipboard
4. **Share** - Share text via system share sheet

### Highlight Color Picker

**Available Colors:**
- Yellow (#FFFF00)
- Green (#00FF00)
- Blue (#00BFFF)
- Pink (#FFB6C1)
- Orange (#FFA500)

**Implementation:**
- JavaScript injection to wrap selected text in span with background color
- CSS class `knowvas-highlight` for identification
- Engagement event emitted with text and color

### Bookmark Management

**Features:**
- Toggle bookmark on current page
- Visual indicator (filled/unfilled bookmark icon)
- Persistent bookmark storage (Set<Int>)
- Engagement events for add/remove actions
- Toast feedback for user confirmation

### Progress Navigation

**Features:**
- Slider for quick page navigation
- Real-time page label update
- Smooth navigation without triggering change events
- Page turn engagement events

## Engagement Events

All user interactions emit engagement events through the platform channel:

### Event Types

1. **Bookmark Events**
```swift
{
    "type": "engagement",
    "session_id": "...",
    "event": "bookmark",
    "page_number": 42,
    "action": "add", // or "remove"
    "timestamp": 1234567890000
}
```

2. **Highlight Events**
```swift
{
    "type": "engagement",
    "session_id": "...",
    "event": "highlight",
    "page_number": 42,
    "highlighted_text": "Selected text...",
    "color": "#FFFF00",
    "timestamp": 1234567890000
}
```

3. **Note Events**
```swift
{
    "type": "engagement",
    "session_id": "...",
    "event": "note",
    "page_number": 42,
    "selected_text": "Selected text...",
    "note_text": "User's note...",
    "timestamp": 1234567890000
}
```

4. **Page Turn Events**
```swift
{
    "type": "engagement",
    "session_id": "...",
    "event": "page_turn",
    "page_index": 42,
    "timestamp": 1234567890000
}
```

## Requirements Mapping

### Requirement 5.8: Tap gesture for control visibility toggle
✅ Implemented with UITapGestureRecognizer
✅ Toggles top and bottom toolbars with animation
✅ Only triggers in center area (not on toolbars)

### Requirement 5.9: Reader toolbar with navigation and settings
✅ Top toolbar with close, title, bookmark, and settings buttons
✅ Bottom toolbar with progress slider and page display
✅ Navigation through slider and page controls

### Requirement 5.11: Bookmark functionality
✅ Add/remove bookmarks on current page
✅ Visual indicator (filled/unfilled icon)
✅ Engagement events emitted
✅ Toast feedback for user

### Requirement 5.12: Highlight functionality
✅ Text selection with long press
✅ Color picker with 5 color options
✅ JavaScript injection for visual highlighting
✅ Engagement events with text and color

### Requirement 5.13: Text selection with actions
✅ Long press gesture for selection
✅ Context menu with multiple actions:
  - Highlight (with color picker)
  - Add Note (with text input)
  - Copy (to clipboard)
  - Share (via system share sheet)

## Usage

### Integration with ReaderManager

```swift
// In ReaderManager.swift
func openEpubReader(request: OpenReaderRequest, eventSink: FlutterEventSink?) {
    let epubReader = EpubReader(eventSink: eventSink, sessionId: request.sessionId)
    
    epubReader.open(fileUrl: request.fileUrl) { result in
        switch result {
        case .success:
            let viewController = EpubReaderViewController(
                epubReader: epubReader,
                sessionId: request.sessionId
            )
            
            // Present the view controller
            self.presentViewController(viewController)
            
        case .failure(let error):
            // Handle error
        }
    }
}
```

### Customization

Settings can be applied programmatically:

```swift
let preferences = ReaderPreferences(from: [
    "font_size": 18,
    "font_family": "sans-serif",
    "theme": "dark",
    "line_height": 1.6,
    "margin": 1.2
])

epubReader.setPreferences(preferences)
```

## Testing

### Manual Testing Checklist

- [ ] Tap center area toggles controls
- [ ] Tap on toolbars doesn't toggle controls
- [ ] Progress slider navigates to correct page
- [ ] Page label updates correctly
- [ ] Bookmark button toggles state
- [ ] Bookmark events are emitted
- [ ] Long press shows text selection menu
- [ ] Highlight applies correct color
- [ ] Highlight events are emitted
- [ ] Note dialog saves note correctly
- [ ] Note events are emitted
- [ ] Copy action copies to clipboard
- [ ] Share action opens share sheet
- [ ] Settings panel opens and closes
- [ ] Settings changes apply in real-time
- [ ] Toast messages appear for feedback
- [ ] Close button dismisses reader

### Unit Testing

Unit tests should be added for:
- Event emission methods
- Bookmark state management
- Page navigation logic
- Settings application

## Future Enhancements

1. **Persistent Storage**
   - Save bookmarks to local database
   - Sync bookmarks with backend
   - Load bookmarks on reader open

2. **Highlight Management**
   - View all highlights
   - Edit/delete highlights
   - Navigate to highlighted text

3. **Note Management**
   - View all notes
   - Edit/delete notes
   - Search notes

4. **Reading Progress**
   - Auto-save reading position
   - Resume from last position
   - Progress synchronization

5. **Accessibility**
   - VoiceOver support
   - Dynamic type support
   - High contrast themes

## Dependencies

- UIKit (iOS 14.0+)
- WebKit (for EPUB rendering)
- Foundation

## Notes

- This implementation uses WebKit as a placeholder until Readium Mobile iOS is fully integrated
- JavaScript injection is used for CSS styling and highlighting
- All engagement events are emitted through the platform channel for Flutter consumption
- The implementation follows iOS design patterns and HIG guidelines
