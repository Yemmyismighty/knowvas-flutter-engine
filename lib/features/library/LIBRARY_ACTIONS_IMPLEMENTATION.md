# Library Item Actions Implementation

## Overview

This document describes the implementation of library item actions (Task 23) which adds interactive context menus to library items with various actions.

## Features Implemented

### 1. Long-Press Context Menu

Library items now support long-press gestures that display a bottom sheet with available actions:

- **Grid View**: Long-press on any library item card
- **List View**: Long-press on any library item row

The context menu displays:
- Item thumbnail
- Title and author
- Available actions with icons

### 2. Download Action

**Status**: Placeholder implementation (full implementation in Task 25)

- Shows "Download" option for items not yet downloaded
- Shows "Downloaded" (disabled) for already downloaded items
- Currently simulates download with a 2-second delay
- Updates item's `isDownloaded` status in library state
- Shows progress feedback via SnackBar

**Future Enhancement**: Will integrate with full DownloadManager in Task 25 with:
- Real progress tracking
- Pause/resume functionality
- File encryption
- Background downloads

### 3. Remove from Library Action

**Status**: Fully implemented

- Shows confirmation dialog before removal
- Calls `LibraryRepository.removeFromLibrary()` to remove from backend
- Updates local state immediately
- Shows success/error feedback
- Handles network errors gracefully

**Confirmation Dialog**:
```dart
AlertDialog(
  title: 'Remove from Library',
  content: 'Are you sure you want to remove "[title]" from your library?',
  actions: [Cancel, Remove]
)
```

### 4. Add to Collection Action

**Status**: Placeholder implementation (full implementation in Task 24)

- Shows "Add to Collection" option
- Currently displays "Collections feature coming soon" message
- Will be fully implemented when collections feature is added

### 5. Mark as Favorite Toggle

**Status**: Fully implemented

- Toggles favorite status on/off
- Updates `isFavorite` field in library item
- Persists to local database via `LibraryRepository.updateLibraryItemLocally()`
- Shows visual feedback with heart icon
- Updates UI immediately

**Visual Indicators**:
- Grid view: Red heart badge in top-left corner
- List view: Red heart icon next to title

## Architecture

### Components

#### LibraryItemCard Widget
- **Location**: `lib/features/library/presentation/widgets/library_item_card.dart`
- **Type**: ConsumerWidget
- **Responsibilities**:
  - Display library item in grid or list layout
  - Handle tap to open reader
  - Handle long-press to show context menu
  - Execute actions and update state

#### _LibraryItemActionsSheet Widget
- **Location**: Same file as LibraryItemCard
- **Type**: StatelessWidget
- **Responsibilities**:
  - Display bottom sheet with actions
  - Show item thumbnail and metadata
  - Provide action buttons with icons
  - Handle action callbacks

### State Management

Actions interact with the library state through Riverpod providers:

```dart
// Update favorite status
await ref.read(libraryProvider.notifier).updateItem(
  contentId: item.content.id,
  isFavorite: newFavoriteStatus,
);

// Remove from library
await ref.read(libraryProvider.notifier).removeFromLibrary(
  item.content.id,
);
```

### Data Flow

```
User Long-Press
    ↓
Show Context Menu (Bottom Sheet)
    ↓
User Selects Action
    ↓
Execute Action Handler
    ↓
Update Library State (via LibraryNotifier)
    ↓
Update Local Database (via LibraryRepository)
    ↓
Update Backend API (if online)
    ↓
Show Feedback (SnackBar)
    ↓
UI Updates Automatically (Riverpod reactivity)
```

## Download Manager (Placeholder)

A basic DownloadManager has been created as a placeholder for Task 25:

**Location**: `lib/core/download/download_manager.dart`

**Features**:
- `DownloadProgress` model with status tracking
- `DownloadStatus` enum (queued, downloading, paused, completed, failed, cancelled)
- Stream-based progress tracking
- Cancel token support
- Basic download implementation using Dio

**Provider**: `lib/core/download/download_manager_provider.dart`

## User Experience

### Interaction Flow

