import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/core/database/database.dart';
import 'package:knowvas/core/errors/exceptions.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/features/library/data/repositories/library_repository.dart';
import 'package:knowvas/shared/models/content.dart';
import 'package:knowvas/shared/models/library_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Fake implementations for testing
class FakeApiClient implements ApiClient {
  Response<Map<String, dynamic>>? nextResponse;
  Exception? nextException;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;

    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse as Response<T>;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastData = data;

    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse as Response<T>;
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;

    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeKnowvasDatabase implements KnowvasDatabase {
  Database? _database;
  Exception? nextException;

  @override
  Future<Database> get database async {
    if (nextException != null) {
      throw nextException!;
    }
    
    if (_database != null) {
      return _database!;
    }

    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE library_items (
            content_id INTEGER PRIMARY KEY,
            user_id TEXT NOT NULL,
            content_data TEXT NOT NULL,
            purchase_date INTEGER,
            reading_progress REAL DEFAULT 0.0,
            current_page INTEGER,
            last_opened INTEGER,
            is_downloaded INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            last_synced INTEGER
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LibraryRepository libraryRepository;
  late FakeApiClient fakeApiClient;
  late FakeKnowvasDatabase fakeDatabase;

  setUp(() async {
    fakeApiClient = FakeApiClient();
    fakeDatabase = FakeKnowvasDatabase();
    libraryRepository = LibraryRepository(
      apiClient: fakeApiClient,
      database: fakeDatabase,
    );
  });

  tearDown(() async {
    await fakeDatabase.close();
  });

  group('fetchLibrary', () {
    const testUserId = 'user_123';
    final testContent = Content(
      id: 1,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testLibraryItem = LibraryItem(
      content: testContent,
      purchaseDate: DateTime(2024, 1, 1),
      readingProgress: 0.5,
      currentPage: 50,
      lastOpened: DateTime(2024, 1, 15),
      isDownloaded: false,
      isFavorite: false,
    );

    test('should return list of LibraryItems when fetch is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      // Act
      final result = await libraryRepository.fetchLibrary(userId: testUserId);

      // Assert
      expect(result, isA<List<LibraryItem>>());
      expect(result.length, equals(1));
      expect(result.first.content.id, equals(testContent.id));
      expect(fakeApiClient.lastPath, equals(ApiConstants.library));
    });

    test('should cache library items when userId is provided', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      // Act
      await libraryRepository.fetchLibrary(userId: testUserId);

      // Assert - check if item was cached
      final cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems.length, equals(1));
      expect(cachedItems.first.content.id, equals(testContent.id));
    });

    test('should return empty list when no items in response', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {'items': []},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      // Act
      final result = await libraryRepository.fetchLibrary();

      // Assert
      expect(result, isEmpty);
    });

    test('should throw ServerFailure when response status is not 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 500,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      // Act & Assert
      expect(
        () => libraryRepository.fetchLibrary(),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });

    test('should throw NetworkFailure when NetworkException occurs', () async {
      // Arrange
      fakeApiClient.nextException = const NetworkException(
        'No internet connection',
        code: 'NO_CONNECTION',
      );

      // Act & Assert
      expect(
        () => libraryRepository.fetchLibrary(),
        throwsA(isA<NetworkFailure>().having(
          (e) => e.code,
          'code',
          'NO_CONNECTION',
        )),
      );
    });

    test('should throw ServerFailure when ServerException occurs', () async {
      // Arrange
      fakeApiClient.nextException = const ServerException(
        'Internal server error',
        statusCode: 500,
        code: 'SERVER_ERROR',
      );

      // Act & Assert
      expect(
        () => libraryRepository.fetchLibrary(),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('getCachedLibrary', () {
    const testUserId = 'user_123';
    final testContent = Content(
      id: 1,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testLibraryItem = LibraryItem(
      content: testContent,
      purchaseDate: DateTime(2024, 1, 1),
      readingProgress: 0.5,
      currentPage: 50,
      lastOpened: DateTime(2024, 1, 15),
      isDownloaded: true,
      isFavorite: true,
    );

    test('should return cached library items', () async {
      // Arrange - first cache some items
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Act
      final result = await libraryRepository.getCachedLibrary(testUserId);

      // Assert
      expect(result, isA<List<LibraryItem>>());
      expect(result.length, equals(1));
      expect(result.first.content.id, equals(testContent.id));
      expect(result.first.isDownloaded, isTrue);
      expect(result.first.isFavorite, isTrue);
    });

    test('should return empty list when no cached items', () async {
      // Act
      final result = await libraryRepository.getCachedLibrary('unknown_user');

      // Assert
      expect(result, isEmpty);
    });

    test('should order items by last_opened DESC', () async {
      // Arrange - cache multiple items
      final item1 = LibraryItem(
        content: testContent.copyWith(id: 1),
        purchaseDate: DateTime(2024, 1, 1),
        readingProgress: 0.5,
        lastOpened: DateTime(2024, 1, 10),
        isDownloaded: false,
        isFavorite: false,
      );

      final item2 = LibraryItem(
        content: testContent.copyWith(id: 2),
        purchaseDate: DateTime(2024, 1, 1),
        readingProgress: 0.3,
        lastOpened: DateTime(2024, 1, 20),
        isDownloaded: false,
        isFavorite: false,
      );

      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [item1.toJson(), item2.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Act
      final result = await libraryRepository.getCachedLibrary(testUserId);

      // Assert - item2 should be first (more recent lastOpened)
      expect(result.length, equals(2));
      expect(result.first.content.id, equals(2));
      expect(result.last.content.id, equals(1));
    });
  });

  group('addToLibrary', () {
    const testContentId = 123;
    final testContent = Content(
      id: testContentId,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testLibraryItem = LibraryItem(
      content: testContent,
      purchaseDate: DateTime.now(),
      readingProgress: 0.0,
      isDownloaded: false,
      isFavorite: false,
    );

    test('should return LibraryItem when add is successful with status 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testLibraryItem.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act
      final result = await libraryRepository.addToLibrary(testContentId);

      // Assert
      expect(result, isA<LibraryItem>());
      expect(result.content.id, equals(testContentId));
      expect(fakeApiClient.lastPath, equals('${ApiConstants.library}/$testContentId'));
    });

    test('should return LibraryItem when add is successful with status 201', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testLibraryItem.toJson(),
        statusCode: 201,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act
      final result = await libraryRepository.addToLibrary(testContentId);

      // Assert
      expect(result, isA<LibraryItem>());
      expect(result.content.id, equals(testContentId));
    });

    test('should throw ServerFailure when response data is null', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act & Assert
      expect(
        () => libraryRepository.addToLibrary(testContentId),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });

    test('should throw NetworkFailure when NetworkException occurs', () async {
      // Arrange
      fakeApiClient.nextException = const NetworkException(
        'Connection timeout',
        code: 'TIMEOUT',
      );

      // Act & Assert
      expect(
        () => libraryRepository.addToLibrary(testContentId),
        throwsA(isA<NetworkFailure>().having(
          (e) => e.code,
          'code',
          'TIMEOUT',
        )),
      );
    });
  });

  group('removeFromLibrary', () {
    const testContentId = 123;

    test('should complete successfully when status is 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {},
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act & Assert
      await expectLater(
        libraryRepository.removeFromLibrary(testContentId),
        completes,
      );
      expect(fakeApiClient.lastPath, equals('${ApiConstants.library}/$testContentId'));
    });

    test('should complete successfully when status is 204', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 204,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act & Assert
      await expectLater(
        libraryRepository.removeFromLibrary(testContentId),
        completes,
      );
    });

    test('should throw ServerFailure when status is not 200 or 204', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 400,
        requestOptions: RequestOptions(path: '${ApiConstants.library}/$testContentId'),
      );

      // Act & Assert
      expect(
        () => libraryRepository.removeFromLibrary(testContentId),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });

    test('should throw NetworkFailure when NetworkException occurs', () async {
      // Arrange
      fakeApiClient.nextException = const NetworkException(
        'No connection',
        code: 'NO_CONNECTION',
      );

      // Act & Assert
      expect(
        () => libraryRepository.removeFromLibrary(testContentId),
        throwsA(isA<NetworkFailure>().having(
          (e) => e.code,
          'code',
          'NO_CONNECTION',
        )),
      );
    });
  });

  group('updateLibraryItemLocally', () {
    const testUserId = 'user_123';
    const testContentId = 1;
    final testContent = Content(
      id: testContentId,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testLibraryItem = LibraryItem(
      content: testContent,
      purchaseDate: DateTime(2024, 1, 1),
      readingProgress: 0.0,
      currentPage: 0,
      isDownloaded: false,
      isFavorite: false,
    );

    test('should update reading progress locally', () async {
      // Arrange - first cache an item
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Act
      await libraryRepository.updateLibraryItemLocally(
        contentId: testContentId,
        userId: testUserId,
        readingProgress: 0.75,
        currentPage: 75,
      );

      // Assert
      final cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems.first.readingProgress, equals(0.75));
      expect(cachedItems.first.currentPage, equals(75));
    });

    test('should update download status locally', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Act
      await libraryRepository.updateLibraryItemLocally(
        contentId: testContentId,
        userId: testUserId,
        isDownloaded: true,
      );

      // Assert
      final cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems.first.isDownloaded, isTrue);
    });

    test('should update favorite status locally', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Act
      await libraryRepository.updateLibraryItemLocally(
        contentId: testContentId,
        userId: testUserId,
        isFavorite: true,
      );

      // Assert
      final cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems.first.isFavorite, isTrue);
    });

    test('should update last opened timestamp locally', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      final newLastOpened = DateTime(2024, 2, 1);

      // Act
      await libraryRepository.updateLibraryItemLocally(
        contentId: testContentId,
        userId: testUserId,
        lastOpened: newLastOpened,
      );

      // Assert
      final cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(
        cachedItems.first.lastOpened?.millisecondsSinceEpoch,
        equals(newLastOpened.millisecondsSinceEpoch),
      );
    });
  });

  group('syncLocalChanges', () {
    const testUserId = 'user_123';

    test('should return true when sync is successful', () async {
      // Act
      final result = await libraryRepository.syncLocalChanges(testUserId);

      // Assert
      expect(result, isTrue);
    });

    test('should return false when sync fails', () async {
      // Arrange
      fakeDatabase.nextException = Exception('Database error');

      // Act
      final result = await libraryRepository.syncLocalChanges(testUserId);

      // Assert
      expect(result, isFalse);
    });
  });

  group('clearCache', () {
    const testUserId = 'user_123';
    final testContent = Content(
      id: 1,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testLibraryItem = LibraryItem(
      content: testContent,
      purchaseDate: DateTime(2024, 1, 1),
      readingProgress: 0.5,
      isDownloaded: false,
      isFavorite: false,
    );

    test('should clear cached library for user', () async {
      // Arrange - first cache some items
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {
          'items': [testLibraryItem.toJson()],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.library),
      );

      await libraryRepository.fetchLibrary(userId: testUserId);

      // Verify items are cached
      var cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems.length, equals(1));

      // Act
      await libraryRepository.clearCache(testUserId);

      // Assert
      cachedItems = await libraryRepository.getCachedLibrary(testUserId);
      expect(cachedItems, isEmpty);
    });
  });
}
