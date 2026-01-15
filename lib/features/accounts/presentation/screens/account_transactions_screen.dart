import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/accounts/presentation/widgets/transaction_tile.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/core/services/report_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/accounts/application/reports/account_report_generator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
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
  List<CurrencyModel> _currencies = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _phoneController = TextEditingController(text: widget.account.phone ?? '');
    _addressController = TextEditingController(text: widget.account.address ?? '');
    _workDetailsController = TextEditingController(text: widget.account.workDetails ?? '');
    _selectedCurrency = widget.account.currencyName;
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await DatabaseHelper().getCurrencies();
      if (currencies.isEmpty) {
        setState(() {
          _currencies = CurrencyModel.getDefaultCurrencies();
          // Only reset if the current currency is null or empty
          if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.name : null;
          }
        });
      } else {
        setState(() {
          _currencies = currencies;
          // Only reset if the current currency is null or empty
          if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
            _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.name : null;
          }
        });
      }
    } catch (e) {
      setState(() {
        _currencies = CurrencyModel.getDefaultCurrencies();
        // Only reset if the current currency is null or empty
        if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
          _selectedCurrency = _currencies.isNotEmpty ? _currencies.first.name : null;
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
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
                      child: const Icon(
                        Icons.edit_outlined,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم الحساب',
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      labelStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _pickContact,
                    icon: const Icon(
                      Icons.contacts_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
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
              decoration: InputDecoration(
                labelText: 'العنوان (اختياري)',
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workDetailsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'تفاصيل العمل (اختياري)',
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.work_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'العملة',
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.attach_money_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _currencies.map((currency) => DropdownMenuItem<String>(
                value: currency.name,
                child: Text(currency.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
              },
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى اختيار العملة' : null,
              isExpanded: true,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              menuMaxHeight: 200,
              dropdownColor: Colors.white,
              alignment: AlignmentDirectional.centerStart,
            ),
                    ],
                  ),
                ),
              ),
              ),
              
              Container(
                padding: const EdgeInsets.all(20),
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
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppTheme.dividerColor),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 16,
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

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('سيتم حذف ${_selectedIds.length} معاملة. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
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
    final sel = _transactions.where((t) => _selectedIds.contains(t.id)).toList();
    final rows = sel.map((t) => [
          DateFormat('yyyy/MM/dd').format(t.date),
          t.description ?? '-',
          t.type == 'credit' ? t.amount.toStringAsFixed(0) : '-',
          t.type == 'debit' ? t.amount.toStringAsFixed(0) : '-',
        ]).toList();
    await ReportService.generateAndOpenPdfWithTableData(
      title: 'معاملات مختارة - ${widget.account.name}',
      headerContent: [],
      tableHeaders: ['التاريخ', 'تفاصيل', 'له', 'عليه'],
      tableData: rows,
    );
  }

  void _shareSelected() {
    if (_selectedIds.isEmpty) return;
    final selectedTx = _transactions.where((t) => _selectedIds.contains(t.id)).toList();
    final header = 'حساب: ${widget.account.name}';
    final lines = selectedTx
        .map((t) {
          final label = t.type == 'debit' ? 'عليه' : 'له';
          return '${DateFormat('dd/MM/yy').format(t.date)} - ${t.description ?? ''} - $label ${t.amount.toStringAsFixed(0)} ${_currentAccount.currencyName}';
        })
        .join('\n');
    Share.share('$header\n$lines', subject: 'معاملات مختارة - ${widget.account.name}');
  }

  List<TransactionModel> _transactions = [];
  Map<String, double> _totals = {'debit': 0.0, 'credit': 0.0, 'net': 0.0};
  bool _isLoading = true;

  final Set<int> _selectedIds = {};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  Future<void> _generateReportForAccount() async {
    await AccountReportGenerator.generate(
      account: widget.account,
      transactions: _transactions,
      totals: _totals,
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
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseHelper().getTransactionsByAccount(widget.account.id!);

      double totalDebit = 0.0;
      double totalCredit = 0.0;

      for (TransactionModel transaction in transactions) {
        if (transaction.type == 'debit') {
          totalDebit += transaction.amount;
        } else {
          totalCredit += transaction.amount;
        }
      }

      setState(() {
        _transactions = transactions;
        _totals = {
          'debit': totalDebit,
          'credit': totalCredit,
          'net': totalCredit - totalDebit,
        };
        _isLoading = false;
      });
      
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
            accountCurrencyCode: _currentAccount.currencyName,
          ),
        ) ??
        false;

    if (result == true) {
      await _loadTransactions();
      _markAccountAsUpdated();
    }
  }

  void _showTransactionDetailDialog(TransactionModel transaction) {
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
                        'تفاصيل المعاملة',
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
                  
                  // Transaction Details
                  _buildDetailRow('المبلغ', '${NumberFormat('#,##0').format(transaction.amount)} ${_currentAccount.currencyName}'),
                  const SizedBox(height: 12),
                  _buildDetailRow('النوع', transaction.type == 'credit' ? 'له' : 'عليه'),
                  const SizedBox(height: 12),
                  _buildDetailRow('التفاصيل', transaction.description?.isNotEmpty == true ? transaction.description! : 'لا توجد تفاصيل'),
                  const SizedBox(height: 12),
                  _buildDetailRow('التاريخ', DateFormat('yyyy/MM/dd - HH:mm').format(transaction.date)),
                  
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
                                _navigateToEditTransaction(transaction);
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
                                _showDeleteConfirmationDialog(transaction);
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
        const SizedBox(width: 12),
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

  void _showDeleteConfirmationDialog(TransactionModel transaction) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            content: Text(
              'هل أنت متأكد من حذف هذه المعاملة؟\nلا يمكن التراجع عن هذا الإجراء.',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteTransaction(transaction);
                  },
                  child: const Text(
                    'حذف',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
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
            accountCurrencyCode: _currentAccount.currencyName,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().deleteTransaction(transaction.id!);
        await _loadTransactions();
        _markAccountAsUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المعاملة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المعاملة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    
    return _transactions.map((transaction) => 
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
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
                tooltip: 'إلغاء التحديد',
              ),
              title: Text('تم تحديد ${_selectedIds.length}'),
              actions: [
                IconButton(
                  icon: Icon(_selectedIds.length == _transactions.length 
                      ? Icons.deselect 
                      : Icons.select_all),
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
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                  tooltip: 'حذف المحدد',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareSelected,
                  tooltip: 'مشاركة',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'المزيد',
                  onSelected: (value) {
                    switch (value) {
                      case 'print':
                        _printSelected();
                        break;
                      case 'export':
                        // TODO: Implement export selected functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم إضافة وظيفة تصدير المحدد قريباً')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'print',
                      child: ListTile(
                        leading: Icon(Icons.print),
                        title: Text('طباعة المحدد'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.file_download),
                        title: Text('تصدير المحدد'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : AppBar(
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [

                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/report_icons/pdf_report.svg',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: _generateReportForAccount,
                    tooltip: 'عرض التقرير',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editAccountDetails,
                    tooltip: 'تعديل الحساب',
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Text(
                            _currentAccount.currencyName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentAccount.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_currentAccount.phone != null && _currentAccount.phone!.isNotEmpty)
                                Text(
                                  _currentAccount.phone!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => Navigator.of(context).pop(_accountUpdated ? _currentAccount : null),
                          tooltip: 'رجوع',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 0, top: 8,right: 8,left:8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'له: ${NumberFormat('#,##0').format(_totals['credit'])}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عليه: ${NumberFormat('#,##0').format(_totals['debit'])}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_totals['credit']! >= _totals['debit']! ? 'المتبقي له' : 'المتبقي عليه'}: ${NumberFormat('#,##0').format((_totals['net']!).abs())}',
                            style: TextStyle(
                              color: _totals['credit']! >= _totals['debit']! ? Colors.green : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                    ),
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد معاملات لهذا الحساب',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'استخدم الزر العائم لإضافة معاملة جديدة',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
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
                                      Expanded(flex: 3, child: Text('المبلغ', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                                      Expanded(flex: 4, child: Center(child: Text('تفاصيل', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)))),
                                      Expanded(flex: 3, child: Text('التاريخ', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.end)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.grey),
                                Expanded(
                                  child: ListView(
                                    controller: _scrollController,
                                    children: _buildTransactionList(),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );  
  }
}
