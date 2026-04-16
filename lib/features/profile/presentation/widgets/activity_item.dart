import 'package:flutter/material.dart';
import '../../../../shared/models/profile_models.dart';

class ActivityItem extends StatelessWidget {
  final Activity activity;

  const ActivityItem({required this.activity, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _getActivityIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityText(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (activity.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        activity.rating!,
                        (index) => const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(activity.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActivityIcon() {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'finished':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'started':
        icon = Icons.menu_book;
        color = Colors.blue;
        break;
      case 'reviewed':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'achievement':
        icon = Icons.emoji_events;
        color = Colors.purple;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }

  String _getActivityText() {
    switch (activity.type) {
      case 'finished':
        return 'Finished reading "${activity.title}" by ${activity.author}';
      case 'started':
        return 'Started reading "${activity.title}" by ${activity.author}';
      case 'reviewed':
        return 'Reviewed "${activity.title}" by ${activity.author}';
      case 'achievement':
        return 'Earned the "${activity.name}" achievement';
      default:
        return 'Unknown activity';
    }
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';

      return '${date.month}/${date.day}';
    } catch (e) {
      return timestamp;
    }
  }
}
