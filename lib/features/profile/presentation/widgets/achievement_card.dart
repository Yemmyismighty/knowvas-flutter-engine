import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({required this.achievement, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: achievement.isUnlocked
            ? LinearGradient(
                colors: [AppTheme.brand50, AppTheme.brand100],
              )
            : null,
        color: achievement.isUnlocked ? null : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: achievement.isUnlocked
            ? Border.all(color: AppTheme.brand200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked
                  ? const LinearGradient(
                      colors: [AppTheme.brand600, AppTheme.brand700],
                    )
                  : null,
              color: achievement.isUnlocked ? null : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.isUnlocked ? achievement.iconUrl : '🔒',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked ? AppTheme.brand700 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (achievement.isUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Earned',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
