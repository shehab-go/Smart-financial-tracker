import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AccountReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generate({
    required AccountModel account,
    required List<TransactionModel> transactions,
    required Map<String, double> totals,
    String currencyFilterName = 'all',
  }) async {
    final bool includeCurrencyColumn = currencyFilterName.trim().isEmpty || currencyFilterName == 'all';
    final String currencyLabel =
        includeCurrencyColumn ? 'الكل' : CurrencyModel.symbolFor(currencyFilterName.trim());

    final accountInfo = pw.Container(
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
                'الحساب: ${account.name}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'الفئة: ${account.category}',
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
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                account.phone?.isNotEmpty == true
                    ? 'الهاتف: ${account.phone}'
                    : 'الهاتف: غير محدد',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                account.address?.isNotEmpty == true
                    ? 'العنوان: ${account.address}'
                    : 'العنوان: غير محدد',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd').format(account.createdDate)}',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  account.workDetails?.isNotEmpty == true
                      ? 'العمل: ${account.workDetails}'
                      : 'العمل: غير محدد',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'المعاملات: ${account.transactionCount}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'الدائن: ${NumberFormat('#,##0').format(account.totalCredit)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green600,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'المدين: ${NumberFormat('#,##0').format(account.totalDebit)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red600,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final pw.Widget financialSummary;
    if (!includeCurrencyColumn) {
      financialSummary = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: primaryColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'الملخص المالي',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text(
                  'لك: ${NumberFormat('#,##0').format(totals['credit'] ?? 0)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  'عليك: ${NumberFormat('#,##0').format(totals['debit'] ?? 0)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  '${(totals['credit'] ?? 0) >= (totals['debit'] ?? 0) ? 'المتبقي لك' : 'المتبقي عليك'}: ${NumberFormat('#,##0').format((totals['net'] ?? 0).abs())}',
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
      for (final t in transactions) {
        final key = t.currencyName.trim().isNotEmpty ? t.currencyName.trim() : 'غير محدد';
        final bucket = totalsByCurrency.putIfAbsent(
          key,
          () => <String, double>{'credit': 0.0, 'debit': 0.0, 'net': 0.0},
        );
        if (t.type == 'credit') {
          bucket['credit'] = (bucket['credit'] ?? 0) + t.amount;
        } else {
          bucket['debit'] = (bucket['debit'] ?? 0) + t.amount;
        }
        bucket['net'] = (bucket['credit'] ?? 0) - (bucket['debit'] ?? 0);
      }

      final currencyLines = totalsByCurrency.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      financialSummary = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(12),
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
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 8),
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

    final rows = transactions
        .map((t) => [
              DateFormat('yyyy/MM/dd').format(t.date),
              t.description ?? '-',
              t.type == 'credit' ? NumberFormat('#,##0').format(t.amount) : '-',
              t.type == 'debit' ? NumberFormat('#,##0').format(t.amount) : '-',
              if (includeCurrencyColumn)
                CurrencyModel.symbolFor(
                  t.currencyName.trim().isNotEmpty ? t.currencyName.trim() : 'غير محدد',
                ),
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير حساب ${account.name}',
      headerContent: [
        accountInfo,
        financialSummary,
        pw.SizedBox(height: 10),
        pw.Text(
          'تفاصيل المعاملات',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
      ],
      tableHeaders: [
        'التاريخ',
        'تفاصيل',
        'لك',
        'عليك',
        if (includeCurrencyColumn) 'العملة',
      ],
      tableData: rows,
    );
  }
}
