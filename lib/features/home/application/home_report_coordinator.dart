import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/services/report_service.dart';

class HomeReportCoordinator {
  static Future<void> generateCategoryReport({
    required CategoryModel category,
    required List<AccountModel> accounts,
  }) async {
    if (accounts.isEmpty) return;

    final totalCredit = accounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebit = accounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netHeaderLabel = totalCredit >= totalDebit ? 'المتبقي عليك' : 'المتبقي لك';

    final rows = accounts
        .map((a) => [
              NumberFormat('#,##0').format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              a.name,
            ])
        .toList();

    final table = pw.Table.fromTextArray(
      headers: [netHeaderLabel, 'عليه', 'له', 'الحساب'],
      data: rows,
    );

    await ReportService.generateAndOpenPdf(
      title: 'تقرير فئة ${category.name}',
      content: [table],
    );
  }

  static Future<void> generateAllAccountsReport({
    required List<AccountModel> allAccounts,
  }) async {
    if (allAccounts.isEmpty) return;

    final totalCreditAll = allAccounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebitAll = allAccounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netHeaderLabelAll = totalCreditAll >= totalDebitAll ? 'المتبقي لك' : 'المتبقي عليك';

    final rows = allAccounts
        .map((a) => [
              NumberFormat('#,##0').format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              a.category,
              a.name,
            ])
        .toList();

    final table = pw.Table.fromTextArray(
      headers: [netHeaderLabelAll, 'عليه', 'له', 'الفئة', 'الحساب'],
      data: rows,
    );

    await ReportService.generateAndOpenPdf(
      title: 'تقرير جميع الحسابات',
      content: [table],
    );
  }

  static Future<void> generateSelectedAccountsReport({
    required List<AccountModel> selected,
  }) async {
    if (selected.isEmpty) return;

    final rows = selected
        .map((a) => [
              a.name,
              a.totalCredit.toStringAsFixed(0),
              a.totalDebit.toStringAsFixed(0),
            ])
        .toList();

    final table = pw.Table.fromTextArray(headers: ['الحساب', 'له', 'عليه'], data: rows);

    await ReportService.generateAndOpenPdf(
      title: 'حسابات مختارة',
      content: [table],
    );
  }
}

