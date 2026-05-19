import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.lightImpact();
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
      HapticFeedback.mediumImpact();
      await _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expense != null ? 'تم تحديث المصروف بنجاح' : 'تم إضافة المصروف بنجاح',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.state.error ?? 'فشل في حفظ المصروف',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    if (expense.id == null) return;

    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.errorColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تأكيد الحذف',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'هل تريد حذف المصروف "${expense.name}"؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
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
    );

    if (confirmed != true) return;

    final success = await _controller.deleteExpense(expense.id!);
    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      await _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم حذف المصروف بنجاح',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.state.error ?? 'فشل في حذف المصروف',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _generateReportForAccount() async {
    HapticFeedback.lightImpact();
    if (_expenses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'لا توجد مصروفات لهذا الحساب لعرض التقرير',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.account.name,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          backgroundColor: Colors.transparent,
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
        body: SafeArea(
          top: false,
          bottom: true,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Bento Style Summary Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.cardShadow,
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_amountFormat.format(_totalAmount)} ${widget.account.currencyName}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorColor,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: AppTheme.dividerColor.withOpacity(0.4),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'عدد العمليات',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_expenses.length} عملية',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _expenses.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          size: 60,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'لا توجد مصروفات لهذا الحساب',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'اضغط على زر "مصروف جديد" بالأسفل لبدء التسجيل',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Table Header
                                      Container(
                                        color: AppTheme.surfaceColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Row(
                                            children: const [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  'اسم المصروف',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textSecondary,
                                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    'المبلغ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textSecondary,
                                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
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
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textSecondary,
                                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
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
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textSecondary,
                                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Expenses List
                                      Expanded(
                                        child: ListView.builder(
                                          physics: const BouncingScrollPhysics(),
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
                        
                        // Bottom Persistent Full-Width Action Button (Sleek design)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () => _openAddOrEditDialog(),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'مصروف جديد',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildExpenseTile(ExpenseModel expense) {
    return InkWell(
      onTap: () => _openAddOrEditDialog(expense: expense),
      onLongPress: () => _deleteExpense(expense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.dividerColor.withOpacity(0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  expense.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    _amountFormat.format(expense.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    expense.detail.isNotEmpty ? expense.detail : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    expense.currency,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
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
