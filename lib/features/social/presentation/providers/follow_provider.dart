import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/follow_repository.dart';
import '../../data/repositories/follow_repository_provider.dart';

part 'follow_provider.g.dart';

/// Provider for following list
@riverpod
class Following extends _$Following {
  @override
  Future<FollowingList> build() async {
    final repository = ref.watch(followRepositoryProvider);
    return repository.getFollowing();
  }

  /// Refresh following list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(followRepositoryProvider);
      return repository.getFollowing(forceRefresh: true);
    });
  }

  /// Load more following (pagination)
  Future<void> loadMore(int page) async {
    final repository = ref.read(followRepositoryProvider);
    final newData = await repository.getFollowing(page: page);
    
    state.whenData((currentData) {
      state = AsyncValue.data(
        FollowingList(
          authors: [...currentData.authors, ...newData.authors],
          users: [...currentData.users, ...newData.users],
          totalCount: newData.totalCount,
          currentPage: newData.currentPage,
          totalPages: newData.totalPages,
        ),
      );
    });
  }

  /// Unfollow an author
  Future<void> unfollowAuthor(int authorId) async {
    final repository = ref.read(followRepositoryProvider);
    await repository.unfollowAuthor(authorId);
    
    // Update local state by removing the author
    state.whenData((currentData) {
      state = AsyncValue.data(
        FollowingList(
          authors: currentData.authors.where((a) => a.id != authorId).toList(),
          users: currentData.users,
          totalCount: currentData.totalCount - 1,
          currentPage: currentData.currentPage,
          totalPages: currentData.totalPages,
        ),
      );
    });
  }
}

/// Provider for followers list
@riverpod
class Followers extends _$Followers {
  @override
  Future<FollowersList> build() async {
    final repository = ref.watch(followRepositoryProvider);
    return repository.getFollowers();
  }

  /// Refresh followers list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(followRepositoryProvider);
      return repository.getFollowers(forceRefresh: true);
    });
  }

  /// Load more followers (pagination)
  Future<void> loadMore(int page) async {
    final repository = ref.read(followRepositoryProvider);
    final newData = await repository.getFollowers(page: page);
    
    state.whenData((currentData) {
      state = AsyncValue.data(
        FollowersList(
          followers: [...currentData.followers, ...newData.followers],
          totalCount: newData.totalCount,
          currentPage: newData.currentPage,
          totalPages: newData.totalPages,
        ),
      );
    });
  }
}
