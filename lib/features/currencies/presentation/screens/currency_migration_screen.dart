import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:world_countries/world_countries.dart';

class CurrencyMigrationScreen extends StatefulWidget {
  const CurrencyMigrationScreen({
    super.key,
    required this.legacyCurrencies,
    required this.onCompleted,
  });

  final List<String> legacyCurrencies;
  final VoidCallback onCompleted;

  @override
  State<CurrencyMigrationScreen> createState() => _CurrencyMigrationScreenState();
}

class _CurrencyMigrationScreenState extends State<CurrencyMigrationScreen> {
  final Map<String, String> _selectedNewNames = {};
  bool _isSaving = false;

  bool get _canSave =>
      !_isSaving && _selectedNewNames.length == widget.legacyCurrencies.length;

  Future<void> _pickCurrency(String legacyName) async {
    FiatCurrency? chosen;

    final picker = CurrencyPicker(
      // When user selects a currency, store it locally. The picker
      // handles closing the dialog / sheet itself.
      onSelect: (FiatCurrency currency) {
        chosen = currency;
      },
    );

    await picker.showInDialog(context);

    if (chosen != null && mounted) {
      // Prefer Arabic localized common name when available via TypedLocale,
      // otherwise fall back to the international name.
      final typedLocale = context.maybeLocale;
      String displayName;
      if (typedLocale != null) {
        displayName =
            chosen!.maybeCommonNameFor(typedLocale) ?? chosen!.internationalName;
      } else {
        displayName = chosen!.internationalName;
      }

      setState(() {
        _selectedNewNames[legacyName] = displayName;
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseHelper().applyCurrencyMappings(_selectedNewNames);
      if (mounted) {
        widget.onCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث جميع العملات بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث العملات: $e'),
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                        Icons.currency_exchange_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'تحديث العملات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'رجاءً قم باختيار عملة عالمية مناسبة لكل عملة مستخدمة سابقاً.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.legacyCurrencies.length,
                  itemBuilder: (context, index) {
                    final legacy = widget.legacyCurrencies[index];
                    final selected = _selectedNewNames[legacy];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'العملة القديمة: $legacy',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selected == null)
                            TextButton.icon(
                              onPressed: () => _pickCurrency(legacy),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text(
                                'اختر عملة جديدة من القائمة العالمية',
                                style: TextStyle(fontSize: 13),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'العملة الجديدة:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selected,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _pickCurrency(legacy),
                                  child: const Text(
                                    'تغيير',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'حفظ ومتابعة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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
