import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

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
  
  runApp(const PersonalFinanceApp());
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
      home: const MainNavigation(),
    );
  }
}

