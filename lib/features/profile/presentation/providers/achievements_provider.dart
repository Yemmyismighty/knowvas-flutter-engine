import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/achievement.dart';
import '../../data/repositories/achievement_repository_provider.dart';

part 'achievements_provider.g.dart';

/// Provider for fetching all achievements
@riverpod
Future<List<Achievement>> achievements(AchievementsRef ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getAchievements();
}

/// Provider for fetching unlocked achievements
@riverpod
Future<List<Achievement>> unlockedAchievements(UnlockedAchievementsRef ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getUnlockedAchievements();
}

/// Provider for fetching locked achievements
@riverpod
Future<List<Achievement>> lockedAchievements(LockedAchievementsRef ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getLockedAchievements();
}

/// Provider for unlocking an achievement
@riverpod
class AchievementUnlocker extends _$AchievementUnlocker {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Unlock an achievement and refresh the achievements list
  Future<Achievement> unlockAchievement(int achievementId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(achievementRepositoryProvider);
      final achievement = await repository.unlockAchievement(achievementId);
      
      // Invalidate achievements to refresh the list
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(lockedAchievementsProvider);
      
      state = const AsyncData(null);
      return achievement;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }
}
