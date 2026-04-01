import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AllExpenseAccountsReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generate({
    required List<ExpenseAccountModel> accounts,
    String currencyFilterName = 'all',
  }) async {
    if (accounts.isEmpty) return;

    final bool includeCurrencyColumn = currencyFilterName.trim().isEmpty || currencyFilterName == 'all';
    final String currencyLabel =
        includeCurrencyColumn ? 'الكل' : CurrencyModel.symbolFor(currencyFilterName.trim());

    final List<ExpenseAccountModel> filteredAccounts = includeCurrencyColumn
        ? accounts
        : accounts
            .where((a) => a.currencyName.trim() == currencyFilterName.trim())
            .toList();
    if (filteredAccounts.isEmpty) return;

    final totalAmountAll =
        filteredAccounts.fold<double>(0.0, (sum, a) => sum + a.totalAmount);
    final totalOperationsAll =
        filteredAccounts.fold<int>(0, (sum, a) => sum + a.expenseCount);

    final allAccountsInfo = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تقرير جميع حسابات المصروفات',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي الحسابات: ${filteredAccounts.length}',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'العملة: $currencyLabel',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'تاريخ إنشاء التقرير: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );

    final pw.Widget financialSummaryAll;
    if (!includeCurrencyColumn) {
      financialSummaryAll = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: primaryColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'الملخص العام للمصروفات',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text(
                  'إجمالي المصروفات: ${NumberFormat('#,##0').format(totalAmountAll)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  'عدد العمليات: $totalOperationsAll',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final Map<String, double> totalsByCurrency = <String, double>{};
      for (final a in filteredAccounts) {
        final key = a.currencyName.trim().isNotEmpty ? a.currencyName.trim() : 'غير محدد';
        totalsByCurrency[key] = (totalsByCurrency[key] ?? 0.0) + a.totalAmount;
      }
      final currencyLines = totalsByCurrency.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      financialSummaryAll = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: primaryColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'الملخص المالي حسب العملة',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'عدد العمليات: $totalOperationsAll',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 8),
            ...currencyLines.map((e) {
              final symbol = CurrencyModel.symbolFor(e.key);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '$symbol - إجمالي المصروفات: ${NumberFormat('#,##0').format(e.value)}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    final rows = filteredAccounts
        .map((a) => [
              NumberFormat('#,##0').format(a.totalAmount),
              a.expenseCount.toString(),
              if (includeCurrencyColumn)
                CurrencyModel.symbolFor(
                  a.currencyName.isNotEmpty ? a.currencyName : 'غير محدد',
                ),
              a.category.isNotEmpty ? a.category : 'غير محدد',
              a.name.isNotEmpty ? a.name : 'غير محدد',
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع حسابات المصروفات',
      headerContent: [
        allAccountsInfo,
        financialSummaryAll,
      ],
      tableHeaders: [
        'الإجمالي',
        'العمليات',
        if (includeCurrencyColumn) 'العملة',
        'الفئة',
        'الحساب',
      ],
      tableData: rows,
    );
  }
}
