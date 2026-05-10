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
import 'package:world_countries/world_countries.dart';

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

  final DatabaseHelper _db = DatabaseHelper();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'debit';
  String? _selectedCurrency;
  Set<String> _favoriteCurrencyNames = <String>{};
  String? _defaultCurrencyName;
  Iterable<FiatCurrency>? _allFiatCurrencies;

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
    for (final input in _allocationInputs) {
      input.dispose();
    }
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
                      _getCurrencySymbol(cur),
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
    }
    _initBalancesAndAllocations();

    if (_isEditing) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _detailsController.text = t.description ?? '';
      _selectedType = t.type;
      _selectedDate = t.date;
      _imagePaths = List<String>.from(t.imagePaths);
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
    _accountNameController.addListener(updateReady);
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

  Iterable<FiatCurrency> _getAllFiatCurrencies() {
    if (_allFiatCurrencies != null) {
      return _allFiatCurrencies!;
    }
    final picker = CurrencyPicker(onSelect: (_) {});
    _allFiatCurrencies = picker.currencies.toList(growable: false);
    return _allFiatCurrencies!;
  }

  FiatCurrency? _findFiatByDisplayName(String displayName) {
    final typedLocale = context.maybeLocale;
    final all = _getAllFiatCurrencies();

    for (final c in all) {
      if (typedLocale != null) {
        final common = c.translations.firstWhere((e) => e.language == typedLocale.language, orElse: () => TranslatedName(typedLocale.language, name: '')).name;
        if (common != null && common == displayName) {
          return c;
        }
      }
      if (c.internationalName == displayName) {
        return c;
      }
    }
    return null;
  }

  FiatCurrency? _findFiatByCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    for (final c in _getAllFiatCurrencies()) {
      if (c.code.toUpperCase() == normalized) {
        return c;
      }
    }
    return null;
  }

  String _getCurrencySymbol(String displayName) {
    final name = displayName.trim();
    if (name.isEmpty) return '';

    if (name == 'محلي') return 'م';

    final fiat = _findFiatByDisplayName(name) ?? _findFiatByCode(name);
    if (fiat == null) return 'م';

    switch (fiat.code) {
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      case 'EGP':
        return 'ج.م';
      default:
        break;
    }

    if (fiat.symbol != null && fiat.symbol!.isNotEmpty) {
      return fiat.symbol!;
    }

    String? symbol;
    if (fiat.disambiguateSymbol != null && fiat.disambiguateSymbol!.isNotEmpty) {
      symbol = fiat.disambiguateSymbol;
    } else if (fiat.alternateSymbols != null && fiat.alternateSymbols!.isNotEmpty) {
      symbol = fiat.alternateSymbols!.first;
    }

    if (symbol != null && symbol.isNotEmpty) {
      return symbol;
    }

    return fiat.code;
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
    initial ??= await _db.getDefaultCurrencyName();

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
      FiatCurrency? chosen;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 380, maxHeight: 520),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
                            // child: const Icon(
                            //   Icons.payments_outlined,
                            //   color: AppTheme.primaryColor,
                            //   size: 18,
                            // ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'العملة',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            icon: const Icon(
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
                      child: CurrencyPicker(
                        onSelect: (FiatCurrency currency) {
                          chosen = currency;
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (chosen != null && mounted) {
        final typedLocale = context.maybeLocale;
        String displayName;
        if (typedLocale != null) {
          displayName = chosen!.translations.firstWhere((e) => e.language == typedLocale.language, orElse: () => TranslatedName(typedLocale.language, name: '')).name ??
              chosen!.internationalName;
        } else {
          displayName = chosen!.internationalName;
        }

        setState(() {
          _selectedCurrency = displayName;
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
          final account = AccountModel(
            name: _accountNameController.text.trim(),
            category: widget.category,
            currencyName: selectedCurrency,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            createdDate: DateTime.now(),
          );
          accountId = await db.insertAccount(account);
        }

        final transaction = TransactionModel(
          accountId: accountId,
          amount: totalAmount,
          type: _selectedType,
          category: widget.category,
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
            // Header (match account list header height & feel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    padding: const EdgeInsets.all(6),
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
                      _isEditing
                          ? 'تعديل معاملة'
                          : (_isNewAccount ? 'حساب جديد' : 'إضافة معاملة'),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.errorColor,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic information section
                      if (_isNewAccount) ...[
                        TextFormField(
                          controller: _accountNameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم',
                            labelStyle: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
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
                              final String displayCurrency = _isNewAccount
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

                              if (selected != null && !dropdownItems.contains(selected)) {
                                dropdownItems.add(selected);
                              }
                              if (defaultName != null && !dropdownItems.contains(defaultName)) {
                                dropdownItems.add(defaultName);
                              }
                              if (!dropdownItems.contains('محلي')) {
                                dropdownItems.add('محلي');
                              }
                              for (final name in favoriteNames) {
                                if (!dropdownItems.contains(name)) {
                                  dropdownItems.add(name);
                                }
                              }

                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 10,
                                  start: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '|',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!canPickCurrency)
                                      Text(
                                        _getCurrencySymbol(displayCurrency),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      )
                                    else
                                      Builder(
                                        builder: (anchorContext) {
                                          final String display = (selected != null)
                                              ? _getCurrencySymbol(selected)
                                              : 'العملة';

                                          return InkWell(
                                            onTap: () => _showCurrencyQuickMenu(
                                              anchorContext,
                                              items: dropdownItems,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                display,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    if (canPickCurrency) ...[
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تفاصيل',
                          labelStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _detailsController,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              minLines: 1,
                              maxLines: 2,
                              decoration: InputDecoration(
                                prefixIcon: _hasDetailsText
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                          start: 4,
                                          end: 8,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/pencil.svg',
                                          width: 18,
                                          height: 18,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.dividerColor),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () async {
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
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              datePickerTheme: DatePickerThemeData(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                headerBackgroundColor: AppTheme.primaryColor,
                                                headerForegroundColor: Colors.white,
                                                headerHeadlineStyle: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                weekdayStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                dayStyle: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                yearStyle: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              textButtonTheme: TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: AppTheme.primaryColor,
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
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
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/calendar.svg',
                                            width: 18,
                                            height: 18,
                                            colorFilter: ColorFilter.mode(
                                              AppTheme.primaryColor.withOpacity(0.7),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${_selectedDate.toLocal()}'.split(' ')[0],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: _pickImages,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/gallery.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                              AppTheme.primaryColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _imagePaths.isEmpty
                                                  ? 'صوره'
                                                  : '(${_imagePaths.length})',
                                              style: const TextStyle(
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
                                ),
                              ],
                            ),
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
                      ),
                      const SizedBox(height: 16),
                      // Advanced section toggle
                      InkWell(
                        onTap: () {
                          setState(() {
                            _advancedExpanded = !_advancedExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'تفاصيل إضافية (اختياري)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                _advancedExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_advancedExpanded) ...[
                        const SizedBox(height: 12),
                        if (_incomeBalances.isNotEmpty && !_hasExistingAllocations) ...[
                          CheckboxListTile(
                            value: _linkToIncomeBalance,
                            onChanged: (value) {
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_incomeBalances.isNotEmpty && (_hasExistingAllocations || _linkToIncomeBalance)) ...[
                          _buildBalanceAllocationSection(),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 12),
                        if (_isNewAccount)
                          TextFormField(
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    child: InkWell(
                      onTap: (_isLoading || !_isFormReady)
                          ? null
                          : () async {
                              setState(() => _selectedType = 'credit');
                              await _save();
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'credit'
                              ? AppTheme.successColor.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_isFormReady
                                    ? AppTheme.successColor
                                    : AppTheme.successColor.withOpacity(0.35)),
                            width: 1.5,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final base = AppTheme.successColor;
                            final color = _isFormReady ? base : base.withOpacity(0.35);
                            if (_isLoading && _selectedType == 'credit') {
                              return const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/arrow-long-up.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'له',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: (_isLoading || !_isFormReady)
                          ? null
                          : () async {
                              setState(() => _selectedType = 'debit');
                              await _save();
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'debit'
                              ? AppTheme.errorColor.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_isFormReady
                                    ? AppTheme.errorColor
                                    : AppTheme.errorColor.withOpacity(0.35)),
                            width: 1.5,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final base = AppTheme.errorColor;
                            final color = _isFormReady ? base : base.withOpacity(0.35);
                            if (_isLoading && _selectedType == 'debit') {
                              return const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/arrow-long-down.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'عليه',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
    final String displayName =
        (widget.accountCurrencyCode != null &&
                widget.accountCurrencyCode!.isNotEmpty)
            ? widget.accountCurrencyCode!
            : 'محلي';

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
          'ربط او تقسيم المبلغ بين الارصدة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
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
              return balance.currencyName == effectiveCurrency;
            }).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
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
                          fontSize: 14,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: balancesForDropdown
                          .map(
                            (balance) => DropdownMenuItem<int>(
                              value: balance.id,
                              child: Text(
                                balance.name,
                                style: const TextStyle(fontSize: 13),
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
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  if (_allocationInputs.length > 1)
                    IconButton(
                      onPressed: () {
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
              setState(() {
                _allocationInputs.add(_BalanceAllocationInput());
              });
            },
            icon: const Icon(
              Icons.add,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            label: const Text(
              'اضف تقسيم آخر',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
