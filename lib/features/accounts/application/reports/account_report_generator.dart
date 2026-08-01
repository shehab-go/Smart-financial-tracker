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

    final accountInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'الحساب',
              account.name,
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('الفئة', account.category),
            ReportService.buildInfoItem('العملة المفلترة', currencyLabel),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'الهاتف',
              account.phone?.isNotEmpty == true ? account.phone! : 'غير محدد',
            ),
            ReportService.buildInfoItem(
              'العنوان',
              account.address?.isNotEmpty == true ? account.address! : 'غير محدد',
            ),
            ReportService.buildInfoItem(
              'تاريخ الإنشاء',
              DateFormat('yyyy/MM/dd').format(account.createdDate),
            ),
          ],
        ),
        if (account.workDetails?.isNotEmpty == true) ...[
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: ReportService.buildInfoItem('تفاصيل العمل', account.workDetails!),
              ),
            ],
          ),
        ],
      ],
    );

    final pw.Widget financialSummary;
    if (!includeCurrencyColumn) {
      final netAmount = (totals['credit'] ?? 0) - (totals['debit'] ?? 0);
      financialSummary = pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'لك (دائن)',
                  NumberFormat('#,##0').format(totals['credit'] ?? 0),
                  currencyLabel,
                  isPositive: true,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: ReportService.buildValueBlock(
                  'عليك (مدين)',
                  NumberFormat('#,##0').format(totals['debit'] ?? 0),
                  currencyLabel,
                  isNegative: true,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          ReportService.buildValueBlock(
            netAmount >= 0 ? 'الرصيد المتبقي (لك)' : 'الرصيد المتبقي (عليك)',
            NumberFormat('#,##0').format(netAmount.abs()),
            currencyLabel,
            isPositive: netAmount >= 0,
            isNegative: netAmount < 0,
          ),
        ],
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
        pw.SizedBox(height: 10),
        financialSummary,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل المعاملات'),
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
