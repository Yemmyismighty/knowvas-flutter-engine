import 'package:equatable/equatable.dart';

import '../../../../shared/models/content.dart';

/// Discover page state
class DiscoverState extends Equatable {
  const DiscoverState({
    this.discoverResponse,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.autocompleteResults = const [],
    this.searchResults,
    this.searchAuthors,
    this.categories,
  });

  /// Initial loading state
  factory DiscoverState.initial() {
    return const DiscoverState(
      isLoading: true,
    );
  }

  /// Loaded state with discover content
  factory DiscoverState.loaded(DiscoverResponse discoverResponse) {
    return DiscoverState(
      discoverResponse: discoverResponse,
      isInitialized: true,
    );
  }

  /// Error state
  factory DiscoverState.error(String error) {
    return DiscoverState(
      error: error,
      isInitialized: true,
    );
  }

  final DiscoverResponse? discoverResponse;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final List<Map<String, dynamic>> autocompleteResults;
  final List<dynamic>? searchResults;
  final List<Map<String, dynamic>>? searchAuthors;
  final List<Map<String, dynamic>>? categories;

  /// Loading state
  DiscoverState copyWithLoading() {
    return DiscoverState(
      discoverResponse: discoverResponse,
      isLoading: true,
      isInitialized: isInitialized,
    );
  }

  /// Error state
  DiscoverState copyWithError(String error) {
    return DiscoverState(
      discoverResponse: discoverResponse,
      error: error,
      isInitialized: isInitialized,
    );
  }

  /// Copy with new values
  DiscoverState copyWith({
    DiscoverResponse? discoverResponse,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    List<Map<String, dynamic>>? autocompleteResults,
    List<dynamic>? searchResults,
    List<Map<String, dynamic>>? searchAuthors,
    List<Map<String, dynamic>>? categories,
  }) {
    return DiscoverState(
      discoverResponse: discoverResponse ?? this.discoverResponse,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      autocompleteResults: autocompleteResults ?? this.autocompleteResults,
      searchResults: searchResults,
      searchAuthors: searchAuthors,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [
        discoverResponse,
        isLoading,
        error,
        isInitialized,
        autocompleteResults,
        searchResults,
        searchAuthors,
        categories,
      ];
}