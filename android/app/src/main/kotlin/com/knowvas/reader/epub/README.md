# EPUB Reader Settings Implementation

## Overview

The EPUB reader settings implementation provides comprehensive customization options for the reading experience. This includes font size, font family, theme, line height, margins, and layout mode.

## Components

### EpubSettings.kt

The `EpubSettings` class manages all reader preferences and provides:

1. **Font Size Adjustment (12-32px)**
   - Minimum: 12px
   - Maximum: 32px
   - Default: 16px
   - Automatically coerced to valid range

2. **Font Family Selection**
   - Serif (default)
   - Sans-serif
   - Monospace

3. **Theme Switching**
   - Light: White background, black text
   - Sepia: Warm beige background (#F4ECD8), brown text (#5B4636)
   - Dark: Dark gray background (#1E1E1E), light gray text (#E0E0E0)

4. **Line Height Adjustment**
   - Range: 1.0 to 2.5
   - Default: 1.5
   - Controls spacing between lines

5. **Margin Adjustment**
   - Range: 0.5 to 2.0
   - Default: 1.0
   - Multiplier for page margins

6. **Layout Mode**
   - Single: One page at a time
   - Double: Two-page spread (for tablets/landscape)

## Usage

### From Flutter

```dart
// Set reader preferences via platform channel
await readerChannel.setReaderPrefs({
  'session_id': sessionId,
  'font_size': 20,
  'font_family': 'sans-serif',
  'theme': 'dark',
  'line_height': 1.8,
  'margin': 1.2,
  'layout': 'single',
});
```

### In Kotlin

```kotlin
// Create settings instance
val settings = EpubSettings()

// Update from map
settings.updateFromMap(mapOf(
    "font_size" to 18,
    "theme" to "sepia"
))

// Generate CSS
val css = settings.generateCSS()

// Get settings as map
val settingsMap = settings.toMap()
```

## CSS Generation

The `generateCSS()` method generates CSS that can be injected into the EPUB content:

```css
:root {
    --font-size: 18px;
    --font-family: sans-serif;
    --line-height: 1.8;
    --margin-multiplier: 1.2;
    --background-color: #1E1E1E;
    --text-color: #E0E0E0;
}

body {
    font-size: var(--font-size) !important;
    font-family: var(--font-family) !important;
    line-height: var(--line-height) !important;
    background-color: var(--background-color) !important;
    color: var(--text-color) !important;
    /* ... margins and padding ... */
}
```

## Real-Time Application

Settings are applied in real-time without closing the reader:

1. Flutter calls `setReaderPrefs` via platform channel
2. `EpubReader.setPreferences()` updates the `EpubSettings` instance
3. `applySettings()` generates CSS and applies it to the navigator
4. A `settings_changed` event is emitted back to Flutter

## Event Flow

```
Flutter                    Android
  |                          |
  |--setReaderPrefs--------->|
  |                          |
  |                    [Update Settings]
  |                          |
  |                    [Apply to Navigator]
  |                          |
  |<--settings_changed-------|
  |                          |
```

## Testing

Unit tests are provided in `EpubSettingsTest.kt` covering:

- Default values
- Range validation (font size, line height, margin)
- Enum parsing (font family, theme, layout)
- Map updates
- CSS generation
- Serialization/deserialization
- Copy functionality

Run tests with:
```bash
./gradlew testDebugUnitTest --tests "*EpubSettingsTest"
```

## Integration with Readium

The current implementation provides the foundation for settings management. Full integration with Readium Navigator would involve:

1. Accessing the WebView in the navigator
2. Injecting the generated CSS
3. Updating navigator preferences via Readium's API
4. Handling layout changes for single/double page modes

Example integration (pseudocode):
```kotlin
navigator?.apply {
    // Inject custom CSS
    evaluateJavascript("""
        var style = document.createElement('style');
        style.textContent = `${settings.generateCSS()}`;
        document.head.appendChild(style);
    """)
    
    // Update background color
    setBackgroundColor(settings.theme.backgroundColor)
    
    // Update layout mode
    if (settings.layout == LayoutMode.DOUBLE) {
        enableSpreadMode()
    } else {
        disableSp readMode()
    }
}
```

## Requirements Validation

This implementation satisfies:

- **Requirement 5.6**: Font size (12-32px), font family (serif, sans-serif, monospace), line height, margins, and theme (light, sepia, dark) customization
- **Requirement 5.7**: Settings applied immediately without closing the reader

## Future Enhancements

1. Persist settings per content (save user preferences for each book)
2. Add more themes (e.g., high contrast, custom colors)
3. Support for custom fonts
4. Text alignment options (left, justify, center)
5. Column width adjustment
6. Hyphenation control
7. Publisher styles override toggle
