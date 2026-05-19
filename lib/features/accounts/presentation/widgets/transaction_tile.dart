import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool highlighted;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.selected,
    this.onTap,
    this.onLongPress,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.type == 'credit';
    final String formattedDate = DateFormat('yyyy/MM/dd').format(transaction.date);
    final String formattedTime = DateFormat('hh:mm a').format(transaction.date);
    final String formattedAmount = NumberFormat('#,##0').format(transaction.amount);

    final String description = (transaction.description != null && transaction.description!.trim().isNotEmpty)
        ? transaction.description!.trim()
        : (isCredit ? 'إيداع مالي (له)' : 'سحب مالي (عليه)');

    final Color badgeColor = isCredit ? AppTheme.creditColor : AppTheme.debitColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryColor.withOpacity(0.08)
            : highlighted
                ? AppTheme.primaryColor.withOpacity(0.04)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.4)
              : highlighted
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : AppTheme.dividerColor.withOpacity(0.4),
          width: selected || highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted || selected
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onTap != null) onTap!();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              if (onLongPress != null) onLongPress!();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    // Flow Indicator Badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: badgeColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Description & Date Column
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 10, color: AppTheme.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time_rounded, size: 10, color: AppTheme.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Amounts Columns
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isCredit ? '+$formattedAmount' : '-$formattedAmount',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCredit ? 'له (ائتمان)' : 'عليه (خصم)',
                          style: TextStyle(
                            color: badgeColor.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
