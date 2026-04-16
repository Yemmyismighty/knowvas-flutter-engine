import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/network/api_client_provider.dart';
import 'engagement_repository.dart';

part 'engagement_repository_provider.g.dart';

/// Provider for EngagementRepository
@riverpod
EngagementRepository engagementRepository(EngagementRepositoryRef ref) {
  return EngagementRepository(
    apiClient: ref.watch(apiClientProvider),
    databaseHelper: DatabaseHelper(),
  );
}
