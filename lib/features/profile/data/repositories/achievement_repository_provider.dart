import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'achievement_repository.dart';

part 'achievement_repository_provider.g.dart';

/// Provider for AchievementRepository
@riverpod
AchievementRepository achievementRepository(AchievementRepositoryRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AchievementRepository(apiClient: apiClient);
}
