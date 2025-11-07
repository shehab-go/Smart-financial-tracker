// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:debit_credit_app/main.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';

void main() {
  testWidgets('PersonalFinanceApp renders main navigation', (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const PersonalFinanceApp());
    await tester.pumpAndSettle();

    // Ensure the main navigation is present.
    expect(find.byType(MainNavigation), findsOneWidget);
  });
}
