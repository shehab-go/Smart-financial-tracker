import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/account_card_tile.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class CategoryAccountsTab extends StatelessWidget {
  final CategoryModel category;
  final List<AccountModel> accounts;
  final Set<int> selectedAccountIds;
  final void Function(AccountModel) onTapAccount;
  final void Function(AccountModel) onLongPressAccount;

  const CategoryAccountsTab({
    super.key,
    required this.category,
    required this.accounts,
    required this.selectedAccountIds,
    required this.onTapAccount,
    required this.onLongPressAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: accounts.isEmpty
          ? const _EmptyState()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final selected = selectedAccountIds.contains(account.id);
                  return AccountCardTile(
                    account: account,
                    selected: selected,
                    onTap: () => onTapAccount(account),
                    onLongPress: () => onLongPressAccount(account),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد حسابات في هذه الفئة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'اضغط على زر + لإضافة حساب جديد',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              
            ),
          ],
        ),
      ),
    );
  }
}
