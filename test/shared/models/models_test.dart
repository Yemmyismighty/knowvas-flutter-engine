import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/shared/models/models.dart';

void main() {
  group('User Model', () {
    test('should serialize and deserialize correctly', () {
      final user = User(
        id: '123',
        email: 'test@example.com',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        preferences: const UserPreferences(),
        stats: const ReadingStats(),
      );

      final json = user.toJson();
      final deserializedUser = User.fromJson(json);

      expect(deserializedUser.id, user.id);
      expect(deserializedUser.email, user.email);
      expect(deserializedUser.username, user.username);
    });
  });

  group('Content Model', () {
    test('should serialize and deserialize correctly', () {
      final content = Content(
        id: 1,
        type: 'ebook',
        title: 'Test Book',
        authorName: 'Test Author',
        authorId: 1,
        description: 'Test description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99, 'NGN': 5000.0},
        genres: ['Fiction', 'Mystery'],
      );

      final json = content.toJson();
      final deserializedContent = Content.fromJson(json);

      expect(deserializedContent.id, content.id);
      expect(deserializedContent.title, content.title);
      expect(deserializedContent.price['USD'], 9.99);
      expect(deserializedContent.genres.length, 2);
    });
  });

  group('LibraryItem Model', () {
    test('should serialize and deserialize correctly', () {
      final content = Content(
        id: 1,
        type: 'ebook',
        title: 'Test Book',
        authorName: 'Test Author',
        authorId: 1,
        description: 'Test description',
        coverUrl: 'https://example.com/cover.jpg',
        price: {'USD': 9.99},
      );

      final libraryItem = LibraryItem(
        content: content,
        purchaseDate: DateTime(2024, 1, 1),
        readingProgress: 0.5,
        currentPage: 50,
        isDownloaded: true,
      );

      final json = libraryItem.toJson();
      final deserializedItem = LibraryItem.fromJson(json);

      expect(deserializedItem.content.id, content.id);
      expect(deserializedItem.readingProgress, 0.5);
      expect(deserializedItem.currentPage, 50);
      expect(deserializedItem.isDownloaded, true);
    });
  });

  group('Bookmark Model', () {
    test('should serialize and deserialize correctly', () {
      final bookmark = Bookmark(
        id: 1,
        contentId: 100,
        pageNumber: 42,
        location: 'chapter-3',
        createdAt: DateTime(2024, 1, 1),
        synced: true,
      );

      final json = bookmark.toJson();
      final deserializedBookmark = Bookmark.fromJson(json);

      expect(deserializedBookmark.id, bookmark.id);
      expect(deserializedBookmark.contentId, bookmark.contentId);
      expect(deserializedBookmark.pageNumber, bookmark.pageNumber);
      expect(deserializedBookmark.synced, true);
    });
  });

  group('Highlight Model', () {
    test('should serialize and deserialize correctly', () {
      final highlight = Highlight(
        id: 1,
        contentId: 100,
        pageNumber: 42,
        startPosition: 100,
        endPosition: 200,
        highlightedText: 'This is highlighted text',
        color: '#FFFF00',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = highlight.toJson();
      final deserializedHighlight = Highlight.fromJson(json);

      expect(deserializedHighlight.id, highlight.id);
      expect(deserializedHighlight.highlightedText, highlight.highlightedText);
      expect(deserializedHighlight.color, '#FFFF00');
    });
  });

  group('AuthResponse Model', () {
    test('should deserialize correctly', () {
      final json = {
        'access_token': 'test_access_token',
        'refresh_token': 'test_refresh_token',
        'expires_in': 3600,
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'username': 'testuser',
          'first_name': 'Test',
          'last_name': 'User',
          'preferences': {},
          'stats': {},
        },
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.accessToken, 'test_access_token');
      expect(authResponse.refreshToken, 'test_refresh_token');
      expect(authResponse.user.email, 'test@example.com');
    });
  });

  group('SearchFilters Model', () {
    test('should serialize to JSON correctly', () {
      final filters = SearchFilters(
        query: 'test query',
        genres: ['Fiction', 'Mystery'],
        minPrice: 5.0,
        maxPrice: 20.0,
        types: ['ebook', 'pdf'],
        sortBy: 'rating',
      );

      final json = filters.toJson();

      expect(json['query'], 'test query');
      expect(json['genres'], ['Fiction', 'Mystery']);
      expect(json['min_price'], 5.0);
      expect(json['max_price'], 20.0);
      expect(json['sort_by'], 'rating');
    });
  });

  group('EngagementEvent Model', () {
    test('should serialize and deserialize correctly', () {
      final event = EngagementEvent(
        id: 1,
        contentId: 100,
        sessionId: 'session-123',
        eventType: 'page_turn',
        payload: {'page_index': 42},
        timestamp: DateTime(2024, 1, 1),
        uploaded: false,
      );

      final json = event.toJson();
      final deserializedEvent = EngagementEvent.fromJson(json);

      expect(deserializedEvent.contentId, event.contentId);
      expect(deserializedEvent.sessionId, event.sessionId);
      expect(deserializedEvent.eventType, 'page_turn');
      expect(deserializedEvent.payload?['page_index'], 42);
    });
  });

  group('PurchaseRequest Model', () {
    test('should serialize correctly', () {
      final request = PurchaseRequest(
        contentIds: [1, 2, 3],
        currency: 'USD',
        paymentMethod: 'card',
      );

      final json = request.toJson();

      expect(json['content_ids'], [1, 2, 3]);
      expect(json['currency'], 'USD');
      expect(json['payment_method'], 'card');
    });
  });

  group('Model Validation', () {
    test('User model should handle null values correctly', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'username': 'testuser',
        'first_name': 'Test',
        'last_name': 'User',
      };

      final user = User.fromJson(json);

      expect(user.profilePicture, isNull);
      expect(user.bio, isNull);
      expect(user.followerCount, 0);
    });

    test('Content model should handle missing optional fields', () {
      final json = {
        'id': 1,
        'type': 'ebook',
        'title': 'Test Book',
        'author_name': 'Test Author',
        'author_id': 1,
        'description': 'Test description',
        'cover_url': 'https://example.com/cover.jpg',
        'price': {},
      };

      final content = Content.fromJson(json);

      expect(content.totalPages, isNull);
      expect(content.language, isNull);
      expect(content.genres, isEmpty);
      expect(content.isFree, false);
    });
  });
}
