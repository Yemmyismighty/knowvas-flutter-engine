class NotificationPreferences {
  final EmailNotifications emailNotifications;
  final PushNotifications pushNotifications;
  final NotificationSchedule notificationSchedule;

  NotificationPreferences({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.notificationSchedule,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotifications: EmailNotifications.fromJson(
        json['emailNotifications'] ?? json['email_notifications'] ?? {},
      ),
      pushNotifications: PushNotifications.fromJson(
        json['pushNotifications'] ?? json['push_notifications'] ?? {},
      ),
      notificationSchedule: NotificationSchedule.fromJson(
        json['notificationSchedule'] ?? json['notification_schedule'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications.toJson(),
      'pushNotifications': pushNotifications.toJson(),
      'notificationSchedule': notificationSchedule.toJson(),
    };
  }
}

class EmailNotifications {
  final bool newReleases;
  final bool readingReminders;
  final bool recommendations;
  final bool accountUpdates;

  EmailNotifications({
    required this.newReleases,
    required this.readingReminders,
    required this.recommendations,
    required this.accountUpdates,
  });

  factory EmailNotifications.fromJson(Map<String, dynamic> json) {
    return EmailNotifications(
      newReleases: json['newReleases'] ?? json['new_releases'] ?? true,
      readingReminders: json['readingReminders'] ?? json['reading_reminders'] ?? true,
      recommendations: json['recommendations'] ?? true,
      accountUpdates: json['accountUpdates'] ?? json['account_updates'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newReleases': newReleases,
      'readingReminders': readingReminders,
      'recommendations': recommendations,
      'accountUpdates': accountUpdates,
    };
  }

  EmailNotifications copyWith({
    bool? newReleases,
    bool? readingReminders,
    bool? recommendations,
    bool? accountUpdates,
  }) {
    return EmailNotifications(
      newReleases: newReleases ?? this.newReleases,
      readingReminders: readingReminders ?? this.readingReminders,
      recommendations: recommendations ?? this.recommendations,
      accountUpdates: accountUpdates ?? this.accountUpdates,
    );
  }
}

class PushNotifications {
  final bool readingStreaks;
  final bool socialActivity;
  final bool downloadComplete;
  final bool weeklySummary;

  PushNotifications({
    required this.readingStreaks,
    required this.socialActivity,
    required this.downloadComplete,
    required this.weeklySummary,
  });

  factory PushNotifications.fromJson(Map<String, dynamic> json) {
    return PushNotifications(
      readingStreaks: json['readingStreaks'] ?? json['reading_streaks'] ?? true,
      socialActivity: json['socialActivity'] ?? json['social_activity'] ?? true,
      downloadComplete: json['downloadComplete'] ?? json['download_complete'] ?? true,
      weeklySummary: json['weeklySummary'] ?? json['weekly_summary'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'readingStreaks': readingStreaks,
      'socialActivity': socialActivity,
      'downloadComplete': downloadComplete,
      'weeklySummary': weeklySummary,
    };
  }

  PushNotifications copyWith({
    bool? readingStreaks,
    bool? socialActivity,
    bool? downloadComplete,
    bool? weeklySummary,
  }) {
    return PushNotifications(
      readingStreaks: readingStreaks ?? this.readingStreaks,
      socialActivity: socialActivity ?? this.socialActivity,
      downloadComplete: downloadComplete ?? this.downloadComplete,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

class NotificationSchedule {
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool weekendNotifications;

  NotificationSchedule({
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.weekendNotifications,
  });

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      quietHoursStart: json['quietHoursStart'] ?? json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? json['quiet_hours_end'] ?? '07:00',
      weekendNotifications: json['weekendNotifications'] ?? json['weekend_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'weekendNotifications': weekendNotifications,
    };
  }

  NotificationSchedule copyWith({
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? weekendNotifications,
  }) {
    return NotificationSchedule(
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      weekendNotifications: weekendNotifications ?? this.weekendNotifications,
    );
  }
}
