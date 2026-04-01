import 'package:flutter/material.dart';
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
    final String formattedDate = DateFormat('dd/MM').format(transaction.date);
    final String formattedAmount = NumberFormat('#,##0').format(transaction.amount);

    final String detailsText = (transaction.description != null && transaction.description!.trim().isNotEmpty)
        ? '$formattedDate - ${transaction.description!.trim()}'
        : formattedDate;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : highlighted
                  ? AppTheme.primaryColor.withOpacity(0.05)
                  : Colors.white,
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  detailsText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    isCredit ? formattedAmount : '0',
                    style: const TextStyle(
                      color: AppTheme.creditColor,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    isCredit ? '0' : formattedAmount,
                    style: const TextStyle(
                      color: AppTheme.debitColor,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
