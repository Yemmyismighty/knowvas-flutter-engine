# Library Feature

This feature implements library state management for the Knowvas Flutter client.

## Components

### Data Layer

#### LibraryRepository (`data/repositories/library_repository.dart`)
Handles all library-related data operations:
- **fetchLibrary()**: Fetches library from backend API
- **getCachedLibrary()**: Retrieves cached library items from local SQLite database
- **addToLibrary()**: Adds content to user's library
- **removeFromLibrary()**: Removes content from library
- **updateLibraryItemLocally()**: Updates library item properties locally (for offline changes)
- **syncLocalChanges()**: Syncs local changes to backend when online

Features:
- Automatic caching of library items to local database
- Support for offline operations
- Proper error handling with typed failures

### Presentation Layer

#### LibraryState (`presentation/providers/library_state.dart`)
Immutable state class that holds:
- `items`: All library items
- `filteredItems`: Filtered and sorted items for display
- `isLoading`: Loading state indicator
- `error`: Error message if any
- `isInitialized`: Whether library has been initialized
- `filter`: Current filter (all, ebooks, comics, magazines, audiobooks, downloaded, favorites)
- `sortBy`: Current sort option (recent, title, author, progress, dateAdded)

#### LibraryNotifier (`presentation/providers/library_provider.dart`)
Riverpod notifier that manages library state:

**Methods:**
- `refresh()`: Fetches fresh library data from backend
- `addToLibrary(contentId)`: Adds content to library
- `removeFromLibrary(contentId)`: Removes content from library
- `updateItem()`: Updates library item properties (progress, favorite, etc.)
- `applyFilter(filter)`: Applies filter to library items
- `applySort(sortBy)`: Applies sort to library items
- `syncLocalChanges()`: Syncs offline changes to backend
- `clearError()`: Clears error state

**Features:**
- Loads cached library on initialization for instant display
- Fetches fresh data from backend in background
- Supports filtering by content type and status
- Supports sorting by multiple criteria
- Handles offline changes with local caching
- Automatic sync when network is restored

## Usage Example

```dart
// In a widget
class LibraryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);
    
    if (libraryState.isLoading && libraryState.items.isEmpty) {
      return CircularProgressIndicator();
    }
    
    if (libraryState.error != null) {
      return Text('Error: ${libraryState.error}');
    }
    
    return ListView.builder(
      itemCount: libraryState.filteredItems.length,
      itemBuilder: (context, index) {
        final item = libraryState.filteredItems[index];
        return LibraryItemCard(item: item);
      },
    );
  }
}

// Refresh library
ref.read(libraryProvider.notifier).refresh();

// Apply filter
ref.read(libraryProvider.notifier).applyFilter(LibraryFilter.ebooks);

// Apply sort
ref.read(libraryProvider.notifier).applySort(LibrarySortBy.title);

// Update item
ref.read(libraryProvider.notifier).updateItem(
  contentId: 123,
  readingProgress: 0.5,
  isFavorite: true,
);
```

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **4.1**: Fetches and displays library content via GET /api/user/library
- **4.2**: Displays content with metadata, progress, and last opened date
- **4.8**: Supports filtering by type and reading status
- **4.9**: Supports sorting by multiple criteria
- **4.10**: Handles library updates and deletions

## Testing

Unit tests are provided in `test/features/library/presentation/providers/library_provider_test.dart` covering:
- State initialization
- Filter logic
- Sort logic
- State transitions
- Error handling

Run tests with:
```bash
flutter test test/features/library/presentation/providers/library_provider_test.dart
```

## Database Schema

Library items are cached in the `library_items` table:
```sql
CREATE TABLE library_items (
  content_id INTEGER PRIMARY KEY,
  user_id TEXT NOT NULL,
  content_data TEXT NOT NULL,  -- JSON
  purchase_date INTEGER,
  reading_progress REAL DEFAULT 0.0,
  current_page INTEGER,
  last_opened INTEGER,
  is_downloaded INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  last_synced INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id)
)
```

## Future Enhancements

- Add pagination support for large libraries
- Implement more advanced filtering (by genre, rating, etc.)
- Add search functionality within library
- Implement collection management
- Add bulk operations (mark multiple as favorite, etc.)
