import 'dart:ui';

class RegionService {
  static final RegionService _instance = RegionService._internal();
  factory RegionService() => _instance;
  RegionService._internal();

  /// Returns true if the user's device locale is set to Yemen (YE).
  bool get isInYemen {
    try {
      final String? countryCode = PlatformDispatcher.instance.locale.countryCode;
      return countryCode?.toUpperCase() == 'YE';
    } catch (e) {
      // Default to true to be safe, or false if you want strict enforcement
      return true; 
    }
  }

  /// Returns true if the "Radar" (الراصد) feature should be shown.
  bool get isRadarEnabled => isInYemen;
}
