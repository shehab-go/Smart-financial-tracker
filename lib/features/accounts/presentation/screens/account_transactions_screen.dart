import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/accounts/presentation/widgets/transaction_tile.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';

class _AccountEditDialog extends StatefulWidget {
  final AccountModel account;
  final Future<void> Function(String name, String currency) onSave;

  const _AccountEditDialog({
    required this.account,
    required this.onSave,
  });

  @override
  _AccountEditDialogState createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  late TextEditingController _nameController;
  String? _selectedCurrency;
  List<CurrencyModel> _currencies = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _selectedCurrency = widget.account.currencyCode;
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await DatabaseHelper().getCurrencies();
      if (currencies.isEmpty) {
        setState(() {
          _currencies = CurrencyModel.getDefaultCurrencies();
          // Only reset if the current currency is null or empty
          if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.symbol : null;
          }
        });
      } else {
        setState(() {
          _currencies = currencies;
          // Only reset if the current currency is null or empty
          if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.symbol : null;
          }
        });
      }
    } catch (e) {
      setState(() {
        _currencies = CurrencyModel.getDefaultCurrencies();
        // Only reset if the current currency is null or empty
        if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
          _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.symbol : null;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل بيانات الحساب'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم الحساب',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم الحساب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'العملة',
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _currencies.map((currency) => DropdownMenuItem<String>(
                value: currency.symbol,
                child: Text('${currency.name} (${currency.symbol})'),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
              },
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى اختيار العملة' : null,
            ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await widget.onSave(_nameController.text.trim(), _selectedCurrency!);
                Navigator.of(context).pop();
              }
            },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

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
  late AccountModel _currentAccount;

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
    _loadTransactions();
  }

  void _toggleSelection(TransactionModel t) {
    if (t.id == null) return;
    setState(() {
      if (_selectedIds.contains(t.id)) {
        _selectedIds.remove(t.id);
      } else {
        _selectedIds.add(t.id!);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('سيتم حذف ${_selectedIds.length} معاملة. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      for (final id in _selectedIds) {
        await DatabaseHelper().deleteTransaction(id);
      }
      _clearSelection();
      _loadTransactions();
    }
  }

  Future<void> _printSelected() async {
    if (_selectedIds.isEmpty) return;
    final sel = _transactions.where((t) => _selectedIds.contains(t.id)).toList();
    final rows = sel.map((t) => [
          DateFormat('yyyy/MM/dd').format(t.date),
          t.description ?? '-',
          t.type == 'credit' ? t.amount.toStringAsFixed(0) : '-',
          t.type == 'debit' ? t.amount.toStringAsFixed(0) : '-',
        ]).toList();
    final table = pw.Table.fromTextArray(headers: ['التاريخ', 'تفاصيل', 'له', 'عليه'], data: rows);
    await ReportService.generateAndOpenPdf(
      title: 'معاملات مختارة - ${widget.account.name}',
      content: [table],
    );
  }

  void _shareSelected() {
    if (_selectedIds.isEmpty) return;
    final selectedTx = _transactions.where((t) => _selectedIds.contains(t.id)).toList();
    final header = 'حساب: ${widget.account.name}';
    final lines = selectedTx
        .map((t) {
          final label = t.type == 'debit' ? 'عليه' : 'له';
          return '${DateFormat('dd/MM/yy').format(t.date)} - ${t.description ?? ''} - $label ${t.amount.toStringAsFixed(0)} ${_currentAccount.currencyCode}';
        })
        .join('\n');
    Share.share('$header\n$lines', subject: 'معاملات مختارة - ${widget.account.name}');
  }

  List<TransactionModel> _transactions = [];
  Map<String, double> _totals = {'debit': 0.0, 'credit': 0.0, 'net': 0.0};
  bool _isLoading = true;

  final Set<int> _selectedIds = {};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  Future<void> _generateReportForAccount() async {
    final rows = _transactions.map((t) => [
          DateFormat('yyyy/MM/dd').format(t.date),
          t.description ?? '-',
          t.type == 'credit' ? t.amount.toStringAsFixed(0) : '-',
          t.type == 'debit' ? t.amount.toStringAsFixed(0) : '-',
        ]).toList();

    final table = pw.Table.fromTextArray(
      headers: ['التاريخ', 'تفاصيل', 'له', 'عليه'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
    );

    final String netLabel = _totals['credit']! >= _totals['debit']! ? 'المتبقي له' : 'المتبقي عليه';
    final totalsRow = pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
          'الإجمالي - له: ${_totals["credit"]!.toStringAsFixed(0)}  |  عليه: ${_totals["debit"]!.toStringAsFixed(0)}  |  $netLabel: ${_totals["net"]!.abs().toStringAsFixed(0)}',
          textDirection: pw.TextDirection.rtl),
    );

    await ReportService.generateAndOpenPdf(
      title: 'تقرير حساب ${widget.account.name}',
      content: [table, pw.SizedBox(height: 12), totalsRow],
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseHelper().getTransactionsByAccount(widget.account.id!);

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
            accountCurrencyCode: _currentAccount.currencyCode,
          ),
        ) ??
        false;

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
            accountCurrencyCode: _currentAccount.currencyCode,
            transaction: transaction,
          ),
        ) ??
        false;

    if (result == true) {
      _loadTransactions();
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
        _loadTransactions();
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

  Widget _buildStatCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _editAccountDetails() {
    showDialog(
      context: context,
      builder: (context) => _AccountEditDialog(
        account: _currentAccount,
        onSave: (name, currency) async {
          try {
            if (_currentAccount.id == null) {
              throw Exception('Account ID is null - cannot update');
            }
            
            // Create a new AccountModel with updated values
            final updatedAccount = _currentAccount.copyWith(
              name: name,
              currencyCode: currency,
            );
            
            // Save to database
            final result = await DatabaseHelper().updateAccount(updatedAccount);
            
            if (result > 0) {
              setState(() {
                _currentAccount = updatedAccount;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث بيانات الحساب بنجاح'), backgroundColor: Colors.green),
              );
            } else {
              throw Exception('No rows were updated in the database');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ في تحديث الحساب: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildTransactionListWithYearSeparators() {
    if (_transactions.isEmpty) return [];
    
    List<Widget> widgets = [];
    int? currentYear;
    
    for (int i = 0; i < _transactions.length; i++) {
      final transaction = _transactions[i];
      final transactionYear = transaction.date.year;
      
      // Add year separator if this is a new year
      if (currentYear != transactionYear) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
        }
        widgets.add(
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Row(
               children: [
                 const Expanded(child: Divider()),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   child: Text(
                     transactionYear.toString(),
                     style: const TextStyle(
                       fontSize: 12,
                       color: Colors.grey,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                 ),
                 const Expanded(child: Divider()),
               ],
             ),
           ),
         );
        widgets.add(const SizedBox(height: 8));
        currentYear = transactionYear;
      }
      
      // Add transaction tile
      widgets.add(
        TransactionTile(
          transaction: transaction,
          selected: _selectedIds.contains(transaction.id),
          onTap: _selectionMode
              ? () => _toggleSelection(transaction)
              : () => _navigateToEditTransaction(transaction),
          onLongPress: () => _toggleSelection(transaction),
      ),
    );
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
              title: Text('تم تحديد ${_selectedIds.length}') ,
              actions: [
                IconButton(icon: const Icon(Icons.select_all), onPressed: () {
                  setState(() {
                    if (_selectedIds.length == _transactions.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(_transactions.map((e) => e.id!).whereType<int>());
                    }
                  });
                }),
                IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
                IconButton(icon: const Icon(Icons.print), onPressed: _printSelected),
                IconButton(icon: const Icon(Icons.share), onPressed: _shareSelected),
              ],
            )
          : AppBar(
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.print),
                onPressed: _generateReportForAccount,
              ),
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.account.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                               _currentAccount.name,
                               style: const TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.black87,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               'العملة: ${_currentAccount.currencyCode}',
                               style: TextStyle(
                                 fontSize: 12,
                                 color: Colors.grey.shade600,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                            ],
                          ),
                          IconButton(
                            onPressed: _editAccountDetails,
                            icon: const Icon(Icons.edit, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                               'له',
                               NumberFormat('#,##0').format(_totals['credit']),
                               Colors.green,
                             ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                               'عليه',
                               NumberFormat('#,##0').format(_totals['debit']),
                               Colors.red,
                             ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                               _totals['credit']! >= _totals['debit']! ? 'المتبقي له' : 'المتبقي عليه',
                               NumberFormat('#,##0').format((_totals['net']!).abs()),
                               _totals['credit']! >= _totals['debit']! ? Colors.green : Colors.red,
                             ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                      SizedBox(width: 16),
                      Expanded(flex: 4, child: Text('تفاصيل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                      SizedBox(width: 16),
                      Expanded(flex: 3, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                    ],
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد معاملات لهذا الحساب',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'اضغط على + لإضافة معاملة جديدة',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _navigateToAddTransaction,
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة معاملة'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          children: _buildTransactionListWithYearSeparators(),
                        ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToAddTransaction,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );  
  }
}
