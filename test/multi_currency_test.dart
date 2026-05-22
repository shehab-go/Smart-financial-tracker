import 'package:flutter_test/flutter_test.dart';
import 'package:debit_credit_app/core/models/account.dart';

void main() {
  group('Multi-currency Model and Stats Tests', () {
    test('AccountCurrencyStats fromMap parses correctly', () {
      final map = {
        'currencyName': 'دولار',
        'totalDebit': 150.0,
        'totalCredit': 350.5,
        'transactionCount': 5,
      };

      final stats = AccountCurrencyStats.fromMap(map);

      expect(stats.currencyName, 'دولار');
      expect(stats.totalDebit, 150.0);
      expect(stats.totalCredit, 350.5);
      expect(stats.transactionCount, 5);
    });

    test('AccountModel default values for currencyStats', () {
      final account = AccountModel(
        id: 1,
        name: 'علي حسن',
        category: 'عملاء',
        createdDate: DateTime.now(),
      );

      expect(account.currencyStats, isEmpty);
    });

    test('AccountModel.copyWith copies currencyStats', () {
      final account = AccountModel(
        id: 1,
        name: 'علي حسن',
        category: 'عملاء',
        createdDate: DateTime.now(),
      );

      final stats = [
        AccountCurrencyStats(
          currencyName: 'YER',
          totalDebit: 1000,
          totalCredit: 5000,
          transactionCount: 2,
        ),
      ];

      final updated = account.copyWith(currencyStats: stats);

      expect(updated.currencyStats.length, 1);
      expect(updated.currencyStats[0].currencyName, 'YER');
      expect(updated.currencyStats[0].totalCredit, 5000);
    });

    test('Currency stats merging algorithm maps and merges "محلي" with local currency', () {
      final String localCurrencyName = 'ريال يمني';
      final List<AccountCurrencyStats> originalStats = [
        AccountCurrencyStats(
          currencyName: 'محلي',
          totalDebit: 100.0,
          totalCredit: 200.0,
          transactionCount: 2,
        ),
        AccountCurrencyStats(
          currencyName: 'ريال يمني',
          totalDebit: 300.0,
          totalCredit: 400.0,
          transactionCount: 3,
        ),
        AccountCurrencyStats(
          currencyName: 'USD',
          totalDebit: 50.0,
          totalCredit: 75.0,
          transactionCount: 1,
        ),
      ];

      // Emulate the mapping and merging logic used in home_screen.dart
      final List<AccountCurrencyStats> merged = [];
      final Map<String, AccountCurrencyStats> statsMap = {};
      for (final s in originalStats) {
        final name = (s.currencyName.trim() == 'محلي' || s.currencyName.trim() == localCurrencyName.trim())
            ? localCurrencyName.trim()
            : s.currencyName.trim();
        if (statsMap.containsKey(name)) {
          final existing = statsMap[name]!;
          statsMap[name] = AccountCurrencyStats(
            currencyName: name,
            totalDebit: existing.totalDebit + s.totalDebit,
            totalCredit: existing.totalCredit + s.totalCredit,
            transactionCount: existing.transactionCount + s.transactionCount,
          );
        } else {
          statsMap[name] = AccountCurrencyStats(
            currencyName: name,
            totalDebit: s.totalDebit,
            totalCredit: s.totalCredit,
            transactionCount: s.transactionCount,
          );
        }
      }
      merged.addAll(statsMap.values);

      expect(merged.length, 2);
      
      final yerStat = merged.firstWhere((s) => s.currencyName == 'ريال يمني');
      expect(yerStat.totalDebit, 400.0); // 100 + 300
      expect(yerStat.totalCredit, 600.0); // 200 + 400
      expect(yerStat.transactionCount, 5); // 2 + 3

      final usdStat = merged.firstWhere((s) => s.currencyName == 'USD');
      expect(usdStat.totalDebit, 50.0);
      expect(usdStat.totalCredit, 75.0);
      expect(usdStat.transactionCount, 1);
    });
  });
}
