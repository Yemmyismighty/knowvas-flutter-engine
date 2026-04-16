# Offline Mode Implementation

This document describes the offline mode detection and handling implementation for the Knowvas Flutter client.

## Overview

The offline mode implementation provides:
1. Real-time connectivity monitoring
2. Automatic filtering of library content when offline
3. Visual indicators for offline status
4. Engagement event queuing for later upload

## Components

### 1. NetworkInfo Service (`network_info.dart`)

Core service for checking network connectivity using the `connectivity_plus` package.

**Features:**
- Check current connectivity status
- Stream of connectivity changes
- WiFi/mobile data detection

**Usage:**
```dart
final networkInfo = NetworkInfo();

// Check current status
final isConnected = await networkInfo.isConnected;

// Listen to changes
networkInfo.onConnectivityChanged.listen((isOnline) {
  print('Connectivity changed: $isOnline');
});
```

### 2. Connectivity Provider (`connectivity_provider.dart`)

Riverpod providers for global connectivity state management.

**Providers:**
- `networkInfoProvider`: Provides NetworkInfo instance
- `connectivityProvider`: Stream provider for connectivity changes
- `isOnlineProvider`: Future provider for current connectivity status

**Usage:**
```dart
// In a ConsumerWidget
final connectivityStream = ref.watch(connectivityProvider);

connectivityStream.when(
  data: (isOnline) => Text(isOnline ? 'Online' : 'Offline'),
  loading: () => CircularProgressIndicator(),
  error: (_, __) => Text('Error'),
);
```

### 3. Offline Indicator Widgets (`shared/widgets/offline_indicator.dart`)

Reusable widgets for displaying offline status.

**Widgets:**
- `OfflineIndicator`: Full-width banner for offline status
- `AppBarOfflineIndicator`: Small icon for app bar

**Usage:**
```dart
// In app bar
AppBar(
  title: Text('Library'),
  actions: [
    AppBarOfflineIndicator(),
    // other actions
  ],
)

// As banner
Column(
  children: [
    OfflineIndicator(),
    // other content
  ],
)
```

### 4. Engagement Queue Service (`core/sync/engagement_queue_service.dart`)

Service for queuing engagement events when offline.

**Features:**
- Queue events to local database
- Retrieve queued events for upload
- Mark events as uploaded
- Automatic cleanup of old events

**Usage:**
```dart
final queueService = ref.read(engagementQueueServiceProvider);

// Queue an event
await queueService.queueEvent(
  contentId: 123,
  userId: 'user-id',
  sessionId: 'session-id',
  eventType: 'page_turn',
  timestamp: DateTime.now(),
  payload: {'page_index': 5},
);

// Get queued events
final events = await queueService.getQueuedEvents();

// Mark as uploaded
await queueService.markEventsAsUploaded([1, 2, 3]);
```

### 5. Library Provider Integration

The library provider automatically filters content when offline.

**Behavior:**
- When offline: Only shows downloaded content
- When online: Applies user-selected filters normally
- Automatic refresh when connectivity is restored

## Implementation Details

### Connectivity Detection

The app uses the `connectivity_plus` package which provides:
- Real-time connectivity monitoring
- Support for WiFi, mobile, ethernet, VPN
- Cross-platform support (Android, iOS, Web, Desktop)

### Offline Filtering

When the device is offline:
1. Library provider checks connectivity status
2. Automatically filters items to show only `isDownloaded = true`
3. User-selected filters are temporarily overridden
4. Normal filtering resumes when back online

### Event Queuing

Engagement events are queued when offline:
1. Events are stored in the `engagement_queue` table
2. Each event has an `uploaded` flag (0 = pending, 1 = uploaded)
3. Events are uploaded in batch when connectivity is restored
4. Old uploaded events are cleaned up after 7 days

## Database Schema

```sql
CREATE TABLE engagement_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT,
    timestamp INTEGER NOT NULL,
    uploaded INTEGER DEFAULT 0
);
```

## Testing

### Manual Testing

1. **Offline Detection:**
   - Enable airplane mode
   - Verify offline indicator appears
   - Verify library shows only downloaded content

2. **Event Queuing:**
   - Go offline
   - Perform actions (page turns, bookmarks)
   - Verify events are queued in database
   - Go online
   - Verify events are uploaded

3. **Connectivity Changes:**
   - Toggle airplane mode on/off
   - Verify UI updates in real-time
   - Verify library content updates

### Unit Testing

```dart
test('NetworkInfo detects offline status', () async {
  final networkInfo = NetworkInfo();
  final isConnected = await networkInfo.isConnected;
  expect(isConnected, isA<bool>());
});

test('EngagementQueueService queues events', () async {
  final service = EngagementQueueService(...);
  
  await service.queueEvent(
    contentId: 1,
    userId: 'test',
    sessionId: 'session',
    eventType: 'test',
    timestamp: DateTime.now(),
  );
  
  final events = await service.getQueuedEvents();
  expect(events.length, 1);
});
```

## Future Enhancements

1. **Smart Sync:**
   - Sync only on WiFi (configurable)
   - Batch size limits
   - Retry logic with exponential backoff

2. **Offline Capabilities:**
   - Cache more content for offline use
   - Offline search in downloaded content
   - Offline reading progress tracking

3. **User Notifications:**
   - Toast when going offline/online
   - Notification when queued events are uploaded
   - Warning before performing actions that require connectivity

## Requirements Satisfied

This implementation satisfies the following requirements:

- **8.8**: Display offline indicator when disconnected
- **9.7**: Queue engagement events when offline
- **9.8**: Sync queued events when connectivity is restored

## Related Files

- `lib/core/network/network_info.dart`
- `lib/core/network/connectivity_provider.dart`
- `lib/core/sync/engagement_queue_service.dart`
- `lib/core/sync/engagement_queue_provider.dart`
- `lib/shared/widgets/offline_indicator.dart`
- `lib/features/library/presentation/providers/library_provider.dart`
- `lib/features/library/presentation/screens/library_screen.dart`
