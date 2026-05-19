import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:world_countries/world_countries.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_navigation.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  List<CurrencyModel> _currencies = [];
  bool _isLoading = true;
  Map<String, Map<String, int>> _usageByName = <String, Map<String, int>>{};
  Set<String> _favoriteCurrencyNames = {};
  Iterable<FiatCurrency>? _allFiatCurrencies;
  String? _defaultCurrencyName;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Iterable<FiatCurrency> _getAllFiatCurrencies() {
    if (_allFiatCurrencies != null) {
      return _allFiatCurrencies!;
    }
    // Use CurrencyPickerExtension.currencies to get the full list once.
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

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      final currencies = await db.getCurrencies();
      final usage = await db.getCurrencyUsageCountsByName();
      final favorites = await db.getFavoriteCurrencies();
      final defaultName = await db.getDefaultCurrencyName();

      // Sort: favorites first, then by total usage (accounts+balances+expenses)
      // descending, then by display name alphabetically.
      final sorted = [...currencies];
      sorted.sort((a, b) {
        final bool aFav = favorites.contains(a.name);
        final bool bFav = favorites.contains(b.name);
        if (aFav != bFav) {
          return bFav ? 1 : -1; // favorites first
        }

        final ua = usage[a.name];
        final ub = usage[b.name];
        final int aTotal =
            (ua?['accounts'] ?? 0) + (ua?['balances'] ?? 0) + (ua?['expenses'] ?? 0);
        final int bTotal =
            (ub?['accounts'] ?? 0) + (ub?['balances'] ?? 0) + (ub?['expenses'] ?? 0);
        if (aTotal != bTotal) {
          return bTotal.compareTo(aTotal); // higher usage first
        }

        return a.name.compareTo(b.name);
      });

      setState(() {
        _currencies = sorted;
        _usageByName = usage;
        _favoriteCurrencyNames = favorites;
        _defaultCurrencyName = defaultName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل العملات: $e'), backgroundColor: Colors.red),
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
        appBar: AppBar(
          title: const Text(
            'إدارة العملات',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.primaryColor,
            iconSize: 20,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigation()),
                (route) => false,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final scaffoldState = Scaffold.of(context);
                if (scaffoldState.hasEndDrawer) {
                  scaffoldState.openEndDrawer();
                }
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: AppTheme.primaryColor,
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadCurrencies();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _addCurrency();
          },
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          tooltip: 'إضافة عملة جديدة',
          child: const Icon(
            Icons.add_rounded,
            size: 24,
          ),
        ),
        body: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.monetization_on_rounded,
                              size: 32,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إدارة العملات المستخدمة',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تحديد العملة الافتراضية والعملات المفضلة التي تستخدمها في حساباتك',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _currencies.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(32),
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
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.monetization_on_outlined,
                                        size: 48,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'لا توجد عملات مسجلة حالياً',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'تتم إدارة العملات تلقائياً من خلال استخدامك للحسابات والأرصدة والمعاملات.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 88),
                              itemCount: _currencies.length,
                              itemBuilder: (context, index) {
                                final currency = _currencies[index];
                                final usage = _usageByName[currency.name];
                                final int accountsCount = usage?['accounts'] ?? 0;
                                final int balancesCount = usage?['balances'] ?? 0;
                                final int expensesCount = usage?['expenses'] ?? 0;
                                final bool isFavorite =
                                    _favoriteCurrencyNames.contains(currency.name);
                                final bool isDefault =
                                    _defaultCurrencyName == currency.name;
                                final int totalUsage =
                                    accountsCount + balancesCount + expensesCount;

                                final fiat = _findFiatByDisplayName(currency.name);
                                final String? code = fiat?.code;
                                String? symbol;
                                if (fiat != null) {
                                  if (fiat.disambiguateSymbol != null &&
                                      fiat.disambiguateSymbol!.isNotEmpty) {
                                    symbol = fiat.disambiguateSymbol;
                                  } else if (fiat.alternateSymbols != null &&
                                      fiat.alternateSymbols!.isNotEmpty) {
                                    symbol = fiat.alternateSymbols!.first;
                                  }
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppTheme.cardShadow,
                                    border: Border.all(
                                      color: isDefault
                                          ? AppTheme.primaryColor.withOpacity(0.7)
                                          : AppTheme.dividerColor.withOpacity(0.5),
                                      width: isDefault ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          currency.name
                                              .substring(0, currency.name.length >= 2 ? 2 : 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      currency.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    subtitle: ((usage == null || totalUsage == 0) &&
                                            code == null)
                                        ? null
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (usage != null && totalUsage > 0)
                                                  Text(
                                                    'الحسابات: $accountsCount • الأرصدة: $balancesCount • المصروفات: $expensesCount',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                if (code != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Text(
                                                      symbol != null
                                                          ? 'الكود: $code • الرمز: $symbol'
                                                          : 'الكود: $code',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isDefault)
                                          const Padding(
                                            padding: EdgeInsetsDirectional.only(end: 8),
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: isFavorite
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade400,
                                            size: 24,
                                          ),
                                          tooltip: isFavorite
                                              ? 'إزالة من المفضلة'
                                              : 'إضافة للمفضلة',
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _toggleFavorite(currency);
                                          },
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color: AppTheme.textSecondary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          onSelected: (value) {
                                            HapticFeedback.mediumImpact();
                                            if (value == 'default') {
                                              _setDefaultCurrency(currency);
                                            } else if (value == 'delete') {
                                              _deleteCurrency(currency);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (!isDefault)
                                              const PopupMenuItem<String>(
                                                value: 'default',
                                                child: Text('تعيين كافتراضية'),
                                              ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text(
                                                'حذف العملة',
                                                style: TextStyle(color: AppTheme.errorColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _setDefaultCurrency(currency);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _setDefaultCurrency(CurrencyModel currency) async {
    _defaultCurrencyName = currency.name;
    setState(() {});
    await DatabaseHelper().setDefaultCurrencyName(currency.name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعيين "${currency.name}" كعملة افتراضية'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(CurrencyModel currency) async {
    final String name = currency.name;
    final updated = Set<String>.from(_favoriteCurrencyNames);
    if (updated.contains(name)) {
      updated.remove(name);
    } else {
      updated.add(name);
    }

    setState(() {
      _favoriteCurrencyNames = updated;
    });

    await DatabaseHelper().setFavoriteCurrencies(updated);
  }

  void _addCurrency() => _showCurrencyDialog();
  void _editCurrency(CurrencyModel currency) => _showCurrencyDialog(currency: currency);

  void _showCurrencyDialog({CurrencyModel? currency}) {
    final isEditing = currency != null;
    final nameController = TextEditingController(text: currency?.name ?? '');
    final formKey = GlobalKey<FormState>();

    Future<void> pickCurrency() async {
      try {
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
                  constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                color: AppTheme.primaryColor.withOpacity(0.1),
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
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.dividerColor),
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
            displayName = chosen!.translations
                    .firstWhere(
                      (e) => e.language == typedLocale.language,
                      orElse: () => TranslatedName(typedLocale.language, name: ''),
                    )
                    .name ??
                chosen!.internationalName;
          } else {
            displayName = chosen!.internationalName;
          }
          nameController.text = displayName;
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing ? 'تعديل العملة' : 'إضافة عملة جديدة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        readOnly: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          pickCurrency();
                        },
                        decoration: InputDecoration(
                          labelText: 'اسم العملة',
                          hintText: 'العملة',
                          prefixIcon: const Icon(Icons.translate_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'يرجى اختيار اسم العملة'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                if (formKey.currentState!.validate()) {
                                  try {
                                    final newCurrency = CurrencyModel(
                                      id: currency?.id,
                                      name: nameController.text.trim(),
                                    );
                                    if (isEditing) {
                                      await DatabaseHelper().updateCurrency(newCurrency);
                                    } else {
                                      await DatabaseHelper().insertCurrency(newCurrency);
                                    }
                                    Navigator.pop(context);
                                    _loadCurrencies();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing
                                              ? 'تم تعديل العملة بنجاح'
                                              : 'تم إضافة العملة بنجاح'),
                                          backgroundColor: AppTheme.successColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('خطأ: $e'),
                                          backgroundColor: AppTheme.errorColor,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(isEditing ? 'تعديل' : 'إضافة'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteCurrency(CurrencyModel currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'حذف العملة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text('هل أنت متأكد من حذف عملة "${currency.name}"؟'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              HapticFeedback.vibrate();
              try {
                await DatabaseHelper().deleteCurrency(currency.id!);
                Navigator.pop(context);
                _loadCurrencies();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف العملة بنجاح'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  String errorMessage = e.toString();
                  if (errorMessage.startsWith('Exception: ')) {
                    errorMessage = errorMessage.substring(11);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
