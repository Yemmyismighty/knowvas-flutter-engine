import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/collection.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/collection_repository_provider.dart';
import 'collection_state.dart';

part 'collection_provider.g.dart';

/// CollectionNotifier manages collection state
/// Handles fetching, creating, updating, and deleting collections
@riverpod
class Collections extends _$Collections {
  @override
  CollectionState build() {
    // Initialize by loading collections
    _initializeCollections();
    return CollectionState.initial();
  }

  /// Initialize collections state
  Future<void> _initializeCollections() async {
    try {
      await refresh();
    } catch (e) {
      state = CollectionState.error('Failed to initialize collections: $e');
    }
  }

  /// Fetch collections from backend
  Future<void> refresh() async {
    // Only show loading if we don't have collections yet
    if (state.collections.isEmpty) {
      state = state.copyWithLoading();
    }

    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      final collections = await repository.fetchCollections();

      state = state.copyWith(
        collections: collections,
        isLoading: false,
        isInitialized: true,
      );
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Create a new collection
  Future<Collection?> createCollection(CreateCollectionRequest request) async {
    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      final newCollection = await repository.createCollection(request);

      // Add to current collections
      final updatedCollections = [...state.collections, newCollection];

      state = state.copyWith(
        collections: updatedCollections,
      );

      return newCollection;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      return null;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      return null;
    } catch (e) {
      state = state.copyWithError('Failed to create collection: $e');
      return null;
    }
  }

  /// Update an existing collection
  Future<bool> updateCollection(
    int collectionId,
    UpdateCollectionRequest request,
  ) async {
    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      final updatedCollection = await repository.updateCollection(
        collectionId,
        request,
      );

      // Update in current collections
      final updatedCollections = state.collections.map((collection) {
        if (collection.id == collectionId) {
          return updatedCollection;
        }
        return collection;
      }).toList();

      state = state.copyWith(
        collections: updatedCollections,
      );

      return true;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } catch (e) {
      state = state.copyWithError('Failed to update collection: $e');
      return false;
    }
  }

  /// Delete a collection
  Future<bool> deleteCollection(int collectionId) async {
    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      await repository.deleteCollection(collectionId);

      // Remove from current collections
      final updatedCollections = state.collections
          .where((collection) => collection.id != collectionId)
          .toList();

      state = state.copyWith(
        collections: updatedCollections,
      );

      return true;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } catch (e) {
      state = state.copyWithError('Failed to delete collection: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }

  /// Get collections
  List<Collection> get collections => state.collections;

  /// Check if collections is empty
  bool get isEmpty => state.collections.isEmpty;

  /// Check if collections is loading
  bool get isLoading => state.isLoading;
}

/// CollectionDetailNotifier manages a single collection's detail state
@riverpod
class CollectionDetail extends _$CollectionDetail {
  @override
  CollectionDetailState build(int collectionId) {
    // Initialize by loading collection
    _initializeCollection(collectionId);
    return CollectionDetailState.initial();
  }

  /// Initialize collection detail state
  Future<void> _initializeCollection(int collectionId) async {
    try {
      await refresh(collectionId);
    } catch (e) {
      state = CollectionDetailState.error('Failed to initialize collection: $e');
    }
  }

  /// Fetch collection from backend
  Future<void> refresh(int collectionId) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      final collection = await repository.getCollection(collectionId);

      state = state.copyWith(
        collection: collection,
        isLoading: false,
      );
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Add content to collection
  Future<bool> addContent(int collectionId, int contentId) async {
    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      await repository.addContentToCollection(collectionId, contentId);

      // Refresh collection to get updated items
      await refresh(collectionId);

      return true;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } catch (e) {
      state = state.copyWithError('Failed to add content to collection: $e');
      return false;
    }
  }

  /// Remove content from collection
  Future<bool> removeContent(int collectionId, int contentId) async {
    try {
      final repository = ref.read<CollectionRepository>(collectionRepositoryProvider);
      await repository.removeContentFromCollection(collectionId, contentId);

      // Refresh collection to get updated items
      await refresh(collectionId);

      return true;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      return false;
    } catch (e) {
      state = state.copyWithError('Failed to remove content from collection: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }
}
