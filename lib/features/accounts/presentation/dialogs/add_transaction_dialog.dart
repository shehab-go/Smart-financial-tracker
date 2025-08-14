import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
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
          _selectedCurrency = _currencies.first.symbol;
        }
      });
    }
  }

  Future<void> _pickContact() async {
    try {
      final phoneContact = await FlutterContactPicker.pickPhoneContact();
      final number = phoneContact.phoneNumber?.number;
      if (number != null) {
        setState(() => _phoneController.text = number);
      }
    } catch (_) {}
  }

  Future<void> _pickContactForName() async {
    try {
      final phoneContact = await FlutterContactPicker.pickPhoneContact();
      final name = phoneContact.fullName;
      final number = phoneContact.phoneNumber?.number;
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
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.symbol : 'USD';
          }
              
          final account = AccountModel(
            name: _accountNameController.text.trim(),
            category: widget.category,
            currencyCode: _selectedCurrency!,
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'تعديل معاملة' : 'إضافة معاملة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(2),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isNewAccount) ...[
                        TextFormField(
                          controller: _accountNameController,
                          decoration: InputDecoration(
                            hintText: 'أدخل اسم الحساب',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.person,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: _pickContactForName,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 4),
                      ],
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'المبلغ',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppTheme.primaryColor.withOpacity(0.7),
                            size: 20,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 4),
                      // Transaction type selection
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedType == 'debit'
                                            ? AppTheme.debitColor
                                            : AppTheme.dividerColor.withOpacity(0.3),
                                        width: _selectedType == 'debit' ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _selectedType == 'debit'
                                            ? AppTheme.debitColor
                                            : AppTheme.textSecondary.withOpacity(0.6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'عليك',
                                        style: TextStyle(
                                          color: _selectedType == 'debit'
                                              ? AppTheme.debitColor
                                              : AppTheme.textSecondary,
                                          fontWeight: _selectedType == 'debit'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 15,
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
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedType == 'credit'
                                            ? AppTheme.creditColor
                                            : AppTheme.dividerColor.withOpacity(0.3),
                                        width: _selectedType == 'credit' ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: _selectedType == 'credit'
                                            ? AppTheme.creditColor
                                            : AppTheme.textSecondary.withOpacity(0.6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'لك',
                                        style: TextStyle(
                                          color: _selectedType == 'credit'
                                              ? AppTheme.creditColor
                                              : AppTheme.textSecondary,
                                          fontWeight: _selectedType == 'credit'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 15,
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
                          hintText: 'التفاصيل (اختياري)',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: AppTheme.primaryColor.withOpacity(0.7),
                            size: 20,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                          hintText: 'رقم الهاتف (اختياري)',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.contact_phone,
                              color: AppTheme.primaryColor.withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: _pickContact,
                            tooltip: 'اختيار من جهات الاتصال',
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        minimumSize: const Size(0, 32),
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppTheme.textSecondary,
                        overlayColor: AppTheme.textSecondary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'حفظ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
      map.putIfAbsent(c.symbol, () => c);
      return map;
    });
    
    final items = uniqueMap.values
        .map((c) => DropdownMenuItem<String>(
          value: c.symbol, 
          child: Text(
            c.name, 
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            )
          )
        )).toList();

    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        hintText: 'العملة',
        hintStyle: TextStyle(
          fontSize: 16,
          color: AppTheme.textSecondary.withOpacity(0.7),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.5),
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        isDense: false,
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
        (c) => c.symbol == widget.accountCurrencyCode,
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