1. **Open Library**: User navigates to library screen
2. **Long-Press Item**: User long-presses on any library item
3. **View Actions**: Bottom sheet slides up showing available actions
4. **Select Action**: User taps on desired action
5. **Confirmation** (if needed): Dialog appears for destructive actions
6. **Execute**: Action is performed
7. **Feedback**: SnackBar shows success/error message
8. **UI Update**: Library refreshes to show updated state

### Visual Feedback

- **Download**: Shows "Downloading..." then "Downloaded successfully"
- **Favorite**: Shows "Added to favorites" or "Removed from favorites"
- **Remove**: Shows "Removed from library"
- **Errors**: Red SnackBar with error message

### Accessibility

- All actions have descriptive labels
- Icons provide visual cues
- Confirmation dialogs prevent accidental deletions
- Error messages are clear and actionable

## Requirements Satisfied

### Requirement 4.4
✅ **WHEN a user long-presses a library item THEN the system SHALL display options (Download, Remove from Library, Add to Collection, Mark as Favorite)**

- Long-press gesture implemented
- Context menu with all required options
- Bottom sheet UI for action selection

### Requirement 4.10
✅ **WHEN library content is deleted from the backend THEN the system SHALL remove it from the local library on next sync**

- Remove from library calls backend API
- Local state updates immediately
- Sync mechanism in place via LibraryRepository

## Testing Recommendations

### Manual Testing

1. **Download Action**:
   - Long-press on non-downloaded item
   - Select "Download"
   - Verify SnackBar shows progress
   - Verify item shows download badge after completion

2. **Favorite Toggle**:
   - Long-press on item
   - Select "Add to Favorites"
   - Verify heart icon appears
   - Long-press again and select "Remove from Favorites"
   - Verify heart icon disappears

3. **Remove from Library**:
   - Long-press on item
   - Select "Remove from Library"
   - Verify confirmation dialog appears
   - Tap "Remove"
   - Verify item disappears from library
   - Verify SnackBar shows success message

4. **Error Handling**:
   - Turn off network
   - Try to remove item
   - Verify error message appears

### Unit Testing (Future)

```dart
testWidgets('Long-press shows context menu', (tester) async {
  // Test that long-press displays bottom sheet
});

testWidgets('Favorite toggle updates state', (tester) async {
  // Test that favorite action updates library state
});

testWidgets('Remove shows confirmation dialog', (tester) async {
  // Test that remove action shows confirmation
});
```

## Future Enhancements

### Task 24: Collections
- Implement full collections feature
- Add collection selection dialog
- Support multiple collections per item

### Task 25: Download Manager
- Implement full download manager
- Add progress tracking UI
- Support pause/resume
- Add file encryption
- Implement background downloads
- Add download queue management

### Additional Features
- Batch actions (select multiple items)
- Share content with others
- Export/backup library
- Sort within collections
- Custom tags/labels

## Code Examples

### Adding a New Action

To add a new action to the context menu:

1. Add action to `_LibraryItemActionsSheet`:
```dart
ListTile(
  leading: const Icon(Icons.new_action),
  title: const Text('New Action'),
  onTap: onNewAction,
),
```

2. Add handler in `LibraryItemCard`:
```dart
Future<void> _handleNewAction(BuildContext context, WidgetRef ref) async {
  Navigator.of(context).pop();
  
  // Implement action logic
  await ref.read(libraryProvider.notifier).performNewAction(
    item.content.id,
  );
  
  // Show feedback
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action completed')),
    );
  }
}
```

3. Pass handler to sheet:
```dart
_LibraryItemActionsSheet(
  item: item,
  onNewAction: () => _handleNewAction(context, ref),
  // ... other handlers
)
```

## Conclusion

Task 23 has been successfully implemented with all required features:
- ✅ Long-press context menu
- ✅ Download action (placeholder)
- ✅ Remove from library with confirmation
- ✅ Add to collection (placeholder)
- ✅ Mark as favorite toggle
- ✅ Connected to library state and repository

The implementation provides a solid foundation for future enhancements and follows Flutter best practices for state management, user interaction, and error handling.
