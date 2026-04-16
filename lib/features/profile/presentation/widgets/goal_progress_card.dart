import 'package:flutter/material.dart';

import '../../../../shared/models/reading_goal.dart';

/// Card displaying reading goal progress
class GoalProgressCard extends StatelessWidget {
  final ReadingGoal goal;
  final VoidCallback? onDelete;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnyGoal = goal.targetBooks != null || 
                       goal.targetPages != null || 
                       goal.targetReadingTimeMinutes != null;

    if (!hasAnyGoal) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.year} Reading Goals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Delete goal',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Books goal
            if (goal.targetBooks != null) ...[
              _buildGoalProgress(
                context: context,
                icon: Icons.book_outlined,
                label: 'Books',
                current: goal.currentBooks,
                target: goal.targetBooks!,
                progress: goal.booksProgress!,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            // Pages goal
            if (goal.targetPages != null) ...[
              _buildGoalProgress(
                context: context,
                icon: Icons.description_outlined,
                label: 'Pages',
                current: goal.currentPages,
                target: goal.targetPages!,
                progress: goal.pagesProgress!,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Reading time goal
            if (goal.targetReadingTimeMinutes != null) ...[
              _buildGoalProgress(
                context: context,
                icon: Icons.access_time,
                label: 'Reading Time',
                current: goal.currentReadingTimeMinutes,
                target: goal.targetReadingTimeMinutes!,
                progress: goal.readingTimeProgress!,
                color: Colors.orange,
                suffix: 'min',
              ),
            ],

            // Completion message
            if (goal.hasCompletedGoal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Congratulations! You\'ve completed a goal!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required double progress,
    required Color color,
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$current / $target ${suffix.isNotEmpty ? suffix : label.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage% complete',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
