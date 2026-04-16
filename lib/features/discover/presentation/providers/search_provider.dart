import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/search_filters.dart' as shared;
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/content_repository_provider.dart';

part 'search_provider.g.dart';

/// Search state
class SearchState {
  const SearchState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  final SearchResponse? response;
  final bool isLoading;
  final String? error;

  SearchState copyWith({
    SearchResponse? response,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  SearchState copyWithLoading() {
    return SearchState(
      response: response,
      isLoading: true,
    );
  }

  SearchState copyWithError(String error) {
    return SearchState(
      response: response,
      error: error,
    );
  }
}

/// Search provider
/// Manages search functionality with filters and sorting
@riverpod
class Search extends _$Search {
  @override
  SearchState build() {
    return const SearchState();
  }

  /// Perform search with filters
  Future<void> search(shared.SearchFilters filters) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read(contentRepositoryProvider);
      final response = await repository.searchContent(
        query: filters.query,
        type: filters.types.isNotEmpty ? filters.types.first : null,
        genre: filters.genres.isNotEmpty ? filters.genres.first : null,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        sort: filters.sortBy,
        page: filters.page,
        limit: filters.pageSize,
      );

      state = SearchState(
        response: response,
      );
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Clear search results
  void clear() {
    state = const SearchState();
  }
}
