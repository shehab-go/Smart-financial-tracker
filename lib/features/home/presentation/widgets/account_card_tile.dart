import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection; // Corrected line
import 'package:debit_credit_app/core/models/account.dart';

class AccountCardTile extends StatelessWidget {
  final AccountModel account;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAddTransaction;

  const AccountCardTile({
    super.key,
    required this.account,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: selected ? Colors.blue.withOpacity(0.2) : null,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Directionality(
            textDirection: TextDirection.rtl, // This will now work correctly
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          account.transactionCount.toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Center(child: Text(account.currencyCode))),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      NumberFormat('#,##0').format(account.totalDebit),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      NumberFormat('#,##0').format(account.totalCredit),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: InkWell(
                      onTap: onAddTransaction,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
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