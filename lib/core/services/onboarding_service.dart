import '../db/database_helper.dart';

class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const String _metaOnboardingCompleted = 'onboarding_completed';

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    try {
      final value = await DatabaseHelper().getMetaValue(_metaOnboardingCompleted);
      if (value == 'true') {
        return true;
      }

      // Smart Bypass: If they already have accounts, they are existing upgrading users.
      // Auto-complete onboarding for them to protect their user experience.
      final accounts = await DatabaseHelper().getAccounts();
      if (accounts.isNotEmpty) {
        await setOnboardingCompleted();
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set onboarding status to completed
  Future<void> setOnboardingCompleted() async {
    try {
      await DatabaseHelper().setMetaValue(_metaOnboardingCompleted, 'true');
    } catch (_) {}
  }
}
