import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Settings screen with sections for Account, Reading, Downloads, Notifications, Privacy, and About
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          SettingsSection(
            title: 'Account',
            children: [
              if (user != null) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePicture != null
                        ? NetworkImage(user.profilePicture!)
                        : null,
                    child: user.profilePicture == null
                        ? Text(user.firstName[0].toUpperCase())
                        : null,
                  ),
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to profile
                    context.push('/profile');
                  },
                ),
                SettingsTile(
                  title: 'Currency',
                  subtitle: _getCurrencyDisplay(user.preferredCurrency),
                  leading: const Icon(Icons.attach_money),
                  onTap: () => _showCurrencyPicker(context, ref, user.preferredCurrency),
                ),
              ],
            ],
          ),

          // Reading Preferences Section
          SettingsSection(
            title: 'Reading',
            children: [
              SettingsTile(
                title: 'Theme',
                subtitle: _getThemeDisplay(preferences.theme),
                leading: const Icon(Icons.palette_outlined),
                onTap: () => _showThemePicker(context, ref, preferences.theme),
              ),
              SettingsTile(
                title: 'Language',
                subtitle: _getLanguageDisplay(preferences.language),
                leading: const Icon(Icons.language),
                onTap: () => _showLanguagePicker(context, ref, preferences.language),
              ),
            ],
          ),

          // Downloads Section
          SettingsSection(
            title: 'Downloads',
            children: [
              SwitchListTile(
                title: const Text('Auto-download'),
                subtitle: const Text('Automatically download purchased content'),
                secondary: const Icon(Icons.download_outlined),
                value: preferences.autoDownload,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateAutoDownload(value);
                },
              ),
              SettingsTile(
                title: 'Download Quality',
                subtitle: _getQualityDisplay(preferences.downloadQuality),
                leading: const Icon(Icons.high_quality_outlined),
                onTap: () => _showQualityPicker(context, ref, preferences.downloadQuality),
              ),
              SwitchListTile(
                title: const Text('WiFi-only downloads'),
                subtitle: const Text('Download only when connected to WiFi'),
                secondary: const Icon(Icons.wifi),
                value: preferences.wifiOnlyDownloads,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateWifiOnlyDownloads(value);
                },
              ),
            ],
          ),

          // Notifications Section
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsTile(
                title: 'Notification Settings',
                subtitle: 'Manage email and push notifications',
                leading: const Icon(Icons.notifications_outlined),
                onTap: () {
                  context.push('/settings/notifications');
                },
              ),
            ],
          ),

          // Privacy Section
          SettingsSection(
            title: 'Privacy',
            children: [
              SettingsTile(
                title: 'Privacy Settings',
                subtitle: 'Manage profile visibility and data sharing',
                leading: const Icon(Icons.privacy_tip_outlined),
                onTap: () {
                  context.push('/settings/privacy');
                },
              ),
            ],
          ),

          // About Section
          SettingsSection(
            title: 'About',
            children: [
              const SettingsTile(
                title: 'Version',
                subtitle: '1.0.0',
                leading: Icon(Icons.info_outline),
              ),
              SettingsTile(
                title: 'Terms of Service',
                leading: const Icon(Icons.description_outlined),
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
              SettingsTile(
                title: 'Privacy Policy',
                leading: const Icon(Icons.policy_outlined),
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              SettingsTile(
                title: 'Sign Out',
                leading: const Icon(Icons.logout, color: Colors.red),
                titleColor: Colors.red,
                onTap: () => _showSignOutDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeDisplay(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'sepia':
        return 'Sepia';
      case 'system':
      default:
        return 'System Default';
    }
  }

  String _getCurrencyDisplay(String? currency) {
    switch (currency) {
      case 'USD':
        return 'US Dollar (USD)';
      case 'NGN':
        return 'Nigerian Naira (NGN)';
      case 'EUR':
        return 'Euro (EUR)';
      case 'GBP':
        return 'British Pound (GBP)';
      default:
        return 'US Dollar (USD)';
    }
  }

  String _getLanguageDisplay(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  String _getQualityDisplay(String quality) {
    switch (quality) {
      case 'standard':
        return 'Standard';
      case 'high':
        return 'High';
      case 'ultra':
        return 'Ultra';
      default:
        return 'Standard';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, String currentTheme) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.light_mode),
              trailing: currentTheme == 'light' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateTheme('light');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.dark_mode),
              trailing: currentTheme == 'dark' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateTheme('dark');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sepia'),
              subtitle: const Text('Warm, comfortable for reading'),
              leading: const Icon(Icons.auto_stories),
              trailing: currentTheme == 'sepia' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateTheme('sepia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.settings_suggest),
              trailing: currentTheme == 'system' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateTheme('system');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String? currentCurrency) {
    final currencies = [
      {'code': 'USD', 'name': 'US Dollar'},
      {'code': 'NGN', 'name': 'Nigerian Naira'},
      {'code': 'EUR', 'name': 'Euro'},
      {'code': 'GBP', 'name': 'British Pound'},
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            final code = currency['code']!;
            final name = currency['name']!;
            return ListTile(
              title: Text('$name ($code)'),
              trailing: currentCurrency == code ? const Icon(Icons.check) : null,
              onTap: () {
                // TODO: Update currency in user profile
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLanguage) {
    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
      {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
      {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            final code = language['code']!;
            final name = language['name']!;
            final nativeName = language['nativeName']!;
            return ListTile(
              title: Text(nativeName),
              subtitle: Text(name),
              trailing: currentLanguage == code ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateLanguage(code);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref, String currentQuality) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Standard'),
              subtitle: const Text('Smaller file size, good quality'),
              trailing: currentQuality == 'standard' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateDownloadQuality('standard');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('High'),
              subtitle: const Text('Larger file size, better quality'),
              trailing: currentQuality == 'high' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateDownloadQuality('high');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Ultra'),
              subtitle: const Text('Largest file size, best quality'),
              trailing: currentQuality == 'ultra' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateDownloadQuality('ultra');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
