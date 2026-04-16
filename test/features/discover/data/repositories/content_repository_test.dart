import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/core/errors/exceptions.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/core/network/network_info.dart';
import 'package:knowvas/features/discover/data/repositories/content_repository.dart';
import 'package:knowvas/shared/models/content.dart';
import 'package:knowvas/shared/models/content_detail.dart';
import 'package:knowvas/shared/models/download_request.dart';
import 'package:knowvas/shared/models/search_filters.dart';

// Fake implementations for testing
class FakeApiClient implements ApiClient {
  Response<Map<String, dynamic>>? nextResponse;
  Exception? nextException;
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;

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
    lastQueryParameters = queryParameters;

    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNetworkInfo implements NetworkInfo {
  bool _isConnected = true;

  void setConnected(bool connected) {
    _isConnected = connected;
  }

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ContentRepository contentRepository;
  late FakeApiClient fakeApiClient;
  late FakeNetworkInfo fakeNetworkInfo;

  setUp(() {
    fakeApiClient = FakeApiClient();
    fakeNetworkInfo = FakeNetworkInfo();
    contentRepository = ContentRepository(
      apiClient: fakeApiClient,
      networkInfo: fakeNetworkInfo,
    );
  });

  group('getContentDetail', () {
    const testContentId = 123;
    final testContent = Content(
      id: testContentId,
      type: 'ebook',
      title: 'Test Book',
      authorName: 'Test Author',
      authorId: 1,
      description: 'Test description',
      coverUrl: 'https://example.com/cover.jpg',
      price: {'USD': 9.99, 'NGN': 5000.0},
      isFree: false,
      purchaseOnly: false,
      premiumOnly: false,
      ratingAverage: 4.5,
      ratingCount: 100,
      genres: ['Fiction'],
    );

    final testContentDetail = ContentDetail(
      content: testContent,
      similarContent: [],
      reviews: [],
    );

    test('should return ContentDetail when fetch is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      // Act
      final result = await contentRepository.getContentDetail(testContentId);

      // Assert
      expect(result, equals(testContentDetail));
      expect(fakeApiClient.lastPath, equals('${ApiConstants.content}/$testContentId'));
    });

    test('should cache ContentDetail after successful fetch', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      // Act
      await contentRepository.getContentDetail(testContentId);
      
      // Second call should use cache (no API call)
      fakeApiClient.nextResponse = null;
      final cachedResult = await contentRepository.getContentDetail(testContentId);

      // Assert
      expect(cachedResult, equals(testContentDetail));
    });

    test('should return cached data when offline and cache exists', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      // First fetch to populate cache
      await contentRepository.getContentDetail(testContentId);

      // Go offline
      fakeNetworkInfo.setConnected(false);

      // Act
      final result = await contentRepository.getContentDetail(testContentId);

      // Assert
      expect(result, equals(testContentDetail));
    });

