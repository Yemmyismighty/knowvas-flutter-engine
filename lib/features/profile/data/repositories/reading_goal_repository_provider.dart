import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'reading_goal_repository.dart';

part 'reading_goal_repository_provider.g.dart';

/// Provider for ReadingGoalRepository
@riverpod
ReadingGoalRepository readingGoalRepository(ReadingGoalRepositoryRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReadingGoalRepository(apiClient: apiClient);
}
