import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/models/income_resource.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AllIncomeBalancesReportGenerator {
  static final PdfColor primaryColor =
      PdfColor.fromInt(AppTheme.primaryColor.value);

  static String _normalizeCurrencyName(String name) {
    if (name.trim() == 'ريلح يمني') {
      return 'ريال يمني';
    }
    return name;
  }

  static Future<void> generate({
    required List<IncomeBalanceModel> balances,
    required List<IncomeResourceModel> resources,
    required Map<int, double> currentBalanceAmounts,
  }) async {
    if (balances.isEmpty) return;

    final Map<int, IncomeResourceModel> resourceById = {
      for (final r in resources)
        if (r.id != null) r.id!: r,
    };

    final Map<String, double> totalByCurrency = {};
    int defaultCount = 0;

    for (final balance in balances) {
      final id = balance.id;
      if (id == null) continue;
      final currentAmount =
          currentBalanceAmounts[id] ?? balance.initialAmount;
      totalByCurrency[balance.currencyName] =
          (totalByCurrency[balance.currencyName] ?? 0.0) + currentAmount;
      if (balance.isDefault) {
        defaultCount++;
      }
    }

    final balancesInfo = pw.Container(
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
                'تقرير جميع أرصدة الدخل',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي الأرصدة: ${balances.length} | الأرصدة الافتراضية: $defaultCount',
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
          'لا توجد أرصدة مسجلة',
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
        final symbol = CurrencyModel.symbolFor(displayCurrency);
        currencySummaryLines.add(
          pw.Text(
            '${NumberFormat('#,##0.00').format(total)} $symbol',
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

    final rows = balances.map((balance) {
      final id = balance.id;
      final currentAmount = id == null
          ? balance.initialAmount
          : (currentBalanceAmounts[id] ?? balance.initialAmount);
      final resource = resourceById[balance.resourceId];
      final displayCurrency = _normalizeCurrencyName(balance.currencyName);
      final symbol = CurrencyModel.symbolFor(displayCurrency);

      return [
        NumberFormat('#,##0.00').format(currentAmount),
        symbol,
        balance.name.isNotEmpty ? balance.name : 'غير محدد',
        resource?.name ?? 'مصدر غير معروف',
        balance.isDefault ? 'نعم' : 'لا',
      ];
    }).toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع أرصدة الدخل',
      headerContent: [
        balancesInfo,
        summary,
      ],
      tableHeaders: const [
        'الرصيد الحالي',
        'العملة',
        'اسم الرصيد',
        'مصدر الدخل',
        'افتراضي',
      ],
      tableData: rows,
    );
  }
}
