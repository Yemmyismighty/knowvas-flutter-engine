import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/features/curated/data/repositories/curated_repository.dart';
import 'package:knowvas/features/curated/data/repositories/curated_repository_provider.dart';
import 'package:knowvas/shared/models/curated_models.dart';

class CuratedState {
  final List<CuratedContent> contents;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  CuratedState({
    this.contents = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  CuratedState copyWith({
    List<CuratedContent>? contents,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return CuratedState(
      contents: contents ?? this.contents,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CuratedNotifier extends StateNotifier<CuratedState> {
  final CuratedRepository _repository;
  String _currentEndpoint = '';

  CuratedNotifier(this._repository) : super(CuratedState());

  Future<void> loadContent(String endpoint) async {
    if (_currentEndpoint != endpoint) {
      _currentEndpoint = endpoint;
      state = CuratedState(isLoading: true);
    } else if (state.isLoading) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _repository.getCuratedContent(endpoint, page: 1);
      
      state = state.copyWith(
        contents: result['contents'],
        hasMore: result['hasMore'],
        isLoading: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    try {
      state = state.copyWith(isLoadingMore: true);
      final nextPage = state.currentPage + 1;
      final result = await _repository.getCuratedContent(
        _currentEndpoint,
        page: nextPage,
      );

      state = state.copyWith(
        contents: [...state.contents, ...result['contents']],
        hasMore: result['hasMore'],
        isLoadingMore: false,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateWishlist(int contentId, bool isWishlisted, int userId) {
    state = state.copyWith(
      contents: state.contents.map((content) {
        if (content.id == contentId) {
          final updatedWishlists = isWishlisted
              ? [
                  ...content.wishlists,
                  Wishlist(
                    userId: userId,
                    resourceId: contentId,
                    resourceType: content.type,
                  ),
                ]
              : content.wishlists
                  .where((w) => w.userId != userId)
                  .toList();

          return CuratedContent(
            id: content.id,
            title: content.title,
            authorName: content.authorName,
            cover: content.cover,
            price: content.price,
            isFree: content.isFree,
            premiumOnly: content.premiumOnly,
            averageRating: content.averageRating,
            reviews: content.reviews,
            type: content.type,
            description: content.description,
            wishlists: updatedWishlists,
          );
        }
        return content;
      }).toList(),
    );
  }
}

final curatedProvider =
    StateNotifierProvider<CuratedNotifier, CuratedState>((ref) {
  final repository = ref.watch(curatedRepositoryProvider);
  return CuratedNotifier(repository);
});

