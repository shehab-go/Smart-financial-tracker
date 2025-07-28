import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.type == 'credit';
    final String formattedDate = DateFormat('dd/MM/yyyy').format(transaction.date);
    final String formattedAmount = NumberFormat('#,##0').format(transaction.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              // الوصف
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
              // خيارات
              SizedBox(
                width: 40,
                child: Center(
                  child: PopupMenuButton<String>(
                    tooltip: 'خيارات',
                    onSelected: (v) {
                      if (v == 'edit' && onEdit != null) onEdit!();
                      if (v == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 6), Text('تعديل')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 6), Text('حذف', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 18),
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