    test('should throw NetworkFailure when offline and no cache exists', () async {
      // Arrange
      fakeNetworkInfo.setConnected(false);

      // Act & Assert
      expect(
        () => contentRepository.getContentDetail(testContentId),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('should throw ContentFailure when response status is not 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 404,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      // Act & Assert
      expect(
        () => contentRepository.getContentDetail(testContentId),
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
        () => contentRepository.getContentDetail(testContentId),
        throwsA(isA<NetworkFailure>().having(
          (e) => e.code,
          'code',
          'TIMEOUT',
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
        () => contentRepository.getContentDetail(testContentId),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('searchContent', () {
    final testFilters = SearchFilters(
      query: 'test',
      genres: ['Fiction'],
      minPrice: 0,
      maxPrice: 20,
    );

    final testSearchResponse = SearchResponse(
      results: [
        Content(
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
          ratingCount: 50,
          genres: ['Fiction'],
        ),
      ],
      totalCount: 1,
      page: 1,
      pageSize: 20,
    );

    test('should return SearchResponse when search is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testSearchResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.search),
      );

      // Act
      final result = await contentRepository.searchContent(testFilters);

      // Assert
      expect(result, equals(testSearchResponse));
      expect(fakeApiClient.lastPath, equals(ApiConstants.search));
      expect(fakeApiClient.lastQueryParameters, equals(testFilters.toJson()));
    });

    test('should throw NetworkFailure when offline', () async {
      // Arrange
      fakeNetworkInfo.setConnected(false);

      // Act & Assert
      expect(
        () => contentRepository.searchContent(testFilters),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('should throw ContentFailure when search fails', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 400,
        requestOptions: RequestOptions(path: ApiConstants.search),
      );

      // Act & Assert
      expect(
        () => contentRepository.searchContent(testFilters),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });
  });

  group('getDiscoverContent', () {
    final testDiscoverContent = DiscoverContent(
      featured: [
        Content(
          id: 1,
          type: 'ebook',
          title: 'Featured Book',
          authorName: 'Author',
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
        ),
      ],
      bestsellers: [],
      newReleases: [],
      trending: [],
    );

    test('should return DiscoverContent when fetch is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDiscoverContent.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      // Act
      final result = await contentRepository.getDiscoverContent();

      // Assert
      expect(result, isA<DiscoverContent>());
      expect(result.featured.length, equals(testDiscoverContent.featured.length));
      expect(fakeApiClient.lastPath, equals(ApiConstants.discover));
    });

    test('should cache DiscoverContent after successful fetch', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDiscoverContent.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      // Act
      await contentRepository.getDiscoverContent();
      
      // Second call should use cache
      fakeApiClient.nextResponse = null;
      final cachedResult = await contentRepository.getDiscoverContent();

      // Assert
      expect(cachedResult, isA<DiscoverContent>());
      expect(cachedResult.featured.length, equals(testDiscoverContent.featured.length));
    });

    test('should return cached data when offline and cache exists', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDiscoverContent.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      // First fetch to populate cache
      await contentRepository.getDiscoverContent();

      // Go offline
      fakeNetworkInfo.setConnected(false);

      // Act
      final result = await contentRepository.getDiscoverContent();

      // Assert
      expect(result, isA<DiscoverContent>());
      expect(result.featured.length, equals(testDiscoverContent.featured.length));
    });

    test('should throw NetworkFailure when offline and no cache exists', () async {
      // Arrange
      fakeNetworkInfo.setConnected(false);

      // Act & Assert
      expect(
        () => contentRepository.getDiscoverContent(),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('should throw ContentFailure when fetch fails', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 500,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      // Act & Assert
      expect(
        () => contentRepository.getDiscoverContent(),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });
  });

  group('getSignedDownloadUrl', () {
    const testContentId = 123;
    const testQuality = 'high';
    final testDownloadResponse = DownloadResponse(
      signedUrl: 'https://example.com/download/signed-url',
      fileHash: 'abc123hash',
      fileSize: 1024000,
      expiresIn: 3600,
    );

    test('should return DownloadResponse when request is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDownloadResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.downloadRequest),
      );

      // Act
      final result = await contentRepository.getSignedDownloadUrl(
        contentId: testContentId,
        quality: testQuality,
      );

      // Assert
      expect(result, equals(testDownloadResponse));
      expect(fakeApiClient.lastPath, equals(ApiConstants.downloadRequest));
      expect(fakeApiClient.lastData, equals({
        'content_id': testContentId,
        'quality': testQuality,
      }));
    });

    test('should use default quality when not specified', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDownloadResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.downloadRequest),
      );

      // Act
      await contentRepository.getSignedDownloadUrl(contentId: testContentId);

      // Assert
      expect(fakeApiClient.lastData, equals({
        'content_id': testContentId,
        'quality': 'standard',
      }));
    });

    test('should throw NetworkFailure when offline', () async {
      // Arrange
      fakeNetworkInfo.setConnected(false);

      // Act & Assert
      expect(
        () => contentRepository.getSignedDownloadUrl(contentId: testContentId),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('should throw ContentFailure when request fails', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 403,
        requestOptions: RequestOptions(path: ApiConstants.downloadRequest),
      );

      // Act & Assert
      expect(
        () => contentRepository.getSignedDownloadUrl(contentId: testContentId),
        throwsA(isA<Failure>().having(
          (e) => e.message,
          'message',
          contains('unexpected error'),
        )),
      );
    });
  });

  group('cache management', () {
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

    final testContentDetail = ContentDetail(
      content: testContent,
      similarContent: [],
      reviews: [],
    );

    test('clearCache should clear all cached data', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      await contentRepository.getContentDetail(testContentId);

      // Act
      contentRepository.clearCache();

      // Assert - should fetch from API again
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      await contentRepository.getContentDetail(testContentId);
      expect(fakeApiClient.lastPath, equals('${ApiConstants.content}/$testContentId'));
    });

    test('clearContentDetailCache should clear specific content cache', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      await contentRepository.getContentDetail(testContentId);

      // Act
      contentRepository.clearContentDetailCache(testContentId);

      // Assert - should fetch from API again
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testContentDetail.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '${ApiConstants.content}/$testContentId'),
      );

      await contentRepository.getContentDetail(testContentId);
      expect(fakeApiClient.lastPath, equals('${ApiConstants.content}/$testContentId'));
    });

    test('clearDiscoverCache should clear discover content cache', () async {
      // Arrange
      final testDiscoverContent = DiscoverContent(
        featured: [testContent],
        bestsellers: [],
        newReleases: [],
        trending: [],
      );

      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDiscoverContent.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      await contentRepository.getDiscoverContent();

      // Act
      contentRepository.clearDiscoverCache();

      // Assert - should fetch from API again
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testDiscoverContent.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.discover),
      );

      await contentRepository.getDiscoverContent();
      expect(fakeApiClient.lastPath, equals(ApiConstants.discover));
    });
  });
}
