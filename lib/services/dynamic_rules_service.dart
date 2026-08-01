import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:debit_credit_app/services/financial_tracker_service.dart';

class DynamicRulesService {


  static final DynamicRulesService _instance = DynamicRulesService._internal();
  factory DynamicRulesService() => _instance;
  DynamicRulesService._internal();

  /// Initialize Firebase & sync dynamic rules with silent offline fallback
  Future<void> syncRulesIfOnline() async {
    try {
      debugPrint('Initializing Firebase Remote Config for dynamic bank rules...');
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase already initialized or skipped: $e');
      }

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      final updated = await remoteConfig.fetchAndActivate();
      debugPrint('Firebase Remote Config fetchAndActivate: $updated');

      final rulesJson = remoteConfig.getString('financial_tracker_rules');
      if (rulesJson.isNotEmpty && rulesJson.trim().startsWith('[')) {
        await saveAndApplyRules(rulesJson);
      } else {
        await FinancialTrackerService.reloadRules();
      }
    } catch (e) {
      debugPrint('Offline/Silent fallback: Skipping remote fetch ($e)');
      await FinancialTrackerService.reloadRules();
    }
  }

  /// Saves new JSON rules content locally and instructs native Kotlin service to reload.
  Future<bool> saveAndApplyRules(String jsonContent) async {
    try {
      if (jsonContent.trim().isEmpty) return false;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/custom_tracker_config.json');
      await file.writeAsString(jsonContent);

      final success = await FinancialTrackerService.reloadRules();
      debugPrint('Dynamic bank rules saved & applied: $success');
      return success;
    } catch (e) {
      debugPrint('Error saving dynamic bank rules: $e');
      return false;
    }
  }
}
