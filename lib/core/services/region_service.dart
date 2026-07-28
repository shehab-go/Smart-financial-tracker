import 'dart:ui';

class RegionService {
  static final RegionService _instance = RegionService._internal();
  factory RegionService() => _instance;
  RegionService._internal();

  /// Returns true if the user's device locale or timezone indicates they are in Yemen,
  /// or if the device language is set to English/Arabic.
  bool get isInYemen {
    try {
      // 1. Check all system preferred locales
      final locales = PlatformDispatcher.instance.locales;
      for (final locale in locales) {
        final country = locale.countryCode?.toUpperCase();
        final language = locale.languageCode.toLowerCase();
        if (country == 'YE' || language == 'ar') {
          return true;
        }
      }

      // 2. Check primary locale
      final locale = PlatformDispatcher.instance.locale;
      final String? countryCode = locale.countryCode?.toUpperCase();

      // If country is explicitly Yemen or not set, show it.
      if (countryCode == null || countryCode.isEmpty || countryCode == 'YE') {
        return true;
      }

      // 3. Check timezone offset (Yemen is UTC+3)
      final offsetInHours = DateTime.now().timeZoneOffset.inHours;
      if (offsetInHours == 3) {
        return true;
      }

      // 4. Default for English / Arabic device languages:
      // When device language is set to English ('en_US', 'en_GB'), countryCode is 'US' or 'GB'.
      // Users in Yemen with English device language should still see the Radar feature.
      final languageCode = locale.languageCode.toLowerCase();
      if (languageCode == 'en' || languageCode == 'ar') {
        return true;
      }

      return false;
    } catch (e) {
      // Default to true to be safe
      return true; 
    }
  }

  /// Returns true if the "Radar" (الراصد) feature should be shown.
  bool get isRadarEnabled => isInYemen;
}
