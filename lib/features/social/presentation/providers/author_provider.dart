import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/author_repository.dart';
import '../../data/repositories/author_repository_provider.dart';

/// Provider for fetching author profile
final authorProfileProvider =
    FutureProvider.family<AuthorProfile, int>((ref, authorId) async {
  final repository = ref.watch(authorRepositoryProvider);
  return repository.getAuthorProfile(authorId);
});

/// Provider for follow/unfollow actions
final authorActionsProvider = Provider<AuthorActions>((ref) {
  final repository = ref.watch(authorRepositoryProvider);
  return AuthorActions(repository: repository, ref: ref);
});

/// Author actions class for follow/unfollow operations
class AuthorActions {
  AuthorActions({
    required AuthorRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref;

  final AuthorRepository _repository;
  final Ref _ref;

  /// Follow an author
  Future<void> followAuthor(int authorId) async {
    await _repository.followAuthor(authorId);
    // Invalidate the author profile to refresh the follow status
    _ref.invalidate(authorProfileProvider(authorId));
  }

  /// Unfollow an author
  Future<void> unfollowAuthor(int authorId) async {
    await _repository.unfollowAuthor(authorId);
    // Invalidate the author profile to refresh the follow status
    _ref.invalidate(authorProfileProvider(authorId));
  }
}
