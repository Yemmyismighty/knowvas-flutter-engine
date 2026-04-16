import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:knowvas/core/database/database_helper.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/core/network/network_info.dart';
import 'package:knowvas/core/sync/sync_manager.dart';

@GenerateMocks([DatabaseHelper, ApiClient, NetworkInfo, Logger])
import 'sync_manager_test.mocks.dart';

void main() {
  late SyncManager syncManager;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockApiClient mockApiClient;
  late MockNetworkInfo mockNetworkInfo;
  late MockLogger mockLogger;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockApiClient = MockApiClient();
    mockNetworkInfo = MockNetworkInfo();
    mockLogger = MockLogger();

    // Setup default network connectivity stream
    when(mockNetworkInfo.onConnectivityChanged).thenAnswer(
      (_) => Stream.value(true),
    );

    syncManager = SyncManager(
      databaseHelper: mockDatabaseHelper,
      apiClient: mockApiClient,
      networkInfo: mockNetworkInfo,
      logger: mockLogger,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('SyncManager', () {
    group('syncEngagementEvents', () {
      test('should sync queued engagement events successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final queuedEvents = [
          {
            'id': 1,
            'content_id': 123,
            'session_id': 'session-1',
            'event_type': 'page_turn',
            'payload': '{"page_index": 5}',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        ];

        when(mockDatabaseHelper.getUnuploadedEngagementEvents(userId))
            .thenAnswer((_) async => queuedEvents);
        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => MockResponse(statusCode: 200));
        when(mockDatabaseHelper.markEngagementEventsUploaded(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await syncManager.syncEngagementEvents(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.syncedCount, 1);
        verify(mockDatabaseHelper.getUnuploadedEngagementEvents(userId))
            .called(1);
        verify(mockApiClient.post('/api/engagement/log', data: anyNamed('data')))
            .called(1);
        verify(mockDatabaseHelper.markEngagementEventsUploaded([1])).called(1);
      });

      test('should return success when no events to sync', () async {
        // Arrange
        const userId = 'test-user-id';
        when(mockDatabaseHelper.getUnuploadedEngagementEvents(userId))
            .thenAnswer((_) async => []);

        // Act
        final result = await syncManager.syncEngagementEvents(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.message, 'No events to sync');
        verifyNever(mockApiClient.post(any, data: anyNamed('data')));
      });
    });

    group('syncBookmarks', () {
      test('should sync unsynced bookmarks successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final unsyncedBookmarks = [
          {
            'id': 1,
            'content_id': 123,
            'page_number': 10,
            'location': 'chapter-1',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
        ];

        when(mockDatabaseHelper.getUnsyncedBookmarks(userId))
            .thenAnswer((_) async => unsyncedBookmarks);
        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => MockResponse(statusCode: 200));
        when(mockDatabaseHelper.markBookmarkSynced(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await syncManager.syncBookmarks(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.syncedCount, 1);
        verify(mockDatabaseHelper.getUnsyncedBookmarks(userId)).called(1);
        verify(mockApiClient.post('/api/bookmarks', data: anyNamed('data')))
            .called(1);
        verify(mockDatabaseHelper.markBookmarkSynced(1)).called(1);
      });

      test('should require user ID', () async {
        // Act
        final result = await syncManager.syncBookmarks();

        // Assert
        expect(result.success, false);
        expect(result.message, 'User ID required');
      });
    });

    group('syncHighlights', () {
      test('should sync unsynced highlights successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final unsyncedHighlights = [
          {
            'id': 1,
            'content_id': 123,
            'page_number': 10,
            'start_position': 100,
            'end_position': 200,
            'highlighted_text': 'Test highlight',
            'color': '#FFFF00',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
        ];

        when(mockDatabaseHelper.getUnsyncedHighlights(userId))
            .thenAnswer((_) async => unsyncedHighlights);
        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => MockResponse(statusCode: 200));
        when(mockDatabaseHelper.markHighlightSynced(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await syncManager.syncHighlights(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.syncedCount, 1);
        verify(mockDatabaseHelper.getUnsyncedHighlights(userId)).called(1);
        verify(mockApiClient.post('/api/highlights', data: anyNamed('data')))
            .called(1);
        verify(mockDatabaseHelper.markHighlightSynced(1)).called(1);
      });
    });

    group('syncNotes', () {
      test('should sync unsynced notes successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final now = DateTime.now().millisecondsSinceEpoch;
        final unsyncedNotes = [
          {
            'id': 1,
            'content_id': 123,
            'page_number': 10,
            'position': 100,
            'note_text': 'Test note',
            'created_at': now,
            'updated_at': now,
          },
        ];

        when(mockDatabaseHelper.getUnsyncedNotes(userId))
            .thenAnswer((_) async => unsyncedNotes);
        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => MockResponse(statusCode: 200));
        when(mockDatabaseHelper.markNoteSynced(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await syncManager.syncNotes(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.syncedCount, 1);
        verify(mockDatabaseHelper.getUnsyncedNotes(userId)).called(1);
        verify(mockApiClient.post('/api/notes', data: anyNamed('data')))
            .called(1);
        verify(mockDatabaseHelper.markNoteSynced(1)).called(1);
      });
    });

    group('syncReadingProgress', () {
      test('should sync unsynced reading sessions successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final now = DateTime.now().millisecondsSinceEpoch;
        final unsyncedSessions = [
          {
            'session_id': 'session-1',
            'content_id': 123,
            'start_time': now,
            'end_time': now + 3600000,
            'start_page': 1,
            'end_page': 10,
          },
        ];

        when(mockDatabaseHelper.getUnsyncedReadingSessions(userId))
            .thenAnswer((_) async => unsyncedSessions);
        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => MockResponse(statusCode: 200));
        when(mockDatabaseHelper.markReadingSessionSynced(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await syncManager.syncReadingProgress(userId: userId);

        // Assert
        expect(result.success, true);
        expect(result.syncedCount, 1);
        verify(mockDatabaseHelper.getUnsyncedReadingSessions(userId)).called(1);
        verify(mockApiClient.post('/api/reading-progress', data: anyNamed('data')))
            .called(1);
        verify(mockDatabaseHelper.markReadingSessionSynced('session-1'))
            .called(1);
      });
    });

    group('syncAll', () {
      test('should skip sync when already syncing', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockDatabaseHelper.getUnuploadedEngagementEvents(any))
            .thenAnswer((_) async => []);
        when(mockDatabaseHelper.getUnsyncedBookmarks(any))
            .thenAnswer((_) async => []);
        when(mockDatabaseHelper.getUnsyncedHighlights(any))
            .thenAnswer((_) async => []);
        when(mockDatabaseHelper.getUnsyncedNotes(any))
            .thenAnswer((_) async => []);
        when(mockDatabaseHelper.getUnsyncedReadingSessions(any))
            .thenAnswer((_) async => []);
        when(mockApiClient.get(any))
            .thenAnswer((_) async => MockResponse(
                  statusCode: 200,
                  data: {'items': []},
                ));

        // Start first sync
        final firstSync = syncManager.syncAll(userId: 'test-user');

        // Act - try to start second sync while first is in progress
        final result = await syncManager.syncAll(userId: 'test-user');

        // Assert
        expect(result.success, false);
        expect(result.message, 'Sync already in progress');

        // Wait for first sync to complete
        await firstSync;
      });

      test('should skip sync when no network connection', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await syncManager.syncAll(userId: 'test-user');

        // Assert
        expect(result.success, false);
        expect(result.message, 'No network connection');
      });
    });
  });
}

// Mock response class for testing
class MockResponse {
  final int statusCode;
  final dynamic data;

  MockResponse({required this.statusCode, this.data});
}
