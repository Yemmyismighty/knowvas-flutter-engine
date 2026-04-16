import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/collection.dart';

/// Repository for collection operations
/// Handles fetching, creating, updating, and managing collections
class CollectionRepository {
  CollectionRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetch all collections for the current user
  /// Returns list of collections
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<List<Collection>> fetchCollections() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.collections,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final collections = (data['collections'] as List<dynamic>?)
                ?.map((item) => Collection.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];

        return collections;
      } else {
        throw const ServerFailure(
          'Failed to fetch collections',
          code: 'FETCH_COLLECTIONS_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching collections: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get a specific collection by ID
  /// Returns collection with items
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<Collection> getCollection(int collectionId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.collections}/$collectionId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Collection.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to fetch collection',
          code: 'FETCH_COLLECTION_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Create a new collection
  /// Returns the created collection
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<Collection> createCollection(CreateCollectionRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.collections,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return Collection.fromJson(response.data!);
        }
      }

      throw const ServerFailure(
        'Failed to create collection',
        code: 'CREATE_COLLECTION_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while creating collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Update an existing collection
  /// Returns the updated collection
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<Collection> updateCollection(
    int collectionId,
    UpdateCollectionRequest request,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.collections}/$collectionId',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Collection.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to update collection',
          code: 'UPDATE_COLLECTION_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while updating collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Delete a collection
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> deleteCollection(int collectionId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConstants.collections}/$collectionId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ServerFailure(
          'Failed to delete collection',
          code: 'DELETE_COLLECTION_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while deleting collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Add content to a collection
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> addContentToCollection(int collectionId, int contentId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.collections}/$collectionId/items',
        data: {'content_id': contentId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ServerFailure(
          'Failed to add content to collection',
          code: 'ADD_TO_COLLECTION_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while adding content to collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Remove content from a collection
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> removeContentFromCollection(
    int collectionId,
    int contentId,
  ) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConstants.collections}/$collectionId/items/$contentId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ServerFailure(
          'Failed to remove content from collection',
          code: 'REMOVE_FROM_COLLECTION_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while removing content from collection: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
