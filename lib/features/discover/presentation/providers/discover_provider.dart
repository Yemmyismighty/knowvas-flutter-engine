import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/content.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/content_repository_provider.dart';
import 'discover_state.dart';

part 'discover_provider.g.dart';

/// DiscoverNotifier manages discover page state
/// Handles fetching curated content categories
@riverpod
class Discover extends _$Discover {
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 10);

  @override
  DiscoverState build() {
    // Keep the provider alive (don't auto-dispose)
    ref.keepAlive();
    
    // Auto-fetch content when provider is first created
    Future.microtask(() {
      fetchDiscoverContent();
      fetchCategories();
    });
    return DiscoverState.initial();
  }

  /// Fetch discover page content
  /// Updates state with curated content categories
  /// Uses cache if data was fetched recently
  Future<void> fetchDiscoverContent({String? category, bool forceRefresh = false}) async {
    // Check if we have cached data and it's still fresh
    if (!forceRefresh && 
        state.discoverResponse != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      // Data is still fresh, no need to refetch
      return;
    }

    // Only show loading if we don't have any data
    if (state.discoverResponse == null) {
      state = state.copyWithLoading();
    }

    try {
      final repository = ref.read<ContentRepository>(contentRepositoryProvider);
      final discoverResponse = await repository.getDiscoverContent(
        category: category,
        limit: 12,
      );

      _lastFetchTime = DateTime.now();
      state = DiscoverState.loaded(discoverResponse);
    } on NetworkFailure catch (e) {
      // Keep existing data if we have it, just show error
      if (state.discoverResponse != null) {
        state = state.copyWith(error: e.message);
      } else {
        state = state.copyWithError(e.message);
      }
    } on ServerFailure catch (e) {
      if (state.discoverResponse != null) {
        state = state.copyWith(error: e.message);
      } else {
        state = state.copyWithError(e.message);
      }
    } catch (e) {
      if (state.discoverResponse != null) {
        state = state.copyWith(error: 'An unexpected error occurred: $e');
      } else {
        state = state.copyWithError('An unexpected error occurred: $e');
      }
    }
  }

  /// Refresh discover content (force refresh)
  Future<void> refresh() async {
    await fetchDiscoverContent(forceRefresh: true);
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Invalidate cache and refetch
  void invalidateCache() {
    _lastFetchTime = null;
    fetchDiscoverContent(forceRefresh: true);
  }

  /// Fetch autocomplete suggestions
  Future<void> fetchAutocomplete(String query) async {
    if (query.length < 2) {
      state = state.copyWith(autocompleteResults: []);
      return;
    }

    try {
      final repository = ref.read<ContentRepository>(contentRepositoryProvider);
      final results = await repository.getAutocomplete(query);
      state = state.copyWith(autocompleteResults: results);
    } catch (e) {
      // Silently fail for autocomplete
      state = state.copyWith(autocompleteResults: []);
    }
  }

  /// Search for content and authors
  Future<void> search({
    required String query,
    String? sortBy,
    String? genre,
    int page = 1,
  }) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read<ContentRepository>(contentRepositoryProvider);
      
      // Search for content using the new method
      final searchResults = await repository.searchContentDiscover(
        query: query,
        sortBy: sortBy,
        genre: genre,
        page: page,
      );

      // Search for authors (only on first page)
      List<Map<String, dynamic>>? authors;
      if (page == 1) {
        authors = await repository.searchAuthors(query);
      }

      state = state.copyWith(
        isLoading: false,
        searchResults: searchResults,
        searchAuthors: authors,
      );
    } catch (e) {
      state = state.copyWithError('Search failed: $e');
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(
      searchResults: null,
      searchAuthors: null,
    );
  }

  /// Fetch categories
  Future<void> fetchCategories() async {
    try {
      final repository = ref.read<ContentRepository>(contentRepositoryProvider);
      final categories = await repository.getCategories();
      state = state.copyWith(categories: categories);
    } catch (e) {
      // Silently fail for categories
    }
  }

  /// Update filters and refetch content
  Future<void> updateFilters({
    String? sortBy,
    String? genre,
  }) async {
    await fetchDiscoverContent(forceRefresh: true);
  }
}