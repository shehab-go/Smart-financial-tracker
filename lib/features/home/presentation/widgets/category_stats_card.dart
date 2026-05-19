import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class CategoryStatsCard extends StatefulWidget {
  final List<AccountModel> accounts;
  final double shrinkProgress;

  const CategoryStatsCard({
    super.key,
    required this.accounts,
    this.shrinkProgress = 0.0,
  });

  @override
  State<CategoryStatsCard> createState() => _CategoryStatsCardState();
}

class _CategoryStatsCardState extends State<CategoryStatsCard> {
  int _touchedIndex = -1;

  Widget _buildCollapsedLayout(double totalCredit, double totalDebit, String primaryCurrency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppTheme.primaryColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'التحليلات المالية',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'له: ${NumberFormat('#,##0').format(totalCredit)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'عليه: ${NumberFormat('#,##0').format(totalDebit)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            primaryCurrency,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group accounts by currency to calculate correct totals
    final Map<String, List<AccountModel>> currencyGroups = {};
    for (var account in widget.accounts) {
      currencyGroups.putIfAbsent(account.currencyName, () => []).add(account);
    }

    // Determine primary currency (the one with most accounts)
    String primaryCurrency = currencyGroups.keys.first;
    int maxCount = 0;
    currencyGroups.forEach((currency, list) {
      if (list.length > maxCount) {
        maxCount = list.length;
        primaryCurrency = currency;
      }
    });

    // Calculate totals for primary currency
    double totalCredit = 0;
    double totalDebit = 0;
    for (var account in currencyGroups[primaryCurrency]!) {
      totalCredit += account.totalCredit;
      totalDebit += account.totalDebit;
    }

    final double total = totalCredit + totalDebit;
    final bool hasData = total > 0;

    final creditPercent = hasData ? (totalCredit / total) * 100 : 0.0;
    final debitPercent = hasData ? (totalDebit / total) * 100 : 0.0;

    // Filter other currencies that have non-zero balances
    final List<MapEntry<String, List<AccountModel>>> otherCurrenciesWithBalances = [];
    currencyGroups.entries
        .where((entry) => entry.key != primaryCurrency)
        .forEach((entry) {
      double cred = 0;
      double deb = 0;
      for (var a in entry.value) {
        cred += a.totalCredit;
        deb += a.totalDebit;
      }
      if (cred > 0 || deb > 0) {
        otherCurrenciesWithBalances.add(entry);
      }
    });

    final bool hasOtherCurrencies = otherCurrenciesWithBalances.isNotEmpty;

    // Linear interpolation helper
    double lerp(double a, double b, double t) => a + (b - a) * t;

    final double collapsedHeight = 54.0;
    final double expandedHeight = hasOtherCurrencies ? 340.0 : 240.0;

    final double currentHeight = lerp(expandedHeight, collapsedHeight, widget.shrinkProgress);
    final double paddingVal = lerp(18.0, 10.0, widget.shrinkProgress);

    // Split fade opacities to completely prevent layout overlapping / text ghosting:
    // Expanded layout fades from 1.0 to 0.0 during the first 50% of the scroll progress (0.0 -> 0.5)
    final double expandedOpacity = (1.0 - (widget.shrinkProgress * 2.0)).clamp(0.0, 1.0);
    // Collapsed layout fades from 0.0 to 1.0 during the second 50% of the scroll progress (0.5 -> 1.0)
    final double collapsedOpacity = ((widget.shrinkProgress - 0.5) * 2.0).clamp(0.0, 1.0);

    return Container(
      height: currentHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(paddingVal),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.6), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Collapsed Layout (fades in)
          if (collapsedOpacity > 0.0)
            Opacity(
              opacity: collapsedOpacity,
              child: _buildCollapsedLayout(totalCredit, totalDebit, primaryCurrency),
            ),

          // Expanded Layout (fades out)
          if (expandedOpacity > 0.0)
            Opacity(
              opacity: expandedOpacity,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 68, // Account for margins & paddings
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'التحليلات والمؤشرات المالية',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              primaryCurrency,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bento Grid Asymmetric Layout
                      Row(
                        children: [
                          // Left Bento: Stats Indicators
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Credit Stat ( له )
                                _buildBentoStatCard(
                                  title: 'إجمالي الديون لك (له)',
                                  amount: totalCredit,
                                  percentage: creditPercent,
                                  color: AppTheme.creditColor,
                                  icon: Icons.trending_up_rounded,
                                  isCredit: true,
                                ),
                                const SizedBox(height: 12),
                                // Debit Stat ( عليه )
                                _buildBentoStatCard(
                                  title: 'إجمالي الديون عليك (عليه)',
                                  amount: totalDebit,
                                  percentage: debitPercent,
                                  color: AppTheme.debitColor,
                                  icon: Icons.trending_down_rounded,
                                  isCredit: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Right Bento: Interactive Chart
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 136,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.dividerColor.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: !hasData
                                  ? const Center(
                                      child: Text(
                                        'لا توجد عمليات',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textTertiary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                if (pieTouchResponse != null &&
                                                    pieTouchResponse.touchedSection != null) {
                                                  final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                                  if (index != _touchedIndex && index >= 0) {
                                                    HapticFeedback.selectionClick();
                                                    setState(() {
                                                      _touchedIndex = index;
                                                    });
                                                  }
                                                } else {
                                                  if (_touchedIndex != -1) {
                                                    setState(() {
                                                      _touchedIndex = -1;
                                                    });
                                                  }
                                                }
                                              },
                                            ),
                                            borderData: FlBorderData(show: false),
                                            sectionsSpace: 3,
                                            centerSpaceRadius: 28,
                                            sections: [
                                              PieChartSectionData(
                                                color: AppTheme.creditColor,
                                                value: totalCredit,
                                                title: '${creditPercent.toStringAsFixed(0)}%',
                                                radius: _touchedIndex == 0 ? 28 : 22,
                                                titleStyle: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                color: AppTheme.debitColor,
                                                value: totalDebit,
                                                title: '${debitPercent.toStringAsFixed(0)}%',
                                                radius: _touchedIndex == 1 ? 28 : 22,
                                                titleStyle: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Center Indicator
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'النسبة',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: AppTheme.textTertiary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              _touchedIndex == 0
                                                  ? '${creditPercent.toStringAsFixed(0)}%'
                                                  : _touchedIndex == 1
                                                      ? '${debitPercent.toStringAsFixed(0)}%'
                                                      : 'موزعة',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // Other Currencies List
                      if (hasOtherCurrencies) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: AppTheme.dividerColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'أرصدة العملات الأخرى المسجلة:',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: otherCurrenciesWithBalances.map((entry) {
                              double cred = 0;
                              double deb = 0;
                              for (var a in entry.value) {
                                cred += a.totalCredit;
                                deb += a.totalDebit;
                              }
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.dividerColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${entry.key}: ',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'له ${NumberFormat('#,##0').format(cred)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      ' | ',
                                      style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                                    ),
                                    Text(
                                      'عليه ${NumberFormat('#,##0').format(deb)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.errorColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required double amount,
    required double percentage,
    required Color color,
    required IconData icon,
    required bool isCredit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Stat Icon Wrap
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        NumberFormat('#,##0').format(amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
