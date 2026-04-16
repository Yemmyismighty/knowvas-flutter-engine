import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

/// Privacy settings screen with profile visibility, analytics, and social features settings
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        children: [
          // Profile Visibility Section
          SettingsSection(
            title: 'Profile Visibility',
            children: [
              SwitchListTile(
                title: const Text('Public Profile'),
                subtitle: const Text(
                  'Allow others to view your profile and reading activity',
                ),
                secondary: const Icon(Icons.public_outlined),
                value: preferences.publicProfile,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updatePublicProfile(value);
                },
              ),
              if (!preferences.publicProfile)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Text(
                    'Your profile is private. Only you can see your reading activity and collections.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
            ],
          ),

          // Data Sharing Section
          SettingsSection(
            title: 'Data Sharing',
            children: [
              SwitchListTile(
                title: const Text('Share Reading Analytics'),
                subtitle: const Text(
                  'Help improve recommendations by sharing your reading patterns',
                ),
                secondary: const Icon(Icons.analytics_outlined),
                value: preferences.shareReadingAnalytics,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateShareReadingAnalytics(value);
                },
              ),
              if (preferences.shareReadingAnalytics)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shared data includes:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Reading time and frequency\n'
                        '• Content preferences and genres\n'
                        '• Reading progress and completion rates\n'
                        '• Device and app usage patterns',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Social Features Section
          SettingsSection(
            title: 'Social Features',
            children: [
              SwitchListTile(
                title: const Text('Allow Social Features'),
                subtitle: const Text(
                  'Enable following, reviews, and social interactions',
                ),
                secondary: const Icon(Icons.people_outline),
                value: preferences.allowSocialFeatures,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateAllowSocialFeatures(value);
                },
              ),
              if (!preferences.allowSocialFeatures)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Text(
                    'Social features are disabled. You will not be able to follow authors, '
                    'write reviews, or interact with other readers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              if (preferences.allowSocialFeatures) ...[
                const Divider(height: 1.0),
                const ListTile(
                  title: Text('Follow Authors & Users'),
                  subtitle: Text('Connect with your favorite authors and readers'),
                  leading: Icon(Icons.person_add_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1.0),
                const ListTile(
                  title: Text('Write Reviews'),
                  subtitle: Text('Share your thoughts on books you have read'),
                  leading: Icon(Icons.rate_review_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1.0),
                const ListTile(
                  title: Text('Like & Comment'),
                  subtitle: Text('Engage with reviews and discussions'),
                  leading: Icon(Icons.thumb_up_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
                const Divider(height: 1.0),
                const ListTile(
                  title: Text('Share Collections'),
                  subtitle: Text('Make your collections visible to others'),
                  leading: Icon(Icons.collections_bookmark_outlined),
                  trailing: Icon(Icons.check, color: Colors.green),
                  dense: true,
                ),
              ],
            ],
          ),

          // Privacy Summary Section
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
                          Icons.security_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Privacy Matters',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We respect your privacy and give you control over your data. '
                      'Your reading content is always private and encrypted. '
                      'These settings only control how you interact with the community '
                      'and how we use anonymized data to improve your experience.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to privacy policy
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy - Coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('Read Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Data Management Section
          SettingsSection(
            title: 'Data Management',
            children: [
              ListTile(
                title: const Text('Download My Data'),
                subtitle: const Text('Request a copy of your personal data'),
                leading: const Icon(Icons.download_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDataDownloadDialog(context);
                },
              ),
              const Divider(height: 1.0),
              ListTile(
                title: const Text('Delete My Account'),
                subtitle: const Text('Permanently delete your account and data'),
                leading: const Icon(Icons.delete_forever_outlined),
                trailing: const Icon(Icons.chevron_right),
                titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Show data download dialog
  void _showDataDownloadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Text(
          'We will prepare a copy of your personal data including:\n\n'
          '• Profile information\n'
          '• Reading history and progress\n'
          '• Bookmarks and highlights\n'
          '• Reviews and ratings\n'
          '• Purchase history\n\n'
          'You will receive an email with a download link within 24-48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data download request submitted'),
                  duration: Duration(seconds: 3),
                ),
              );
              // TODO: Call backend API to request data download
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  /// Show delete account dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Deleting your account will:\n\n'
          '• Remove all your personal data\n'
          '• Delete your reading history and progress\n'
          '• Remove all bookmarks and highlights\n'
          '• Cancel any active subscriptions\n'
          '• Delete all reviews and ratings\n\n'
          'Downloaded content will be removed from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmationDialog(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Show final delete confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type "DELETE" to confirm account deletion:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion request submitted'),
                    duration: Duration(seconds: 3),
                  ),
                );
                // TODO: Call backend API to delete account
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
