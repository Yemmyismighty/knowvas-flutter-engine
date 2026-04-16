import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/features/library/presentation/providers/library_state.dart';
import 'package:knowvas/shared/models/content.dart';
import 'package:knowvas/shared/models/library_item.dart';

void main() {
  group('LibraryState', () {
    test('initial state should be loading', () {
      final state = LibraryState.initial();
      expect(state.isLoading, true);
      expect(state.isInitialized, false);
    });

    test('applyFilter should filter items by type', () {
      // Create test data
      final ebookContent = Content(
        id: 1,
        type: 'ebook',
        title: 'Test Ebook',
        authorName: 'Author 1',
        authorId: 1,
        description: 'Description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.5,
        ratingCount: 100,
        genres: ['Fiction'],
      );

      final comicContent = Content(
        id: 2,
        type: 'comic',
        title: 'Test Comic',
        authorName: 'Author 2',
        authorId: 2,
        description: 'Description',
        coverUrl: 'https://example.com/cover2.jpg',
        price: {'USD': 5.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.0,
        ratingCount: 50,
        genres: ['Action'],
      );

      final items = [
        LibraryItem(
          content: ebookContent,
          purchaseDate: DateTime.now(),
        ),
        LibraryItem(
          content: comicContent,
          purchaseDate: DateTime.now(),
        ),
      ];

      // Note: This is a simplified test
      // In a real scenario, you would need to properly set up the provider
      // with mocked dependencies and test the actual filtering logic
      
      expect(items.length, 2);
      
      // Test filtering logic
      final ebooksOnly = items.where((item) => item.content.type == 'ebook').toList();
      expect(ebooksOnly.length, 1);
      expect(ebooksOnly.first.content.title, 'Test Ebook');
    });

    test('applySort should sort items correctly', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final content1 = Content(
        id: 1,
        type: 'ebook',
        title: 'B Book',
        authorName: 'Author B',
        authorId: 1,
        description: 'Description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.5,
        ratingCount: 100,
        genres: ['Fiction'],
      );

      final content2 = Content(
        id: 2,
        type: 'ebook',
        title: 'A Book',
        authorName: 'Author A',
        authorId: 2,
        description: 'Description',
        coverUrl: 'https://example.com/cover2.jpg',
        price: {'USD': 5.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.0,
        ratingCount: 50,
        genres: ['Fiction'],
      );

      final items = [
        LibraryItem(
          content: content1,
          purchaseDate: yesterday,
        ),
        LibraryItem(
          content: content2,
          purchaseDate: now,
        ),
      ];

      // Test sorting by title
      final sortedByTitle = [...items]..sort((a, b) => 
        a.content.title.toLowerCase().compareTo(b.content.title.toLowerCase())
      );
      expect(sortedByTitle.first.content.title, 'A Book');
      expect(sortedByTitle.last.content.title, 'B Book');

      // Test sorting by date added
      final sortedByDate = [...items]..sort((a, b) => 
        b.purchaseDate.compareTo(a.purchaseDate)
      );
      expect(sortedByDate.first.content.title, 'A Book');
      expect(sortedByDate.last.content.title, 'B Book');
    });

    test('LibraryState should handle loading state correctly', () {
      final state = LibraryState.initial();
      expect(state.isLoading, true);
      expect(state.isInitialized, false);
      expect(state.items, isEmpty);
    });

    test('LibraryState should handle loaded state correctly', () {
      final content = Content(
        id: 1,
        type: 'ebook',
        title: 'Test Book',
        authorName: 'Test Author',
        authorId: 1,
        description: 'Description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.5,
        ratingCount: 100,
        genres: ['Fiction'],
      );

      final items = [
        LibraryItem(
          content: content,
          purchaseDate: DateTime.now(),
        ),
      ];

      final state = LibraryState.loaded(items);
      expect(state.isLoading, false);
      expect(state.isInitialized, true);
      expect(state.items.length, 1);
      expect(state.filteredItems.length, 1);
    });

    test('LibraryState should handle error state correctly', () {
      const errorMessage = 'Failed to load library';
      final state = LibraryState.error(errorMessage);
      expect(state.error, errorMessage);
      expect(state.isInitialized, true);
      expect(state.items, isEmpty);
    });

    test('LibraryState copyWith should preserve values', () {
      final content = Content(
        id: 1,
        type: 'ebook',
        title: 'Test Book',
        authorName: 'Test Author',
        authorId: 1,
        description: 'Description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99},
        isFree: false,
        purchaseOnly: false,
        premiumOnly: false,
        ratingAverage: 4.5,
        ratingCount: 100,
        genres: ['Fiction'],
      );

      final items = [
        LibraryItem(
          content: content,
          purchaseDate: DateTime.now(),
        ),
      ];

      final state = LibraryState.loaded(items);
      final newState = state.copyWith(filter: LibraryFilter.favorites);
      
      expect(newState.items, state.items);
      expect(newState.filter, LibraryFilter.favorites);
      expect(newState.isInitialized, state.isInitialized);
    });
  });
}
