import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';

import 'package:debit_credit_app/main.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Seed onboarding_completed to true so AppLockChecker routes directly to MainNavigation
    await DatabaseHelper().setMetaValue('onboarding_completed', 'true');
  });

  testWidgets('PersonalFinanceApp renders main navigation', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build the app.
      await tester.pumpWidget(const PersonalFinanceApp());
      
      // Let the real Dart event loop run to process FFI/SQLite isolate callbacks
      await Future.delayed(const Duration(seconds: 1));
      
      // Pump a frame to process rebuild after _checkLock sets isLoading to false
      await tester.pump();
    });

    // Ensure the main navigation is present.
    expect(find.byType(MainNavigation), findsOneWidget);
  });
}

