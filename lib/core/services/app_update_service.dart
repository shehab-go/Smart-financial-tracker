import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdateAndPrompt(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('يتوفر تحديث جديد للتطبيق.'),
              action: SnackBarAction(
                label: 'تثبيت الآن',
                onPressed: () async {
                  try {
                    await InAppUpdate.completeFlexibleUpdate();
                  } catch (e) {
                    debugPrint('Error completing flexible update: $e');
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }
}
