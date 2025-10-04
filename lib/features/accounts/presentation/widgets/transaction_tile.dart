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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  // Date column
                  Expanded(
                    flex: 3,
                    child: Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details column
                  Expanded(
                    flex: 4,
                    child: Text(
                      transaction.description ?? 'بدون وصف',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Amount column
                  Expanded(
                    flex: 3,
                    child: Text(
                      formattedAmount,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
