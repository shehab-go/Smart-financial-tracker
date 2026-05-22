import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/services/report_service.dart';

class SelectedAccountsReportGenerator {
  static Future<void> generate({
    required List<AccountModel> selected,
    String currencyFilterName = 'all',
  }) async {
    if (selected.isEmpty) return;

    final bool includeCurrencyColumn = currencyFilterName.trim().isEmpty || currencyFilterName == 'all';
    final List<AccountModel> filtered = includeCurrencyColumn
        ? selected
        : selected
            .where((a) => a.currencyName.trim() == currencyFilterName.trim())
            .toList();
    if (filtered.isEmpty) return;

    final rows = filtered
        .map((a) => [
              a.name,
              a.totalCredit.toStringAsFixed(0),
              a.totalDebit.toStringAsFixed(0),
              if (includeCurrencyColumn) CurrencyModel.symbolFor(a.currencyName),
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'حسابات مختارة',
      headerContent: const [],
      tableHeaders: [
        'الحساب',
        'لك',
        'عليك',
        if (includeCurrencyColumn) 'العملة',
      ],
      tableData: rows,
    );
  }
}
