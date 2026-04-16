import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'bookmark_repository.dart';

part 'bookmark_repository_provider.g.dart';

/// Provider for BookmarkRepository
@riverpod
BookmarkRepository bookmarkRepository(BookmarkRepositoryRef ref) {
  return BookmarkRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}
