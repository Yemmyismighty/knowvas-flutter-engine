import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/user_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'settings_provider.g.dart';

/// Settings provider manages user preferences and settings
@riverpod
class Settings extends _$Settings {
  @override
  UserPreferences build() {
    // Get preferences from current user
    final authState = ref.watch(authProvider);
    return authState.user?.preferences ?? const UserPreferences();
  }

  /// Update theme preference
  Future<void> updateTheme(String theme) async {
    final newPrefs = state.copyWith(theme: theme);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update language preference
  Future<void> updateLanguage(String language) async {
    final newPrefs = state.copyWith(language: language);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update auto-download preference
  Future<void> updateAutoDownload(bool enabled) async {
    final newPrefs = state.copyWith(autoDownload: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update download quality preference
  Future<void> updateDownloadQuality(String quality) async {
    final newPrefs = state.copyWith(downloadQuality: quality);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update WiFi-only downloads preference
  Future<void> updateWifiOnlyDownloads(bool enabled) async {
    final newPrefs = state.copyWith(wifiOnlyDownloads: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update email notifications preference
  Future<void> updateEmailNotifications(bool enabled) async {
    final newPrefs = state.copyWith(emailNotifications: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update push notifications preference
  Future<void> updatePushNotifications(bool enabled) async {
    final newPrefs = state.copyWith(pushNotifications: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update quiet hours enabled preference
  Future<void> updateQuietHoursEnabled(bool enabled) async {
    final newPrefs = state.copyWith(quietHoursEnabled: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update quiet hours start time
  Future<void> updateQuietHoursStart(String time) async {
    final newPrefs = state.copyWith(quietHoursStart: time);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update quiet hours end time
  Future<void> updateQuietHoursEnd(String time) async {
    final newPrefs = state.copyWith(quietHoursEnd: time);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update weekend notifications preference
  Future<void> updateWeekendNotifications(bool enabled) async {
    final newPrefs = state.copyWith(weekendNotifications: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update public profile preference
  Future<void> updatePublicProfile(bool enabled) async {
    final newPrefs = state.copyWith(publicProfile: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update share reading analytics preference
  Future<void> updateShareReadingAnalytics(bool enabled) async {
    final newPrefs = state.copyWith(shareReadingAnalytics: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update allow social features preference
  Future<void> updateAllowSocialFeatures(bool enabled) async {
    final newPrefs = state.copyWith(allowSocialFeatures: enabled);
    state = newPrefs;
    await _updateUserPreferences(newPrefs);
  }

  /// Update user preferences in auth state
  Future<void> _updateUserPreferences(UserPreferences preferences) async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      final updatedUser = authState.user!.copyWith(preferences: preferences);
      ref.read(authProvider.notifier).updateUser(updatedUser);
      
      // TODO: Sync preferences to backend
      // await ref.read(settingsRepositoryProvider).updatePreferences(preferences);
    }
  }
}

/// Provider for current theme mode
@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  final theme = ref.watch(settingsProvider.select((prefs) => prefs.theme));
  
  switch (theme) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}
