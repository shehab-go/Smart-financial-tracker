import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AddTransactionDialog extends StatefulWidget {
  final String category;
  final int? accountId;
  final String? accountCurrencyCode;
  final TransactionModel? transaction;

  const AddTransactionDialog({
    super.key,
    required this.category,
    this.accountId,
    this.accountCurrencyCode,
    this.transaction,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'debit';
  String? _selectedCurrency;

  List<CurrencyModel> _currencies = [];
  bool _isLoading = false;
  List<String> _imagePaths = [];

  bool get _isNewAccount => widget.accountId == null;
  bool get _isEditing => widget.transaction != null;

  @override
  void dispose() {
    _accountNameController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        List<String> newImagePaths = [];
        
        for (XFile image in images) {
          final fileName = 'transaction_${DateTime.now().millisecondsSinceEpoch}_${newImagePaths.length}.jpg';
          final savedImage = await File(image.path).copy(path.join(appDir.path, fileName));
          newImagePaths.add(savedImage.path);
        }
        
        setState(() {
          _imagePaths.addAll(newImagePaths);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الصور: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _initCurrency();

    if (_isEditing) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _detailsController.text = t.description ?? '';
      _selectedType = t.type;
      _selectedDate = t.date;
      _imagePaths = List<String>.from(t.imagePaths);
    }
  }

  Future<void> _initCurrency() async {
    final list = await DatabaseHelper().getCurrencies();
    if (mounted) {
      setState(() {
        _currencies = list;
        // Set the selected currency to the account's currency if available
        if (widget.accountCurrencyCode != null && widget.accountCurrencyCode!.isNotEmpty) {
          _selectedCurrency = widget.accountCurrencyCode;
        } else if (_currencies.isNotEmpty) {
          _selectedCurrency = _currencies.first.name;
        }
      });
    }
  }

  Future<void> _pickContact() async {
    try {
      final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
      final contact = await _picker.selectContact();
      final number = contact?.phoneNumbers?.isNotEmpty == true ? contact?.phoneNumbers?.first : null;
      if (number != null) {
        setState(() => _phoneController.text = number);
      }
    } catch (_) {}
  }

  Future<void> _pickContactForName() async {
    try {
      final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
      final contact = await _picker.selectContact();
      final name = contact?.fullName;
      final number = contact?.phoneNumbers?.isNotEmpty == true ? contact?.phoneNumbers?.first : null;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _accountNameController.text = name;
          if (number != null) {
            _phoneController.text = number;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    int accountId = widget.accountId ?? -1;
    
    try {
      if (_isEditing) {
        final updated = widget.transaction!.copyWith(
          amount: double.parse(_amountController.text),
          type: _selectedType,
          date: _selectedDate,
          description: _detailsController.text.trim(),
          imagePaths: _imagePaths,
        );
        await DatabaseHelper().updateTransaction(updated);
      } else {
        if (_isNewAccount) {
          // Use default currency if none selected
          if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.name : 'دولار أمريكي';
          }
              
          final account = AccountModel(
            name: _accountNameController.text.trim(),
            category: widget.category,
            currencyName: _selectedCurrency!,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            createdDate: DateTime.now(),
          );
          accountId = await DatabaseHelper().insertAccount(account);
        }

        final transaction = TransactionModel(
          accountId: accountId,
          amount: double.parse(_amountController.text),
          type: _selectedType,
          category: widget.category,
          date: _selectedDate,
          description: _detailsController.text.trim(),
          imagePaths: _imagePaths,
        );
        await DatabaseHelper().insertTransaction(transaction);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
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
                      _isEditing ? Icons.edit_outlined : Icons.add,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'تعديل معاملة' : 'إضافة معاملة',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.dividerColor),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isNewAccount) ...[
                        TextFormField(
                          controller: _accountNameController,
                          decoration: InputDecoration(
                            labelText: 'اسم الحساب',
                            labelStyle: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.person_outline,
                                color: AppTheme.textSecondary,
                                size: 18,
                              ),
                              onPressed: _pickContactForName,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      // Transaction type selection
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedType = 'debit'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'debit'
                                        ? AppTheme.debitColor.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedType == 'debit'
                                          ? AppTheme.debitColor
                                          : Colors.grey.shade300,
                                      width: _selectedType == 'debit' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _selectedType == 'debit'
                                            ? AppTheme.debitColor
                                            : AppTheme.textSecondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'عليه',
                                        style: TextStyle(
                                          color: _selectedType == 'debit'
                                              ? AppTheme.debitColor
                                              : AppTheme.textSecondary,
                                          fontWeight: _selectedType == 'debit'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedType = 'credit'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'credit'
                                        ? AppTheme.creditColor.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedType == 'credit'
                                          ? AppTheme.creditColor
                                          : Colors.grey.shade300,
                                      width: _selectedType == 'credit' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: _selectedType == 'credit'
                                            ? AppTheme.creditColor
                                            : AppTheme.textSecondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'له',
                                        style: TextStyle(
                                          color: _selectedType == 'credit'
                                              ? AppTheme.creditColor
                                              : AppTheme.textSecondary,
                                          fontWeight: _selectedType == 'credit'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
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
                      const SizedBox(height: 4),
                      // Currency and Date row
                      Row(
                        children: [
                          // Currency selection - only show when creating new account
                          if (_isNewAccount) ...[
                            Expanded(
                              child: _buildCurrencyDropdown(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Date picker
                          Expanded(
                            child: _buildDatePicker(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _detailsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'التفاصيل (اختياري)',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.description,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Image attachment section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add images button
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _pickImages,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _imagePaths.isEmpty 
                                          ? 'إضافة صور (اختياري)' 
                                          : 'إضافة المزيد من الصور',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Display selected images
                          if (_imagePaths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GridView.builder(
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                 crossAxisCount: 4,
                                 crossAxisSpacing: 6,
                                 mainAxisSpacing: 6,
                                 childAspectRatio: 1.0,
                               ),
                              itemCount: _imagePaths.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_imagePaths[index]),
                                        height: double.infinity,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _removeImage(index),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          padding: const EdgeInsets.all(1),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_isNewAccount) TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.contacts,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            onPressed: _pickContact,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                                fontWeight: FontWeight.w600,
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
    // Always include default currencies
    final allCurrencies = _currencies.isEmpty 
        ? CurrencyModel.getDefaultCurrencies()
        : _currencies;
        
    final uniqueMap = allCurrencies.fold<Map<String, CurrencyModel>>({}, (map,c) {
      map.putIfAbsent(c.name, () => c);
      return map;
    });
    
    final items = uniqueMap.values
        .map((c) => DropdownMenuItem<String>(
          value: c.name, 
          child: Text(
            c.name, 
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            )
          )
        )).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        value: _selectedCurrency,
        decoration: InputDecoration(
          labelText: 'العملة',
          labelStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.monetization_on,
            color: AppTheme.textSecondary,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items,
        onChanged: (val) => setState(() => _selectedCurrency = val),
        isExpanded: true,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
        menuMaxHeight: 200,
        dropdownColor: Colors.white,
        alignment: AlignmentDirectional.centerStart,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى اختيار العملة';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCurrencyReadonly() {
    final allCurrencies = _currencies.isEmpty 
        ? CurrencyModel.getDefaultCurrencies()
        : _currencies;
    
    // Find the currency that matches the account's currency code
    CurrencyModel curr;
    if (widget.accountCurrencyCode != null && widget.accountCurrencyCode!.isNotEmpty) {
      curr = allCurrencies.firstWhere(
        (c) => c.name == widget.accountCurrencyCode,
        orElse: () => allCurrencies.isNotEmpty ? allCurrencies.first : CurrencyModel.defaultLocal(),
      );
    } else {
      curr = allCurrencies.isNotEmpty ? allCurrencies.first : CurrencyModel.defaultLocal();
    }
    
    return TextFormField(
      initialValue: curr.name,
      enabled: false,
      style: const TextStyle(fontSize: 10),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        isDense: true,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'التاريخ',
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: AppTheme.primaryColor.withOpacity(0.7),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 12,
            ),
          ),
          child: Text(
            '${_selectedDate.toLocal()}'.split(' ')[0],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
