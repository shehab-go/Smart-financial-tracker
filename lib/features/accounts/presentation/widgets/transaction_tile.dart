import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.selected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.type == 'credit';
    final String formattedDate = DateFormat('dd/MM').format(transaction.date);
    final String formattedAmount = NumberFormat('#,##0').format(transaction.amount);
    final Color amountColor = isCredit ? AppTheme.creditColor : AppTheme.debitColor;
    final IconData typeIcon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // Amount column
              Expanded(
                flex: 3,
                child: Text(
                  formattedAmount,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Details column
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    transaction.description ?? 'بدون وصف',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Date column
              Expanded(
                flex: 3,
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
