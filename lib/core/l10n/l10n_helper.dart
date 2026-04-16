import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension to easily access localized strings from BuildContext
extension LocalizationExtension on BuildContext {
  /// Get the current AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);
  
  /// Check if the current locale is RTL (Right-to-Left)
  bool get isRTL => locale.languageCode == 'ar' || locale.languageCode == 'he';
}

/// Helper class for localization utilities
class L10nHelper {
  /// Get supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('ar'), // Arabic
  ];
  
  /// Get language name from code
  static String getLanguageName(String code) {
    switch (code) {
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
  
  /// Get language code from locale
  static String getLanguageCode(Locale locale) {
    return locale.languageCode;
  }
  
  /// Check if a language code is supported
  static bool isLanguageSupported(String code) {
    return supportedLocales.any((locale) => locale.languageCode == code);
  }
  
  /// Get locale from language code
  static Locale getLocaleFromCode(String code) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => const Locale('en'),
    );
  }
}
