import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'content_actions_repository.dart';

/// Provider for ContentActionsRepository
final contentActionsRepositoryProvider = Provider<ContentActionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContentActionsRepository(apiClient: apiClient);
});
