import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/accounts_header_row.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/account_card_tile.dart';

class CategoryAccountsTab extends StatelessWidget {
  final CategoryModel category;
  final List<AccountModel> accounts;
  final Set<int> selectedAccountIds;
  final void Function(AccountModel) onTapAccount;
  final void Function(AccountModel) onLongPressAccount;
  final void Function(AccountModel) onAddTransaction;

  const CategoryAccountsTab({
    super.key,
    required this.category,
    required this.accounts,
    required this.selectedAccountIds,
    required this.onTapAccount,
    required this.onLongPressAccount,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const AccountsHeaderRow(),
          const SizedBox(height: 8),
          Expanded(
            child: accounts.isEmpty
                ? const _EmptyState()
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListView.builder(
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final selected = selectedAccountIds.contains(account.id);
                        return AccountCardTile(
                          account: account,
                          selected: selected,
                          onTap: () => onTapAccount(account),
                          onLongPress: () => onLongPressAccount(account),
                          onAddTransaction: () => onAddTransaction(account),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('لا توجد حسابات في هذه الفئة', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('اضغط على + لإضافة حساب جديد', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
