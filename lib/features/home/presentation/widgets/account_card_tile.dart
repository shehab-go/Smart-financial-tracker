import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AccountCardTile extends StatelessWidget {
  final AccountModel account;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AccountCardTile({
    super.key,
    required this.account,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
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
                    // Name column (flex: 6)
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Debit column (flex: 2)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          NumberFormat('#,##0').format(account.totalDebit),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.debitColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Credit column (flex: 2)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          NumberFormat('#,##0').format(account.totalCredit),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.creditColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Currency column (flex: 2)
                    Expanded(
                      flex: 2,
                      child: Text(
                        account.currencyName,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
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
