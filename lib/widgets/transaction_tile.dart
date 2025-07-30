import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/transaction.dart';

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
    final String formattedDate = DateFormat('dd/MM/yyyy').format(transaction.date);
    final String formattedAmount = NumberFormat('#,##0').format(transaction.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Card(
        color: selected ? Colors.blue.withOpacity(0.2) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              
              // التاريخ
              Expanded(
                flex: 3,
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              // التفاصيل
              Expanded(
                flex: 4,
                child: Text(
                  transaction.description ?? '—',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // المبلغ
              Expanded(
                flex: 3,
                child: Text(
                  formattedAmount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              
              
              
              
            ],
          ),
        ),
      ),
    ),
  );
  }
}