import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/accounts/presentation/widgets/transaction_tile.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/smart_reminder_dialog.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/currencies/presentation/widgets/local_currency_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/accounts/application/reports/account_report_generator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:async';
import 'package:pdf/pdf.dart';

// Convert AppTheme primary color to PDF color
final PdfColor primaryColor = PdfColor.fromInt(AppTheme.primaryColor.value);

class _AccountEditDialog extends StatefulWidget {
  final AccountModel account;
  final Future<void> Function(String name, String phone, String currency, String address, String workDetails) onSave;

  const _AccountEditDialog({
    required this.account,
    required this.onSave,
  });

  @override
  _AccountEditDialogState createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _workDetailsController;
  String? _selectedCurrency;
  final _formKey = GlobalKey<FormState>();
  String _localCurrencyName = 'محلي';

  Future<void> _pickCurrency() async {
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
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _phoneController = TextEditingController(text: widget.account.phone ?? '');
    _addressController = TextEditingController(text: widget.account.address ?? '');
    _workDetailsController = TextEditingController(text: widget.account.workDetails ?? '');
    _selectedCurrency = widget.account.currencyName.trim();
    _loadLocalCurrencyName();
  }

  Future<void> _loadLocalCurrencyName() async {
    try {
      final name = await DatabaseHelper().getDefaultCurrencyName();
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() {
          _localCurrencyName = name.trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _pickContact() async {
    try {
      final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
      final contact = await _picker.selectContact();
      final number = contact?.phoneNumbers?.isNotEmpty == true ? contact?.phoneNumbers?.first : null;
      if (number != null) {
        HapticFeedback.lightImpact();
        setState(() => _phoneController.text = number);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ).borderRadius,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
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
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تعديل بيانات الحساب',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
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
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            decoration: InputDecoration(
                              labelText: 'اسم الحساب',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                color: AppTheme.primaryColor,
                                size: 18,
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم الحساب' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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
                                      color: AppTheme.primaryColor,
                                      size: 18,
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    width: 1.2,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _pickContact,
                                  icon: const Icon(
                                    Icons.contacts_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                  tooltip: 'اختيار من جهات الاتصال',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            decoration: InputDecoration(
                              labelText: 'العنوان (اختياري)',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.primaryColor,
                                size: 18,
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _workDetailsController,
                            maxLines: 2,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                            decoration: InputDecoration(
                              labelText: 'تفاصيل العمل (اختياري)',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                              prefixIcon: const Icon(
                                Icons.work_rounded,
                                color: AppTheme.primaryColor,
                                size: 18,
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FormField<String>(
                            initialValue: _selectedCurrency,
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى اختيار العملة' : null,
                            builder: (field) {
                              return InkWell(
                                onTap: () async {
                                  await _pickCurrency();
                                  field.didChange(_selectedCurrency);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'العملة',
                                    labelStyle: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.attach_money_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 18,
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    errorText: field.errorText,
                                    suffixIcon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  child: Text(
                                    (_selectedCurrency != null && _selectedCurrency!.trim().isNotEmpty)
                                        ? (_selectedCurrency!.trim() == 'محلي' ? _localCurrencyName : _selectedCurrency!.trim())
                                        : 'اختر العملة',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            backgroundColor: Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              HapticFeedback.mediumImpact();
                              await widget.onSave(
                                _nameController.text.trim(),
                                _phoneController.text.trim(),
                                _selectedCurrency!,
                                _addressController.text.trim(),
                                _workDetailsController.text.trim()
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'حفظ والتحديث',
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
      ),
    );


  }
}

class AccountTransactionsScreen extends StatefulWidget {
  final AccountModel account;
  final int? highlightTransactionId;

  const AccountTransactionsScreen({
    super.key,
    required this.account,
    this.highlightTransactionId,
  });

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  late AccountModel _currentAccount;
  bool _accountUpdated = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _highlightTimer;
  int? _currentHighlightId;
  String _selectedCurrencyFilter = 'all';
  List<String> _availableCurrencies = const <String>[];
  String _localCurrencyName = 'محلي';

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
    _currentHighlightId = widget.highlightTransactionId;
    _loadTransactions();
    
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
    _scrollController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _toggleSelection(TransactionModel t) {
    if (t.id == null) return;
    setState(() {
      if (_selectedIds.contains(t.id)) {
        _selectedIds.remove(t.id);
      } else {
        _selectedIds.add(t.id!);
      }
    });
  }

  void _markAccountAsUpdated() {
    setState(() {
      _accountUpdated = true;
    });
  }

  void _scrollToHighlightedTransaction() {
    if (widget.highlightTransactionId == null || _transactions.isEmpty) return;
    
    // Find the index of the highlighted transaction
    final highlightedIndex = _transactions.indexWhere(
      (transaction) => transaction.id == widget.highlightTransactionId
    );
    
    if (highlightedIndex != -1) {
      // Add a small delay to ensure the UI is built
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // Calculate the position to scroll to (approximate height per item)
          const itemHeight = 80.0; // Approximate height of TransactionTile
          final scrollPosition = highlightedIndex * itemHeight;
          
          _scrollController.animateTo(
            scrollPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  List<TransactionModel> get _filteredTransactions {
    if (_selectedCurrencyFilter == 'all') return _transactions;
    final filter = _selectedCurrencyFilter.trim();
    return _transactions
        .where((t) {
          final tCur = t.currencyName.trim();
          if (filter == _localCurrencyName) {
            return tCur == 'محلي' || tCur == _localCurrencyName;
          }
          return tCur == filter;
        })
        .toList();
  }

  void _recalculateTotals() {
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final t in _filteredTransactions) {
      if (t.type == 'debit') {
        totalDebit += t.amount;
      } else {
        totalCredit += t.amount;
      }
    }

    _totals = {
      'debit': totalDebit,
      'credit': totalCredit,
      'net': totalCredit - totalDebit,
    };
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: AppTheme.errorColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'تأكيد حذف المحدد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Content text
                    Text(
                      'سيتم حذف ${_selectedIds.length} معاملة نهائياً.\nهل تريد الاستمرار؟',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              backgroundColor: Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'حذف الآن',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
    if (confirmed) {
      for (final id in _selectedIds) {
        await DatabaseHelper().deleteTransaction(id);
      }
      _clearSelection();
      await _loadTransactions();
      _markAccountAsUpdated();
    }
  }

  Future<void> _printSelected() async {
    if (_selectedIds.isEmpty) return;
    final sel = _filteredTransactions.where((t) => _selectedIds.contains(t.id)).toList();
    if (sel.isEmpty) return;

    final bool includeCurrencyColumn = _selectedCurrencyFilter == 'all';
    final rows = sel
        .map((t) => [
              DateFormat('yyyy/MM/dd').format(t.date),
              t.description ?? '-',
              t.type == 'credit' ? t.amount.toStringAsFixed(0) : '-',
              t.type == 'debit' ? t.amount.toStringAsFixed(0) : '-',
              if (includeCurrencyColumn) (t.currencyName.trim() == 'محلي' ? _localCurrencyName : t.currencyName),
            ])
        .toList();

    final headers = <String>['التاريخ', 'تفاصيل', 'لك', 'عليك'];
    if (includeCurrencyColumn) {
      headers.add('العملة');
    }
    await ReportService.generateAndOpenPdfWithTableData(
      title: 'معاملات مختارة - ${widget.account.name}',
      headerContent: [],
      tableHeaders: headers,
      tableData: rows,
    );
  }

  void _shareSelected() {
    if (_selectedIds.isEmpty) return;
    final selectedTx = _filteredTransactions.where((t) => _selectedIds.contains(t.id)).toList();
    if (selectedTx.isEmpty) return;
    final header = 'حساب: ${widget.account.name}';
    final lines = selectedTx
        .map((t) {
          final label = t.type == 'debit' ? 'عليك' : 'لك';
          final amountPart = '${t.amount.toStringAsFixed(0)}';
          if (_selectedCurrencyFilter == 'all') {
            return '${DateFormat('dd/MM/yy').format(t.date)} - ${t.description ?? ''} - $label $amountPart ${(t.currencyName.trim() == 'محلي' ? _localCurrencyName : t.currencyName)}';
          }
          return '${DateFormat('dd/MM/yy').format(t.date)} - ${t.description ?? ''} - $label $amountPart';
        })
        .join('\n');
    Share.share('$header\n$lines', subject: 'معاملات مختارة - ${widget.account.name}');
  }

  List<TransactionModel> _transactions = [];
  Map<String, double> _totals = {'debit': 0.0, 'credit': 0.0, 'net': 0.0};
  bool _isLoading = true;

  int _lastPerfLogEpochMs = 0;

  void _debugPerf(String label, Stopwatch sw, {int thresholdMs = 16}) {
    if (!kDebugMode) return;
    final ms = sw.elapsedMilliseconds;
    if (ms < thresholdMs) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPerfLogEpochMs < 500) return;
    _lastPerfLogEpochMs = now;
    debugPrint('PERF $label: ${ms}ms');
  }

  final Set<int> _selectedIds = {};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  Future<void> _generateReportForAccount() async {
    await AccountReportGenerator.generate(
      account: widget.account,
      transactions: _filteredTransactions,
      totals: _totals,
      currencyFilterName: _selectedCurrencyFilter,
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: color, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, color: color, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  pw.Widget _buildAccountInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: primaryColor.shade(0.6), fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, color: primaryColor.shade(0.8), fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  Future<void> _loadTransactions() async {
    final swTotal = Stopwatch()..start();
    setState(() {
      _isLoading = true;
    });

    try {
      final localName = await DatabaseHelper().getDefaultCurrencyName();
      final resolvedLocalName = (localName != null && localName.trim().isNotEmpty) ? localName.trim() : 'محلي';

      final swDb = Stopwatch()..start();
      final transactions = await DatabaseHelper().getTransactionsByAccount(widget.account.id!);
      _debugPerf('AccountTransactions._loadTransactions.db', swDb);

      final swCurrencies = Stopwatch()..start();
      final Set<String> currencySet = <String>{};
      for (final t in transactions) {
        final name = t.currencyName.trim();
        if (name.isNotEmpty) {
          if (name == 'محلي') {
            currencySet.add(resolvedLocalName);
          } else {
            currencySet.add(name);
          }
        }
      }
      final currencies = currencySet.toList()..sort();
      if (currencies.isNotEmpty && currencies.first != resolvedLocalName && currencies.contains(resolvedLocalName)) {
        currencies
          ..remove(resolvedLocalName)
          ..insert(0, resolvedLocalName);
      }
      if (!currencies.contains(resolvedLocalName)) {
        currencies.insert(0, resolvedLocalName);
      }
      _debugPerf('AccountTransactions._loadTransactions.buildCurrencies', swCurrencies);

      String selected = _selectedCurrencyFilter;
      if (selected == 'محلي') {
        selected = resolvedLocalName;
      }
      if (selected != 'all' && !currencySet.contains(selected)) {
        selected = 'all';
      }

      setState(() {
        _localCurrencyName = resolvedLocalName;
        _transactions = transactions;
        _availableCurrencies = currencies;
        _selectedCurrencyFilter = selected;
        _recalculateTotals();
        _isLoading = false;
      });

      _debugPerf('AccountTransactions._loadTransactions.total', swTotal);
      
      // Auto-scroll to highlighted transaction if exists
      if (widget.highlightTransactionId != null) {
        _scrollToHighlightedTransaction();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المعاملات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(
            accountId: widget.account.id!,
            category: widget.account.category,
            accountCurrencyCode: _currentAccount.currencyName.trim() == 'محلي' ? _localCurrencyName : _currentAccount.currencyName,
          ),
        ) ??
        false;

    if (result == true) {
      await _loadTransactions();
      _markAccountAsUpdated();
    }
  }

  void _showTransactionDetailDialog(TransactionModel transaction) {
    final bool isCredit = transaction.type == 'credit';
    final Color badgeColor = isCredit ? AppTheme.successColor : AppTheme.errorColor;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: badgeColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تفاصيل المعاملة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Transaction Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('المبلغ', '${NumberFormat('#,##0').format(transaction.amount)} ${(transaction.currencyName.trim() == 'محلي' ? _localCurrencyName : transaction.currencyName)}', isBold: true, valueColor: badgeColor),
                        const SizedBox(height: 12),
                        _buildDetailRow('النوع', isCredit ? 'ديون لك (إيداع)' : 'ديون عليك (سحب)', isBold: true, valueColor: badgeColor),
                        const SizedBox(height: 12),
                        _buildDetailRow('التفاصيل', transaction.description?.isNotEmpty == true ? transaction.description! : 'لا توجد تفاصيل'),
                        const SizedBox(height: 12),
                        _buildDetailRow('التاريخ', DateFormat('yyyy/MM/dd - hh:mm a').format(transaction.date)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            _navigateToEditTransaction(transaction);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            'تعديل',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            _showDeleteConfirmationDialog(transaction);
                          },
                          icon: const Icon(Icons.delete_rounded, size: 16),
                          label: const Text(
                            'حذف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppTheme.errorColor.withOpacity(0.2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppTheme.textPrimary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.errorColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'تأكيد الحذف',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Content text
                  const Text(
                    'هل أنت متأكد من حذف هذه المعاملة؟\nلا يمكن التراجع عن هذا الإجراء بعد الحفظ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            backgroundColor: Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            _deleteTransaction(transaction);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'تأكيد الحذف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToEditTransaction(TransactionModel transaction) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(
            accountId: widget.account.id!,
            category: widget.account.category,
            accountCurrencyCode: _currentAccount.currencyName.trim() == 'محلي' ? _localCurrencyName : _currentAccount.currencyName,
            transaction: transaction,
          ),
        ) ??
        false;

    if (result == true) {
      await _loadTransactions();
      _markAccountAsUpdated();
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      await DatabaseHelper().deleteTransaction(transaction.id!);
      await _loadTransactions();
      _markAccountAsUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف المعاملة بنجاح',
              style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في حذف المعاملة: $e',
              style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildStatCard(String title, String amount, Color color) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '$title: $amount',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  void _editAccountDetails() {
    showDialog(
      context: context,
      builder: (context) => _AccountEditDialog(
        account: _currentAccount,
        onSave: (name, phone, currency, address, workDetails) async {
          try {
            if (_currentAccount.id == null) {
              throw Exception('Account ID is null - cannot update');
            }
            
            // Create a new AccountModel with updated values
            final updatedAccount = _currentAccount.copyWith(
              name: name,
              phone: phone.isEmpty ? null : phone,
              currencyName: currency,
              address: address.isEmpty ? null : address,
              workDetails: workDetails.isEmpty ? null : workDetails,
            );
            
            // Save to database
            final result = await DatabaseHelper().updateAccount(updatedAccount);
            
            if (result > 0) {
              setState(() {
                _currentAccount = updatedAccount;
              });
              _markAccountAsUpdated();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث بيانات الحساب بنجاح'), backgroundColor: Colors.green),
              );
            } else {
              throw Exception('No rows were updated in the database');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ في تحديث الحساب: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildTransactionList() {
    if (_transactions.isEmpty) return [];
    
    final data = _filteredTransactions;
    if (data.isEmpty) return [];

    return data.map((transaction) => 
      TransactionTile(
        transaction: transaction,
        selected: _selectedIds.contains(transaction.id),
        highlighted: _currentHighlightId != null && transaction.id == _currentHighlightId,
        onTap: _selectionMode
              ? () => _toggleSelection(transaction)
              : () => _showTransactionDetailDialog(transaction),
        onLongPress: () => _toggleSelection(transaction),
      )
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              title: Text(
                'تم تحديد ${_selectedIds.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
              backgroundColor: AppTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _clearSelection,
                tooltip: 'إلغاء التحديد',
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedIds.length == _transactions.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _transactions.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds
                          ..clear()
                          ..addAll(_transactions.map((e) => e.id!).whereType<int>());
                      }
                    });
                  },
                  tooltip: _selectedIds.length == _transactions.length 
                      ? 'إلغاء تحديد الكل' 
                      : 'تحديد الكل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  onPressed: _deleteSelected,
                  tooltip: 'حذف المحدد',
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: _shareSelected,
                  tooltip: 'مشاركة',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  tooltip: 'المزيد',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  onSelected: (value) {
                    switch (value) {
                      case 'print':
                        _printSelected();
                        break;
                      case 'export':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم إضافة وظيفة تصدير المحدد قريباً')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'print',
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.print_rounded, color: AppTheme.primaryColor, size: 20),
                        ),
                        title: const Text(
                          'طباعة المحدد',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.file_download_rounded, color: Colors.green, size: 20),
                        ),
                        title: const Text(
                          'تصدير المحدد',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.primaryColor),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppTheme.primaryColor,
                iconSize: 20,
                onPressed: () => Navigator.of(context).pop(_accountUpdated ? _currentAccount : null),
                tooltip: 'رجوع',
              ),
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentAccount.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                        if (_currentAccount.phone != null && _currentAccount.phone!.isNotEmpty)
                          Text(
                            _currentAccount.phone!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary.withOpacity(0.8),
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 70),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Text(
                      _currentAccount.currencyName.trim() == 'محلي' ? _localCurrencyName : _currentAccount.currencyName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 22),
                  onPressed: _editAccountDetails,
                  tooltip: 'تعديل الحساب',
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/report_icons/pdf_report.svg',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _generateReportForAccount,
                  tooltip: 'عرض التقرير',
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              bottom: true,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Currency selection and Smart Reminder Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dividerColor),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCurrencyFilter,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: 'all',
                                      child: Text('جميع العملات'),
                                    ),
                                    ..._availableCurrencies.map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedCurrencyFilter = v;
                                      _selectedIds.clear();
                                      _recalculateTotals();
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_totals['net'] != 0)
                              ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  showDialog(
                                    context: context,
                                    builder: (context) => SmartReminderDialog(
                                      account: _currentAccount,
                                      netBalance: _totals['net']!,
                                      currency: _selectedCurrencyFilter == 'all' 
                                          ? (_currentAccount.currencyName.trim() == 'محلي' ? _localCurrencyName : _currentAccount.currencyName) 
                                          : _selectedCurrencyFilter,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                                label: const Text(
                                  'تذكير ذكي 🔔',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Bento Grid stats cards (Credit & Debit side-by-side)
                        Row(
                          children: [
                            // Credit Bento card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded, color: AppTheme.creditColor, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'إجمالي ديون لك',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      NumberFormat('#,##0').format(_totals['credit']),
                                      style: const TextStyle(
                                        color: AppTheme.creditColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Debit Bento card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, color: AppTheme.debitColor, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'إجمالي ديون عليك',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      NumberFormat('#,##0').format(_totals['debit']),
                                      style: const TextStyle(
                                        color: AppTheme.debitColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Remaining / Net Balance Bento Card (Span Full Width)
                        Builder(
                          builder: (context) {
                            final double netVal = _totals['net']!;
                            final bool isFavor = netVal >= 0;
                            final Color stateColor = isFavor ? AppTheme.creditColor : AppTheme.debitColor;
                            
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isFavor
                                      ? [Colors.green.shade50, Colors.white]
                                      : [Colors.red.shade50, Colors.white],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: stateColor.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isFavor ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                            color: stateColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isFavor ? 'الرصيد المتبقي (لصالحك)' : 'الرصيد المتبقي (مستحق عليك)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: stateColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isFavor ? 'فائض مالي' : 'مطلوب سداد',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: stateColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    NumberFormat('#,##0').format(netVal.abs()),
                                    style: TextStyle(
                                      color: stateColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Premium Repayment Progress Bar
                        if (_totals['credit']! > 0 && _totals['debit']! > 0) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final double credit = _totals['credit']!;
                              final double debit = _totals['debit']!;
                              final double ratio = credit >= debit ? (debit / credit) : (credit / debit);
                              final String percentStr = (ratio * 100).toStringAsFixed(0);
                              final Color progressColor = ratio >= 0.75 
                                  ? Colors.green 
                                  : (ratio >= 0.4 ? Colors.orange : Colors.red);
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          credit >= debit ? 'نسبة تسوية الديون (المدفوع)' : 'نسبة سداد ما عليك (المدفوع)',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '$percentStr%',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor: AppTheme.backgroundColor,
                                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
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
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(),
                            child: const Row(
                              children: [
                                Expanded(flex: 4, child: Text('تفاصيل', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                                Expanded(flex: 2, child: Center(child: Text('لك', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)))),
                                Expanded(flex: 2, child: Center(child: Text('عليك', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          Expanded(
                            child: _filteredTransactions.isEmpty
                                ? Center(
                                    child: Text(
                                      _selectedCurrencyFilter == 'all'
                                          ? 'لا توجد معاملات لهذا الحساب'
                                          : 'لا توجد معاملات لهذه العملة',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView(
                                    controller: _scrollController,
                                    children: _buildTransactionList(),
                                  ),
                          ),
                          const Divider(
                            height: 1,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: _navigateToAddTransaction,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        foregroundColor: AppTheme.primaryColor,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        Icons.add,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'معاملة جديدة',
                                        style: TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
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
              ),
            ),
    );  
  }
}
