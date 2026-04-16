import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'reading_progress_repository.dart';

part 'reading_progress_repository_provider.g.dart';

/// Provider for ReadingProgressRepository
@riverpod
ReadingProgressRepository readingProgressRepository(
    ReadingProgressRepositoryRef ref) {
  return ReadingProgressRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}
