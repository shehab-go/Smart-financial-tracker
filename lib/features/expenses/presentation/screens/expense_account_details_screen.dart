import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/expenses/application/expense_controller.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/features/expenses/presentation/dialogs/add_expense_dialog.dart';
import 'package:debit_credit_app/features/expenses/application/reports/expense_account_report_generator.dart';

class ExpenseAccountDetailsScreen extends StatefulWidget {
  final ExpenseAccountModel account;

  const ExpenseAccountDetailsScreen({super.key, required this.account});

  @override
  State<ExpenseAccountDetailsScreen> createState() => _ExpenseAccountDetailsScreenState();
}

class _ExpenseAccountDetailsScreenState extends State<ExpenseAccountDetailsScreen> {
  final ExpenseRepository _repo = ExpenseRepository();
  late final ExpenseController _controller = ExpenseController(repo: _repo);

  final NumberFormat _amountFormat = NumberFormat('#,##0', 'ar');

  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.account.id == null) {
        _expenses = [];
      } else {
        _expenses = await _repo.fetchExpensesByAccount(widget.account.id!);
      }
    } catch (e) {
      _error = 'فشل في تحميل المصروفات: $e';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  double get _totalAmount {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> _openAddOrEditDialog({ExpenseModel? expense}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );

    if (result == null) return;

    final ExpenseModel expenseResult = result['expense'] as ExpenseModel;
    final List<ExpenseAllocationInput> allocations =
        (result['allocations'] as List<ExpenseAllocationInput>?) ?? const [];

    bool success;
    if (expense != null) {
      // Preserve existing account binding, or fall back to this account
      final updated = expenseResult.copyWith(
        expenseAccountId: expense.expenseAccountId ?? widget.account.id,
      );
      success = await _controller.updateExpense(updated, allocations: allocations);
    } else {
      final created = expenseResult.copyWith(expenseAccountId: widget.account.id);
      success = await _controller.addExpense(created, allocations: allocations);
    }

    if (!mounted) return;

    if (success) {
      await _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expense != null
              ? 'تم تحديث المصروف بنجاح'
              : 'تم إضافة المصروف بنجاح'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.state.error ?? 'فشل في حفظ المصروف'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    if (expense.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل تريد حذف المصروف "${expense.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final success = await _controller.deleteExpense(expense.id!);
    if (!mounted) return;

    if (success) {
      await _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المصروف بنجاح'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.state.error ?? 'فشل في حذف المصروف'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _generateReportForAccount() async {
    if (_expenses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد مصروفات لهذا الحساب لعرض التقرير'),
        ),
      );
      return;
    }

    await ExpenseAccountReportGenerator.generate(
      account: widget.account,
      expenses: _expenses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.account.name,
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primaryColor),
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/report_icons/pdf_report.svg',
                width: 24,
                height: 24,
              ),
              onPressed: _generateReportForAccount,
              tooltip: 'تقرير حساب المصروفات',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddOrEditDialog(),
          // Minimal, consistent FAB: light background with primary-colored border and icon
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.add,
            size: 22,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Summary card
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'إجمالي المصروفات',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _amountFormat.format(_totalAmount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'عدد العمليات',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_expenses.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _expenses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 80,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد مصروفات لهذا الحساب',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'اضغط على + لإضافة مصروف جديد',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header row similar to HomeScreen account list
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 4),
                                          Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Row(
                                              children: const [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    'اسم المصروف',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      'المبلغ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      'التفاصيل',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                    child: Text(
                                                      'العملة',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Colors.grey,
                                    ),
                                    // Expenses list - scrollable
                                    Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: _expenses.length,
                                        itemBuilder: (context, index) {
                                          final expense = _expenses[index];
                                          return _buildExpenseTile(expense);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildExpenseTile(ExpenseModel expense) {
    return InkWell(
      onTap: () => _openAddOrEditDialog(expense: expense),
      onLongPress: () => _deleteExpense(expense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // Expense name
              Expanded(
                flex: 3,
                child: Text(
                  expense.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    _amountFormat.format(expense.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ),
              // Detail
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    expense.detail.isNotEmpty ? expense.detail : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Currency
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    expense.currency,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
