# Reader Settings Panel Implementation

## Overview

The `ReaderSettingsPanel` is a bottom sheet widget that allows users to customize their reading experience. It provides different settings based on the content type (EPUB, PDF, or Comic).

## Features

### EPUB Settings (Full Feature Set)
- **Font Size**: Adjustable slider from 12px to 32px
- **Font Family**: Choice between Serif, Sans Serif, and Monospace
- **Theme**: Light, Sepia, and Dark themes
- **Line Height**: Adjustable from 1.0 to 2.5
- **Margins**: Adjustable from 0.5 to 2.0
- **Layout**: Single page or double page spread

### PDF Settings
- **Theme**: Light and Dark themes only

### Comic Settings
- **Theme**: Light and Dark themes
- **Layout**: Single page or double page spread

## Usage

The settings panel is displayed as a modal bottom sheet from the reader screen:

```dart
void _handleSettingsTap() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ReaderSettingsPanel(),
  );
}
```

## Implementation Details

### State Management
- Uses `ConsumerStatefulWidget` to access the reader state via Riverpod
- Maintains local state for preference changes until the user applies them
- Reads current preferences from `ReaderState` on initialization

### Preference Updates
When the user taps "Apply Settings":
1. Calls `ref.read(readerProvider.notifier).updatePreferences(preferences)`
2. The `ReaderProvider` saves preferences to the local database
3. The `ReaderProvider` calls the platform channel to apply settings to the native reader
4. Shows a success snackbar and closes the panel

### Platform Channel Integration
The settings are sent to the native reader modules via the `setReaderPrefs` method in `ReaderChannel`:

```dart
await _readerChannel.setReaderPrefs(preferences);
```

The native modules (Android/iOS) receive these preferences and apply them in real-time without closing the reader.

## UI Components

### Sliders
- Font size slider with visual indicators (small 'A' to large 'A')
- Line height slider with numeric display
- Margin slider with numeric display

### Choice Chips
- Font family selector with three options
- Layout selector with single/double page options

### Theme Chips
- Custom `FilterChip` widgets with color previews
- Visual representation of each theme (white for light, sepia color, dark gray)

### Apply Button
- Full-width elevated button at the bottom
- Applies all changes and closes the panel

## Testing

Comprehensive widget tests are provided in `reader_settings_panel_test.dart`:
- Verifies correct settings display for different content types
- Tests user interactions (sliders, chips, buttons)
- Validates theme and layout options
- Tests panel dismissal

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 5.6**: EPUB reader settings (font size, font family, line height, margins, theme)
- **Requirement 5.7**: Settings applied immediately without closing reader
- **Requirement 6.7**: PDF reader settings (theme)
- **Requirement 7.4**: Comic reader settings (layout, theme)

## Future Enhancements

Potential improvements for future iterations:
- Add reading direction option for comics (LTR/RTL)
- Add brightness control
- Add custom color themes
- Add font size presets (Small, Medium, Large)
- Add reset to defaults button
- Add preview of settings before applying
