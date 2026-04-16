/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Knowvas';
  static const String appVersion = '1.0.0';

  // Platform channel names
  static const String readerMethodChannel = 'com.knowvas.reader/channel';
  static const String readerEventChannel = 'com.knowvas.reader/events';

  // Reader types
  static const String readerTypeEpub = 'epub';
  static const String readerTypePdf = 'pdf';
  static const String readerTypeComic = 'comic';

  // Content types
  static const String contentTypeEbook = 'ebook';
  static const String contentTypePdf = 'pdf';
  static const String contentTypeComic = 'comic';
  static const String contentTypeMagazine = 'magazine';
  static const String contentTypeAudiobook = 'audiobook';

  // Download quality
  static const String qualityStandard = 'standard';
  static const String qualityHigh = 'high';
  static const String qualityUltra = 'ultra';

  // Theme modes
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSepia = 'sepia';
  static const String themeSystem = 'system';

  // Memory thresholds
  static const double memoryThreshold = 0.8; // 80%
}
