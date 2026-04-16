import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/features/settings/presentation/providers/notifications_provider.dart';

class NotificationsTab extends ConsumerWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);

    if (notificationsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final prefs = notificationsState.preferences;
    if (prefs == null) {
      return const Center(
        child: Text('Failed to load notification preferences'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Email Notifications Section
        _buildSection(
          context,
          'Email Notifications',
          Icons.email_outlined,
          const Color(0xFF3B82F6),
          [
            _buildSwitchTile(
              context,
              ref,
              'New Releases',
              'Books from your favorite authors',
              prefs.emailNotifications.newReleases,
              (value) => ref.read(notificationsProvider.notifier).updateEmailNotification('newReleases', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Reading Reminders',
              'Daily reading goal notifications',
              prefs.emailNotifications.readingReminders,
              (value) => ref.read(notificationsProvider.notifier).updateEmailNotification('readingReminders', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Recommendations',
              'Personalized book suggestions',
              prefs.emailNotifications.recommendations,
              (value) => ref.read(notificationsProvider.notifier).updateEmailNotification('recommendations', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Account Updates',
              'Security and billing notifications',
              prefs.emailNotifications.accountUpdates,
              (value) => ref.read(notificationsProvider.notifier).updateEmailNotification('accountUpdates', value),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Push Notifications Section
        _buildSection(
          context,
          'Push Notifications',
          Icons.notifications_outlined,
          const Color(0xFF8B5CF6),
          [
            _buildSwitchTile(
              context,
              ref,
              'Reading Streaks',
              'Celebrate your reading milestones',
              prefs.pushNotifications.readingStreaks,
              (value) => ref.read(notificationsProvider.notifier).updatePushNotification('readingStreaks', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Social Activity',
              'New followers and interactions',
              prefs.pushNotifications.socialActivity,
              (value) => ref.read(notificationsProvider.notifier).updatePushNotification('socialActivity', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Download Complete',
              'When books finish downloading',
              prefs.pushNotifications.downloadComplete,
              (value) => ref.read(notificationsProvider.notifier).updatePushNotification('downloadComplete', value),
            ),
            _buildSwitchTile(
              context,
              ref,
              'Weekly Summary',
              'Your reading progress recap',
              prefs.pushNotifications.weeklySummary,
              (value) => ref.read(notificationsProvider.notifier).updatePushNotification('weeklySummary', value),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Notification Schedule Section
        _buildSection(
          context,
          'Notification Schedule',
          Icons.schedule,
          const Color(0xFF10B981),
          [
            _buildDropdownTile(
              context,
              'Quiet Hours Start',
              prefs.notificationSchedule.quietHoursStart,
              ['20:00', '21:00', '22:00', '23:00'],
              (value) => ref.read(notificationsProvider.notifier).updateSchedule('quietHoursStart', value!),
            ),
            const SizedBox(height: 12),
            _buildDropdownTile(
              context,
              'Quiet Hours End',
              prefs.notificationSchedule.quietHoursEnd,
              ['06:00', '07:00', '08:00', '09:00'],
              (value) => ref.read(notificationsProvider.notifier).updateSchedule('quietHoursEnd', value!),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              context,
              ref,
              'Weekend Notifications',
              'Receive notifications on weekends',
              prefs.notificationSchedule.weekendNotifications,
              (value) => ref.read(notificationsProvider.notifier).updateSchedule('weekendNotifications', value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        DropdownButton<String>(
          value: value,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                _formatTime(option),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${parts[1]} $period';
  }
}

