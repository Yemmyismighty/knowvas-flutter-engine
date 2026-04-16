import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'highlight_repository.dart';

part 'highlight_repository_provider.g.dart';

/// Provider for HighlightRepository
@riverpod
HighlightRepository highlightRepository(HighlightRepositoryRef ref) {
  return HighlightRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}
