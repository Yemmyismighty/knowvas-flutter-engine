/// Storage key constants for secure storage and shared preferences
class StorageKeys {
  StorageKeys._();

  // Secure storage keys (for sensitive data)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String encryptionKey = 'encryption_key';
  static const String userId = 'user_id';
  static const String accessTokenExpiry = 'access_token_expiry';
  static const String refreshTokenExpiry = 'refresh_token_expiry';
  static const String lastLoginTime = 'last_login_time';
  static const String userData = 'user_data';

  // Shared preferences keys
  static const String isFirstLaunch = 'is_first_launch';
  static const String preferredTheme = 'preferred_theme';
  static const String preferredLanguage = 'preferred_language';
  static const String preferredCurrency = 'preferred_currency';
  static const String autoDownload = 'auto_download';
  static const String wifiOnlyDownload = 'wifi_only_download';
  static const String downloadQuality = 'download_quality';

  // Database name
  static const String databaseName = 'knowvas.db';
  static const int databaseVersion = 1;
}
