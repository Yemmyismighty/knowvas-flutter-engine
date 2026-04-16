# Sync Manager

The Sync Manager handles synchronization of local data with the backend server. It automatically syncs data when network connectivity is restored and implements conflict resolution using a last-write-wins strategy.

## Features

- **Automatic Sync on Network Restore**: Listens to network connectivity changes and automatically triggers sync when connection is restored
- **Batch Upload**: Efficiently uploads queued engagement events in batches
- **Conflict Resolution**: Uses last-write-wins strategy for resolving conflicts
- **Comprehensive Sync**: Syncs all data types including:
  - Engagement events
  - Bookmarks
  - Highlights
  - Notes
  - Reading progress
  - Library updates

## Usage

### Basic Usage

```dart
// Get the sync manager from provider
final syncManager = ref.read(syncManagerProvider);

// Sync all data
final result = await syncManager.syncAll(userId: currentUserId);

if (result.success) {
  print('Sync completed successfully');
} else {
  print('Sync failed: ${result.message}');
}
```

### Sync Specific Data Types

```dart
// Sync only engagement events
await syncManager.syncEngagementEvents(userId: userId);

// Sync only bookmarks
await syncManager.syncBookmarks(userId: userId);

// Sync only highlights
await syncManager.syncHighlights(userId: userId);

// Sync only notes
await syncManager.syncNotes(userId: userId);

// Sync only reading progress
await syncManager.syncReadingProgress(userId: userId);

// Sync library updates from backend
await syncManager.syncLibraryUpdates(userId: userId);
```

### Check Sync Status

```dart
// Check if sync is in progress
if (syncManager.isSyncing) {
  print('Sync in progress...');
}

// Get last sync time
final lastSync = syncManager.lastSyncTime;
if (lastSync != null) {
  print('Last synced: $lastSync');
}
```

### Using with Riverpod

```dart
// Watch sync status
final syncStatus = ref.watch(syncStatusProvider);

// Trigger sync
ref.read(syncManagerProvider).syncAll(userId: userId);

// Update sync status
ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
```

## Architecture

### Automatic Network Listener

The SyncManager automatically listens to network connectivity changes:

```dart
void _initializeNetworkListener() {
  _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
    (isConnected) {
      if (isConnected) {
        _logger.i('Network connectivity restored, triggering sync');
        syncAll();
      }
    },
  );
}
```

### Conflict Resolution

The SyncManager uses a **last-write-wins** strategy for conflict resolution:

1. **Bookmarks, Highlights, Notes**: Local changes are always uploaded to the server, overwriting any server-side changes
2. **Library Updates**: Compares `last_synced` timestamps and keeps the most recent version
3. **Reading Progress**: Sessions are uploaded with timestamps, allowing the backend to determine the most recent progress

### Error Handling

The SyncManager handles errors gracefully:

- Individual item sync failures don't stop the entire sync process
- Failed items are logged but the sync continues with remaining items
- Network errors are caught and reported in the sync result
- Sync can be retried manually or will retry automatically on next network restore

## API Endpoints

The SyncManager interacts with the following backend endpoints:

- `POST /api/engagement/log` - Batch upload engagement events
- `POST /api/bookmarks` - Upload bookmarks
- `POST /api/highlights` - Upload highlights
- `POST /api/notes` - Upload notes
- `POST /api/reading-progress` - Upload reading sessions
- `GET /api/user/library` - Fetch library updates

## Requirements Mapping

This implementation satisfies the following requirements:

- **Requirement 9.7**: Queue engagement events locally when offline and sync when online
- **Requirement 9.8**: Batch upload queued engagement events when network connectivity is restored
- **Requirement 9.9**: Implement conflict resolution using last-write-wins strategy

## Testing

Unit tests are provided in `test/core/sync/sync_manager_test.dart`:

```bash
# Run sync manager tests
flutter test test/core/sync/sync_manager_test.dart
```

## Performance Considerations

- **Batch Processing**: Engagement events are uploaded in batches to reduce network requests
- **Incremental Sync**: Only unsynced items are processed, reducing data transfer
- **Background Sync**: Sync operations run asynchronously without blocking the UI
- **Error Recovery**: Failed syncs can be retried without re-processing successful items

## Future Enhancements

Potential improvements for future versions:

1. **Exponential Backoff**: Implement retry logic with exponential backoff for failed syncs
2. **Partial Sync**: Allow syncing specific content items instead of all data
3. **Sync Scheduling**: Add periodic background sync at configurable intervals
4. **Conflict UI**: Show users when conflicts are detected and allow manual resolution
5. **Sync Analytics**: Track sync performance metrics and success rates
6. **Delta Sync**: Only sync changed fields instead of entire objects
