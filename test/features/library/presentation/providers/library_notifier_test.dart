import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/core/network/connectivity_provider.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_provider.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_state.dart';
import 'package:knowvas/features/library/data/repositories/library_repository.dart';
import 'package:knowvas/features/library/presentation/providers/library_provider.dart';
import 'package:knowvas/features/library/presentation/providers/library_state.dart';
import 'package:knowvas/shared/models/content.dart';
import 'package:knowvas/shared/models/library_item.dart';
import 'package:knowvas/shared/models/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'library_notifier_test.mocks.dart';

@GenerateMocks([LibraryRepository])
void main() {
  late MockLibraryRepository mockLibraryRepository;
  late ProviderContainer container;
  late User testUser;
  late List<LibraryItem> testLibraryItems;

  setUp(() {
    mockLibraryRepository = MockLibraryRepository();
    
    testUser = User(
      id: 'user123',
      email: 'test@example.com',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
    );

    testLibraryItems = [
      LibraryItem(
        content: Content(
          id: 1,
          type: 'ebook',
          title: 'Test Book 1',
          authorName: 'Author 1',
          authorId: 1,
          description: 'Description 1',
          coverUrl: 'https://example.com/cover1.jpg',
          price: {'USD': 9.99},
          isFree: false,
          purchaseOnly: false,
          premiumOnly: false,
          ratingAverage: 4.5,
          ratingCount: 100,
          genres: ['Fiction'],
          estimatedReadTime: 300,
        ),
        purchaseDate: DateTime(2024, 1, 1),
        readingProgress: 0.5,
        currentPage: 50,
        lastOpened: DateTime(2024, 1, 15),
        isDownloaded: true,
        isFavorite: false,
      ),
      LibraryItem(
        content: Content(
          id: 2,
          type: 'comic',
          title: 'Test Comic 1',
          authorName: 'Author 2',
          authorId: 2,
          description: 'Description 2',
          coverUrl: 'https://example.com/cover2.jpg',
          price: {'USD': 4.99},
          isFree: false,
          purchaseOnly: false,
          premiumOnly: false,
          ratingAverage: 4.0,
          ratingCount: 50,
          genres: ['Action'],
          estimatedReadTime: 60,
        ),
        purchaseDate: DateTime(2024, 1, 5),
        readingProgress: 0.0,
        isDownloaded: false,
        isFavorite: true,
      ),
    ];

    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(mockLibraryRepository),
        authProvider.overrideWith((ref) {
          return AuthState.authenticated(testUser);
        }),
        isOnlineProvider.overrideWith((ref) => const AsyncValue.data(true)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LibraryNotifier', () {
    group('initialization', () {
      test('should start with initial state', () {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => []);

        // Act
        final state = container.read(libraryProvider);

        // Assert
        expect(state.isLoading, true);
        expect(state.items, isEmpty);
        expect(state.isInitialized, false);
      });

      test('should load cached library on initialization', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => testLibraryItems);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Act
        container.read(libraryProvider);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = container.read(libraryProvider);
        expect(state.items, isNotEmpty);
        expect(state.isInitialized, true);
      });

      test('should handle error when user not authenticated', () async {
        // Arrange
        final unauthContainer = ProviderContainer(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(mockLibraryRepository),
            authProvider.overrideWith((ref) => AuthState.unauthenticated()),
          ],
        );

        // Act
        unauthContainer.read(libraryProvider);
        await Future.delayed(Duration.zero);

        // Assert
        final state = unauthContainer.read(libraryProvider);
        expect(state.error, 'User not authenticated');
        
        unauthContainer.dispose();
      });
    });

    group('refresh', () {
      test('should fetch library from backend and update state', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(libraryProvider);
        expect(state.items, testLibraryItems);
        expect(state.isLoading, false);
        expect(state.isInitialized, true);
      });

      test('should set error state on NetworkFailure', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenThrow(const NetworkFailure('No internet connection'));

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(libraryProvider);
        expect(state.error, 'No internet connection');
      });

      test('should set error state on ServerFailure', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenThrow(const ServerFailure('Server error', statusCode: 500));

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(libraryProvider);
        expect(state.error, 'Server error');
      });
    });

    group('addToLibrary', () {
      test('should add new item to library', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => [testLibraryItems[0]]);
        
        final newItem = testLibraryItems[1];
        when(mockLibraryRepository.addToLibrary(any))
            .thenAnswer((_) async => newItem);

        // Initialize with one item
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        await notifier.addToLibrary(2);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.items.length, 2);
        expect(state.items.last, newItem);
      });

      test('should set error state on failure', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.addToLibrary(any))
            .thenThrow(const NetworkFailure('Network error'));

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.addToLibrary(1);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.error, 'Network error');
      });
    });

    group('removeFromLibrary', () {
      test('should remove item from library', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);
        when(mockLibraryRepository.removeFromLibrary(any))
            .thenAnswer((_) async => {});

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        await notifier.removeFromLibrary(1);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.items.length, 1);
        expect(state.items.first.content.id, 2);
      });

      test('should set error state on failure', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);
        when(mockLibraryRepository.removeFromLibrary(any))
            .thenThrow(const ServerFailure('Server error', statusCode: 500));

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        await notifier.removeFromLibrary(1);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.error, 'Server error');
      });
    });

    group('updateItem', () {
      test('should update item reading progress', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);
        when(mockLibraryRepository.updateLibraryItemLocally(
          contentId: anyNamed('contentId'),
          userId: anyNamed('userId'),
          readingProgress: anyNamed('readingProgress'),
          currentPage: anyNamed('currentPage'),
          lastOpened: anyNamed('lastOpened'),
          isDownloaded: anyNamed('isDownloaded'),
          isFavorite: anyNamed('isFavorite'),
        )).thenAnswer((_) async => {});

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        await notifier.updateItem(
          contentId: 1,
          readingProgress: 0.75,
          currentPage: 75,
        );

        // Assert
        final state = container.read(libraryProvider);
        final updatedItem = state.items.firstWhere((item) => item.content.id == 1);
        expect(updatedItem.readingProgress, 0.75);
        expect(updatedItem.currentPage, 75);
      });

      test('should update item favorite status', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);
        when(mockLibraryRepository.updateLibraryItemLocally(
          contentId: anyNamed('contentId'),
          userId: anyNamed('userId'),
          readingProgress: anyNamed('readingProgress'),
          currentPage: anyNamed('currentPage'),
          lastOpened: anyNamed('lastOpened'),
          isDownloaded: anyNamed('isDownloaded'),
          isFavorite: anyNamed('isFavorite'),
        )).thenAnswer((_) async => {});

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        await notifier.updateItem(
          contentId: 1,
          isFavorite: true,
        );

        // Assert
        final state = container.read(libraryProvider);
        final updatedItem = state.items.firstWhere((item) => item.content.id == 1);
        expect(updatedItem.isFavorite, true);
      });
    });

    group('applyFilter', () {
      test('should filter ebooks only', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applyFilter(LibraryFilter.ebooks);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.filter, LibraryFilter.ebooks);
        expect(state.filteredItems.length, 1);
        expect(state.filteredItems.first.content.type, 'ebook');
      });

      test('should filter comics only', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applyFilter(LibraryFilter.comics);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.filter, LibraryFilter.comics);
        expect(state.filteredItems.length, 1);
        expect(state.filteredItems.first.content.type, 'comic');
      });

      test('should filter downloaded only', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applyFilter(LibraryFilter.downloaded);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.filter, LibraryFilter.downloaded);
        expect(state.filteredItems.length, 1);
        expect(state.filteredItems.first.isDownloaded, true);
      });

      test('should filter favorites only', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applyFilter(LibraryFilter.favorites);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.filter, LibraryFilter.favorites);
        expect(state.filteredItems.length, 1);
        expect(state.filteredItems.first.isFavorite, true);
      });

      test('should show all items with all filter', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applyFilter(LibraryFilter.all);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.filter, LibraryFilter.all);
        expect(state.filteredItems.length, 2);
      });
    });

    group('applySort', () {
      test('should sort by title', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applySort(LibrarySortBy.title);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.sortBy, LibrarySortBy.title);
        expect(state.filteredItems.first.content.title, 'Test Book 1');
        expect(state.filteredItems.last.content.title, 'Test Comic 1');
      });

      test('should sort by author', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applySort(LibrarySortBy.author);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.sortBy, LibrarySortBy.author);
        expect(state.filteredItems.first.content.authorName, 'Author 1');
        expect(state.filteredItems.last.content.authorName, 'Author 2');
      });

      test('should sort by progress', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applySort(LibrarySortBy.progress);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.sortBy, LibrarySortBy.progress);
        expect(state.filteredItems.first.readingProgress, 0.5);
        expect(state.filteredItems.last.readingProgress, 0.0);
      });

      test('should sort by date added', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Initialize with items
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Act
        notifier.applySort(LibrarySortBy.dateAdded);

        // Assert
        final state = container.read(libraryProvider);
        expect(state.sortBy, LibrarySortBy.dateAdded);
        // Most recent first
        expect(state.filteredItems.first.purchaseDate, DateTime(2024, 1, 5));
        expect(state.filteredItems.last.purchaseDate, DateTime(2024, 1, 1));
      });
    });

    group('syncLocalChanges', () {
      test('should return true on successful sync', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.syncLocalChanges(any))
            .thenAnswer((_) async => true);

        // Act
        final notifier = container.read(libraryProvider.notifier);
        final result = await notifier.syncLocalChanges();

        // Assert
        expect(result, true);
      });

      test('should return false on sync failure', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.syncLocalChanges(any))
            .thenThrow(Exception('Sync failed'));

        // Act
        final notifier = container.read(libraryProvider.notifier);
        final result = await notifier.syncLocalChanges();

        // Assert
        expect(result, false);
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenThrow(const NetworkFailure('Network error'));

        // Set error state
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();
        
        var state = container.read(libraryProvider);
        expect(state.error, 'Network error');

        // Act
        notifier.clearError();

        // Assert
        state = container.read(libraryProvider);
        expect(state.error, null);
      });
    });

    group('getters', () {
      test('items should return filtered items', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => testLibraryItems);

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Assert
        expect(notifier.items, testLibraryItems);
      });

      test('isEmpty should return true when no items', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async => []);

        // Act
        final notifier = container.read(libraryProvider.notifier);
        await notifier.refresh();

        // Assert
        expect(notifier.isEmpty, true);
      });

      test('isLoading should return loading state', () async {
        // Arrange
        when(mockLibraryRepository.getCachedLibrary(any))
            .thenAnswer((_) async => []);
        when(mockLibraryRepository.fetchLibrary(userId: anyNamed('userId')))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return [];
        });

        // Act
        final notifier = container.read(libraryProvider.notifier);
        container.read(libraryProvider);
        
        // Assert - should be loading initially
        expect(notifier.isLoading, true);
      });
    });
  });
}
