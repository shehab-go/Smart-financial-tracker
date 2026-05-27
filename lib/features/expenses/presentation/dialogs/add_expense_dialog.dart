import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/features/currencies/presentation/widgets/local_currency_picker.dart';
import 'package:debit_credit_app/features/categories/presentation/screens/categories_screen.dart';
import '../widgets/category_picker_sheet.dart';

class _ExpenseBalanceAllocationInput {
  int? balanceId;
  final TextEditingController amountController;

  _ExpenseBalanceAllocationInput({this.balanceId, String initialAmount = ''})
      : amountController = TextEditingController(text: initialAmount);

  void dispose() {
    amountController.dispose();
  }
}

class AddExpenseDialog extends StatefulWidget {
  final ExpenseModel? expense;

  const AddExpenseDialog({super.key, this.expense});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailController = TextEditingController();
  bool _isLoading = false;

  List<CategoryModel> _categories = [];
  String? _selectedCategory;
  String? _selectedCurrency;

  final DatabaseHelper _db = DatabaseHelper();
  List<IncomeBalanceModel> _incomeBalances = [];
  List<_ExpenseBalanceAllocationInput> _allocationInputs = [];
  bool _linkToIncomeBalance = false;
  bool _hasExistingAllocations = false;

  bool get _isEditing => widget.expense != null;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _detailController.dispose();
    for (final input in _allocationInputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _initBalancesAndAllocations();

    if (widget.expense != null) {
      _nameController.text = widget.expense!.name;
      _amountController.text = widget.expense!.amount.toString();
      _detailController.text = widget.expense!.detail;
      _selectedCategory = widget.expense!.category;
      _selectedCurrency = widget.expense!.currency;
    } else {
      _initDefaultCurrency();
    }
  }

  Future<void> _initDefaultCurrency() async {
    final String? defaultName = await _db.getDefaultCurrencyName();
    if (!mounted) return;
    setState(() {
      _selectedCurrency = defaultName;
    });
  }

