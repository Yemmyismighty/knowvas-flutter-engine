import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'content_repository.dart';

/// Provider for ContentRepository
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return ContentRepository(
    apiClient: apiClient,
  );
});