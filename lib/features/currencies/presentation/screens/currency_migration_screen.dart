import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      HapticFeedback.lightImpact();
      FiatCurrency? chosen;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 380, maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
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
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                    // Content
                    Flexible(
                      child: CurrencyPicker(
                        onSelect: (FiatCurrency currency) {
                          HapticFeedback.lightImpact();
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
          displayName =
              chosen!.translations.firstWhere((e) => e.language == typedLocale.language, orElse: () => TranslatedName(typedLocale.language, name: '')).name ?? chosen!.internationalName;
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
        HapticFeedback.vibrate();
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
      await db.applyCurrencyMappings(_selectedNewNames);

      try {
        final Set<String> existingFavorites = await db.getFavoriteCurrencies();
        final Set<String> newNames = _selectedNewNames.values.toSet();
        final Set<String> merged = {...existingFavorites, ...newNames};
        await db.setFavoriteCurrencies(merged);
      } catch (_) {}

      try {
        if (_firstSelectedNewName != null) {
          final String? currentDefault = await db.getDefaultCurrencyName();
          if (currentDefault == null || currentDefault.trim().isEmpty) {
            await db.setDefaultCurrencyName(_firstSelectedNewName!);
          }
        }
      } catch (_) {}
      
      if (mounted) {
        HapticFeedback.mediumImpact();
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
        HapticFeedback.vibrate();
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
                maxHeight: 580,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
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
                                'تحديث العملات القديمة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'الرجاء اختيار عملة عالمية مقابلة لكل عملة سابقة.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: () {
                          final List<String> sortedLegacies =
                              List<String>.from(widget.legacyCurrencies)
                                ..sort((a, b) => a.compareTo(b));

                          return sortedLegacies.map((legacy) {
                            final selected = _selectedNewNames[legacy];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.dividerColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'العملة السابقة: $legacy',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (selected == null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () => _pickCurrency(legacy),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppTheme.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.search_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'اختر عملة جديدة من القائمة العالمية',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.dividerColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'العملة العالمية الجديدة:',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  selected,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
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
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
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
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
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
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                  fontWeight: FontWeight.bold,
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
