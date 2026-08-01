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

    final allAccountsInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'نوع التقرير',
              'تقرير حسابات المصروفات',
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('إجمالي الحسابات', '${filteredAccounts.length}'),
            ReportService.buildInfoItem('العملة المفلترة', currencyLabel),
          ],
        ),
      ],
    );

    final pw.Widget financialSummaryAll;
    if (!includeCurrencyColumn) {
      financialSummaryAll = pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'إجمالي المصروفات',
                  NumberFormat('#,##0').format(totalAmountAll),
                  currencyLabel,
                  isNegative: true,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'عدد العمليات',
                  totalOperationsAll.toString(),
                  'عملية',
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      final Map<String, double> totalsByCurrency = <String, double>{};
      for (final a in filteredAccounts) {
        final key = a.currencyName.trim().isNotEmpty ? a.currencyName.trim() : 'غير محدد';
        totalsByCurrency[key] = (totalsByCurrency[key] ?? 0.0) + a.totalAmount;
      }
      final currencyLines = totalsByCurrency.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      financialSummaryAll = ReportService.buildCard(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              ReportService.buildInfoItem(
                'الملخص المالي حسب العملة',
                'المصروفات الإجمالية',
                valueStyle: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: ReportService.slate800,
                ),
              ),
              ReportService.buildInfoItem('إجمالي العمليات', '$totalOperationsAll'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: const ['العملة', 'إجمالي المصروفات'],
            data: currencyLines
                .map((e) {
                  final symbol = CurrencyModel.symbolFor(e.key);
                  return [
                    symbol,
                    NumberFormat('#,##0').format(e.value),
                  ];
                })
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: ReportService.primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            cellStyle: pw.TextStyle(fontSize: 9, color: ReportService.slate800),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: ReportService.slate200, width: 0.5),
              bottom: pw.BorderSide(color: ReportService.slate200, width: 0.5),
            ),
            oddRowDecoration: pw.BoxDecoration(
              color: ReportService.slate50,
            ),
          ),
        ],
      );
    }

    final rows = filteredAccounts
        .map((a) => [
              a.name.isNotEmpty ? a.name : 'غير محدد',
              a.category.isNotEmpty ? a.category : 'غير محدد',
              if (includeCurrencyColumn)
                CurrencyModel.symbolFor(
                  a.currencyName.isNotEmpty ? a.currencyName : 'غير محدد',
                ),
              a.expenseCount.toString(),
              NumberFormat('#,##0').format(a.totalAmount),
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع حسابات المصروفات',
      headerContent: [
        allAccountsInfo,
        pw.SizedBox(height: 10),
        financialSummaryAll,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل حسابات المصروفات'),
      ],
      tableHeaders: [
        'الحساب',
        'الفئة',
        if (includeCurrencyColumn) 'العملة',
        'العمليات',
        'الإجمالي',
      ],
      tableData: rows,
    );
  }
}
