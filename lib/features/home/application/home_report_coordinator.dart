import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class HomeReportCoordinator {
  // Convert AppTheme primary color to PDF color
  static final PdfColor primaryColor = PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<void> generateCategoryReport({
    required CategoryModel category,
    required List<AccountModel> accounts,
  }) async {
    if (accounts.isEmpty) return;

    final totalCredit = accounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebit = accounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netBalance = totalCredit - totalDebit;
    final netHeaderLabel = totalCredit >= totalDebit ? 'المتبقي لك' : 'المتبقي عليك';

    // Category Information Header
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
          // Category name and account count
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الفئة: ${category.name.isNotEmpty ? category.name : "غير محدد"}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'عدد الحسابات: ${accounts.length}',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Creation date
          pw.Text(
            'تاريخ إنشاء التقرير: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );

    // Financial Summary Card
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
                '${netBalance >= 0 ? 'المتبقي لك' : 'المتبقي عليك'}: ${NumberFormat('#,##0').format(netBalance.abs())}',
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

    // Accounts Table
    final rows = accounts
        .map((a) => [
              NumberFormat('#,##0').format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              a.name.isNotEmpty ? a.name : 'غير محدد',
            ])
        .toList();

    final table = pw.Table.fromTextArray(
      headers: [netHeaderLabel, 'عليك', 'لك', 'الحساب'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 11),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey50,
      ),
    );

    await ReportService.generateAndOpenPdf(
      title: 'تقرير فئة ${category.name}',
      content: [
        categoryInfo,
        financialSummary,
        table,
      ],
    );
  }

  static Future<void> generateAllAccountsReport({
    required List<AccountModel> allAccounts,
  }) async {
    if (allAccounts.isEmpty) return;

    final totalCreditAll = allAccounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebitAll = allAccounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netBalanceAll = totalCreditAll - totalDebitAll;
    final netHeaderLabelAll = totalCreditAll >= totalDebitAll ? 'المتبقي لك' : 'المتبقي عليك';

    // All Accounts Information Header
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
          // Report title and account count
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تقرير جميع الحسابات',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي الحسابات: ${allAccounts.length}',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Creation date
          pw.Text(
            'تاريخ إنشاء التقرير: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );

    // Financial Summary Card for All Accounts
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
                'لك: ${NumberFormat('#,##0').format(totalCreditAll)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'عليك: ${NumberFormat('#,##0').format(totalDebitAll)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${netBalanceAll >= 0 ? 'المتبقي لك' : 'المتبقي عليك'}: ${NumberFormat('#,##0').format(netBalanceAll.abs())}',
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

    // All Accounts Table
    final rows = allAccounts
        .map((a) => [
              NumberFormat('#,##0').format((a.totalCredit - a.totalDebit).abs()),
              NumberFormat('#,##0').format(a.totalDebit),
              NumberFormat('#,##0').format(a.totalCredit),
              a.category.isNotEmpty ? a.category : 'غير محدد',
              a.name.isNotEmpty ? a.name : 'غير محدد',
            ])
        .toList();

    final table = pw.Table.fromTextArray(
      headers: [netHeaderLabelAll, 'عليك', 'لك', 'الفئة', 'الحساب'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 11),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey50,
      ),
    );

    await ReportService.generateAndOpenPdf(
      title: 'تقرير جميع الحسابات',
      content: [
        allAccountsInfo,
        financialSummaryAll,
        table,
      ],
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

    final table = pw.Table.fromTextArray(headers: ['الحساب', 'لك', 'عليك'], data: rows);

    await ReportService.generateAndOpenPdf(
      title: 'حسابات مختارة',
      content: [table],
    );
  }
}

