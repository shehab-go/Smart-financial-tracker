import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/services/report_service.dart';

class SelectedAccountsReportGenerator {
  static Future<void> generate({
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

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'حسابات مختارة',
      headerContent: const [],
      tableHeaders: ['الحساب', 'له', 'عليه'],
      tableData: rows,
    );
  }
}
