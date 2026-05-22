import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
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
  String? _defaultCurrencyName;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
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

                                final String? code = CurrencyModel.codeFor(currency.name);
                                final String? symbol = CurrencyModel.symbolFor(currency.name) != currency.name
                                    ? CurrencyModel.symbolFor(currency.name)
                                    : null;

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

  Future<void> _addCurrency() async {
    final existingNames = _currencies.map((c) => c.name).toList();
    final PredefinedCurrency? chosen = await showDialog<PredefinedCurrency>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PredefinedCurrencyPickerDialog(
        existingNames: existingNames,
      ),
    );

    if (chosen != null && mounted) {
      try {
        final newCurrency = CurrencyModel(
          name: chosen.name,
        );
        await DatabaseHelper().insertCurrency(newCurrency);
        _loadCurrencies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة العملة "${chosen.name}" بنجاح'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إضافة العملة: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
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

class _PredefinedCurrencyPickerDialog extends StatefulWidget {
  final List<String> existingNames;

  const _PredefinedCurrencyPickerDialog({
    required this.existingNames,
  });

  @override
  State<_PredefinedCurrencyPickerDialog> createState() =>
      _PredefinedCurrencyPickerDialogState();
}

class _PredefinedCurrencyPickerDialogState
    extends State<_PredefinedCurrencyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PredefinedCurrency> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = predefinedCurrencies;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = _searchController.text;
      if (query.isEmpty) {
        _filtered = predefinedCurrencies;
      } else {
        _filtered = predefinedCurrencies.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'إضافة عملة جديدة',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
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
              Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),

              // Search Input
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                  decoration: InputDecoration(
                    hintText: 'البحث عن عملة...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.dividerColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              // Predefined Currencies List
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.money_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد عملات مطابقة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          final bool isAdded = widget.existingNames.contains(c.name);

                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? AppTheme.successColor.withOpacity(0.08)
                                    : AppTheme.primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  c.symbol,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isAdded
                                        ? AppTheme.successColor
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isAdded
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                            subtitle: Text(
                              c.code,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: isAdded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'مضافة',
                                      style: TextStyle(
                                        color: AppTheme.successColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isAdded) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('العملة "${c.name}" مضافة بالفعل'),
                                    backgroundColor: AppTheme.warningColor,
                                  ),
                                );
                              } else {
                                Navigator.of(context).pop(c);
                              }
                            },
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
}
