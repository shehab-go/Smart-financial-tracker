import 'package:flutter/material.dart';
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
        final common = c.maybeCommonNameFor(typedLocale);
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
      appBar: AppBar(
        title: Text(
          'إدارة العملات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: AppTheme.primaryColor,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
              (route) => false,
            );
            // Open drawer after navigation
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
            icon: const Icon(Icons.refresh),
            color: AppTheme.primaryColor,
            onPressed: _loadCurrencies,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.monetization_on,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'إدارة العملات المستخدمة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يمكنك إضافة وتعديل وحذف العملات وتحديد العملة الافتراضية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _currencies.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.monetization_on_outlined,
                                    size: 64,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد عملات مسجلة حالياً',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'تتم إدارة العملات تلقائياً من خلال استخدامك للحسابات والأرصدة والمعاملات.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _currencies.length,
                          itemBuilder: (context, index) {
                            final currency = _currencies[index];
                            final usage = _usageByName[currency.name];
                            final int accountsCount = usage?['accounts'] ?? 0;
                            final int balancesCount = usage?['balances'] ?? 0;
                            final int expensesCount = usage?['expenses'] ?? 0;
                            final bool isFavorite =
                                _favoriteCurrencyNames.contains(currency.name);
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
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      currency.name
                                          .substring(0, currency.name.length >= 2 ? 2 : 1)
                                          .toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  currency.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                subtitle: ((usage == null || totalUsage == 0) &&
                                        code == null)
                                    ? null
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (usage != null &&
                                              totalUsage > 0)
                                            Text(
                                              'الحسابات: $accountsCount • الأرصدة: $balancesCount • المصروفات: $expensesCount',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                            ),
                                          if (code != null)
                                            Text(
                                              symbol != null
                                                  ? 'الكود: $code • الرمز: $symbol'
                                                  : 'الكود: $code',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                            ),
                                        ],
                                      ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: isFavorite
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade500,
                                    size: 20,
                                  ),
                                  tooltip: isFavorite
                                      ? 'إزالة من المفضلة'
                                      : 'إضافة للمفضلة',
                                  onPressed: () => _toggleFavorite(currency),
                                ),
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
                              onPressed: () => Navigator.of(dialogContext).pop(),
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
            displayName =
                chosen!.maybeCommonNameFor(typedLocale) ?? chosen!.internationalName;
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing ? 'تعديل العملة' : 'إضافة عملة جديدة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        readOnly: true,
                        onTap: pickCurrency,
                        decoration: InputDecoration(
                          labelText: 'اسم العملة',
                          hintText: 'العملة',
                          prefixIcon: const Icon(Icons.translate),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'يرجى اختيار اسم العملة'
                            : null,
                      ),

                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
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
                                        SnackBar(content: Text(isEditing ? 'تم تعديل العملة بنجاح' : 'تم إضافة العملة بنجاح'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('حذف العملة'),
        content: Text('هل أنت متأكد من حذف عملة "${currency.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            ),
            onPressed: () async {
              try {
                await DatabaseHelper().deleteCurrency(currency.id!);
                Navigator.pop(context);
                _loadCurrencies();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف العملة بنجاح'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  String errorMessage = e.toString();
                  // Clean up the error message if it contains 'Exception: '
                  if (errorMessage.startsWith('Exception: ')) {
                    errorMessage = errorMessage.substring(11);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
