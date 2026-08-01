import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:debit_credit_app/core/models/currency.dart';
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

    final accountInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'حساب المصروفات',
              account.name,
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('الفئة', account.category),
            ReportService.buildInfoItem(
              'العملة',
              CurrencyModel.symbolFor(account.currencyName),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'تاريخ الإنشاء',
              DateFormat('yyyy/MM/dd').format(account.createdDate),
            ),
            ReportService.buildInfoItem('', ''),
            ReportService.buildInfoItem('', ''),
          ],
        ),
      ],
    );

    final financialSummary = pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: ReportService.buildValueBlock(
                'إجمالي المصروفات',
                NumberFormat('#,##0').format(totalAmount),
                CurrencyModel.symbolFor(account.currencyName),
                isNegative: true,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: ReportService.buildValueBlock(
                'عدد العمليات',
                expenses.length.toString(),
                'عملية',
              ),
            ),
          ],
        ),
      ],
    );

    final rows = expenses
        .map((e) => [
              CurrencyModel.symbolFor(e.currency),
              NumberFormat('#,##0').format(e.amount),
              e.detail.isNotEmpty ? e.detail : '-',
              e.name.isNotEmpty ? e.name : 'غير محدد',
              DateFormat('yyyy/MM/dd').format(e.createdDate),
            ])
        .toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير حساب مصروفات ${account.name}',
      headerContent: [
        accountInfo,
        pw.SizedBox(height: 10),
        financialSummary,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل العمليات'),
      ],
      tableHeaders: const [
        'العملة',
        'المبلغ',
        'التفاصيل',
        'المصروف',
        'التاريخ',
      ],
      tableData: rows,
    );
  }
}
