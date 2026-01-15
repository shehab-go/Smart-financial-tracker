import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/models/income_resource.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AllIncomeResourcesReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static String _normalizeCurrencyName(String name) {
    if (name.trim() == 'ريلح يمني') {
      return 'ريال يمني';
    }
    return name;
  }

  static Future<void> generate({
    required List<IncomeResourceModel> resources,
    required Map<int, List<IncomeBalanceModel>> balancesByResource,
    required Map<int, double> currentBalanceAmounts,
  }) async {
    if (resources.isEmpty) return;

    final Map<String, double> totalByCurrency = {};
    int totalBalancesCount = 0;

    for (final resource in resources) {
      final id = resource.id;
      if (id == null) continue;
      final balances = balancesByResource[id] ?? const <IncomeBalanceModel>[];
      for (final balance in balances) {
        final balanceId = balance.id;
        if (balanceId == null) continue;
        final currentAmount =
            currentBalanceAmounts[balanceId] ?? balance.initialAmount;
        totalByCurrency[balance.currencyName] =
            (totalByCurrency[balance.currencyName] ?? 0.0) + currentAmount;
        totalBalancesCount++;
      }
    }

    final resourcesInfo = pw.Container(
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
                'تقرير جميع مصادر الدخل',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي المصادر: ${resources.length} | إجمالي الأرصدة: $totalBalancesCount',
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

    final currencySummaryLines = <pw.Widget>[];

    if (totalByCurrency.isEmpty) {
      currencySummaryLines.add(
        pw.Text(
          'لا توجد أرصدة مسجلة للمصادر',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.white,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      );
    } else {
      totalByCurrency.forEach((currency, total) {
        final displayCurrency = _normalizeCurrencyName(currency);
        currencySummaryLines.add(
          pw.Text(
            '${NumberFormat('#,##0.00').format(total)} $displayCurrency',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        );
      });
    }

    final summary = pw.Container(
      width: double.infinity,
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
            'الملخص العام للأرصدة',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          ...currencySummaryLines,
        ],
      ),
    );

    final List<List<String>> rows = [];

    for (final resource in resources) {
      final id = resource.id;
      if (id == null) continue;
      final balances = balancesByResource[id] ?? const <IncomeBalanceModel>[];

      final Map<String, double> totalsByCurrencyForResource = {};
      for (final balance in balances) {
        final balanceId = balance.id;
        if (balanceId == null) continue;
        final currentAmount =
            currentBalanceAmounts[balanceId] ?? balance.initialAmount;
        totalsByCurrencyForResource[balance.currencyName] =
            (totalsByCurrencyForResource[balance.currencyName] ?? 0.0) +
                currentAmount;
      }

      if (totalsByCurrencyForResource.isEmpty) {
        rows.add([
          '0.00',
          '-',
          resource.name.isNotEmpty ? resource.name : 'غير محدد',
          (resource.description ?? '').isNotEmpty ? resource.description! : '-',
        ]);
      } else {
        totalsByCurrencyForResource.forEach((currency, total) {
          final displayCurrency = _normalizeCurrencyName(currency);
          rows.add([
            NumberFormat('#,##0.00').format(total),
            displayCurrency,
            resource.name.isNotEmpty ? resource.name : 'غير محدد',
            (resource.description ?? '').isNotEmpty
                ? resource.description!
                : '-',
          ]);
        });
      }
    }

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع مصادر الدخل',
      headerContent: [
        resourcesInfo,
        summary,
      ],
      tableHeaders: const [
        'الإجمالي',
        'العملة',
        'المصدر',
        'الوصف',
      ],
      tableData: rows,
    );
  }
}
