import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/achievement.dart';
import '../providers/achievements_provider.dart';
import '../widgets/achievement_unlock_notification.dart';

/// Helper class for achievement-related operations
class AchievementHelper {
  /// Attempt to unlock an achievement and show notification on success
  /// Returns true if unlock was successful, false otherwise
  static Future<bool> unlockAndNotify({
    required BuildContext context,
    required WidgetRef ref,
    required int achievementId,
  }) async {
    try {
      final unlocker = ref.read(achievementUnlockerProvider.notifier);
      final achievement = await unlocker.unlockAchievement(achievementId);

      if (context.mounted) {
        AchievementUnlockNotification.show(context, achievement);
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlock achievement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Check if user has unlocked a specific achievement
  static Future<bool> hasUnlockedAchievement({
    required WidgetRef ref,
    required int achievementId,
  }) async {
    try {
      final achievements = await ref.read(achievementsProvider.future);
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw Exception('Achievement not found'),
      );
      return achievement.isUnlocked;
    } catch (e) {
      return false;
    }
  }

  /// Get achievement progress for a specific achievement
  static Future<double?> getAchievementProgress({
    required WidgetRef ref,
    required int achievementId,
  }) async {
    try {
      final achievements = await ref.read(achievementsProvider.future);
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw Exception('Achievement not found'),
      );
      return achievement.progress;
    } catch (e) {
      return null;
    }
  }

  /// Get count of unlocked achievements
  static Future<int> getUnlockedCount(WidgetRef ref) async {
    try {
      final unlocked = await ref.read(unlockedAchievementsProvider.future);
      return unlocked.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get count of total achievements
  static Future<int> getTotalCount(WidgetRef ref) async {
    try {
      final achievements = await ref.read(achievementsProvider.future);
      return achievements.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get achievement completion percentage
  static Future<double> getCompletionPercentage(WidgetRef ref) async {
    try {
      final total = await getTotalCount(ref);
      if (total == 0) return 0.0;

      final unlocked = await getUnlockedCount(ref);
      return (unlocked / total) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Show achievement details dialog
  static void showAchievementDetails({
    required BuildContext context,
    required Achievement achievement,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              achievement.isUnlocked ? Icons.emoji_events : Icons.lock,
              color: achievement.isUnlocked ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            Text(
              'Category: ${achievement.category}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (!achievement.isUnlocked) ...[
              Text(
                'Progress: ${achievement.currentValue}/${achievement.targetValue}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Text(
                '${achievement.progressPercentage}% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Text(
                'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
