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

    final balancesInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'نوع التقرير',
              'تقرير أرصدة الدخل',
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('إجمالي الأرصدة', '${balances.length}'),
            ReportService.buildInfoItem('أرصدة افتراضية', '$defaultCount'),
          ],
        ),
      ],
    );

    final List<pw.Widget> summaryBlocks = [];
    totalByCurrency.forEach((currency, total) {
      final displayCurrency = _normalizeCurrencyName(currency);
      final symbol = CurrencyModel.symbolFor(displayCurrency);
      summaryBlocks.add(
        pw.Expanded(
          child: ReportService.buildValueBlock(
            'رصيد الدخل ($displayCurrency)',
            NumberFormat('#,##0.00').format(total),
            symbol,
            isPositive: true,
          ),
        ),
      );
    });

    final pw.Widget summaryWidget;
    if (summaryBlocks.isEmpty) {
      summaryWidget = ReportService.buildCard(
        children: [
          pw.Center(
            child: pw.Text(
              'لا توجد أرصدة مسجلة',
              style: pw.TextStyle(fontSize: 11, color: ReportService.slate500),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      );
    } else {
      final List<pw.Widget> summaryRows = [];
      for (int i = 0; i < summaryBlocks.length; i += 2) {
        final rowChildren = <pw.Widget>[];
        rowChildren.add(summaryBlocks[i]);
        if (i + 1 < summaryBlocks.length) {
          rowChildren.add(pw.SizedBox(width: 10));
          rowChildren.add(summaryBlocks[i + 1]);
        } else {
          rowChildren.add(pw.SizedBox(width: 10));
          rowChildren.add(pw.Expanded(child: pw.Container()));
        }
        summaryRows.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: rowChildren,
          ),
        );
        if (i + 2 < summaryBlocks.length) {
          summaryRows.add(pw.SizedBox(height: 10));
        }
      }
      summaryWidget = pw.Column(children: summaryRows);
    }

    final rows = balances.map((balance) {
      final id = balance.id;
      final currentAmount = id == null
          ? balance.initialAmount
          : (currentBalanceAmounts[id] ?? balance.initialAmount);
      final resource = resourceById[balance.resourceId];
      final displayCurrency = _normalizeCurrencyName(balance.currencyName);
      final symbol = CurrencyModel.symbolFor(displayCurrency);

      return [
        balance.isDefault ? 'نعم' : 'لا',
        resource?.name ?? 'مصدر غير معروف',
        balance.name.isNotEmpty ? balance.name : 'غير محدد',
        symbol,
        NumberFormat('#,##0.00').format(currentAmount),
      ];
    }).toList();

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع أرصدة الدخل',
      headerContent: [
        balancesInfo,
        pw.SizedBox(height: 10),
        summaryWidget,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل أرصدة الدخل'),
      ],
      tableHeaders: const [
        'افتراضي',
        'مصدر الدخل',
        'اسم الرصيد',
        'العملة',
        'الرصيد الحالي',
      ],
      tableData: rows,
    );
  }
}
