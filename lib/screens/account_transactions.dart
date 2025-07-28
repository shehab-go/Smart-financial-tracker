import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../db/database_helper.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/app_drawer.dart';
import '../widgets/add_transaction_dialog.dart';


class AccountTransactionsScreen extends StatefulWidget {
  final AccountModel account;

  const AccountTransactionsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  List<TransactionModel> _transactions = [];
  Map<String, double> _totals = {'debit': 0.0, 'credit': 0.0, 'net': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseHelper().getTransactionsByAccount(widget.account.id!);
      
      // Calculate totals
      double totalDebit = 0.0;
      double totalCredit = 0.0;
      
      for (TransactionModel transaction in transactions) {
        if (transaction.type == 'debit') {
          totalDebit += transaction.amount;
        } else {
          totalCredit += transaction.amount;
        }
      }

      setState(() {
        _transactions = transactions;
        _totals = {
          'debit': totalDebit,
          'credit': totalCredit,
          'net': totalCredit - totalDebit,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المعاملات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTransactionDialog(
        accountId: widget.account.id!,
        category: widget.account.category,
      ),
    ) ?? false;

    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _navigateToEditTransaction(TransactionModel transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTransactionDialog(
        accountId: widget.account.id!,
        category: widget.account.category,
        accountCurrencyCode: widget.account.currencyCode,
        transaction: transaction,
      ),
    ) ?? false;

    if (result == true) {
      _loadTransactions(); // Refresh transactions after editing
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().deleteTransaction(transaction.id!);
        _loadTransactions(); // Refresh transactions after deletion
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المعاملة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المعاملة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.account.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Account totals card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _totals['net']! >= 0 ? 'المتبقي لك' : 'المتبقي عليك',
                                  style: TextStyle(
                                    color: _totals['net']! >= 0 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  NumberFormat('#,##0').format((_totals['net']!).abs()) + ' ${widget.account.currencyCode}',
                                  style: TextStyle(
                                    color: _totals['net']! >= 0 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('لك', style: TextStyle(color: Colors.red)),
                                Text(
                                  NumberFormat('#,##0').format(_totals['debit']) + ' ${widget.account.currencyCode}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('عليك', style: TextStyle(color: Colors.green)),
                                Text(
                                  NumberFormat('#,##0').format(_totals['credit']) + ' ${widget.account.currencyCode}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('المبلغ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text('تفاصيل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('التاريخ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        
                        
                                             

                      ],
                    ),
                  ),
                ),

                // Transactions list
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد معاملات لهذا الحساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'اضغط على + لإضافة معاملة جديدة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return TransactionTile(
                              transaction: transaction,
                              onEdit: () => _navigateToEditTransaction(transaction),
                              onDelete: () => _deleteTransaction(transaction),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
