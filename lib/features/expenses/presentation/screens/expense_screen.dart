import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'package:debit_credit_app/core/events/financial_events.dart';

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
  bool _isDashboardExpanded = true;
  Timer? _highlightTimer;
  int? _currentHighlightId;
  StreamSubscription<FinancialEvent>? _financialEventSubscription;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightExpenseId;
    _loadExpenses();
    _loadFiltersData();

    // Listen for financial events (expenses/radar updates)
    _financialEventSubscription = FinancialEventBus().events.listen((event) {
      if (event.type == FinancialEventType.expenseAdded ||
          event.type == FinancialEventType.expenseUpdated ||
          event.type == FinancialEventType.expenseDeleted ||
          event.type == FinancialEventType.radarClassified) {
        _loadExpenses();
      }
    });
    
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
    _financialEventSubscription?.cancel();
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
      // Fallback to generating report for all accounts instead of showing an error
      return _generateExpenseReportForAllAccounts();
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

  void _showExpenseAccountOptions(ExpenseAccountModel account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                ),
                title: const Text(
                  'تعديل تفاصيل المصروف',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (account.expenseCount == 1) {
                    final accountExpenses = _controller.state.expenses
                        .where((e) => e.expenseAccountId == account.id)
                        .toList();
                    if (accountExpenses.isNotEmpty) {
                      await _showAddExpenseDialog(expense: accountExpenses.first);
                    } else {
                      _showEditExpenseAccountDialog(account);
                    }
                  } else {
                    _showEditExpenseAccountDialog(account);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
                ),
                title: const Text(
                  'حذف المصروف بالكامل',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                subtitle: const Text(
                  'سيتم حذف المصروف وجميع العمليات التابعة له',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
                        content: const Text(
                          'هل أنت متأكد من حذف هذا المصروف؟ سيتم مسح جميع بياناته بشكل نهائي.',
                          style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('إلغاء', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('حذف', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (confirmed == true && mounted) {
                    final success = await _controller.deleteExpenseAccount(account.id!);
                    if (success) {
                      await _loadExpenses();
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_controller.state.error ?? 'فشل الحذف')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditExpenseAccountDialog(ExpenseAccountModel account) async {
    final nameController = TextEditingController(text: account.name);
    String selectedCategory = account.category;
    
    // Make sure the category exists in the list
    if (selectedCategory.isNotEmpty && !_categories.any((c) => c.name == selectedCategory)) {
      setState(() {
        _categories.add(CategoryModel(name: selectedCategory, type: 'expense'));
      });
    }

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تعديل المصروف',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المصروف',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory.isNotEmpty ? selectedCategory : null,
                      decoration: InputDecoration(
                        labelText: 'الفئة',
                        prefixIcon: const Icon(Icons.category_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) {
                        setStateDialog(() {
                          selectedCategory = v ?? '';
                        });
                      },
                      validator: (v) => v == null || v.isEmpty ? 'اختر الفئة' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        final updatedAccount = account.copyWith(
          name: nameController.text.trim(),
          category: selectedCategory,
        );
        final success = await _controller.updateExpenseAccount(updatedAccount);
        if (success) {
          await _loadExpenses();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_controller.state.error ?? 'فشل التعديل')),
          );
        }
      }
    });
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

    String displayStr = hintText;
    if (hasFilter) {
      final selectedItem = items.firstWhere(
        (item) => item.value == value,
        orElse: () => items.first,
      );
      if (selectedItem.child is Row) {
        displayStr = 'إضافة فئة';
      } else if (selectedItem.child is Text) {
        displayStr = (selectedItem.child as Text).data ?? hintText;
      } else if (value.toString() == '__add_new_category__') {
        displayStr = 'إضافة فئة';
      } else {
        displayStr = value.toString();
      }
    }

    return PopupMenuButton<T?>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<T?>(
            value: item.value,
            child: item.child,
          );
        }).toList();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: hasFilter ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFilter ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: hasFilter 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasFilter ? Colors.white : AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: hasFilter ? Colors.white : AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip() {
    final bool hasFilter = _selectedDateRange != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDateRange,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasFilter ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasFilter ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: hasFilter 
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : AppTheme.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: hasFilter ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedDateRange == null
                    ? 'التاريخ'
                    : '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasFilter ? Colors.white : AppTheme.textSecondary,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
            ],
          ),
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
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Capsule Filters Scroll Row
                  SliverToBoxAdapter(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
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
                            padding: const EdgeInsets.only(left: 16),
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
                  ), // closes SliverToBoxAdapter

                  // Accounts list Bento Slate Cards
                  _filteredAccounts.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
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
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.only(top: 8, bottom: 88),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final account = _filteredAccounts[index];
                                return _buildExpenseAccountCard(account);
                              },
                              childCount: _filteredAccounts.length,
                            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showExpenseAccountOptions(account);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.errorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(6),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sync_alt_rounded,
                                  size: 10,
                                  color: AppTheme.errorColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${account.expenseCount} عمليات',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorColor,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(account.totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildExpenseDashboardCard(double shrinkProgress) {
    // Calculate Chart Data
    final double contentOpacity = (1.0 - (shrinkProgress * 2)).clamp(0.0, 1.0);
    final double titleTotalOpacity = ((shrinkProgress - 0.5) * 2).clamp(0.0, 1.0);
    final Map<String, double> categoryTotals = {};
    for (final expense in _filteredExpenses) {
      final category = expense.category.isNotEmpty ? expense.category : 'مصروفات';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      AppTheme.errorColor,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    if (_filteredTotalExpenses > 0) {
      for (final entry in sortedCategories) {
        final percentage = (entry.value / _filteredTotalExpenses) * 100;
        if (percentage < 1) continue;

        final color = colors[colorIndex % colors.length];
        colorIndex++;

        sections.add(
          PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 35,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
            badgeWidget: null,
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'تحليل المصروفات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
              if (shrinkProgress > 0) ...[
                const SizedBox(width: 8),
                Opacity(
                  opacity: titleTotalOpacity,
                  child: Text(
                    _currencyFormat.format(_filteredTotalExpenses),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_filteredExpenses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_filteredExpenses.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'عمليات',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (shrinkProgress < 1.0)
            Opacity(
              opacity: contentOpacity,
              child: SizedBox(
                height: 180 * (1.0 - shrinkProgress),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (sections.isNotEmpty)
                        Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: sections,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'الإجمالي',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textTertiary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _currencyFormat.format(_filteredTotalExpenses),
                              style: const TextStyle(
                                fontSize: 13,
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      sortedCategories.length > 5 ? 5 : sortedCategories.length,
                      (index) {
                        final entry = sortedCategories[index];
                        final color = colors[index % colors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'لا توجد مصروفات',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ),
            ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseDashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _ExpenseScreenState state;

  _ExpenseDashboardHeaderDelegate({required this.state});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double maxShrink = maxExtent - minExtent;
    final double progress = maxShrink > 0 ? (shrinkOffset / maxShrink).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      color: AppTheme.backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: state.buildExpenseDashboardCard(progress),
      ),
    );
  }

  @override
  double get maxExtent => 300.0;

  @override
  double get minExtent => 105.0;

  @override
  bool shouldRebuild(covariant _ExpenseDashboardHeaderDelegate oldDelegate) {
    return true;
  }
}
