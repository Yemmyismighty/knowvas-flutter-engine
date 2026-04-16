import 'package:equatable/equatable.dart';

import '../../../../shared/models/collection.dart';

/// Collection state
class CollectionState extends Equatable {
  const CollectionState({
    this.collections = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  /// Initial state
  factory CollectionState.initial() {
    return const CollectionState(
      isLoading: true,
    );
  }

  /// Loaded state with collections
  factory CollectionState.loaded(List<Collection> collections) {
    return CollectionState(
      collections: collections,
      isInitialized: true,
    );
  }

  /// Error state
  factory CollectionState.error(String error) {
    return CollectionState(
      error: error,
      isInitialized: true,
    );
  }

  final List<Collection> collections;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  /// Loading state
  CollectionState copyWithLoading() {
    return CollectionState(
      collections: collections,
      isLoading: true,
      isInitialized: isInitialized,
    );
  }

  /// Error state
  CollectionState copyWithError(String error) {
    return CollectionState(
      collections: collections,
      error: error,
      isInitialized: isInitialized,
    );
  }

  /// Copy with new values
  CollectionState copyWith({
    List<Collection>? collections,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return CollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [
        collections,
        isLoading,
        error,
        isInitialized,
      ];
}

/// Collection detail state
class CollectionDetailState extends Equatable {
  const CollectionDetailState({
    this.collection,
    this.isLoading = false,
    this.error,
  });

  /// Initial state
  factory CollectionDetailState.initial() {
    return const CollectionDetailState(
      isLoading: true,
    );
  }

  /// Loaded state with collection
  factory CollectionDetailState.loaded(Collection collection) {
    return CollectionDetailState(
      collection: collection,
    );
  }

  /// Error state
  factory CollectionDetailState.error(String error) {
    return CollectionDetailState(
      error: error,
    );
  }

  final Collection? collection;
  final bool isLoading;
  final String? error;

  /// Loading state
  CollectionDetailState copyWithLoading() {
    return CollectionDetailState(
      collection: collection,
      isLoading: true,
    );
  }

  /// Error state
  CollectionDetailState copyWithError(String error) {
    return CollectionDetailState(
      collection: collection,
      error: error,
    );
  }

  /// Copy with new values
  CollectionDetailState copyWith({
    Collection? collection,
    bool? isLoading,
    String? error,
  }) {
    return CollectionDetailState(
      collection: collection ?? this.collection,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        collection,
        isLoading,
        error,
      ];
}
