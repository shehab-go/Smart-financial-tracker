import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/expenses/application/expense_controller.dart';
import 'package:debit_credit_app/features/expenses/application/expense_state.dart';
import 'package:debit_credit_app/features/expenses/presentation/dialogs/add_expense_dialog.dart';
import 'package:debit_credit_app/features/expenses/presentation/screens/expense_account_details_screen.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/home/presentation/screens/search_screen.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/report_bottom_sheet.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:debit_credit_app/features/expenses/application/reports/all_expense_accounts_report_generator.dart';
import 'package:debit_credit_app/features/expenses/application/reports/expense_category_report_generator.dart';
import 'package:debit_credit_app/features/categories/presentation/dialogs/category_dialog.dart';


class ExpenseScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;
  final int? highlightExpenseId;
  
  const ExpenseScreen({super.key, this.onDrawerChanged, this.highlightExpenseId});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseController _controller = ExpenseController();
  ExpenseState _state = ExpenseState.initial();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'ar');
  
  // Filter variables
  List<CategoryModel> _categories = [];
  List<CurrencyModel> _currencies = [];
  String? _selectedCategoryFilter;
  String? _selectedCurrencyFilter;
  DateTimeRange? _selectedDateRange;
  List<ExpenseModel> _filteredExpenses = [];
  List<ExpenseAccountModel> _filteredAccounts = [];
  bool _isDrawerOpen = false;
  Timer? _highlightTimer;
  int? _currentHighlightId;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightExpenseId;
    _loadExpenses();
    _loadFiltersData();
    
    // Set up timer to clear highlighting after 5 seconds
    if (_currentHighlightId != null) {
      _highlightTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _currentHighlightId = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final newState = await _controller.load();
    if (mounted) {
      setState(() {
        _state = newState;
        _applyFilters();
      });
    }
  }

  Future<void> _loadFiltersData() async {
    try {
      final categories = await DatabaseHelper().getCategories();
      final currencies = await DatabaseHelper().getCurrencies();
      if (mounted) {
        setState(() {
          _categories = categories;
          _currencies = currencies;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _applyFilters() {
    // Filter individual expenses based on selected category and currency
    _filteredExpenses = _state.expenses.where((expense) {
      final matchesCategory =
          _selectedCategoryFilter == null ||
          expense.category == _selectedCategoryFilter;
      final matchesCurrency =
          _selectedCurrencyFilter == null ||
          expense.currency == _selectedCurrencyFilter;
      final matchesDate = _selectedDateRange == null ||
          (!expense.createdDate.isBefore(_selectedDateRange!.start) &&
              !expense.createdDate.isAfter(_selectedDateRange!.end));

      return matchesCategory && matchesCurrency && matchesDate;
    }).toList();

    // Derive which expense accounts should be shown based on the filtered
    // expenses. If there are active filters, only show accounts that have at
    // least one matching expense. If no filters are set, show all accounts.
    final bool hasActiveFilters =
        _selectedCategoryFilter != null || _selectedCurrencyFilter != null;

    if (!hasActiveFilters) {
      _filteredAccounts = List<ExpenseAccountModel>.from(_state.expenseAccounts);
    } else {
      final Set<int> matchingAccountIds = _filteredExpenses
          .map((e) => e.expenseAccountId)
          .whereType<int>()
          .toSet();

      _filteredAccounts = _state.expenseAccounts.where((account) {
        final id = account.id;
        if (id == null) return false;
        return matchingAccountIds.contains(id);
      }).toList();
    }
  }

  double get _filteredTotalExpenses {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateExpenseReportForCurrentCategory,
        onAllCategories: _generateExpenseReportForAllAccounts,
        onEditProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateExpenseReportForAllAccounts() async {
    if (_state.expenseAccounts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد حسابات مصروفات لعرض التقرير')),
      );
      return;
    }

    await AllExpenseAccountsReportGenerator.generate(
      accounts: _state.expenseAccounts,
    );
  }

  Future<void> _generateExpenseReportForCurrentCategory() async {
    if (_selectedCategoryFilter == null || _selectedCategoryFilter!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فئة للمصروفات أولاً')),
      );
      return;
    }

    final categoryName = _selectedCategoryFilter!;
    final accountsForCategory = _state.expenseAccounts
        .where((account) => account.category == categoryName)
        .toList();

    if (accountsForCategory.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا توجد حسابات مصروفات للفئة "$categoryName"')),
      );
      return;
    }

    await ExpenseCategoryReportGenerator.generate(
      categoryName: categoryName,
      accounts: accountsForCategory,
    );
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      helpText: 'اختيار الفترة',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedDateRange = result;
      _applyFilters();
    });
  }

  Future<void> _showAddExpenseDialog({ExpenseModel? expense}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );

    if (result != null) {
      final ExpenseModel expenseResult = result['expense'] as ExpenseModel;
      final List<ExpenseAllocationInput> allocations =
          (result['allocations'] as List<ExpenseAllocationInput>?) ?? const [];
      bool success;
      if (expense != null) {
        // Update existing expense
        success = await _controller.updateExpense(expenseResult, allocations: allocations);
      } else {
        // Add new expense
        success = await _controller.addExpense(expenseResult, allocations: allocations);
      }
      
      if (success && mounted) {
        setState(() {
          _state = _controller.state;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expense != null ? 'تم تحديث المصروف بنجاح' : 'تم إضافة المصروف بنجاح'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_state.error ?? (expense != null ? 'فشل في تحديث المصروف' : 'فشل في إضافة المصروف')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    );

    if (confirmed == true && expense.id != null) {
      final success = await _controller.deleteExpense(expense.id!);
      if (success && mounted) {
        setState(() {
          _state = _controller.state;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المصروف بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_state.error ?? 'فشل في حذف المصروف'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مصروف',
           style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: null, // Explicitly remove any leading widget
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              tooltip: 'بحث',
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/report_icons/pdf_report.svg',
                width: 24,
                height: 24,
              ),
              onPressed: _showReportOptions,
            ),
            if (!_isDrawerOpen)
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'القائمة',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
          ],
        ),
        endDrawer: const AppDrawer(),
        onEndDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
          widget.onDrawerChanged?.call(isOpened);
        },
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddExpenseDialog,
          // Minimal, but clearly visible: light background with primary-colored border
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
          tooltip: 'إضافة مصروف جديد',
          child: const Icon(
            Icons.add,
            size: 22,
          ),
        ),
        body: _state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Filters + summary (aligned with HomeScreen design)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Summary (total)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجمالي',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _filteredExpenses.isNotEmpty
                                  ? _currencyFormat.format(_filteredTotalExpenses)
                                  : '0',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const VerticalDivider(
                          width: 16,
                          thickness: 1,
                          color: AppTheme.dividerColor,
                        ),
                        const SizedBox(width: 4),

                        // Filters row (category, currency, date) similar to Home
                        Expanded(
                          child: Row(
                            children: [
                              // Category filter with inline "+ add category" option
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategoryFilter,
                                  icon: const SizedBox.shrink(),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'الفئة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ..._categories.map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category.name,
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: '__add_new_category__',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.add,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'إضافة فئة',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) async {
                                    if (value == '__add_new_category__') {
                                      // Open category creation dialog
                                      final newCategory = await showDialog<CategoryModel>(
                                        context: context,
                                        builder: (dialogContext) => const CategoryDialog(),
                                      );

                                      if (newCategory != null) {
                                        try {
                                          await DatabaseHelper().insertCategory(newCategory);
                                          await _loadFiltersData();
                                          if (!mounted) return;
                                          setState(() {
                                            _selectedCategoryFilter = newCategory.name;
                                          });
                                          _applyFilters();
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('فشل في إضافة الفئة: $e'),
                                              backgroundColor: AppTheme.errorColor,
                                            ),
                                          );
                                        }
                                      }

                                      return;
                                    }

                                    setState(() {
                                      _selectedCategoryFilter = value;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Currency filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCurrencyFilter,
                                  icon: const SizedBox.shrink(),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'العملة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ..._currencies.map(
                                      (currency) => DropdownMenuItem<String>(
                                        value: currency.name,
                                        child: Text(
                                          currency.name,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCurrencyFilter = value;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Date filter (range summary)
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDateRange,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedDateRange == null
                                                ? 'التاريخ'
                                                : '${DateFormat('MM/dd').format(_selectedDateRange!.start)}-${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _selectedDateRange == null
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
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
                      ],
                    ),
                  ),

                  // Expense accounts list (table style, filtered by selected category/currency)
                  Expanded(
                    child: _filteredAccounts.isEmpty
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
                                  'لا توجد حسابات مصروفات',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط على + لإضافة مصروف جديد (سيتم إنشاء حساب تلقائياً)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              top: 2,
                              bottom: 8,
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
                                            // Account name header
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'مصروف',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            // Total amount header
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  'الإجمالي',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Operations count header
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  'العمليات',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Currency header
                                            Expanded(
                                              flex: 1,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'العملة',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textSecondary,
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
                                const Divider(height: 1, color: Colors.grey),
                                // Accounts list
                                Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredAccounts.length,
                                    itemBuilder: (context, index) {
                                      final account = _filteredAccounts[index];
                                      return _buildExpenseAccountCard(account);
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

  Widget _buildExpenseAccountCard(ExpenseAccountModel account) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExpenseAccountDetailsScreen(account: account),
          ),
        );
        // Refresh main expenses/accounts when coming back from details
        if (mounted) {
          await _loadExpenses();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              // Account name
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Total amount
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    _currencyFormat.format(account.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ),
              // Operations count
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${account.expenseCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              // Currency
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    account.currencyName,
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

  Widget _buildExpenseCard(ExpenseModel expense) {
    final bool isHighlighted = _currentHighlightId != null && expense.id == _currentHighlightId;
    
    return InkWell(
      onTap: () {
        _showExpenseDetailDialog(expense);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
          boxShadow: isHighlighted 
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // Expense Name (flex: 3)
              Expanded(
                flex: 3,
                child: Text(
                  expense.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount (flex: 2)
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${NumberFormat('#,##0').format(expense.amount)}',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Details (flex: 2)
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    expense.detail.isNotEmpty ? expense.detail : '-',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Currency (flex: 1)
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    expense.currency,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetailDialog(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppTheme.cardGradient,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تفاصيل المصروف',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Expense Details
                  _buildDetailRow('اسم المصروف', expense.name),
                  const SizedBox(height: 12),
                  _buildDetailRow('المبلغ', '${NumberFormat('#,##0').format(expense.amount)} ${expense.currency}'),
                  const SizedBox(height: 12),
                  _buildDetailRow('التفاصيل', expense.detail.isNotEmpty ? expense.detail : 'لا توجد تفاصيل'),
                  const SizedBox(height: 12),
                  _buildDetailRow('الفئة', expense.category),
                  const SizedBox(height: 12),
                  _buildDetailRow('تاريخ الإنشاء', DateFormat('yyyy/MM/dd - HH:mm').format(expense.createdDate)),
                  if (expense.updatedDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('تاريخ التحديث', DateFormat('yyyy/MM/dd - HH:mm').format(expense.updatedDate!)),
                  ],
                  
                  const SizedBox(height: 24),

                  // Action Buttons (edit + delete)
                  _buildActionButtons(expense),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'هل أنت متأكد من حذف المصروف "${expense.name}"؟\nلا يمكن التراجع عن هذا الإجراء.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              Container(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.textSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _deleteExpenseFromDialog(expense);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
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
                              fontSize: 16,
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
        );
      },
    );
  }

  Widget _buildActionButtons(ExpenseModel expense) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddExpenseDialog(expense: expense);
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'تعديل',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmationDialog(expense);
                            },
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              'حذف',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteExpenseFromDialog(ExpenseModel expense) async {
    if (expense.id != null) {
      final success = await _controller.deleteExpense(expense.id!);
      if (success && mounted) {
        setState(() {
          _state = _controller.state;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف المصروف بنجاح'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_state.error ?? 'فشل في حذف المصروف'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
