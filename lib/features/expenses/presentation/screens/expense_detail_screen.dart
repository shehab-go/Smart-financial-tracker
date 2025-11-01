import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/expenses/application/expense_controller.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback? onExpenseUpdated;
  final VoidCallback? onExpenseDeleted;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    this.onExpenseUpdated,
    this.onExpenseDeleted,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final ExpenseController _controller = ExpenseController();
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar');
  
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _detailController;
  
  // Dropdown data
  List<CategoryModel> _categories = [];
  List<CurrencyModel> _currencies = [];
  String? _selectedCategory;
  String? _selectedCurrency;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDropdownData();
  }
  
  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.expense.name);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _detailController = TextEditingController(text: widget.expense.detail);
    _selectedCategory = widget.expense.category;
    _selectedCurrency = widget.expense.currency;
  }
  
  Future<void> _loadDropdownData() async {
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
  
  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _detailController.dispose();
    super.dispose();
  }
  
  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedExpense = widget.expense.copyWith(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        detail: _detailController.text.trim(),
        category: _selectedCategory!,
        currency: _selectedCurrency!,
        updatedDate: DateTime.now(),
      );
      
      final success = await _controller.updateExpense(updatedExpense);
      
      if (success && mounted) {
        setState(() {
          _isEditing = false;
        });
        widget.onExpenseUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المصروف بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.state.error ?? 'فشل في تحديث المصروف'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المصروف: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المصروف "${widget.expense.name}"؟'),
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
    
    if (confirmed == true && widget.expense.id != null) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _controller.deleteExpense(widget.expense.id!);
      
      if (success && mounted) {
        widget.onExpenseDeleted?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المصروف بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.state.error ?? 'فشل في حذف المصروف'),
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
          title: Text(
            _isEditing ? 'تعديل المصروف' : 'تفاصيل المصروف',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'تعديل',
              ),
            
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                onPressed: _deleteExpense,
                tooltip: 'حذف',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.errorColor),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initializeControllers();
                  });
                },
                tooltip: 'إلغاء',
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppTheme.successColor),
                onPressed: _isLoading ? null : _updateExpense,
                tooltip: 'حفظ',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExpenseCard(),
                      const SizedBox(height: 16),
                      _buildDetailsSection(),
                      const SizedBox(height: 16),
                      _buildMetadataSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  Widget _buildExpenseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            TextFormField(
              controller: _nameController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'اسم المصروف',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم المصروف';
                }
                return null;
              },
            )
          else
            Text(
              widget.expense.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال مبلغ صحيح';
                }
                if (double.parse(value) <= 0) {
                  return 'يجب أن يكون المبلغ أكبر من صفر';
                }
                return null;
              },
            )
          else
            Text(
              '${_currencyFormat.format(widget.expense.amount)} ${widget.expense.currency}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التفاصيل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('الفئة', _isEditing ? null : widget.expense.category, 
              isEditing: _isEditing, 
              editWidget: _buildCategoryDropdown()),
          const SizedBox(height: 12),
          _buildDetailRow('العملة', _isEditing ? null : widget.expense.currency,
              isEditing: _isEditing,
              editWidget: _buildCurrencyDropdown()),
          const SizedBox(height: 12),
          _buildDetailRow('الوصف', _isEditing ? null : widget.expense.detail,
              isEditing: _isEditing,
              editWidget: _buildDetailTextField()),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String? value, {bool isEditing = false, Widget? editWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isEditing && editWidget != null
              ? editWidget
              : Text(
                  value ?? 'غير محدد',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.name,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى اختيار الفئة';
        }
        return null;
      },
    );
  }
  
  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency.name,
          child: Text(currency.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCurrency = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى اختيار العملة';
        }
        return null;
      },
    );
  }
  
  Widget _buildDetailTextField() {
    return TextFormField(
      controller: _detailController,
      maxLines: 3,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'أدخل وصف المصروف...',
        contentPadding: EdgeInsets.all(12),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال وصف المصروف';
        }
        return null;
      },
    );
  }
  
  Widget _buildMetadataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات إضافية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('تاريخ الإنشاء', DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(widget.expense.createdDate)),
          if (widget.expense.updatedDate != null) ...[
            const SizedBox(height: 8),
            _buildMetadataRow('تاريخ التحديث', DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(widget.expense.updatedDate!)),
          ],
          if (widget.expense.id != null) ...[
            const SizedBox(height: 8),
            _buildMetadataRow('معرف المصروف', widget.expense.id.toString()),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}