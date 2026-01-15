import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class ExpenseAccountReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generate({
    required ExpenseAccountModel account,
    required List<ExpenseModel> expenses,
  }) async {
    if (expenses.isEmpty) return;

    final totalAmount =
        expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

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
                'حساب المصروفات: ${account.name}',
                style: pw.TextStyle(
                  fontSize: 16,
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
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'العملة: ${account.currencyName}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd').format(account.createdDate)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );

    final financialSummary = pw.Container(
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
            'الملخص المالي للحساب',
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
                'إجمالي المصروفات: ${NumberFormat('#,##0').format(totalAmount)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'عدد العمليات: ${expenses.length}',
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

    final rows = expenses
        .map((e) => [
              DateFormat('yyyy/MM/dd').format(e.createdDate),
              e.name.isNotEmpty ? e.name : 'غير محدد',
              e.detail.isNotEmpty ? e.detail : '-',
              NumberFormat('#,##0').format(e.amount),
              e.currency,
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير حساب مصروفات ${account.name}',
      headerContent: [
        accountInfo,
        financialSummary,
      ],
      tableHeaders: const [
        'التاريخ',
        'المصروف',
        'التفاصيل',
        'المبلغ',
        'العملة',
      ],
      tableData: rows,
    );
  }
}
