import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';
import 'package:debit_credit_app/core/widgets/currency_migration_gate.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:world_countries/world_countries.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Arabic locale
  await initializeDateFormatting('ar', null);
  
  // Let AndroidX EdgeToEdge handle system bars; only control overlay visibility.
  // Do not set status/navigation bar colors directly to avoid deprecated APIs on Android 15.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(Phoenix(child: const PersonalFinanceApp()));
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حسابات يوميه',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Avoid wrapping a global SafeArea; handle paddings per-screen using MediaQuery insets.
      builder: (context, child) => child ?? const SizedBox.shrink(),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        TypedLocaleDelegate(),
      ],
      home: const CurrencyMigrationGate(),
    );
  }
}

