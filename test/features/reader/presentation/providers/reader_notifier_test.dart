import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/database/database_helper.dart';
import 'package:knowvas/core/platform/reader_channel.dart';
import 'package:knowvas/core/platform/reader_dtos.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_provider.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_state.dart';
import 'package:knowvas/features/library/presentation/providers/library_provider.dart';
import 'package:knowvas/features/reader/data/repositories/engagement_repository.dart';
import 'package:knowvas/features/reader/data/repositories/engagement_repository_provider.dart';
import 'package:knowvas/features/reader/presentation/providers/reader_provider.dart';
import 'package:knowvas/features/reader/presentation/providers/reader_state.dart';
import 'package:knowvas/shared/models/engagement_event.dart' as model;
import 'package:knowvas/shared/models/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'reader_notifier_test.mocks.dart';

@GenerateMocks([
  ReaderChannel,
  DatabaseHelper,
  EngagementRepository,
])
void main() {
  late MockReaderChannel mockReaderChannel;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockEngagementRepository mockEngagementRepository;
  late ProviderContainer container;
  late User testUser;
  late StreamController<ReaderEvent> eventStreamController;

  setUp(() {
    mockReaderChannel = MockReaderChannel();
    mockDatabaseHelper = MockDatabaseHelper();
    mockEngagementRepository = MockEngagementRepository();
    eventStreamController = StreamController<ReaderEvent>.broadcast();

    testUser = User(
      id: 'user123',
      email: 'test@example.com',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
    );

    // Setup default mock behaviors
    when(mockReaderChannel.readerEvents)
        .thenAnswer((_) => eventStreamController.stream);
    
    when(mockDatabaseHelper.getReaderPreferences(any, any))
        .thenAnswer((_) async => null);
    
    when(mockDatabaseHelper.upsertReaderPreferences(any))
        .thenAnswer((_) async => 1);
    
    when(mockDatabaseHelper.insertReadingSession(any))
        .thenAnswer((_) async => 1);
    
    when(mockDatabaseHelper.updateReadingSessionEnd(any, any, any))
        .thenAnswer((_) async => 1);
    
    when(mockDatabaseHelper.updateReadingProgress(any, any, any, any))
        .thenAnswer((_) async => 1);
    
    when(mockEngagementRepository.logEngagement(any))
        .thenAnswer((_) async => {});

    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => AuthState.authenticated(testUser)),
        engagementRepositoryProvider.overrideWithValue(mockEngagementRepository),
        libraryProvider.overrideWith((ref) {
          // Mock library provider
          return null;
        }),
      ],
    );
  });

  tearDown(() {
    eventStreamController.close();
    container.dispose();
  });

  group('ReaderNotifier', () {
    group('initialization', () {
      test('should start with initial state', () {
        // Act
        final state = container.read(readerProvider);

        // Assert
        expect(state.sessionId, null);
        expect(state.contentId, null);
        expect(state.isReaderOpen, false);
        expect(state.isLoading, false);
      });
    });

    group('openContent', () {
      test('should open content and update state', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Act
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Assert
        final state = container.read(readerProvider);
        expect(state.contentId, 1);
        expect(state.contentType, 'epub');
        expect(state.isReaderOpen, true);
        expect(state.sessionId, isNotNull);
      });

      test('should set loading state while opening', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const ReaderResponse(status: 'ok');
        });

        // Act
        final notifier = container.read(readerProvider.notifier);
        final openFuture = notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Check loading state immediately
        await Future.delayed(Duration.zero);
        var state = container.read(readerProvider);
        expect(state.isLoading, true);

        await openFuture;
      });

      test('should set error state on failure', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(
              status: 'error',
              errorCode: 'FILE_NOT_FOUND',
              errorMessage: 'File not found',
            ));

        // Act
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Assert
        final state = container.read(readerProvider);
        expect(state.error, 'File not found');
        expect(state.isReaderOpen, false);
      });

      test('should handle error when user not authenticated', () async {
        // Arrange
        final unauthContainer = ProviderContainer(
          overrides: [
            authProvider.overrideWith((ref) => AuthState.unauthenticated()),
            engagementRepositoryProvider.overrideWithValue(mockEngagementRepository),
          ],
        );

        // Act
        final notifier = unauthContainer.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Assert
        final state = unauthContainer.read(readerProvider);
        expect(state.error, 'User not authenticated');
        
        unauthContainer.dispose();
      });

      test('should load saved preferences', () async {
        // Arrange
        when(mockDatabaseHelper.getReaderPreferences(any, any))
            .thenAnswer((_) async => {
          'font_size': 18,
          'theme': 'dark',
          'layout': 'single',
        });
        
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Act
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Assert
        final state = container.read(readerProvider);
        expect(state.preferences.fontSize, 18);
        expect(state.preferences.theme, 'dark');
        expect(state.preferences.layout, 'single');
      });
    });

    group('closeContent', () {
      test('should close reader and reset state', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));
        when(mockReaderChannel.closeReader(any))
            .thenAnswer((_) async => {});

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Act
        await notifier.closeContent();

        // Assert
        final state = container.read(readerProvider);
        expect(state.sessionId, null);
        expect(state.contentId, null);
        expect(state.isReaderOpen, false);
      });

      test('should do nothing if no reader is open', () async {
        // Act
        final notifier = container.read(readerProvider.notifier);
        await notifier.closeContent();

        // Assert - should not throw
        final state = container.read(readerProvider);
        expect(state.isReaderOpen, false);
      });
    });

    group('updatePreferences', () {
      test('should update preferences and save to database', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));
        when(mockReaderChannel.setReaderPrefs(any))
            .thenAnswer((_) async => {});

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final newPrefs = const ReaderPreferences(
          fontSize: 20,
          theme: 'sepia',
          fontFamily: 'serif',
        );

        // Act
        await notifier.updatePreferences(newPrefs);

        // Assert
        final state = container.read(readerProvider);
        expect(state.preferences.fontSize, 20);
        expect(state.preferences.theme, 'sepia');
        expect(state.preferences.fontFamily, 'serif');
        
        verify(mockReaderChannel.setReaderPrefs(newPrefs)).called(1);
        verify(mockDatabaseHelper.upsertReaderPreferences(any)).called(1);
      });

      test('should do nothing if reader not open', () async {
        // Act
        final notifier = container.read(readerProvider.notifier);
        await notifier.updatePreferences(const ReaderPreferences(fontSize: 20));

        // Assert - should not throw
        verifyNever(mockReaderChannel.setReaderPrefs(any));
      });
    });

    group('handleReaderEvent', () {
      test('should handle ReaderReadyEvent', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final sessionId = container.read(readerProvider).sessionId!;

        // Act
        eventStreamController.add(ReaderReadyEvent(
          sessionId: sessionId,
          totalPages: 200,
          timestamp: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(readerProvider);
        expect(state.totalPages, 200);
        expect(state.isLoading, false);
      });

      test('should handle page turn EngagementEvent', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final sessionId = container.read(readerProvider).sessionId!;

        // Set total pages first
        eventStreamController.add(ReaderReadyEvent(
          sessionId: sessionId,
          totalPages: 200,
          timestamp: DateTime.now(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        eventStreamController.add(EngagementEvent(
          sessionId: sessionId,
          eventType: 'page_turn',
          pageIndex: 50,
          timestamp: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(readerProvider);
        expect(state.currentPage, 50);
      });

      test('should handle ReaderErrorEvent', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final sessionId = container.read(readerProvider).sessionId!;

        // Act
        eventStreamController.add(ReaderErrorEvent(
          sessionId: sessionId,
          code: 'RENDER_ERROR',
          message: 'Failed to render page',
          timestamp: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(readerProvider);
        expect(state.error, contains('RENDER_ERROR'));
      });

      test('should ignore events from different session', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        // Act - send event with different session ID
        eventStreamController.add(ReaderReadyEvent(
          sessionId: 'different-session-id',
          totalPages: 200,
          timestamp: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - state should not be updated
        final state = container.read(readerProvider);
        expect(state.totalPages, null);
      });
    });

    group('progress calculation', () {
      test('should calculate progress correctly', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final sessionId = container.read(readerProvider).sessionId!;

        // Set total pages
        eventStreamController.add(ReaderReadyEvent(
          sessionId: sessionId,
          totalPages: 100,
          timestamp: DateTime.now(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        // Act - turn to page 50
        eventStreamController.add(EngagementEvent(
          sessionId: sessionId,
          eventType: 'page_turn',
          pageIndex: 50,
          timestamp: DateTime.now(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(readerProvider);
        expect(state.progress, 0.5);
      });

      test('should return 0 progress when no pages', () {
        // Act
        final state = container.read(readerProvider);

        // Assert
        expect(state.progress, 0);
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(
              status: 'error',
              errorMessage: 'Test error',
            ));

        // Set error state
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );
        
        var state = container.read(readerProvider);
        expect(state.error, 'Test error');

        // Act
        notifier.clearError();

        // Assert
        state = container.read(readerProvider);
        expect(state.error, null);
      });
    });

    group('engagement logging', () {
      test('should log engagement events', () async {
        // Arrange
        when(mockReaderChannel.openReader(any))
            .thenAnswer((_) async => const ReaderResponse(status: 'ok'));

        // Open content first
        final notifier = container.read(readerProvider.notifier);
        await notifier.openContent(
          contentId: 1,
          contentType: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test_token',
        );

        final sessionId = container.read(readerProvider).sessionId!;

        // Act - trigger page turn event
        eventStreamController.add(EngagementEvent(
          sessionId: sessionId,
          eventType: 'page_turn',
          pageIndex: 10,
          timestamp: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - verify engagement was logged
        verify(mockEngagementRepository.logEngagement(any)).called(greaterThan(0));
      });
    });
  });
}
