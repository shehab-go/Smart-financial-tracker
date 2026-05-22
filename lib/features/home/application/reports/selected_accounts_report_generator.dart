import 'package:pdf/widgets.dart' as pw;
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

    final headerCard = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'نوع التقرير',
              'تقرير الحسابات المختارة',
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('عدد الحسابات المختارة', '${filtered.length}'),
            ReportService.buildInfoItem('العملة المفلترة', includeCurrencyColumn ? 'الكل' : CurrencyModel.symbolFor(currencyFilterName.trim())),
          ],
        ),
      ],
    );

    final rows = filtered
        .map((a) => [
              if (includeCurrencyColumn) CurrencyModel.symbolFor(a.currencyName),
              a.totalDebit.toStringAsFixed(0),
              a.totalCredit.toStringAsFixed(0),
              a.name,
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'حسابات مختارة',
      headerContent: [
        headerCard,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل الحسابات المختارة'),
      ],
      tableHeaders: [
        if (includeCurrencyColumn) 'العملة',
        'عليك',
        'لك',
        'الحساب',
      ],
      tableData: rows,
    );
  }
}
