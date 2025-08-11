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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
          border: selected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    // Name column (flex: 3)
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                    // Currency column (flex: 2)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          account.currencyCode,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
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
                    // Empty space for alignment
                    const Expanded(
                      flex: 1,
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
