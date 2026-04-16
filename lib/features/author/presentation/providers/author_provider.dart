import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/author_profile_models.dart';
import 'package:knowvas/features/author/data/repositories/author_repository_provider.dart';

// State class for author profile
class AuthorProfileState {
  final AuthorProfile? profile;
  final bool isLoading;
  final bool isFollowLoading;
  final String? error;

  AuthorProfileState({
    this.profile,
    this.isLoading = false,
    this.isFollowLoading = false,
    this.error,
  });

  AuthorProfileState copyWith({
    AuthorProfile? profile,
    bool? isLoading,
    bool? isFollowLoading,
    String? error,
  }) {
    return AuthorProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isFollowLoading: isFollowLoading ?? this.isFollowLoading,
      error: error,
    );
  }
}

// Author profile provider
class AuthorProfileNotifier extends StateNotifier<AuthorProfileState> {
  final AuthorRepository _repository;

  AuthorProfileNotifier(this._repository) : super(AuthorProfileState());

  /// Load author profile
  Future<void> loadProfile(int authorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getAuthorProfile(authorId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle follow
  Future<void> toggleFollow() async {
    if (state.profile == null) return;

    final currentlyFollowing = state.profile!.author.isFollowing;
    final authorId = state.profile!.author.id;

    // Optimistic update
    state = state.copyWith(
      isFollowLoading: true,
      profile: AuthorProfile(
        author: AuthorData(
          id: state.profile!.author.id,
          name: state.profile!.author.name,
          bio: state.profile!.author.bio,
          profilePicture: state.profile!.author.profilePicture,
          followers: currentlyFollowing
              ? state.profile!.author.followers - 1
              : state.profile!.author.followers + 1,
          verified: state.profile!.author.verified,
          background: state.profile!.author.background,
          awards: state.profile!.author.awards,
          isFollowing: !currentlyFollowing,
        ),
        statistics: state.profile!.statistics,
        resources: state.profile!.resources,
      ),
    );

    try {
      if (currentlyFollowing) {
        await _repository.unfollowAuthor(authorId);
      } else {
        await _repository.followAuthor(authorId);
      }
      state = state.copyWith(isFollowLoading: false);
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isFollowLoading: false,
        error: e.toString(),
        profile: AuthorProfile(
          author: AuthorData(
            id: state.profile!.author.id,
            name: state.profile!.author.name,
            bio: state.profile!.author.bio,
            profilePicture: state.profile!.author.profilePicture,
            followers: currentlyFollowing
                ? state.profile!.author.followers + 1
                : state.profile!.author.followers - 1,
            verified: state.profile!.author.verified,
            background: state.profile!.author.background,
            awards: state.profile!.author.awards,
            isFollowing: currentlyFollowing,
          ),
          statistics: state.profile!.statistics,
          resources: state.profile!.resources,
        ),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authorProfileProvider = StateNotifierProvider<AuthorProfileNotifier, AuthorProfileState>((ref) {
  final repository = ref.watch(authorRepositoryProvider);
  return AuthorProfileNotifier(repository);
});

