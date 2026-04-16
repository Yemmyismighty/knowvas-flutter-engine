import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

/// Notification settings screen with email, push, and quiet hours settings
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          // Email Notifications Section
          SettingsSection(
            title: 'Email Notifications',
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                secondary: const Icon(Icons.email_outlined),
                value: preferences.emailNotifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateEmailNotifications(value);
                },
              ),
              if (preferences.emailNotifications) ...[
                const Divider(height: 1),
                const ListTile(
                  title: Text('New Releases'),
                  subtitle: Text('Get notified about new books from followed authors'),
                  leading: Icon(Icons.new_releases_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Reading Reminders'),
                  subtitle: Text('Reminders to continue reading'),
                  leading: Icon(Icons.schedule_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Recommendations'),
                  subtitle: Text('Personalized content recommendations'),
                  leading: Icon(Icons.recommend_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Promotions & Deals'),
                  subtitle: Text('Special offers and discounts'),
                  leading: Icon(Icons.local_offer_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Reading Goals'),
                  subtitle: Text('Updates on your reading progress'),
                  leading: Icon(Icons.flag_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
              ],
            ],
          ),

          // Push Notifications Section
          SettingsSection(
            title: 'Push Notifications',
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive notifications on your device'),
                secondary: const Icon(Icons.notifications_outlined),
                value: preferences.pushNotifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updatePushNotifications(value);
                },
              ),
              if (preferences.pushNotifications) ...[
                const Divider(height: 1),
                const ListTile(
                  title: Text('New Content'),
                  subtitle: Text('Notifications for new releases'),
                  leading: Icon(Icons.fiber_new_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Social Activity'),
                  subtitle: Text('Likes, comments, and follows'),
                  leading: Icon(Icons.people_outline),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Download Complete'),
                  subtitle: Text('When content finishes downloading'),
                  leading: Icon(Icons.download_done_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
              ],
            ],
          ),

          // Quiet Hours Section
          SettingsSection(
            title: 'Quiet Hours',
            children: [
              SwitchListTile(
                title: const Text('Enable Quiet Hours'),
                subtitle: const Text('Suppress notifications during specific hours'),
                secondary: const Icon(Icons.bedtime_outlined),
                value: preferences.quietHoursEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateQuietHoursEnabled(value);
                },
              ),
              if (preferences.quietHoursEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(
                    preferences.quietHoursStart ?? 'Not set',
                    style: TextStyle(
                      color: preferences.quietHoursStart != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  leading: const Icon(Icons.access_time),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTimePicker(
                    context,
                    ref,
                    isStartTime: true,
                    currentTime: preferences.quietHoursStart,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(
                    preferences.quietHoursEnd ?? 'Not set',
                    style: TextStyle(
                      color: preferences.quietHoursEnd != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  leading: const Icon(Icons.access_time),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTimePicker(
                    context,
                    ref,
                    isStartTime: false,
                    currentTime: preferences.quietHoursEnd,
                  ),
                ),
              ],
            ],
          ),

          // Additional Settings Section
          SettingsSection(
            title: 'Additional Settings',
            children: [
              SwitchListTile(
                title: const Text('Weekend Notifications'),
                subtitle: const Text('Receive notifications on weekends'),
                secondary: const Icon(Icons.weekend_outlined),
                value: preferences.weekendNotifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateWeekendNotifications(value);
                },
              ),
            ],
          ),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email notifications are sent to your registered email address. '
                      'Push notifications require device permissions. '
                      'Quiet hours will suppress all notifications during the specified time range.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Show time picker for quiet hours
  Future<void> _showTimePicker(
    BuildContext context,
    WidgetRef ref, {
    required bool isStartTime,
    String? currentTime,
  }) async {
    // Parse current time if available
    TimeOfDay initialTime = TimeOfDay.now();
    if (currentTime != null) {
      final parts = currentTime.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format time as HH:mm
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';

      if (isStartTime) {
        await ref.read(settingsProvider.notifier).updateQuietHoursStart(formattedTime);
      } else {
        await ref.read(settingsProvider.notifier).updateQuietHoursEnd(formattedTime);
      }
    }
  }
}
