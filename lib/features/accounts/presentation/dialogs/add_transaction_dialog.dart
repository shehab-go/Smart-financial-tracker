import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/models/transaction_balance_allocation.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/features/currencies/presentation/widgets/local_currency_picker.dart';
import 'package:debit_credit_app/core/services/region_service.dart';

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final originalText = newValue.text;
    final rawText = originalText.replaceAll(',', '');

    if (rawText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final endsWithDot = rawText.endsWith('.');
    final dotIndex = rawText.indexOf('.');
    String rawIntPart;
    String rawDecPart;
    if (dotIndex >= 0) {
      rawIntPart = rawText.substring(0, dotIndex);
      rawDecPart = rawText.substring(dotIndex + 1);
    } else {
      rawIntPart = rawText;
      rawDecPart = '';
    }

    rawIntPart = rawIntPart.replaceAll(RegExp(r'\D'), '');
    rawDecPart = rawDecPart.replaceAll(RegExp(r'\D'), '');

    final formattedIntPart = _formatIntWithCommas(rawIntPart);
    final formattedText = (dotIndex >= 0)
        ? '$formattedIntPart.${rawDecPart.isNotEmpty ? rawDecPart : (endsWithDot ? '' : '')}'
        : formattedIntPart;

    final commasBeforeCursor =
        originalText.substring(0, newValue.selection.end).split(',').length - 1;
    final rawCursor = (newValue.selection.end - commasBeforeCursor)
        .clamp(0, rawText.length);

    int cursor = 0;
    if (rawCursor == 0) {
      cursor = 0;
    } else {
      var count = 0;
      for (var i = 0; i < formattedText.length; i++) {
        if (formattedText[i] != ',') {
          count++;
        }
        if (count == rawCursor) {
          cursor = i + 1;
          break;
        }
      }
      if (cursor == 0) {
        cursor = formattedText.length;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  String _formatIntWithCommas(String digits) {
    if (digits.isEmpty) return '';
    final len = digits.length;
    final firstGroupLen = len % 3 == 0 ? 3 : len % 3;
    final buffer = StringBuffer();
    buffer.write(digits.substring(0, firstGroupLen));
    for (var i = firstGroupLen; i < len; i += 3) {
      buffer.write(',');
      buffer.write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }
}

class _BalanceAllocationInput {
  int? balanceId;
  final TextEditingController amountController;

  _BalanceAllocationInput({this.balanceId, String initialAmount = ''})
      : amountController = TextEditingController(text: initialAmount);

  void dispose() {
    amountController.dispose();
  }
}

class AddTransactionDialog extends StatefulWidget {
  final String category;
  final int? accountId;
  final String? accountCurrencyCode;
  final TransactionModel? transaction;
  final String? initialAccountName;
  final double? initialAmount;
  final String? initialType;
  final String? initialDetails;

  const AddTransactionDialog({
    super.key,
    required this.category,
    this.accountId,
    this.accountCurrencyCode,
    this.transaction,
    this.initialAccountName,
    this.initialAmount,
    this.initialType,
    this.initialDetails,
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
  final FocusNode _nameFocusNode = FocusNode();
  List<AccountModel> _existingAccounts = [];
  AccountModel? _selectedAccount;

  final DatabaseHelper _db = DatabaseHelper();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = '';
  String? _selectedCurrency;
  Set<String> _favoriteCurrencyNames = <String>{};
  String? _defaultCurrencyName;

  static const String _pickNewCurrencyValue = '__pick_new_currency__';

  bool _isLoading = false;
  List<String> _imagePaths = [];
  List<IncomeBalanceModel> _incomeBalances = [];
  List<_BalanceAllocationInput> _allocationInputs = [];
  bool _linkToIncomeBalance = false;
  bool _hasExistingAllocations = false;
  bool _advancedExpanded = false;
  bool _hasDetailsText = false;
  bool _isFormReady = false;

  bool get _isNewAccount => widget.accountId == null;
  bool get _isEditing => widget.transaction != null;

  @override
  void dispose() {
    _accountNameController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    for (final input in _allocationInputs) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingAccounts() async {
    try {
      final accounts = await _db.getAccounts();
      if (mounted) {
        setState(() {
          _existingAccounts = accounts;
          if (widget.initialAccountName != null) {
            try {
              _selectedAccount = accounts.firstWhere(
                (a) => a.name.trim().toLowerCase() == widget.initialAccountName!.trim().toLowerCase()
              );
            } catch (_) {}
          }
        });
      }
    } catch (_) {}
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

  Future<void> _showCurrencyQuickMenu(
    BuildContext anchorContext, {
    required List<String> items,
  }) async {
    try {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final renderBox = anchorContext.findRenderObject() as RenderBox;

      final rect = renderBox.localToGlobal(Offset.zero, ancestor: overlay) &
          renderBox.size;

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          rect,
          Offset.zero & overlay.size,
        ),
        items: [
          ...items.map(
            (cur) => PopupMenuItem<String>(
              value: cur,
              child: SizedBox(
                width: 260,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cur,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyModel.symbolFor(cur),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const PopupMenuItem<String>(
            value: _pickNewCurrencyValue,
            child: SizedBox(
              width: 260,
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'عملة أخرى',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      if (selected == null) return;
      if (selected == _pickNewCurrencyValue) {
        await _pickCurrency();
        if (mounted) {
          await _loadCurrencyQuickPickData();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _selectedCurrency = selected;
        });
      }
    } catch (_) {}
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
    if (_isNewAccount) {
      _loadCurrencyQuickPickData();
      _loadExistingAccounts();
    }
    _initBalancesAndAllocations();

    if (_isEditing) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _detailsController.text = t.description ?? '';
      _selectedType = t.type;
      _selectedDate = t.date;
      _imagePaths = List<String>.from(t.imagePaths);
    } else {
      if (widget.initialAccountName != null) {
        _accountNameController.text = widget.initialAccountName!;
      }
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount.toString();
      }
      if (widget.initialType != null) {
        _selectedType = widget.initialType!;
      }
      if (widget.initialDetails != null) {
        _detailsController.text = widget.initialDetails!;
      }
    }
    _hasDetailsText = _detailsController.text.trim().isNotEmpty;
    _detailsController.addListener(() {
      final next = _detailsController.text.trim().isNotEmpty;
      if (next != _hasDetailsText && mounted) {
        setState(() => _hasDetailsText = next);
      }
    });

    void updateReady() {
      final amountOk = _amountController.text.trim().isNotEmpty;
      final nameOk = !_isNewAccount || _accountNameController.text.trim().isNotEmpty;
      final next = amountOk && nameOk;
      if (next != _isFormReady && mounted) {
        setState(() => _isFormReady = next);
      }
    }

    updateReady();
    _amountController.addListener(updateReady);
    _accountNameController.addListener(() {
      updateReady();
      if (_selectedAccount != null &&
          _accountNameController.text.trim().toLowerCase() !=
              _selectedAccount!.name.trim().toLowerCase()) {
        setState(() {
          _selectedAccount = null;
        });
      }
    });
  }

  Future<void> _loadCurrencyQuickPickData() async {
    try {
      final favorites = await _db.getFavoriteCurrencies();
      final defaultName = await _db.getDefaultCurrencyName();
      if (!mounted) return;
      setState(() {
        _favoriteCurrencyNames = favorites;
        _defaultCurrencyName = defaultName;
      });
    } catch (_) {}
  }

  Future<void> _initCurrency() async {
    // Priority:
    // 1) accountCurrencyCode passed from the account (if any)
    // 2) existing transaction's currency (for editing) if available
    // 3) global default currency stored in DatabaseHelper (app_meta)
    String? initial;
    if (_isEditing && widget.transaction != null) {
      final String name = widget.transaction!.currencyName.trim();
      initial = name.isNotEmpty ? name : null;
    }
    initial ??= (widget.accountCurrencyCode != null && widget.accountCurrencyCode!.isNotEmpty)
        ? widget.accountCurrencyCode
        : null;
    final defaultName = await _db.getDefaultCurrencyName();
    initial ??= defaultName;

    if (initial == 'محلي' && defaultName != null && defaultName.trim().isNotEmpty) {
      initial = defaultName.trim();
    }

    if (!mounted) return;
    setState(() {
      _selectedCurrency = initial;
    });
  }

  Future<void> _initBalancesAndAllocations() async {
    try {
      final balances = await _db.getIncomeBalances();
      List<_BalanceAllocationInput> allocationInputs = [];
      bool hasExisting = false;

      if (_isEditing && widget.transaction?.id != null) {
        final existingAllocations =
            await _db.getTransactionAllocations(widget.transaction!.id!);
        if (existingAllocations.isNotEmpty) {
          hasExisting = true;
          allocationInputs = existingAllocations
              .map(
                (a) => _BalanceAllocationInput(
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
          _BalanceAllocationInput(balanceId: defaultBalance?.id),
        ];
      }

      if (!mounted) return;
      setState(() {
        _incomeBalances = balances;
        _allocationInputs = allocationInputs;
        _hasExistingAllocations = hasExisting;
        _linkToIncomeBalance = hasExisting;
        _advancedExpanded = hasExisting;
      });
    } catch (e) {
      print('Error loading income balances: $e');
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

  Future<void> _pickCurrency() async {
    try {
      final selected = await showLocalCurrencyPicker(
        context: context,
        showLocalOption: true,
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedCurrency = (selected == 'محلي' && _defaultCurrencyName != null && _defaultCurrencyName!.trim().isNotEmpty)
              ? _defaultCurrencyName!.trim()
              : selected;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار العملة: $e')),
        );
      }
    }
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
    AccountModel? existingAccount;
    
    try {
      final db = _db;
      final double totalAmount =
          double.parse(_amountController.text.replaceAll(',', ''));

      final List<Map<String, dynamic>> allocationData = [];
      final bool shouldHandleAllocations =
          _hasExistingAllocations || (!_isEditing && _linkToIncomeBalance);

      if (shouldHandleAllocations) {
        final List<_BalanceAllocationInput> validInputs = _allocationInputs
            .where((input) =>
                input.balanceId != null &&
                input.amountController.text.trim().isNotEmpty)
            .toList();

        if (validInputs.isEmpty) {
          final defaultBalance = await db.getDefaultIncomeBalance();
          if (defaultBalance == null || defaultBalance.id == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا يوجد رصيد افتراضي متاح لتوزيع المبلغ')),
              );
            }
            return;
          }
          allocationData.add({
            'balanceId': defaultBalance.id!,
            'amount': totalAmount,
          });
        } else {
          double totalAllocated = 0.0;
          for (final input in validInputs) {
            final balanceId = input.balanceId;
            if (balanceId == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار رصيد لكل سطر توزيع')),
                );
              }
              return;
            }
            final text = input.amountController.text.trim();
            final value = double.tryParse(text.replaceAll(',', ''));
            if (value == null || value <= 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قيمة المبلغ في توزيع الأرصدة غير صحيحة')),
                );
              }
              return;
            }
            totalAllocated += value;
            allocationData.add({
              'balanceId': balanceId,
              'amount': value,
            });
          }

          if ((totalAllocated - totalAmount).abs() > 0.01) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مجموع مبالغ الأرصدة يجب أن يساوي المبلغ الكلي')),
              );
            }
            return;
          }
        }
      }

      if (_isEditing) {
        final existing = widget.transaction!;
        final String selectedCurrency = (_selectedCurrency != null && _selectedCurrency!.trim().isNotEmpty)
            ? _selectedCurrency!.trim()
            : (widget.accountCurrencyCode ?? 'محلي');
        final updated = existing.copyWith(
          amount: totalAmount,
          type: _selectedType,
          date: _selectedDate,
          description: _detailsController.text.trim(),
          imagePaths: _imagePaths,
          currencyName: selectedCurrency,
        );
        if (existing.id != null) {
          await db.updateTransaction(updated);
          if (allocationData.isNotEmpty) {
            await db.deleteTransactionAllocations(existing.id!);
            final allocations = allocationData
                .map(
                  (data) => TransactionBalanceAllocation(
                    transactionId: existing.id!,
                    balanceId: data['balanceId'] as int,
                    allocatedAmount: data['amount'] as double,
                  ),
                )
                .toList();
            await db.insertTransactionAllocations(allocations);
          }
        } else {
          await db.updateTransaction(updated);
        }
      } else {
        final String? selectedCurrency = (_selectedCurrency != null && _selectedCurrency!.trim().isNotEmpty)
            ? _selectedCurrency!.trim()
            : null;

        if (selectedCurrency == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يرجى اختيار العملة')),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        if (_isNewAccount) {
          final name = _accountNameController.text.trim();
          if (_selectedAccount != null &&
              _selectedAccount!.name.trim().toLowerCase() == name.toLowerCase()) {
            existingAccount = _selectedAccount;
          } else {
            final existingAccounts = await db.getAccounts();
            try {
              existingAccount = existingAccounts.firstWhere((a) =>
                  a.name.trim().toLowerCase() == name.toLowerCase() &&
                  a.category == widget.category);
            } catch (_) {
              try {
                existingAccount = existingAccounts.firstWhere((a) =>
                    a.name.trim().toLowerCase() == name.toLowerCase());
              } catch (_) {
                existingAccount = null;
              }
            }
          }

          if (existingAccount != null) {
            accountId = existingAccount.id!;
          } else {
            final account = AccountModel(
              name: name,
              category: widget.category,
              currencyName: selectedCurrency,
              phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              createdDate: DateTime.now(),
            );
            accountId = await db.insertAccount(account);
          }
        }

        final transaction = TransactionModel(
          accountId: accountId,
          amount: totalAmount,
          type: _selectedType,
          category: _isNewAccount && existingAccount != null ? existingAccount.category : widget.category,
          currencyName: selectedCurrency,
          date: _selectedDate,
          description: _detailsController.text.trim(),
          imagePaths: _imagePaths,
        );
        final transactionId = await db.insertTransaction(transaction);
        if (allocationData.isNotEmpty) {
          final allocations = allocationData
              .map(
                (data) => TransactionBalanceAllocation(
                  transactionId: transactionId,
                  balanceId: data['balanceId'] as int,
                  allocatedAmount: data['amount'] as double,
                ),
              )
              .toList();
          await db.insertTransactionAllocations(allocations);
        }
      }

      // Update default and favorite currencies based on the currency actually used.
      final String? usedCurrency = (_selectedCurrency != null && _selectedCurrency!.trim().isNotEmpty)
          ? _selectedCurrency!.trim()
          : null;
      if (usedCurrency != null && usedCurrency.trim().isNotEmpty) {
        await db.registerCurrencyUsage(usedCurrency);
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
    final bool isDebitSelected = _selectedType == 'debit';
    final bool isCreditSelected = _selectedType == 'credit';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'تعديل المعاملة'
                            : (_isNewAccount ? 'عملية جديدة' : 'إضافة معاملة'),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(false);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
              ),
              
              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Name Field (if New Account)
                        if (_isNewAccount) ...[
                          RawAutocomplete<AccountModel>(
                            textEditingController: _accountNameController,
                            focusNode: _nameFocusNode,
                            displayStringForOption: (AccountModel option) => option.name,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.trim().isEmpty) {
                                  return const Iterable<AccountModel>.empty();
                              }
                              final searchTerm = textEditingValue.text.trim().toLowerCase();
                              final matched = _existingAccounts.where((AccountModel option) {
                                return option.name.toLowerCase().contains(searchTerm);
                              }).toList();

                              // Deduplicate by name+category+phone only (not currency)
                              // so that multi-currency accounts appear once
                              final Map<String, AccountModel> uniqueMap = {};
                              for (final option in matched) {
                                final key = '${option.name.trim().toLowerCase()}_${option.category.trim().toLowerCase()}_${(option.phone ?? '').trim()}';
                                uniqueMap.putIfAbsent(key, () => option);
                              }
                              return uniqueMap.values;
                            },
                            onSelected: (AccountModel selection) {
                              setState(() {
                                _selectedAccount = selection;
                                _accountNameController.text = selection.name;
                                final phone = selection.phone;
                                if (phone != null && phone.isNotEmpty) {
                                  _phoneController.text = phone;
                                }
                                // Map 'محلي' to the user's configured default currency name
                                if (selection.currencyName.isNotEmpty) {
                                  final rawCur = selection.currencyName.trim();
                                  _selectedCurrency = (rawCur == 'محلي' && _defaultCurrencyName != null && _defaultCurrencyName!.trim().isNotEmpty)
                                      ? _defaultCurrencyName!.trim()
                                      : rawCur;
                                }
                              });
                            },
                            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                                decoration: InputDecoration(
                                  labelText: 'الاسم',
                                  labelStyle: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                  suffixIcon: IconButton(
                                    icon: SvgPicture.asset(
                                      'assets/images/user-circle.svg',
                                      width: 20,
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                        AppTheme.primaryColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    tooltip: 'اختيار من جهات الاتصال',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _pickContactForName();
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppTheme.dividerColor.withOpacity(0.5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppTheme.dividerColor.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceColor,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال الاسم' : null,
                                onFieldSubmitted: (String value) {
                                  onFieldSubmitted();
                                },
                              );
                            },
                            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<AccountModel> onSelected, Iterable<AccountModel> options) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(14),
                                  shadowColor: AppTheme.textSecondary.withOpacity(0.15),
                                  color: Colors.white,
                                  child: Container(
                                    width: (MediaQuery.of(context).size.width - 72).clamp(0.0, 340.0),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppTheme.dividerColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) => const Divider(
                                          height: 1,
                                          color: AppTheme.dividerColor,
                                        ),
                                        itemBuilder: (BuildContext context, int index) {
                                          final AccountModel option = options.elementAt(index);
                                          return InkWell(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.history_rounded,
                                                    size: 16,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          option.name,
                                                          style: const TextStyle(
                                                            color: AppTheme.textPrimary,
                                                            fontSize: 14,
                                                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        if (option.category.isNotEmpty || (option.phone != null && option.phone!.isNotEmpty)) ...[
                                                           const SizedBox(height: 2),
                                                           Text(
                                                             [
                                                               if (option.category.isNotEmpty) option.category,
                                                               if (option.phone != null && option.phone!.isNotEmpty) option.phone!,
                                                             ].join(' | '),
                                                             style: const TextStyle(
                                                               color: AppTheme.textTertiary,
                                                               fontSize: 11,
                                                               fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                             ),
                                                           ),
                                                         ],
                                                      ],
                                                    ),
                                                  ),
                                                  Builder(builder: (context) {
                                                    // Determine which currencies to show
                                                    final String localDefault = (_defaultCurrencyName != null && _defaultCurrencyName!.trim().isNotEmpty)
                                                        ? _defaultCurrencyName!.trim()
                                                        : 'محلي';
                                                    // Build deduplicated currency set from stats or fallback to currencyName
                                                    final Set<String> seenCurrencies = {};
                                                    final List<String> displayCurrencies = [];
                                                    if (option.currencyStats.isNotEmpty) {
                                                      for (final stat in option.currencyStats) {
                                                        final name = (stat.currencyName.trim() == 'محلي' || stat.currencyName.trim() == localDefault)
                                                            ? localDefault
                                                            : stat.currencyName.trim();
                                                        if (seenCurrencies.add(name)) {
                                                          displayCurrencies.add(name);
                                                        }
                                                      }
                                                    } else if (option.currencyName.isNotEmpty) {
                                                      final rawName = option.currencyName.trim();
                                                      final name = (rawName == 'محلي') ? localDefault : rawName;
                                                      displayCurrencies.add(name);
                                                    }
                                                    if (displayCurrencies.isEmpty) return const SizedBox.shrink();
                                                    return Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const SizedBox(width: 8),
                                                        ...displayCurrencies.map((cur) => Container(
                                                          margin: const EdgeInsets.only(right: 4),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primaryColor.withOpacity(0.06),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            cur,
                                                            style: const TextStyle(
                                                              color: AppTheme.primaryColor,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                            ),
                                                          ),
                                                        )),
                                                      ],
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Amount Field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _ThousandsSeparatorInputFormatter(),
                          ],
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                          decoration: InputDecoration(
                            labelText: 'المبلغ',
                            labelStyle: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 0,
                              minWidth: 0,
                            ),
                            suffixIcon: Builder(
                              builder: (context) {
                                String displayCurrency = _isNewAccount
                                    ? (_selectedCurrency ?? 'العملة')
                                    : ((widget.accountCurrencyCode != null &&
                                                widget.accountCurrencyCode!.isNotEmpty)
                                            ? widget.accountCurrencyCode!
                                            : 'محلي');
                                final bool canPickCurrency = true;

                                final String? defaultName = (_defaultCurrencyName != null &&
                                        _defaultCurrencyName!.trim().isNotEmpty)
                                    ? _defaultCurrencyName!.trim()
                                    : null;
                                if (displayCurrency == 'محلي' && defaultName != null) {
                                  displayCurrency = defaultName;
                                }
                                final List<String> favoriteNames =
                                    _favoriteCurrencyNames.toList(growable: true)
                                      ..sort();
                                if (defaultName != null) {
                                  favoriteNames.removeWhere((e) => e == defaultName);
                                }

                                final List<String> dropdownItems = <String>[];
                                final String? selected =
                                    (_selectedCurrency != null && _selectedCurrency!.trim().isNotEmpty)
                                        ? _selectedCurrency!.trim()
                                        : null;

                                final String? mappedSelected = (selected == 'محلي' && defaultName != null)
                                    ? defaultName
                                    : selected;

                                if (mappedSelected != null && !dropdownItems.contains(mappedSelected)) {
                                  dropdownItems.add(mappedSelected);
                                }
                                if (defaultName != null && !dropdownItems.contains(defaultName)) {
                                  dropdownItems.add(defaultName);
                                }
                                if (defaultName == null && !dropdownItems.contains('محلي')) {
                                  dropdownItems.add('محلي');
                                }
                                for (final name in favoriteNames) {
                                  final mappedName = (name == 'محلي' && defaultName != null) ? defaultName : name;
                                  if (!dropdownItems.contains(mappedName)) {
                                    dropdownItems.add(mappedName);
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 12,
                                    start: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '|',
                                        style: TextStyle(
                                          color: AppTheme.dividerColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!canPickCurrency)
                                        Text(
                                          CurrencyModel.symbolFor(displayCurrency),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                                          ),
                                        )
                                      else
                                        Builder(
                                          builder: (anchorContext) {
                                            final String display = (selected != null)
                                                ? CurrencyModel.symbolFor(selected)
                                                : 'العملة';

                                            return InkWell(
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                _showCurrencyQuickMenu(
                                                  anchorContext,
                                                  items: dropdownItems,
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      display,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primaryColor,
                                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(
                                                      Icons.keyboard_arrow_down_rounded,
                                                      size: 16,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'الرجاء إدخال المبلغ' : null,
                        ),
                        const SizedBox(height: 16),

                        // Premium Cohesive Details & Attachments Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'التفاصيل والمرفقات',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                              const SizedBox(height: 6),
                              
                              // Text Field without nested boundaries
                              TextFormField(
                                controller: _detailsController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 3,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'اكتب تفاصيل المعاملة هنا...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textTertiary.withOpacity(0.7),
                                    fontSize: 13,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                  prefixIcon: _hasDetailsText
                                      ? null
                                      : Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                            start: 0,
                                            end: 8,
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/images/pencil.svg',
                                            width: 16,
                                            height: 16,
                                            colorFilter: const ColorFilter.mode(
                                              AppTheme.textSecondary,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                  isDense: true,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 16, thickness: 1, color: AppTheme.dividerColor),
                              
                              // Modern Selector Chips Row
                              Row(
                                children: [
                                  // Date Chip
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      onTap: () async {
                                        HapticFeedback.lightImpact();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                          builder: (context, child) {
                                            final theme = Theme.of(context);
                                            return Theme(
                                              data: theme.copyWith(
                                                colorScheme: theme.colorScheme.copyWith(
                                                  primary: AppTheme.primaryColor,
                                                  onPrimary: Colors.white,
                                                  onSurface: AppTheme.textPrimary,
                                                ),
                                                dialogTheme: DialogThemeData(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                                datePickerTheme: DatePickerThemeData(
                                                  backgroundColor: Colors.white,
                                                  surfaceTintColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  headerBackgroundColor: AppTheme.primaryColor,
                                                  headerForegroundColor: Colors.white,
                                                  headerHeadlineStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                  ),
                                                  weekdayStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textSecondary,
                                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                  ),
                                                  dayStyle: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                  ),
                                                  yearStyle: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                  ),
                                                ),
                                                textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: AppTheme.primaryColor,
                                                    textStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              child: child ?? const SizedBox.shrink(),
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(() => _selectedDate = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/calendar.svg',
                                              width: 16,
                                              height: 16,
                                              colorFilter: const ColorFilter.mode(
                                                AppTheme.primaryColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${_selectedDate.toLocal()}'.split(' ')[0],
                                                style: const TextStyle(
                                                  fontSize: 13,
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
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Attachment Image Chip
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _pickImages();
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/gallery.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter: const ColorFilter.mode(
                                                AppTheme.primaryColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _imagePaths.isEmpty
                                                    ? 'صورة'
                                                    : '(${_imagePaths.length})',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Selected Images Gallery
                              if (_imagePaths.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: _imagePaths.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
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
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                _removeImage(index);
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
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
                        ),
                        const SizedBox(height: 16),

                        // Advanced options Expandable Banner
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _advancedExpanded = !_advancedExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'تفاصيل إضافية (اختياري)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                ),
                                Icon(
                                  _advancedExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Expanded Advanced section
                        if (_advancedExpanded) ...[
                          const SizedBox(height: 12),
                          if (_incomeBalances.isNotEmpty && !_hasExistingAllocations) ...[
                            CheckboxListTile(
                              value: _linkToIncomeBalance,
                              activeColor: AppTheme.primaryColor,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _linkToIncomeBalance = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'ربط هذه المعاملة برصيد الدخل',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_incomeBalances.isNotEmpty && (_hasExistingAllocations || _linkToIncomeBalance)) ...[
                            _buildBalanceAllocationSection(),
                            const SizedBox(height: 12),
                          ],
                          if (_isNewAccount) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف (اختياري)',
                                labelStyle: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.contacts_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _pickContact();
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: AppTheme.dividerColor.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: AppTheme.dividerColor.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Sticky Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Credit "ديون لك" Button
                    Expanded(
                      child: GestureDetector(
                        onTap: (_isLoading || !_isFormReady)
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setState(() => _selectedType = 'credit');
                                await _save();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isCreditSelected && _isFormReady
                                ? AppTheme.successColor
                                : (_isFormReady
                                    ? AppTheme.successColor.withOpacity(0.07)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isFormReady
                                  ? AppTheme.successColor
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: (isCreditSelected && _isFormReady)
                                ? [
                                    BoxShadow(
                                      color: AppTheme.successColor.withOpacity(0.30),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: _isLoading && _selectedType == 'credit'
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/arrow-long-up.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        (isCreditSelected && _isFormReady)
                                            ? Colors.white
                                            : (_isFormReady
                                                ? AppTheme.successColor
                                                : Colors.grey.shade400),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isNewAccount ? 'ديون لك' : 'لك',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                        color: (isCreditSelected && _isFormReady)
                                            ? Colors.white
                                            : (_isFormReady
                                                ? AppTheme.successColor
                                                : Colors.grey.shade400),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Debit "ديون عليك" Button
                    Expanded(
                      child: GestureDetector(
                        onTap: (_isLoading || !_isFormReady)
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setState(() => _selectedType = 'debit');
                                await _save();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDebitSelected && _isFormReady
                                ? AppTheme.errorColor
                                : (_isFormReady
                                    ? AppTheme.errorColor.withOpacity(0.07)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isFormReady
                                  ? AppTheme.errorColor
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: (isDebitSelected && _isFormReady)
                                ? [
                                    BoxShadow(
                                      color: AppTheme.errorColor.withOpacity(0.30),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: _isLoading && _selectedType == 'debit'
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/arrow-long-down.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        (isDebitSelected && _isFormReady)
                                            ? Colors.white
                                            : (_isFormReady
                                                ? AppTheme.errorColor
                                                : Colors.grey.shade400),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isNewAccount ? 'ديون عليك' : 'عليك',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                        color: (isDebitSelected && _isFormReady)
                                            ? Colors.white
                                            : (_isFormReady
                                                ? AppTheme.errorColor
                                                : Colors.grey.shade400),
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
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: _pickCurrency,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            // prefixIcon: const Icon(
            //   Icons.payments_outlined,
            //   color: AppTheme.textSecondary,
            //   size: 18,
            // ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          child: Text(
            _selectedCurrency ?? 'العملة',
            style: TextStyle(
              fontSize: 14,
              color: _selectedCurrency == null
                  ? AppTheme.textSecondary.withOpacity(0.7)
                  : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyReadonly() {
    String displayName =
        (widget.accountCurrencyCode != null &&
                widget.accountCurrencyCode!.isNotEmpty)
            ? widget.accountCurrencyCode!
            : 'محلي';
    if (displayName == 'محلي' && _defaultCurrencyName != null && _defaultCurrencyName!.trim().isNotEmpty) {
      displayName = _defaultCurrencyName!.trim();
    }

    return TextFormField(
      initialValue: displayName,
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

  Widget _buildBalanceAllocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ربط أو تقسيم المبلغ بين الأرصدة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(_allocationInputs.length, (index) {
            final input = _allocationInputs[index];

            final String? effectiveCurrency = _isNewAccount
                ? _selectedCurrency
                : (widget.accountCurrencyCode != null &&
                        widget.accountCurrencyCode!.isNotEmpty
                    ? widget.accountCurrencyCode!
                    : null);

            final List<IncomeBalanceModel> balancesForDropdown =
                _incomeBalances.where((balance) {
              if (input.balanceId != null && balance.id == input.balanceId) {
                return true;
              }
              if (effectiveCurrency == null) {
                return true;
              }
              final balanceCur = balance.currencyName.trim();
              final effCur = effectiveCurrency.trim();
              if (effCur == 'محلي' || (_defaultCurrencyName != null && effCur == _defaultCurrencyName!.trim())) {
                return balanceCur == 'محلي' || (_defaultCurrencyName != null && balanceCur == _defaultCurrencyName!.trim());
              }
              return balanceCur == effCur;
            }).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      value: input.balanceId,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                      decoration: InputDecoration(
                        labelText: 'الرصيد',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                          ),
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: balancesForDropdown
                          .map(
                            (balance) => DropdownMenuItem<int>(
                              value: balance.id,
                              child: Text(
                                balance.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        _ThousandsSeparatorInputFormatter(),
                      ],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                          ),
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
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
                        Icons.remove_circle_outline,
                        color: AppTheme.errorColor,
                        size: 20,
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
                _allocationInputs.add(_BalanceAllocationInput());
              });
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            label: const Text(
              'أضف تقسيم آخر',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
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
