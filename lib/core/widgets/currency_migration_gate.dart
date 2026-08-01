import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';
import 'package:debit_credit_app/features/currencies/presentation/screens/currency_migration_screen.dart';

class CurrencyMigrationGate extends StatefulWidget {
  const CurrencyMigrationGate({super.key});

  @override
  State<CurrencyMigrationGate> createState() => _CurrencyMigrationGateState();
}

class _CurrencyMigrationGateState extends State<CurrencyMigrationGate> {
  bool _isChecking = true;
  bool _needsMigration = false;
  List<String> _legacyCurrencies = const [];

  @override
  void initState() {
    super.initState();
    _checkMigration();
  }

  Future<void> _checkMigration() async {
    final db = DatabaseHelper();
    try {
      final completed = await db.isCurrencyMigrationCompleted();
      if (!completed) {
        final legacy = await db.getUsedCurrenciesForMigration();
        if (legacy.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _needsMigration = true;
            _legacyCurrencies = legacy;
            _isChecking = false;
          });
          return;
        } else {
          // No legacy currencies in use; mark as completed.
          await db.setMetaValue('currency_migration_completed', 'true');
        }
      }
    } catch (_) {
      // In case of any error, do not block app; continue to main navigation.
    }

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _needsMigration = false;
    });
  }

  void _handleMigrationCompleted() {
    setState(() {
      _needsMigration = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsMigration) {
      return CurrencyMigrationScreen(
        legacyCurrencies: _legacyCurrencies,
        onCompleted: _handleMigrationCompleted,
      );
    }

    return const MainNavigation();
  }
}
