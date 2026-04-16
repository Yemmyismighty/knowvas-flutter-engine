import 'package:equatable/equatable.dart';

import '../../../../shared/models/library_item.dart';

/// Library state
class LibraryState extends Equatable {
  const LibraryState({
    this.items = const [],
    this.filteredItems = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.filter = LibraryFilter.all,
    this.sortBy = LibrarySortBy.recent,
  });

  /// Initial state
  factory LibraryState.initial() {
    return const LibraryState(
      isLoading: true,
    );
  }

  /// Loaded state with items
  factory LibraryState.loaded(List<LibraryItem> items) {
    return LibraryState(
      items: items,
      filteredItems: items,
      isInitialized: true,
    );
  }

  /// Error state
  factory LibraryState.error(String error) {
    return LibraryState(
      error: error,
      isInitialized: true,
    );
  }

  final List<LibraryItem> items;
  final List<LibraryItem> filteredItems;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final LibraryFilter filter;
  final LibrarySortBy sortBy;

  /// Loading state
  LibraryState copyWithLoading() {
    return LibraryState(
      items: items,
      filteredItems: filteredItems,
      isLoading: true,
      isInitialized: isInitialized,
      filter: filter,
      sortBy: sortBy,
    );
  }

  /// Error state
  LibraryState copyWithError(String error) {
    return LibraryState(
      items: items,
      filteredItems: filteredItems,
      error: error,
      isInitialized: isInitialized,
      filter: filter,
      sortBy: sortBy,
    );
  }

  /// Copy with new values
  LibraryState copyWith({
    List<LibraryItem>? items,
    List<LibraryItem>? filteredItems,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    LibraryFilter? filter,
    LibrarySortBy? sortBy,
  }) {
    return LibraryState(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        items,
        filteredItems,
        isLoading,
        error,
        isInitialized,
        filter,
        sortBy,
      ];
}

/// Library filter options
enum LibraryFilter {
  all,
  ebooks,
  comics,
  magazines,
  audiobooks,
  downloaded,
  favorites,
}

/// Library sort options
enum LibrarySortBy {
  recent,
  title,
  author,
  progress,
  dateAdded,
}
