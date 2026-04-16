# iOS EPUB Reader Implementation

This directory contains the iOS implementation of the EPUB reader with full controls, interactions, and settings for the Knowvas Flutter client.

## Overview

The EPUB reader settings system provides comprehensive customization options for the reading experience, including:

- **Font Size**: Adjustable from 12px to 32px
- **Font Family**: Serif, Sans-Serif, or Monospace
- **Theme**: Light, Sepia, or Dark mode
- **Line Height**: Adjustable from 1.0 to 2.5
- **Margin**: Adjustable from 0.5 to 2.0

## Files

### EpubReaderViewController.swift

The main view controller that provides the complete EPUB reading experience with UI controls and interactions.

**Key Features:**
- WebView-based EPUB rendering
- Top toolbar with close, title, bookmark, and settings buttons
- Bottom toolbar with progress slider and page display
- Tap gesture to toggle control visibility
- Text selection with context menu (highlight, note, copy, share)
- Bookmark management with visual feedback
- Highlight functionality with color picker
- Note-taking capability
- Engagement event emission for all interactions

**Usage Example:**

```swift
let epubReader = EpubReader(eventSink: eventSink, sessionId: sessionId)
let viewController = EpubReaderViewController(epubReader: epubReader, sessionId: sessionId)

// Present the reader
present(viewController, animated: true)

// Update total pages when ready
viewController.updateTotalPages(totalPages)

// Navigate to specific page
viewController.goToPage(42)
```

### EpubSettingsViewController.swift

A modal settings panel for customizing the reading experience.

**Key Features:**
- Scrollable interface with all settings
- Real-time preview of changes
- Delegate pattern for change notifications
- Sheet presentation style with medium detent

**Settings Available:**
- Font size slider (12-32px)
- Font family segmented control (Serif, Sans Serif, Monospace)
- Theme segmented control (Light, Sepia, Dark)
- Line height slider (1.0-2.5)
- Margin slider (0.5-2.0)

**Usage Example:**

```swift
let settingsVC = EpubSettingsViewController(epubReader: epubReader)
settingsVC.delegate = self

let navController = UINavigationController(rootViewController: settingsVC)
present(navController, animated: true)
```

### EpubSettings.swift

The main settings manager class that handles all reader preferences.

**Key Features:**
- Type-safe enum-based theme and font family selection
- Automatic validation of all settings values
- CSS generation for applying settings to EPUB content
- JavaScript injection for dynamic settings updates
- Dictionary conversion for serialization

**Usage Example:**

```swift
// Create settings with defaults
let settings = EpubSettings()

// Update individual settings
settings.updateFontSize(18)
settings.updateTheme(.dark)
settings.updateFontFamily(.sansSerif)

// Update from ReaderPreferences
let preferences = ReaderPreferences(from: prefsDict)
settings.updatePreferences(preferences)

// Generate CSS for EPUB content
let css = settings.generateCSS()

// Generate JavaScript for dynamic injection
let script = settings.generateCSSInjectionScript()
```

### EpubReader.swift

The EPUB reader implementation that integrates with EpubSettings.

**Key Features:**
- Settings initialization on reader creation
- Dynamic settings application without closing the reader
- WebKit integration for CSS injection
- Settings persistence across reading sessions

**Usage Example:**

```swift
// Create reader with event sink
let reader = EpubReader(eventSink: eventSink, sessionId: sessionId)

// Open EPUB with initial preferences
reader.open(fileUrl: url, preferences: preferences) { result in
    switch result {
    case .success:
        print("EPUB opened successfully")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Update settings dynamically
let prefsDict: [String: Any] = [
    "font_size": 20,
    "theme": "dark"
]
reader.setPreferences(prefsDict)

// Set WebView for rendering
reader.setWebView(webView)
```

## Settings Details

### Font Size

- **Range**: 12-32 pixels
- **Default**: 16 pixels
- **Validation**: Automatically clamped to valid range

```swift
settings.updateFontSize(18) // Valid
settings.updateFontSize(50) // Clamped to 32
settings.updateFontSize(5)  // Clamped to 12
```

### Font Family

Three font families are supported:

1. **Serif** (default)
   - CSS: `Georgia, 'Times New Roman', serif`
   - Best for traditional book reading

2. **Sans-Serif**
   - CSS: `-apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif`
   - Modern, clean appearance

3. **Monospace**
   - CSS: `'Courier New', Courier, monospace`
   - Fixed-width font for code or technical content

```swift
settings.updateFontFamily(.serif)
settings.updateFontFamily(.sansSerif)
settings.updateFontFamily(.monospace)

// Or from string
settings.updateFontFamily(fromString: "sans-serif")
```

### Theme

Three themes are available:

1. **Light** (default)
   - Background: `#FFFFFF` (white)
   - Text: `#000000` (black)

2. **Sepia**
   - Background: `#FAF4E4` (warm beige)
   - Text: `#332E26` (dark brown)
   - Reduces eye strain in low light

3. **Dark**
   - Background: `#1E1E1E` (dark gray)
   - Text: `#D9D9D9` (light gray)
   - OLED-friendly, reduces battery usage

```swift
settings.updateTheme(.light)
settings.updateTheme(.sepia)
settings.updateTheme(.dark)

// Or from string
settings.updateTheme(fromString: "dark")
```

### Line Height

- **Range**: 1.0-2.5
- **Default**: 1.5
- **Purpose**: Controls spacing between lines of text

