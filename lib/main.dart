import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/app_lock_screen.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:workmanager/workmanager.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:debit_credit_app/services/smart_debt_settlement_service.dart';
import 'package:debit_credit_app/services/dynamic_rules_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task == AutoBackupManager.workmanagerTaskName) {
      try {
        await AutoBackupManager.instance.maybeRunAutoBackup(trigger: 'workmanager');
        return true;
      } catch (e) {
        return false;
      }
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  } catch (e) {
    debugPrint('Workmanager init failed: $e');
  }
  
  // Initialize date formatting for Arabic locale
  await initializeDateFormatting('ar', null);
  
  // Set system UI style globally for pristine edge-to-edge rendering
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark status bar icons on light background
    statusBarBrightness: Brightness.light, // For iOS: Dark status bar icons
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark, // Dark navigation icons
  ));
  
  // Set preferred orientations

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Smart Debt Settlement Service to listen for background transactions
  SmartDebtSettlementService().initialize();

  // Sync dynamic bank rules if available
  DynamicRulesService().syncRulesIfOnline();

  runApp(Phoenix(child: const PersonalFinanceApp()));
}

class PersonalFinanceApp extends StatelessWidget {

  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SmartDebtSettlementService.navigatorKey,
      title: '???? ??????',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Avoid wrapping a global SafeArea; handle paddings per-screen using MediaQuery insets.
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AppLockChecker(),
    );
  }
}
