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
  String? _firstSelectedNewName;

  bool get _canSave =>
      !_isSaving && _selectedNewNames.length == widget.legacyCurrencies.length;

  Future<void> _pickCurrency(String legacyName) async {
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
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                              color:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'اختيار العملة',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
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
                    const Divider(
                      height: 1,
                      color: AppTheme.dividerColor,
                    ),
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
          _firstSelectedNewName ??= displayName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار العملة: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final db = DatabaseHelper();

      // Apply the actual DB updates for legacy -> new currency names
      await db.applyCurrencyMappings(_selectedNewNames);

      // 1) Mark all newly selected currencies as favorites
      try {
        final Set<String> existingFavorites = await db.getFavoriteCurrencies();
        final Set<String> newNames = _selectedNewNames.values.toSet();
        final Set<String> merged = {...existingFavorites, ...newNames};
        await db.setFavoriteCurrencies(merged);
      } catch (_) {
        // In case of any issue with favorites, don't block migration.
      }

      // 2) If no default currency is set yet, use the first selected one
      try {
        if (_firstSelectedNewName != null) {
          final String? currentDefault = await db.getDefaultCurrencyName();
          if (currentDefault == null || currentDefault.trim().isEmpty) {
            await db.setDefaultCurrencyName(_firstSelectedNewName!);
          }
        }
      } catch (_) {
        // Also non-critical; migration itself already succeeded.
      }
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
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(
                maxWidth: 380,
                maxHeight: 560,
              ),
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
                  // Header (matches dialog style)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
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
                            Icons.currency_exchange_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: () {
                          // Sort legacy currencies alphabetically for display
                          final List<String> sortedLegacies =
                              List<String>.from(widget.legacyCurrencies)
                                ..sort((a, b) => a.compareTo(b));

                          return sortedLegacies.map((legacy) {
                            final selected = _selectedNewNames[legacy];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade300),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                      ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'العملة الجديدة:',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                selected,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              _pickCurrency(legacy),
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
                          }).toList();
                        }(),
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
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canSave && !_isSaving ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
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
        ),
      ),
    );
  }
}
