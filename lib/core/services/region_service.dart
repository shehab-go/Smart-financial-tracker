import 'dart:ui';

class RegionService {
  static final RegionService _instance = RegionService._internal();
  factory RegionService() => _instance;
  RegionService._internal();

  /// Returns true if the user's device locale is set to Yemen (YE).
  bool get isInYemen {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final String? countryCode = locale.countryCode;

      // If country is explicitly Yemen or not set, we show it.
      if (countryCode == null || countryCode.isEmpty || countryCode.toUpperCase() == 'YE') {
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
