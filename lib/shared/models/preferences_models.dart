// Preferences models

class AppPreferences {
  final String theme; // 'light', 'dark', 'system'
  final bool reduceMotion;
  final bool highContrast;
  final String fontSize; // 'small', 'medium', 'large'
  final String readingMode; // 'comfortable', 'compact'
  final bool autoBookmark;
  final bool readingReminders;
  final String language; // 'en', 'es', 'fr', etc.
  final String timeZone; // 'est', 'pst', 'utc', etc.

  AppPreferences({
    this.theme = 'system',
    this.reduceMotion = false,
    this.highContrast = false,
    this.fontSize = 'medium',
    this.readingMode = 'comfortable',
    this.autoBookmark = true,
    this.readingReminders = true,
    this.language = 'en',
    this.timeZone = 'utc',
  });

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      theme: json['theme'] ?? 'system',
      reduceMotion: json['reduce_motion'] ?? json['reduceMotion'] ?? false,
      highContrast: json['high_contrast'] ?? json['highContrast'] ?? false,
      fontSize: json['font_size'] ?? json['fontSize'] ?? 'medium',
      readingMode: json['reading_mode'] ?? json['readingMode'] ?? 'comfortable',
      autoBookmark: json['auto_bookmark'] ?? json['autoBookmark'] ?? true,
      readingReminders: json['reading_reminders'] ?? json['readingReminders'] ?? true,
      language: json['language'] ?? 'en',
      timeZone: json['time_zone'] ?? json['timeZone'] ?? 'utc',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'reduce_motion': reduceMotion,
      'high_contrast': highContrast,
      'font_size': fontSize,
      'reading_mode': readingMode,
      'auto_bookmark': autoBookmark,
      'reading_reminders': readingReminders,
      'language': language,
      'time_zone': timeZone,
    };
  }

  AppPreferences copyWith({
    String? theme,
    bool? reduceMotion,
    bool? highContrast,
    String? fontSize,
    String? readingMode,
    bool? autoBookmark,
    bool? readingReminders,
    String? language,
    String? timeZone,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      fontSize: fontSize ?? this.fontSize,
      readingMode: readingMode ?? this.readingMode,
      autoBookmark: autoBookmark ?? this.autoBookmark,
      readingReminders: readingReminders ?? this.readingReminders,
      language: language ?? this.language,
      timeZone: timeZone ?? this.timeZone,
    );
  }
}
