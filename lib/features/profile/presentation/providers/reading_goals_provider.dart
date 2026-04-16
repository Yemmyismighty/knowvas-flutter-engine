import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/reading_goal.dart';
import '../../data/repositories/reading_goal_repository_provider.dart';

part 'reading_goals_provider.g.dart';

/// Provider for reading goals list
@riverpod
class ReadingGoals extends _$ReadingGoals {
  @override
  Future<List<ReadingGoal>> build() async {
    return await _fetchGoals();
  }

  Future<List<ReadingGoal>> _fetchGoals() async {
    final repository = ref.read(readingGoalRepositoryProvider);
    return await repository.getGoals();
  }

  /// Create a new reading goal
  Future<void> createGoal({
    required int year,
    int? targetBooks,
    int? targetPages,
    int? targetReadingTimeMinutes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(readingGoalRepositoryProvider);
      await repository.createGoal(
        year: year,
        targetBooks: targetBooks,
        targetPages: targetPages,
        targetReadingTimeMinutes: targetReadingTimeMinutes,
      );
      return await _fetchGoals();
    });
  }

  /// Update goal progress
  Future<void> updateProgress({
    required int goalId,
    int? currentBooks,
    int? currentPages,
    int? currentReadingTimeMinutes,
  }) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(readingGoalRepositoryProvider);
      await repository.updateGoalProgress(
        goalId: goalId,
        currentBooks: currentBooks,
        currentPages: currentPages,
        currentReadingTimeMinutes: currentReadingTimeMinutes,
      );
      return await _fetchGoals();
    });
  }

  /// Delete a reading goal
  Future<void> deleteGoal(int goalId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(readingGoalRepositoryProvider);
      await repository.deleteGoal(goalId);
      return await _fetchGoals();
    });
  }

  /// Refresh goals
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGoals());
  }
}

/// Provider for current year's reading goal
@riverpod
Future<ReadingGoal?> currentYearGoal(CurrentYearGoalRef ref) async {
  final currentYear = DateTime.now().year;
  final repository = ref.watch(readingGoalRepositoryProvider);
  return await repository.getGoalByYear(currentYear);
}
