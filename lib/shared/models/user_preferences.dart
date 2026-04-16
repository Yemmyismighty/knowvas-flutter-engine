import 'package:equatable/equatable.dart';

/// User preferences model
class UserPreferences extends Equatable {
  final String theme; // 'light', 'dark', 'system'
  final String language;
  final bool autoDownload;
  final String downloadQuality; // 'standard', 'high', 'ultra'
  final bool wifiOnlyDownloads;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool weekendNotifications;
  final bool publicProfile;
  final bool shareReadingAnalytics;
  final bool allowSocialFeatures;

  const UserPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.autoDownload = false,
    this.downloadQuality = 'standard',
    this.wifiOnlyDownloads = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.weekendNotifications = true,
    this.publicProfile = true,
    this.shareReadingAnalytics = true,
    this.allowSocialFeatures = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      autoDownload: json['auto_download'] as bool? ?? false,
      downloadQuality: json['download_quality'] as String? ?? 'standard',
      wifiOnlyDownloads: json['wifi_only_downloads'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      weekendNotifications: json['weekend_notifications'] as bool? ?? true,
      publicProfile: json['public_profile'] as bool? ?? true,
      shareReadingAnalytics: json['share_reading_analytics'] as bool? ?? true,
      allowSocialFeatures: json['allow_social_features'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'auto_download': autoDownload,
      'download_quality': downloadQuality,
      'wifi_only_downloads': wifiOnlyDownloads,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'weekend_notifications': weekendNotifications,
      'public_profile': publicProfile,
      'share_reading_analytics': shareReadingAnalytics,
      'allow_social_features': allowSocialFeatures,
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? autoDownload,
    String? downloadQuality,
    bool? wifiOnlyDownloads,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? weekendNotifications,
    bool? publicProfile,
    bool? shareReadingAnalytics,
    bool? allowSocialFeatures,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoDownload: autoDownload ?? this.autoDownload,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      weekendNotifications: weekendNotifications ?? this.weekendNotifications,
      publicProfile: publicProfile ?? this.publicProfile,
      shareReadingAnalytics: shareReadingAnalytics ?? this.shareReadingAnalytics,
      allowSocialFeatures: allowSocialFeatures ?? this.allowSocialFeatures,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        language,
        autoDownload,
        downloadQuality,
        wifiOnlyDownloads,
        emailNotifications,
        pushNotifications,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
        weekendNotifications,
        publicProfile,
        shareReadingAnalytics,
        allowSocialFeatures,
      ];
}
