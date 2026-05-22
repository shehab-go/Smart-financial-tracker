import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/currencies/presentation/screens/currencies_screen.dart';

class LocalCurrencyPickerDialog extends StatefulWidget {
  final bool showLocalOption;

  const LocalCurrencyPickerDialog({
    super.key,
    this.showLocalOption = true,
  });

  @override
  State<LocalCurrencyPickerDialog> createState() => _LocalCurrencyPickerDialogState();
}

class _LocalCurrencyPickerDialogState extends State<LocalCurrencyPickerDialog> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<CurrencyModel> _allCurrencies = [];
  List<CurrencyModel> _filteredCurrencies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _defaultCurrencyName = 'محلي';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isLoading = true);
    try {
      final defaultName = await _db.getDefaultCurrencyName();
      final resolvedDefaultName = (defaultName != null && defaultName.trim().isNotEmpty) ? defaultName.trim() : 'محلي';

      final currencies = await _db.getCurrencies();
      
      // If we don't want to show 'محلي' (Local) option inside the list itself
      // (e.g. if the caller handles it separately), we can filter it out here.
      // But typically, since it is in the database, we just let it load normally.
      if (!widget.showLocalOption) {
        currencies.removeWhere((c) => c.name == 'محلي');
      }

      // Map 'محلي' to resolvedDefaultName and deduplicate
      final List<CurrencyModel> mappedCurrencies = [];
      final Set<String> seenNames = {};

      for (var c in currencies) {
        final name = c.name.trim();
        final mappedName = name == 'محلي' ? resolvedDefaultName : name;
        if (mappedName.isNotEmpty && !seenNames.contains(mappedName)) {
          seenNames.add(mappedName);
          mappedCurrencies.add(c.copyWith(name: mappedName));
        }
      }

      // Sort favorites or defaults first, or keep database order
      final favorites = await _db.getFavoriteCurrencies();
      // Map favorites list to resolvedDefaultName if they contain 'محلي'
      final mappedFavorites = favorites.map((f) => f == 'محلي' ? resolvedDefaultName : f).toSet();

      mappedCurrencies.sort((a, b) {
        final aFav = mappedFavorites.contains(a.name);
        final bFav = mappedFavorites.contains(b.name);
        if (aFav != bFav) {
          return bFav ? 1 : -1;
        }
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          _defaultCurrencyName = resolvedDefaultName;
          _allCurrencies = mappedCurrencies;
          _isLoading = false;
          _filterCurrencies();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterCurrencies();
    });
  }

  void _filterCurrencies() {
    if (_searchQuery.trim().isEmpty) {
      _filteredCurrencies = List.from(_allCurrencies);
    } else {
      final query = _searchQuery.trim().toLowerCase();
      _filteredCurrencies = _allCurrencies.where((c) {
        return c.name.toLowerCase().contains(query);
      }).toList();
    }
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
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
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
                      borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),

              // Currency List
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _filteredCurrencies.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                            itemCount: _filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = _filteredCurrencies[index];
                              final String symbol = CurrencyModel.symbolFor(currency.name);

                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  currency.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                                trailing: Text(
                                  symbol,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop(currency.name);
                                },
                              );
                            },
                          ),
              ),

              Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),

              // Footer Shortcut Button to Currencies Management
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CurrenciesScreen()),
                      );
                      // Reload when returning
                      _loadCurrencies();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text(
                      'إدارة العملات (إضافة عملة جديدة)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
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

Future<String?> showLocalCurrencyPicker({
  required BuildContext context,
  bool showLocalOption = true,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => LocalCurrencyPickerDialog(
      showLocalOption: showLocalOption,
    ),
  );
}
