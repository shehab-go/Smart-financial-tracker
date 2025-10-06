import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/expenses/application/expense_controller.dart';
import 'package:debit_credit_app/features/expenses/application/expense_state.dart';
import 'package:debit_credit_app/features/expenses/presentation/dialogs/add_expense_dialog.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/home/presentation/screens/search_screen.dart';


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
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar');
  
  // Filter variables
  List<CategoryModel> _categories = [];
  List<CurrencyModel> _currencies = [];
  String? _selectedCategoryFilter;
  String? _selectedCurrencyFilter;
  List<ExpenseModel> _filteredExpenses = [];
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
    _filteredExpenses = _state.expenses.where((expense) {
      bool matchesCategory = _selectedCategoryFilter == null || 
                           expense.category == _selectedCategoryFilter;
      bool matchesCurrency = _selectedCurrencyFilter == null || 
                           expense.currency == _selectedCurrencyFilter;
      return matchesCategory && matchesCurrency;
    }).toList();
  }

  double get _filteredTotalExpenses {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<void> _showAddExpenseDialog({ExpenseModel? expense}) async {
    final result = await showDialog<ExpenseModel>(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );

    if (result != null) {
      bool success;
      if (expense != null) {
        // Update existing expense
        success = await _controller.updateExpense(result);
      } else {
        // Add new expense
        success = await _controller.addExpense(result);
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
            'المصروفات',
            style: TextStyle(
              fontSize: 14,
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showAddExpenseDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            tooltip: 'إضافة مصروف جديد',
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        body: _state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Total expenses card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجمالي',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedCurrencyFilter != null)
                              Text(
                                '${_currencyFormat.format(_filteredTotalExpenses)} $_selectedCurrencyFilter',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryFilter,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            hint: const Text(
                                'جميع الفئات',
                                style: TextStyle(color: Colors.grey),
                              ),
                             dropdownColor: Colors.white,
                             style: const TextStyle(color: Colors.black),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('جميع الفئات'),
                              ),
                              ..._categories.map((category) => DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryFilter = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrencyFilter,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            hint: const Text(
                                'ر.س',
                                style: TextStyle(color: Colors.grey),
                              ),
                             dropdownColor: Colors.white,
                             style: const TextStyle(color: Colors.black),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('جميع العملات'),
                              ),
                              ..._currencies.map((currency) => DropdownMenuItem<String>(
                                value: currency.name,
                                child: Text(currency.name),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrencyFilter = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expenses list
                  Expanded(
                    child: _filteredExpenses.isEmpty
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
                                  'لا توجد مصروفات',
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
                        : Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 8),
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
                                  // Header Section
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 4),
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Row(
                                            children: [
                                              // Expense Name Header
                                              const Expanded(
                                                flex: 3,
                                                child: Text(
                                                  'اسم المصروف',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              // Amount Header
                                              const Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    'المبلغ',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Details Header
                                              const Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    'التفاصيل',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Currency Header
                                              const Expanded(
                                                flex: 1,
                                                child: Center(
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
                                  // Expenses list - Scrollable
                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.zero,
                                      children: _filteredExpenses.map((expense) => _buildExpenseCard(expense)).toList(),
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
                  
                  // Action Buttons
                  Container(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
          ),
        );
      },
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
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.errorColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
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