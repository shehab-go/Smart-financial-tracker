import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/installment_plan.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/services/installment_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AddInstallmentDialog extends StatefulWidget {
  final InstallmentPlanModel? plan;

  const AddInstallmentDialog({super.key, this.plan});

  @override
  State<AddInstallmentDialog> createState() => _AddInstallmentDialogState();
}

class _AddInstallmentDialogState extends State<AddInstallmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalCountController = TextEditingController();
  final _notesController = TextEditingController();

  final DatabaseHelper _db = DatabaseHelper();
  final InstallmentService _service = InstallmentService();

  String _planType = 'installment';
  String _frequency = 'monthly';
  DateTime _firstDueDate = DateTime.now().add(const Duration(days: 30));
  int _remindDaysBefore = 3;
  String _selectedCurrency = 'محلي';

  List<CurrencyModel> _currencies = [];
  AccountModel? _selectedAccount;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.plan != null) {
      final p = widget.plan!;
      _titleController.text = p.title;
      _planType = p.planType;
      _amountController.text = p.installmentAmount.toStringAsFixed(0);
      _totalCountController.text = p.totalCount?.toString() ?? '';
      _frequency = p.frequency;
      _firstDueDate = p.firstDueDate;
      _remindDaysBefore = p.remindDaysBefore;
      _selectedCurrency = p.currencyName;
      _notesController.text = p.notes ?? '';
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final accounts = await _db.getAccounts();
      final currencies = await _db.getCurrencies();
      if (mounted) {
        setState(() {
          _currencies = currencies;
          if (widget.plan?.accountId != null && accounts.isNotEmpty) {
            _selectedAccount = accounts.firstWhere(
              (a) => a.id == widget.plan!.accountId,
              orElse: () => accounts.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _totalCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final totalCount = int.tryParse(_totalCountController.text.trim());

    final plan = InstallmentPlanModel(
      id: widget.plan?.id,
      title: title,
      planType: _planType,
      accountId: _selectedAccount?.id,
      accountName: _selectedAccount?.name,
      installmentAmount: amount,
      currencyName: _selectedCurrency,
      totalCount: totalCount,
      paidCount: widget.plan?.paidCount ?? 0,
      frequency: _frequency,
      firstDueDate: _firstDueDate,
      nextDueDate: widget.plan?.nextDueDate ?? _firstDueDate,
      remindDaysBefore: _remindDaysBefore,
      status: widget.plan?.status ?? 'active',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdDate: widget.plan?.createdDate ?? DateTime.now(),
    );

    final success = await _service.savePlan(plan);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ القسط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCurrencies = ['محلي', ..._currencies.map((c) => c.name)].toSet().toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.plan != null ? 'تعديل الالتزام المجدول' : 'إضافة قسط / التزام مجدول 📅',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Plan Type Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _planType = 'installment'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _planType == 'installment' ? AppTheme.primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'قسط محدد 📱',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _planType == 'installment' ? Colors.white : AppTheme.textSecondary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _planType = 'recurring_bill'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _planType == 'recurring_bill' ? AppTheme.primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'فاتورة مكررة 🏠',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _planType == 'recurring_bill' ? Colors.white : AppTheme.textSecondary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: 'اسم القسط / الفاتورة (مثال: إيجار الشقة)',
                    prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الالتزام' : null,
                ),
                const SizedBox(height: 16),

                // Amount field (full width)
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'مبلغ الدفعة الدورية',
                    prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                // Currency selector (full width, compact)
                DropdownButtonFormField<String>(
                  value: allCurrencies.contains(_selectedCurrency) ? _selectedCurrency : allCurrencies.first,
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    prefixIcon: const Icon(Icons.currency_exchange_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: allCurrencies
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCurrency = v ?? 'محلي'),
                ),
                const SizedBox(height: 16),

                // Frequency & Remind Days
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: InputDecoration(
                          labelText: 'معدل التكرار',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('شهرياً')),
                          DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً')),
                          DropdownMenuItem(value: 'yearly', child: Text('سنوياً')),
                        ],
                        onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _remindDaysBefore,
                        decoration: InputDecoration(
                          labelText: 'التنبيه قبل',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('يوم واحد')),
                          DropdownMenuItem(value: 3, child: Text('3 أيام')),
                          DropdownMenuItem(value: 7, child: Text('أسبوع')),
                        ],
                        onChanged: (v) => setState(() => _remindDaysBefore = v ?? 3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _firstDueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => _firstDueDate = picked);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ استحقاق الدفعة القادمة',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_firstDueDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total count for fixed installments
                if (_planType == 'installment') ...[
                  TextFormField(
                    controller: _totalCountController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'عدد الأقساط الكلي (مثال: 12)',
                      prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optional notes
                TextFormField(
                  controller: _notesController,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.plan != null ? 'تعديل' : 'حفظ الالتزام المجدول',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
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