```swift
settings.updateLineHeight(1.5) // Default
settings.updateLineHeight(2.0) // More spacious
settings.updateLineHeight(1.2) // More compact
```

### Margin

- **Range**: 0.5-2.0
- **Default**: 1.0
- **Purpose**: Controls padding around content
- **Conversion**: Multiplier × 20 = pixels

```swift
settings.updateMargin(1.0)  // 20px margin
settings.updateMargin(1.5)  // 30px margin
settings.updateMargin(0.5)  // 10px margin
```

## CSS Generation

The settings system generates CSS that is injected into EPUB content:

```css
body {
    font-size: 18px !important;
    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif !important;
    line-height: 1.5 !important;
    background-color: #1E1E1E !important;
    color: #D9D9D9 !important;
    margin: 20px !important;
    padding: 20px !important;
}

p, div, span {
    font-size: inherit !important;
    font-family: inherit !important;
    line-height: inherit !important;
    color: inherit !important;
}

h1, h2, h3, h4, h5, h6 {
    font-family: inherit !important;
    color: inherit !important;
}

a {
    color: #6BA4FF !important;
}
```

## JavaScript Injection

Settings can be applied dynamically using JavaScript injection:

```javascript
(function() {
    var style = document.getElementById('knowvas-reader-style');
    if (!style) {
        style = document.createElement('style');
        style.id = 'knowvas-reader-style';
        document.head.appendChild(style);
    }
    style.textContent = '/* CSS here */';
})();
```

This allows settings to be updated without reloading the EPUB content.

## Integration with Flutter

Settings are passed from Flutter via the platform channel:

```dart
// Flutter side
await readerChannel.setReaderPrefs({
  'font_size': 18,
  'font_family': 'sans-serif',
  'theme': 'dark',
  'line_height': 1.8,
  'margin': 1.5,
});
```

```swift
// iOS side
func setPreferences(_ preferences: [String: Any]) {
    let readerPrefs = ReaderPreferences(from: preferences)
    let hasChanges = settings.updatePreferences(readerPrefs)
    
    if hasChanges {
        applySettingsToReader()
    }
}
```

## Controls and Interactions

### Tap Gesture for Control Toggle

Tap in the center area of the screen to toggle toolbar visibility:
- Smooth fade animation (0.3s duration)
- Taps on toolbars don't trigger toggle
- Controls remain accessible via gesture

### Text Selection

Long press on text to trigger selection:
1. JavaScript evaluation gets selected text from WebView
2. Context menu appears with actions:
   - **Highlight**: Choose from 5 colors (Yellow, Green, Blue, Pink, Orange)
   - **Add Note**: Attach a note to selected text
   - **Copy**: Copy text to clipboard
   - **Share**: Share text via system share sheet

### Bookmarks

- Toggle bookmark on current page with bookmark button
- Visual indicator (filled/unfilled bookmark icon)
- Toast feedback for user confirmation
- Engagement events emitted for add/remove actions

### Progress Navigation

- Slider for quick page navigation
- Real-time page label update (Page X of Y)
- Smooth navigation without triggering change events
- Page turn engagement events

## Engagement Events

All user interactions emit engagement events through the platform channel:

### Event Types

1. **Bookmark Events**
   - Event type: `bookmark`
   - Includes: page_number, action (add/remove)

2. **Highlight Events**
   - Event type: `highlight`
   - Includes: page_number, highlighted_text, color

3. **Note Events**
   - Event type: `note`
   - Includes: page_number, selected_text, note_text

4. **Page Turn Events**
   - Event type: `page_turn`
   - Includes: page_index

See `CONTROLS_IMPLEMENTATION.md` for detailed event schemas.

## Requirements Satisfied

This implementation satisfies the following requirements:

- **Requirement 5.6**: Reader settings with font size (12-32px), font family (serif, sans-serif, monospace), line height, margins, and theme (light, sepia, dark)
- **Requirement 5.7**: Settings changes applied immediately without closing the reader
- **Requirement 5.8**: Tap gesture for control visibility toggle
- **Requirement 5.9**: Reader toolbar with navigation and settings
- **Requirement 5.11**: Bookmark functionality with engagement events
- **Requirement 5.12**: Highlight functionality with color selection
- **Requirement 5.13**: Text selection with actions (highlight, note, copy, share)

## Future Enhancements

When Readium Mobile iOS is integrated:

1. Replace WebKit CSS injection with Readium's native settings API
2. Add support for additional Readium-specific features:
   - Text alignment
   - Hyphenation
   - Publisher styles override
   - Column count (single/double)
3. Implement settings persistence per content item
4. Add accessibility features (dyslexia-friendly fonts, high contrast)

## Testing

See the following test files:
- `EpubSettingsTests.swift` - Settings functionality tests
- `EpubReaderViewControllerTests.swift` - UI and interaction tests

### Manual Testing Checklist

- [ ] Tap center area toggles controls
- [ ] Progress slider navigates correctly
- [ ] Bookmark button toggles state
- [ ] Long press shows text selection menu
- [ ] Highlight applies correct color
- [ ] Note dialog saves note
- [ ] Copy action works
- [ ] Share action opens share sheet
- [ ] Settings panel opens and applies changes
- [ ] Toast messages appear for feedback
- [ ] All engagement events are emitted

## Notes

- All settings values are validated and clamped to safe ranges
- Settings are applied immediately when the reader is open
- CSS uses `!important` to override publisher styles
- Theme colors are optimized for readability and battery efficiency
- The implementation is ready for Readium integration with minimal changes
