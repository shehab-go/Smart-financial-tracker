import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        _selectedCategoryFilter != null || _selectedCurrencyFilter != null || _selectedDateRange != null;

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
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateExpenseReportForCurrentCategory,
        onAllCategories: _generateExpenseReportForAllAccounts,
        onEditProfile: () {
          HapticFeedback.lightImpact();
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
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد حسابات مصروفات لعرض التقرير',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    await AllExpenseAccountsReportGenerator.generate(
      accounts: _state.expenseAccounts,
      currencyFilterName: _selectedCurrencyFilter ?? 'all',
    );
  }

  Future<void> _generateExpenseReportForCurrentCategory() async {
    if (_selectedCategoryFilter == null || _selectedCategoryFilter!.isEmpty) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار فئة للمصروفات أولاً',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final categoryName = _selectedCategoryFilter!;
    final accountsForCategory = _state.expenseAccounts
        .where((account) => account.category == categoryName)
        .toList();

    if (accountsForCategory.isEmpty) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد حسابات مصروفات للفئة "$categoryName"',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    await ExpenseCategoryReportGenerator.generate(
      categoryName: categoryName,
      accounts: accountsForCategory,
      currencyFilterName: _selectedCurrencyFilter ?? 'all',
    );
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
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
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              appBarTheme: const AppBarTheme(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                actionsIconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                headerBackgroundColor: AppTheme.primaryColor,
                headerForegroundColor: Colors.white,
                rangePickerHeaderBackgroundColor: AppTheme.primaryColor,
                rangePickerHeaderForegroundColor: Colors.white,
                backgroundColor: Colors.white,
                rangeSelectionBackgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                dayForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  if (states.contains(MaterialState.disabled)) {
                    return AppTheme.textSecondary.withOpacity(0.5);
                  }
                  return AppTheme.textPrimary;
                }),
                headerHeadlineStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                headerHelpStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 12,
                  color: Colors.white70,
                ),
                rangePickerHeaderHeadlineStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                rangePickerHeaderHelpStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 12,
                  color: Colors.white70,
                ),
                dayStyle: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                weekdayStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
                yearStyle: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
        _applyFilters();
      });
    }
  }

  Future<void> _showAddExpenseDialog({ExpenseModel? expense}) async {
    HapticFeedback.lightImpact();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddExpenseDialog(expense: expense),
    );

    if (result != null) {
      final ExpenseModel expenseResult = result['expense'] as ExpenseModel;
      final List<ExpenseAllocationInput> allocations =
          (result['allocations'] as List<ExpenseAllocationInput>?) ?? const [];
      bool success;
      if (expense != null) {
        success = await _controller.updateExpense(expenseResult, allocations: allocations);
      } else {
        success = await _controller.addExpense(expenseResult, allocations: allocations);
      }
      
      if (success && mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _state = _controller.state;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              expense != null ? 'تم تحديث المصروف بنجاح' : 'تم إضافة المصروف بنجاح',
              style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.error ?? (expense != null ? 'فشل في تحديث المصروف' : 'فشل في إضافة المصروف'),
              style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildFilterChipDropdown<T>({
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final bool hasFilter = value != null;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hasFilter ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFilter ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hintText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: hasFilter ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: hasFilter ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 18,
          ),
          isExpanded: false,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: items,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((DropdownMenuItem<T> item) {
              if (item.value == null) {
                return Center(
                  child: Text(
                    hintText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasFilter ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                );
              }
              
              String displayStr = '';
              if (item.child is Text) {
                displayStr = (item.child as Text).data ?? '';
              } else if (item.value != null) {
                if (item.value.toString() == '__add_new_category__') {
                  displayStr = 'إضافة فئة';
                } else {
                  displayStr = item.value.toString();
                }
              }
              
              return Center(
                child: Text(
                  displayStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasFilter ? AppTheme.primaryColor : AppTheme.textPrimary,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              );
            }).toList();
          },
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateFilterChip() {
    final bool hasFilter = _selectedDateRange != null;
    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasFilter ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFilter ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: hasFilter ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedDateRange == null
                  ? 'التاريخ'
                  : '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: hasFilter ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilterActive = _selectedCategoryFilter != null || _selectedCurrencyFilter != null || _selectedDateRange != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'المصروفات',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primaryColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
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
              icon: const Icon(Icons.assessment_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showReportOptions();
              },
              tooltip: 'التقارير',
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: const AppDrawer(),
        onDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
          widget.onDrawerChanged?.call(isOpened);
        },
        body: _state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Bento Stats Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                color: AppTheme.errorColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إجمالي المصروفات',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _filteredExpenses.isNotEmpty
                                      ? _currencyFormat.format(_filteredTotalExpenses)
                                      : '0',
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_filteredExpenses.length} مصروف',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Capsule Filters Scroll Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.filter_list_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            if (isFilterActive)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.successColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'تصفية:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                // Category capsule dropdown
                                _buildFilterChipDropdown<String>(
                                  value: _selectedCategoryFilter,
                                  hintText: 'الفئة',
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'عرض الكل',
                                        style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                      ),
                                    ),
                                    ..._categories.map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category.name,
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: '__add_new_category__',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 14,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'إضافة فئة',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) async {
                                    HapticFeedback.lightImpact();
                                    if (value == '__add_new_category__') {
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
                                const SizedBox(width: 8),

                                // Currency capsule dropdown
                                _buildFilterChipDropdown<String>(
                                  value: _selectedCurrencyFilter,
                                  hintText: 'العملة',
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'عرض الكل',
                                        style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                      ),
                                    ),
                                    ..._currencies.map(
                                      (currency) => DropdownMenuItem<String>(
                                        value: currency.name,
                                        child: Text(
                                          currency.name,
                                          style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedCurrencyFilter = value;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Date range capsule
                                _buildDateFilterChip(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Accounts list Bento Slate Cards
                  Expanded(
                    child: _filteredAccounts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 60,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد حسابات مصروفات',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'اضغط على زر + لإضافة مصروف جديد وسيتم إنشاء حساب تلقائياً.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 88),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filteredAccounts.length,
                            itemBuilder: (context, index) {
                              final account = _filteredAccounts[index];
                              return _buildExpenseAccountCard(account);
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_expense',
          onPressed: _showAddExpenseDialog,
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseAccountCard(ExpenseAccountModel account) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseAccountDetailsScreen(account: account),
            ),
          );
          if (mounted) {
            await _loadExpenses();
          }
        },
        child: Row(
          children: [
            // Outward (Expense) Red accent side bar
            Container(
              width: 5,
              height: 76,
              color: AppTheme.errorColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              account.category.isNotEmpty ? account.category : 'مصروفات',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _currencyFormat.format(account.totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.currencyName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${account.expenseCount} عمليات',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
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
  }}