  Future<void> _pickCurrency() async {
    HapticFeedback.lightImpact();
    try {
      final selected = await showLocalCurrencyPicker(
        context: context,
        showLocalOption: true,
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedCurrency = selected;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في اختيار العملة: $e',
              style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final allCategories = await db.getCategories();
      final categories = allCategories.where((c) => c.type == 'expense').toList();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _showCategorySheet() async {
    while (true) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExpenseCategoryPickerSheet(
          categories: _categories,
          initialCategory: _selectedCategory,
        ),
      );

      if (selected != null) {
        if (selected == '__MANAGE_MAIN__') {
          // Navigate to CategoriesScreen to add a main category
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoriesScreen(
                initialTabIndex: 1,
                autoOpenAddExpenseCategory: true,
                autoAddForceNoParent: true,
              ),
            ),
          );
          await _loadData();
          continue; // re-show sheet
        } else if (selected.startsWith('__MANAGE:')) {
          final parent = selected.substring(9);
          final actualParent = parent == 'عام' ? null : parent;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoriesScreen(
                initialTabIndex: 1,
                autoOpenAddExpenseCategory: true,
                autoAddParentName: actualParent,
              ),
            ),
          );
          await _loadData();
          continue; // re-show sheet
        } else {
          // Normal selection
          if (mounted) {
            setState(() {
              _selectedCategory = selected;
            });
          }
          break;
        }
      } else {
        break; // user dismissed sheet
      }
    }
  }

  Future<void> _initBalancesAndAllocations() async {
    try {
      final balances = await _db.getIncomeBalances();
      List<_ExpenseBalanceAllocationInput> allocationInputs = [];
      bool hasExisting = false;

      if (widget.expense != null && widget.expense!.id != null) {
        final existingAllocations =
            await _db.getExpenseAllocations(widget.expense!.id!);
        if (existingAllocations.isNotEmpty) {
          hasExisting = true;
          allocationInputs = existingAllocations
              .map(
                (a) => _ExpenseBalanceAllocationInput(
                  balanceId: a.balanceId,
                  initialAmount: a.allocatedAmount.toString(),
                ),
              )
              .toList();
        }
      }

      if (allocationInputs.isEmpty) {
        IncomeBalanceModel? defaultBalance;

        if (balances.isNotEmpty) {
          try {
            defaultBalance = balances.firstWhere((b) => b.isDefault);
          } catch (_) {
            defaultBalance = balances.first;
          }
        }
        allocationInputs = [
          _ExpenseBalanceAllocationInput(balanceId: defaultBalance?.id),
        ];
      }

      if (!mounted) return;
      setState(() {
        _incomeBalances = balances;
        _allocationInputs = allocationInputs;
        _hasExistingAllocations = hasExisting;
        _linkToIncomeBalance = hasExisting;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _saveExpense() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار العملة',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار الفئة',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double totalAmount = double.parse(_amountController.text);

      final List<ExpenseAllocationInput> allocations = [];
      final bool shouldHandleAllocations =
          _hasExistingAllocations || (!_isEditing && _linkToIncomeBalance);

      if (shouldHandleAllocations) {
        final List<_ExpenseBalanceAllocationInput> validInputs = _allocationInputs
            .where((input) =>
                input.balanceId != null &&
                input.amountController.text.trim().isNotEmpty)
            .toList();

        if (validInputs.isEmpty) {
          final defaultBalance = await _db.getDefaultIncomeBalance();
          if (defaultBalance == null || defaultBalance.id == null) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'لا يوجد رصيد افتراضي متاح لتوزيع المبلغ',
                  style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          allocations.add(
            ExpenseAllocationInput(
              balanceId: defaultBalance.id!,
              amount: totalAmount,
            ),
          );
        } else {
          double totalAllocated = 0.0;
          for (final input in validInputs) {
            final balanceId = input.balanceId;
            if (balanceId == null) {
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'يرجى اختيار رصيد لكل سطر توزيع',
                    style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                  ),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            final text = input.amountController.text.trim();
            final value = double.tryParse(text);
            if (value == null || value <= 0) {
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'قيمة المبلغ في توزيع الأرصدة غير صحيحة',
                    style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                  ),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            totalAllocated += value;
            allocations.add(
              ExpenseAllocationInput(balanceId: balanceId, amount: value),
            );
          }

          if ((totalAllocated - totalAmount).abs() > 0.01) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'مجموع مبالغ الأرصدة يجب أن يساوي المبلغ الكلي',
                  style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }

      final expense = ExpenseModel(
        id: widget.expense?.id,
        name: _nameController.text.trim(),
        amount: totalAmount,
        detail: _detailController.text.trim(),
        category: _selectedCategory!,
        currency: _selectedCurrency!,
        createdDate: widget.expense?.createdDate ?? DateTime.now(),
        updatedDate: widget.expense != null ? DateTime.now() : null,
        expenseAccountId: widget.expense?.expenseAccountId,
      );

      await _db.registerCurrencyUsage(_selectedCurrency!);

      Navigator.of(context).pop({
        'expense': expense,
        'allocations': allocations,
      });
    } catch (e) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في حفظ البيانات: $e',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing ? 'تعديل مصروف' : 'إضافة مصروف جديد',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'اسم المصروف *',
                            labelStyle: const TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: AppTheme.textSecondary,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            hintText: 'مثال: فاتورة كهرباء',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 14, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم المصروف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: 'المبلغ *',
                                  labelStyle: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال المبلغ';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'يرجى إدخال مبلغ صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildCurrencyDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _detailController,
                          decoration: InputDecoration(
                            labelText: 'التفاصيل (اختياري)',
                            labelStyle: const TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: AppTheme.textSecondary,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            hintText: 'وصف تفصيلي للمصروف',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 14, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              FocusScope.of(context).unfocus();
                              await _showCategorySheet();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'الفئة *',
                                labelStyle: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedCategory ?? 'اختر الفئة',
                                      style: TextStyle(
                                        fontSize: 14, 
                                        color: _selectedCategory == null ? AppTheme.textSecondary : AppTheme.textPrimary, 
                                        fontWeight: FontWeight.bold, 
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_hasExistingAllocations) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: CheckboxListTile(
                              value: _linkToIncomeBalance,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _linkToIncomeBalance = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              title: const Text(
                                'ربط هذا المصروف برصيد الدخل',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_incomeBalances.isNotEmpty && (_hasExistingAllocations || _linkToIncomeBalance)) ...[
                          _buildBalanceAllocationSection(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'حفظ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
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
  }

  Widget _buildCurrencyDropdown() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: _pickCurrency,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'العملة *',
            labelStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedCurrency ?? 'العملة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedCurrency == null
                        ? AppTheme.textSecondary.withOpacity(0.7)
                        : AppTheme.textPrimary,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceAllocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'ربط او تقسيم المبلغ بين الارصدة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(_allocationInputs.length, (index) {
            final input = _allocationInputs[index];
            final String? effectiveCurrency = (_selectedCurrency != null && _selectedCurrency!.isNotEmpty)
                ? _selectedCurrency
                : null;

            final List<IncomeBalanceModel> balancesForDropdown = _incomeBalances.where((balance) {
              if (input.balanceId != null && balance.id == input.balanceId) {
                return true;
              }
              if (effectiveCurrency == null) {
                return true;
              }
              return balance.currencyName == effectiveCurrency;
            }).toList();
            
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      value: input.balanceId,
                      decoration: InputDecoration(
                        labelText: 'الرصيد',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      items: balancesForDropdown
                          .map(
                            (balance) => DropdownMenuItem<int>(
                              value: balance.id,
                              child: Text(
                                balance.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          input.balanceId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: input.amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                    ),
                  ),
                  if (_allocationInputs.length > 1)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          final removed = _allocationInputs.removeAt(index);
                          removed.dispose();
                        });
                      },
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppTheme.errorColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _allocationInputs.add(_ExpenseBalanceAllocationInput());
              });
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            label: const Text(
              'اضف تقسيم آخر',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
          ),
        ),
      ],
    );
  }
}