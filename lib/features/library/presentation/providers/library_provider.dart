import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/library_item.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/library_repository_provider.dart';

/// Library state
class LibraryState {
  final List<LibraryItem> currentlyReading;
  final List<LibraryItem> purchased;
  final List<LibraryItem> recentlyViewed;
  final List<LibraryItem> finished;
  final List<LibraryItem> favorites;
  final ReadingStats stats;
  final bool isLoading;
  final String? error;

  const LibraryState({
    required this.currentlyReading,
    required this.purchased,
    required this.recentlyViewed,
    required this.finished,
    required this.favorites,
    required this.stats,
    required this.isLoading,
    this.error,
  });

  factory LibraryState.initial() {
    return const LibraryState(
      currentlyReading: [],
      purchased: [],
      recentlyViewed: [],
      finished: [],
      favorites: [],
      stats: ReadingStats(
        totalBooksRead: 0,
        currentStreak: 0,
        booksThisMonth: 0,
        totalReadingTime: 0,
        currentlyReadingCount: 0,
      ),
      isLoading: true,
      error: null,
    );
  }

  LibraryState copyWith({
    List<LibraryItem>? currentlyReading,
    List<LibraryItem>? purchased,
    List<LibraryItem>? recentlyViewed,
    List<LibraryItem>? finished,
    List<LibraryItem>? favorites,
    ReadingStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      currentlyReading: currentlyReading ?? this.currentlyReading,
      purchased: purchased ?? this.purchased,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      finished: finished ?? this.finished,
      favorites: favorites ?? this.favorites,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Filter items by search query
  List<LibraryItem> filterItems(List<LibraryItem> items, String query) {
    if (query.trim().isEmpty) return items;
    
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.author.toLowerCase().contains(lowerQuery) ||
          (item.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

/// Library notifier
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._repository) : super(LibraryState.initial()) {
    loadLibrary();
  }

  final LibraryRepository _repository;

  /// Load all library data
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getLibrary();
      
      state = LibraryState(
        currentlyReading: response.currentlyReading,
        purchased: response.purchased,
        recentlyViewed: response.recentlyViewed,
        finished: response.finished,
        favorites: response.favorites,
        stats: response.stats,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh library data
  Future<void> refresh() async {
    await loadLibrary();
  }

  /// Load currently reading books
  Future<void> loadCurrentlyReading() async {
    try {
      final items = await _repository.getCurrentlyReading();
      state = state.copyWith(currentlyReading: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load purchased books
  Future<void> loadPurchased() async {
    try {
      final items = await _repository.getPurchased();
      state = state.copyWith(purchased: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load recently viewed books
  Future<void> loadRecentlyViewed() async {
    try {
      final items = await _repository.getRecentlyViewed();
      state = state.copyWith(recentlyViewed: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load finished books
  Future<void> loadFinished() async {
    try {
      final items = await _repository.getFinished();
      state = state.copyWith(finished: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load favorite books
  Future<void> loadFavorites() async {
    try {
      final items = await _repository.getFavorites();
      state = state.copyWith(favorites: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load reading stats
  Future<void> loadStats() async {
    try {
      final stats = await _repository.getReadingStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a library item's local state (progress, favorite, downloaded)
  Future<void> updateItem({
    required int contentId,
    double? readingProgress,
    int? currentPage,
    DateTime? lastOpened,
    bool? isFavorite,
    bool? isDownloaded,
  }) async {
    // Update in all lists
    List<LibraryItem> _updateList(List<LibraryItem> items) {
      return items.map((item) {
        if (item.id != contentId) return item;
        return LibraryItem(
          id: item.id,
          title: item.title,
          author: item.author,
          cover: item.cover,
          type: item.type,
          progress: readingProgress ?? item.progress,
          currentPage: currentPage ?? item.currentPage,
          totalPages: item.totalPages,
          lastReadAt: lastOpened?.toIso8601String() ?? item.lastReadAt,
          isFavorite: isFavorite ?? item.isFavorite,
          isPurchased: item.isPurchased,
          isFinished: item.isFinished,
          rating: item.rating,
          reviewCount: item.reviewCount,
          description: item.description,
          categories: item.categories,
        );
      }).toList();
    }

    state = state.copyWith(
      currentlyReading: _updateList(state.currentlyReading),
      purchased: _updateList(state.purchased),
      recentlyViewed: _updateList(state.recentlyViewed),
      finished: _updateList(state.finished),
      favorites: _updateList(state.favorites),
    );
  }

  /// Remove an item from the library
  Future<void> removeFromLibrary(int contentId) async {
    List<LibraryItem> _removeFrom(List<LibraryItem> items) =>
        items.where((item) => item.id != contentId).toList();

    state = state.copyWith(
      currentlyReading: _removeFrom(state.currentlyReading),
      purchased: _removeFrom(state.purchased),
      recentlyViewed: _removeFrom(state.recentlyViewed),
      finished: _removeFrom(state.finished),
      favorites: _removeFrom(state.favorites),
    );
  }
}

/// Library provider
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return LibraryNotifier(repository);
});
