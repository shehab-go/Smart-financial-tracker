import 'package:flutter/material.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';

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

  List<CurrencyModel> _currencies = [];
  bool _isLoading = false;

  bool get _isNewAccount => widget.accountId == null;
  bool get _isEditing => widget.transaction != null;

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
    }
  }

  Future<void> _initCurrency() async {
    final list = await DatabaseHelper().getCurrencies();
    if (mounted) {
      setState(() {
        _currencies = list;

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
        );
        await DatabaseHelper().updateTransaction(updated);
      } else {
        if (_isNewAccount) {
          final account = AccountModel(
            name: _accountNameController.text.trim(),
            category: widget.category,
            currencyCode: _currencies.isNotEmpty ? _currencies.first.symbol : 'LOC',
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
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل معاملة' : 'إضافة معاملة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isNewAccount)
                TextFormField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(hintText: 'اسم الحساب'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'المبلغ'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'debit',
                        groupValue: _selectedType,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('عليه', style: TextStyle(color: Colors.red)),
                        onChanged: (val) => setState(() => _selectedType = val ?? 'debit'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'credit',
                        groupValue: _selectedType,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('له', style: TextStyle(color: Colors.green)),
                        onChanged: (val) => setState(() => _selectedType = val ?? 'credit'),
                      ),
                    ),
                  ],
                ),
              ),
              _isNewAccount ? _buildCurrencyDropdown() : _buildCurrencyReadonly(),
              _buildDatePicker(context),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(hintText: 'التفاصيل'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(hintText: 'رقم الهاتف'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.contact_phone),
                    onPressed: _pickContact,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator() : const Text('حفظ'),
        )
      ],
    );
  }

  Widget _buildCurrencyDropdown() {
    final uniqueMap = _currencies.fold<Map<String, CurrencyModel>>({}, (map,c) {
      map.putIfAbsent(c.symbol, () => c);
      return map;
    });
    final items = uniqueMap.values
        .map(
          (c) => DropdownMenuItem(value: c.symbol, child: Text(c.name)
          )).toList();

    String selected = _currencies.isNotEmpty ? _currencies.first.symbol : 'LOC';
    if (!uniqueMap.containsKey(selected)) {
      selected = uniqueMap.keys.first;
    }

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(hintText: 'العملة'),
      items: items,
      onChanged: (val) => {}, // Currency selection disabled for simplicity
    );
  }

  Widget _buildCurrencyReadonly() {
    final curr = _currencies.isNotEmpty ? _currencies.first : CurrencyModel.defaultLocal();
    return TextFormField(
      initialValue: curr.name,
      enabled: false,
      decoration: const InputDecoration(hintText: 'العملة'),
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
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(hintText: 'التاريخ'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_selectedDate.toLocal()}'.split(' ')[0]),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
