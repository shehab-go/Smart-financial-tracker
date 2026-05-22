import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:debit_credit_app/core/models/currency.dart';
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

    final resourcesInfo = ReportService.buildCard(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ReportService.buildInfoItem(
              'نوع التقرير',
              'تقرير مصادر الدخل',
              valueStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ReportService.primaryColor,
              ),
            ),
            ReportService.buildInfoItem('إجمالي المصادر', '${resources.length}'),
            ReportService.buildInfoItem('إجمالي الأرصدة المرتبطة', '$totalBalancesCount'),
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
            'إجمالي الدخل ($displayCurrency)',
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
          (resource.description ?? '').isNotEmpty ? resource.description! : '-',
          resource.name.isNotEmpty ? resource.name : 'غير محدد',
          '-',
          '0.00',
        ]);
      } else {
        totalsByCurrencyForResource.forEach((currency, total) {
          final displayCurrency = _normalizeCurrencyName(currency);
          final symbol = CurrencyModel.symbolFor(displayCurrency);
          rows.add([
            (resource.description ?? '').isNotEmpty ? resource.description! : '-',
            resource.name.isNotEmpty ? resource.name : 'غير محدد',
            symbol,
            NumberFormat('#,##0.00').format(total),
          ]);
        });
      }
    }

    await ReportService.generateAndOpenPdfWithTableData(
      title: 'تقرير جميع مصادر الدخل',
      headerContent: [
        resourcesInfo,
        pw.SizedBox(height: 10),
        summaryWidget,
        pw.SizedBox(height: 10),
        ReportService.buildSectionTitle('تفاصيل مصادر الدخل والأرصدة'),
      ],
      tableHeaders: const [
        'الوصف',
        'المصدر',
        'العملة',
        'الإجمالي',
      ],
      tableData: rows,
    );
  }
}
