import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AllAccountsReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generate({
    required List<AccountModel> allAccounts,
  }) async {
    if (allAccounts.isEmpty) return;

    final totalCreditAll =
        allAccounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebitAll =
        allAccounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netBalanceAll = totalCreditAll - totalDebitAll;
    final netHeaderLabelAll = totalCreditAll >= totalDebitAll
        ? 'المتبقي لهم'
        : 'المتبقي عليهم';

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
                'تقرير جميع الحسابات',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي الحسابات: ${allAccounts.length}',
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

    final financialSummaryAll = pw.Container(
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
            'الملخص المالي الإجمالي',
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
                'له: ${NumberFormat('#,##0').format(totalCreditAll)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'عليه: ${NumberFormat('#,##0').format(totalDebitAll)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${netBalanceAll >= 0 ? 'المتبقي لهم' : 'المتبقي عليهم'}: ${NumberFormat('#,##0').format(netBalanceAll.abs())}',
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

    final rows = allAccounts
        .map((a) => [
              NumberFormat('#,##0')
                  .format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              a.category.isNotEmpty ? a.category : 'غير محدد',
              a.name.isNotEmpty ? a.name : 'غير محدد',
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع الحسابات',
      headerContent: [
        allAccountsInfo,
        financialSummaryAll,
      ],
      tableHeaders: [
        netHeaderLabelAll,
        'عليه',
        'له',
        'الفئة',
        'الحساب',
      ],
      tableData: rows,
    );
  }
}
