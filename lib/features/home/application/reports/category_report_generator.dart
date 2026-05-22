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

    final categoryInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'الفئة',
              category.name.isNotEmpty ? category.name : 'غير محدد',
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('عدد الحسابات', '${filteredAccounts.length}'),
            ReportService.buildInfoItem('العملة المفلترة', currencyLabel),
          ],
        ),
      ],
    );

    final pw.Widget financialSummary;
    if (!includeCurrencyColumn) {
      final netAmount = totalCredit - totalDebit;
      financialSummary = pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'إجمالي لك (دائن)',
                  NumberFormat('#,##0').format(totalCredit),
                  currencyLabel,
                  isPositive: true,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'إجمالي عليك (مدين)',
                  NumberFormat('#,##0').format(totalDebit),
                  currencyLabel,
                  isNegative: true,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          ReportService.buildValueBlock(
            netAmount >= 0 ? 'صافي الرصيد المتبقي (لك)' : 'صافي الرصيد المتبقي (عليك)',
            NumberFormat('#,##0').format(netAmount.abs()),
            currencyLabel,
            isPositive: netAmount >= 0,
            isNegative: netAmount < 0,
          ),
        ],
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

      financialSummary = ReportService.buildCard(
        children: [
          pw.Text(
            'الملخص المالي حسب العملة',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: ReportService.slate800,
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
        pw.SizedBox(height: 10),
        financialSummary,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل الحسابات للفئة'),
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
