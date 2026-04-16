import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/shared/models/user_preferences.dart';

void main() {
  group('UserPreferences - Notification Settings', () {
    test('default preferences have notification settings enabled', () {
      const preferences = UserPreferences();

      expect(preferences.emailNotifications, true);
      expect(preferences.pushNotifications, true);
      expect(preferences.quietHoursEnabled, false);
      expect(preferences.quietHoursStart, null);
      expect(preferences.quietHoursEnd, null);
      expect(preferences.weekendNotifications, true);
    });

    test('copyWith can update email notifications', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(emailNotifications: false);

      expect(updated.emailNotifications, false);
      expect(updated.pushNotifications, true); // unchanged
    });

    test('copyWith can update push notifications', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(pushNotifications: false);

      expect(updated.pushNotifications, false);
      expect(updated.emailNotifications, true); // unchanged
    });

    test('copyWith can update quiet hours enabled', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(quietHoursEnabled: true);

      expect(updated.quietHoursEnabled, true);
    });

    test('copyWith can update quiet hours start time', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(quietHoursStart: '22:00');

      expect(updated.quietHoursStart, '22:00');
    });

    test('copyWith can update quiet hours end time', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(quietHoursEnd: '08:00');

      expect(updated.quietHoursEnd, '08:00');
    });

    test('copyWith can update weekend notifications', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(weekendNotifications: false);

      expect(updated.weekendNotifications, false);
    });

    test('multiple notification settings can be updated with copyWith', () {
      const preferences = UserPreferences();
      final updated = preferences.copyWith(
        emailNotifications: false,
        pushNotifications: false,
        quietHoursEnabled: true,
        quietHoursStart: '23:00',
        quietHoursEnd: '07:00',
        weekendNotifications: false,
      );

      expect(updated.emailNotifications, false);
      expect(updated.pushNotifications, false);
      expect(updated.quietHoursEnabled, true);
      expect(updated.quietHoursStart, '23:00');
      expect(updated.quietHoursEnd, '07:00');
      expect(updated.weekendNotifications, false);
    });

    test('toJson includes notification settings', () {
      const preferences = UserPreferences(
        emailNotifications: false,
        pushNotifications: false,
        quietHoursEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
        weekendNotifications: false,
      );

      final json = preferences.toJson();

      expect(json['email_notifications'], false);
      expect(json['push_notifications'], false);
      expect(json['quiet_hours_enabled'], true);
      expect(json['quiet_hours_start'], '22:00');
      expect(json['quiet_hours_end'], '08:00');
      expect(json['weekend_notifications'], false);
    });

    test('fromJson parses notification settings', () {
      final json = {
        'email_notifications': false,
        'push_notifications': false,
        'quiet_hours_enabled': true,
        'quiet_hours_start': '22:00',
        'quiet_hours_end': '08:00',
        'weekend_notifications': false,
      };

      final preferences = UserPreferences.fromJson(json);

      expect(preferences.emailNotifications, false);
      expect(preferences.pushNotifications, false);
      expect(preferences.quietHoursEnabled, true);
      expect(preferences.quietHoursStart, '22:00');
      expect(preferences.quietHoursEnd, '08:00');
      expect(preferences.weekendNotifications, false);
    });
  });
}
