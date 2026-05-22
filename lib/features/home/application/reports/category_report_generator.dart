import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class CategoryReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generate({
    required CategoryModel category,
    required List<AccountModel> accounts,
    String currencyFilterName = 'all',
  }) async {
    if (accounts.isEmpty) return;

    final bool includeCurrencyColumn = currencyFilterName.trim().isEmpty || currencyFilterName == 'all';
    final String currencyLabel =
        includeCurrencyColumn ? 'الكل' : CurrencyModel.symbolFor(currencyFilterName.trim());

    final List<AccountModel> filteredAccounts = includeCurrencyColumn
        ? accounts
        : accounts
            .where((a) => a.currencyName.trim() == currencyFilterName.trim())
            .toList();
    if (filteredAccounts.isEmpty) return;

    double totalCredit = 0.0;
    double totalDebit = 0.0;
    for (final a in filteredAccounts) {
      totalCredit += a.totalCredit;
      totalDebit += a.totalDebit;
    }
    final netBalance = totalCredit - totalDebit;
    final netHeaderLabel = includeCurrencyColumn
        ? 'الصافي'
        : (totalCredit >= totalDebit ? 'الصافي لك' : 'الصافي عليك');

    final categoryInfo = pw.Container(
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
                'الفئة: ${category.name.isNotEmpty ? category.name : "غير محدد"}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'عدد الحسابات: ${filteredAccounts.length}',
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

    final pw.Widget financialSummary;
    if (!includeCurrencyColumn) {
      financialSummary = pw.Container(
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
              'الملخص المالي',
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
                  'لك: ${NumberFormat('#,##0').format(totalCredit)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  'عليك: ${NumberFormat('#,##0').format(totalDebit)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  '${netBalance >= 0 ? 'الصافي لك' : 'الصافي عليك'}: ${NumberFormat('#,##0').format(netBalance.abs())}',
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
      final Map<String, Map<String, double>> totalsByCurrency = <String, Map<String, double>>{};
      for (final a in filteredAccounts) {
        final key = a.currencyName.trim().isNotEmpty ? a.currencyName.trim() : 'غير محدد';
        final bucket = totalsByCurrency.putIfAbsent(
          key,
          () => <String, double>{'credit': 0.0, 'debit': 0.0, 'net': 0.0},
        );
        bucket['credit'] = (bucket['credit'] ?? 0) + a.totalCredit;
        bucket['debit'] = (bucket['debit'] ?? 0) + a.totalDebit;
        bucket['net'] = (bucket['credit'] ?? 0) - (bucket['debit'] ?? 0);
      }
      final currencyLines = totalsByCurrency.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      financialSummary = pw.Container(
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
            pw.Table.fromTextArray(
              headers: const ['العملة', 'لك', 'عليك', 'الصافي'],
              data: currencyLines
                  .map((e) {
                    final c = e.key;
                    final credit = e.value['credit'] ?? 0;
                    final debit = e.value['debit'] ?? 0;
                    final net = e.value['net'] ?? 0;
                    final symbol = CurrencyModel.symbolFor(c);
                    final netLabel = net >= 0 ? 'لك' : 'عليك';
                    return [
                      symbol,
                      NumberFormat('#,##0').format(credit),
                      NumberFormat('#,##0').format(debit),
                      '$netLabel ${NumberFormat('#,##0').format(net.abs())}',
                    ];
                  })
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: primaryColor,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.white,
              ),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: pw.TableBorder.all(color: PdfColors.white, width: 0.5),
            ),
          ],
        ),
      );
    }

    final rows = filteredAccounts
        .map((a) => [
              NumberFormat('#,##0').format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              if (includeCurrencyColumn)
                CurrencyModel.symbolFor(
                  a.currencyName.trim().isNotEmpty ? a.currencyName.trim() : 'غير محدد',
                ),
              a.name.isNotEmpty ? a.name : 'غير محدد',
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير فئة ${category.name}',
      headerContent: [
        categoryInfo,
        financialSummary,
      ],
      tableHeaders: [
        netHeaderLabel,
        'عليك',
        'لك',
        if (includeCurrencyColumn) 'العملة',
        'الحساب',
      ],
      tableData: rows,
    );
  }
}
