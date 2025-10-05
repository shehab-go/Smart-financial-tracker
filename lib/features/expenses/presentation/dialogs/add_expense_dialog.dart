import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

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
  List<CurrencyModel> _currencies = [];
  String _selectedCategory = 'مصروفات';
  String _selectedCurrency = 'محلي';

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.expense != null) {
      _nameController.text = widget.expense!.name;
      _amountController.text = widget.expense!.amount.toString();
      _detailController.text = widget.expense!.detail;
      _selectedCategory = widget.expense!.category;
      _selectedCurrency = widget.expense!.currency;
    }
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final categories = await db.getCategories();
      final currencies = await db.getCurrencies();
      
      setState(() {
        _categories = categories;
        _currencies = currencies;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = ExpenseModel(
        id: widget.expense?.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        detail: _detailController.text.trim(),
        category: _selectedCategory,
        currency: _selectedCurrency,
        createdDate: widget.expense?.createdDate ?? DateTime.now(),
        updatedDate: widget.expense != null ? DateTime.now() : null,
      );

      Navigator.of(context).pop(expense);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $e'),
          backgroundColor: AppTheme.errorColor,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.expense == null ? 'إضافة مصروف جديد' : 'تعديل المصروف',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المصروف *',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: 'مثال: فاتورة كهرباء',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المصروف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'المبلغ *',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    suffixText: 'ر.س',
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                const SizedBox(height: 16),
                // Detail field
                TextFormField(
                  controller: _detailController,
                  decoration: InputDecoration(
                    labelText: 'التفاصيل *',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: 'وصف تفصيلي للمصروف',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال تفاصيل المصروف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'الفئة *',
                    labelStyle: const TextStyle(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار الفئة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Currency dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة *',
                    labelStyle: const TextStyle(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  items: _currencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency.name,
                      child: Text(currency.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار العملة';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.expense == null ? 'إضافة' : 'حفظ',
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }
}