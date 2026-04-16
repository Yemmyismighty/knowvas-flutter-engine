import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/shared/models/notification_models.dart';

class NotificationsState {
  final NotificationPreferences? preferences;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  NotificationsState({
    this.preferences,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  NotificationsState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return NotificationsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsNotifier(this._apiClient) : super(NotificationsState()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get('/api/user/notification-preferences');

      if (response.data['status'] == 'success') {
        final prefs = NotificationPreferences.fromJson(response.data['data']);
        state = state.copyWith(preferences: prefs, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load preferences',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Network error',
      );
    }
  }

  Future<void> _savePreferences(NotificationPreferences prefs) async {
    state = state.copyWith(isSaving: true);

    try {
      final response = await _apiClient.post(
        '/api/user/notification-preferences',
        data: prefs.toJson(),
      );

      if (response.data['status'] == 'success') {
        final updatedPrefs = NotificationPreferences.fromJson(response.data['data']);
        state = state.copyWith(preferences: updatedPrefs, isSaving: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data['message'] ?? 'Failed to save preferences',
      );
    }
  }

  Future<void> updateEmailNotification(String key, bool value) async {
    if (state.preferences == null) return;

    final updatedEmail = _updateEmailField(state.preferences!.emailNotifications, key, value);
    final updatedPrefs = NotificationPreferences(
      emailNotifications: updatedEmail,
      pushNotifications: state.preferences!.pushNotifications,
      notificationSchedule: state.preferences!.notificationSchedule,
    );

    state = state.copyWith(preferences: updatedPrefs);
    await _savePreferences(updatedPrefs);
  }

  Future<void> updatePushNotification(String key, bool value) async {
    if (state.preferences == null) return;

    final updatedPush = _updatePushField(state.preferences!.pushNotifications, key, value);
    final updatedPrefs = NotificationPreferences(
      emailNotifications: state.preferences!.emailNotifications,
      pushNotifications: updatedPush,
      notificationSchedule: state.preferences!.notificationSchedule,
    );

    state = state.copyWith(preferences: updatedPrefs);
    await _savePreferences(updatedPrefs);
  }

  Future<void> updateSchedule(String key, dynamic value) async {
    if (state.preferences == null) return;

    final updatedSchedule = _updateScheduleField(state.preferences!.notificationSchedule, key, value);
    final updatedPrefs = NotificationPreferences(
      emailNotifications: state.preferences!.emailNotifications,
      pushNotifications: state.preferences!.pushNotifications,
      notificationSchedule: updatedSchedule,
    );

    state = state.copyWith(preferences: updatedPrefs);
    await _savePreferences(updatedPrefs);
  }

  EmailNotifications _updateEmailField(EmailNotifications email, String key, bool value) {
    switch (key) {
      case 'newReleases':
        return email.copyWith(newReleases: value);
      case 'readingReminders':
        return email.copyWith(readingReminders: value);
      case 'recommendations':
        return email.copyWith(recommendations: value);
      case 'accountUpdates':
        return email.copyWith(accountUpdates: value);
      default:
        return email;
    }
  }

  PushNotifications _updatePushField(PushNotifications push, String key, bool value) {
    switch (key) {
      case 'readingStreaks':
        return push.copyWith(readingStreaks: value);
      case 'socialActivity':
        return push.copyWith(socialActivity: value);
      case 'downloadComplete':
        return push.copyWith(downloadComplete: value);
      case 'weeklySummary':
        return push.copyWith(weeklySummary: value);
      default:
        return push;
    }
  }

  NotificationSchedule _updateScheduleField(NotificationSchedule schedule, String key, dynamic value) {
    switch (key) {
      case 'quietHoursStart':
        return schedule.copyWith(quietHoursStart: value as String);
      case 'quietHoursEnd':
        return schedule.copyWith(quietHoursEnd: value as String);
      case 'weekendNotifications':
        return schedule.copyWith(weekendNotifications: value as bool);
      default:
        return schedule;
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});

