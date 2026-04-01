import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/screens/account_transactions_screen.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/report_bottom_sheet.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/home/application/home_report_coordinator.dart';
import 'package:debit_credit_app/features/home/application/home_controller.dart';
import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/events/category_events.dart';
import 'package:debit_credit_app/core/services/app_update_service.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/categories/presentation/dialogs/category_dialog.dart';
import 'package:world_countries/world_countries.dart';
import 'search_screen.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;
  
  const HomeScreen({super.key, this.onDrawerChanged});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  HomeState _state = HomeState.initial();
  StreamSubscription<CategoryEvent>? _categoryEventSubscription;
  bool _isRefreshing = false;
  List<String> _availableCurrencies = const <String>[];
  
  // State for category navigation
  int _selectedCategoryIndex = 0;
  late PageController _pageController;
  ScrollController? _categoryScrollController;
  bool _isDrawerOpen = false;

  // Filters for accounts view
  String _selectedTypeFilter = 'all'; // all, credit, debit
  String _selectedCurrencyFilter = 'all'; // 'all' or specific currencyName
  String _selectedDateFilter = 'all'; // all, today, this_month, this_year
  
  // State for selection mode
  bool _isSelectionMode = false;
  Set<String> _selectedAccountIds = <String>{};
  Iterable<FiatCurrency>? _allFiatCurrencies;
  final Map<String, String> _currencySymbolCache = <String, String>{};

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

  /// Returns the standard currency symbol for a given display name
  /// using the world_countries FiatCurrency metadata.
  /// Examples: $, ر.س, €, etc. Falls back to ISO code if no symbol.
  String _getCurrencySymbol(String displayName) {
    final name = displayName.trim();
    final cached = _currencySymbolCache[name];
    if (cached != null) return cached;

    if (name.isEmpty || name == 'all') {
      _currencySymbolCache[name] = '';
      return '';
    }
    if (name == 'محلي') {
      _currencySymbolCache[name] = 'م';
      return 'م';
    }

    final fiat = _findFiatByDisplayName(name);
    if (fiat == null) {
      _currencySymbolCache[name] = 'م';
      return 'م';
    }

    // Prefer custom Arabic/local symbols for known currencies.
    switch (fiat.code) {
      case 'SAR':
        _currencySymbolCache[name] = 'ر.س';
        return 'ر.س';
      case 'AED':
        _currencySymbolCache[name] = 'د.إ';
        return 'د.إ';
      case 'EGP':
        _currencySymbolCache[name] = 'ج.م';
        return 'ج.م';
      default:
        break;
    }

    // Try the primary symbol from world_countries first (what the picker shows).
    if (fiat.symbol != null && fiat.symbol!.isNotEmpty) {
      _currencySymbolCache[name] = fiat.symbol!;
      return fiat.symbol!;
    }

    String? symbol;
    if (fiat.disambiguateSymbol != null &&
        fiat.disambiguateSymbol!.isNotEmpty) {
      symbol = fiat.disambiguateSymbol;
    } else if (fiat.alternateSymbols != null &&
        fiat.alternateSymbols!.isNotEmpty) {
      symbol = fiat.alternateSymbols!.first;
    }

    if (symbol != null && symbol.isNotEmpty) {
      _currencySymbolCache[name] = symbol;
      return symbol;
    }
    // Fallback to ISO currency code if no explicit symbol is available.
    _currencySymbolCache[name] = fiat.code;
    return fiat.code;
  }

  Future<void> _showCurrencyFilterMenu(
    BuildContext anchorContext, {
    required List<String> currencies,
  }) async {
    try {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final renderBox = anchorContext.findRenderObject() as RenderBox;

      final rect = renderBox.localToGlobal(Offset.zero, ancestor: overlay) &
          renderBox.size;

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          rect,
          Offset.zero & overlay.size,
        ),
        items: [
          const PopupMenuItem<String>(
            value: 'all',
            child: SizedBox(
              width: 260,
              child: Text(
                'الكل',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...currencies.map(
            (cur) => PopupMenuItem<String>(
              value: cur,
              child: SizedBox(
                width: 260,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cur,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_getCurrencySymbol(cur)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

      if (selected == null || !mounted) return;
      setState(() => _selectedCurrencyFilter = selected);
      await loadDataPreservingCategory(background: true);
    } catch (_) {}
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateReportForCurrentCategory,
        onAllCategories: _generateReportForAll,
        onEditProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateReportForCurrentCategory() async {
    if (_state.categories.isEmpty) return;

    // Use the currently selected category (from dropdown/PageView), with bounds safety
    int safeIndex = _selectedCategoryIndex;
    if (safeIndex >= _state.categories.length) {
      safeIndex = 0;
    }

    final cat = _state.categories[safeIndex];
    final accounts = _state.accountsByCategory[cat.name] ?? [];
    await HomeReportCoordinator.generateCategoryReport(
      category: cat,
      accounts: accounts,
      currencyFilterName: _selectedCurrencyFilter,
    );
  }

  Future<void> _generateReportForAll() async {
    final allAccounts = _state.categories
        .expand((c) => _state.accountsByCategory[c.name] ?? [])
        .cast<AccountModel>()
        .toList();
    await HomeReportCoordinator.generateAllAccountsReport(
      allAccounts: allAccounts,
      currencyFilterName: _selectedCurrencyFilter,
    );
  }

  // Selection mode methods
  void _enterSelectionMode(String accountId) {
    setState(() {
      _isSelectionMode = true;
      _selectedAccountIds.add(accountId);
    });
    print('Entered selection mode. Selected accounts: ${_selectedAccountIds.length}');
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedAccountIds.clear();
    });
  }

  void _toggleAccountSelection(String accountId) {
    setState(() {
      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
        if (_selectedAccountIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAccountIds.add(accountId);
      }
    });
  }

  void _selectAllAccounts() {
    setState(() {
      final currentCategory = _state.categories[_selectedCategoryIndex];
      final accounts = _state.accountsByCategory[currentCategory.name] ?? [];
      _selectedAccountIds.addAll(accounts.map((a) => a.id.toString()));
    });
  }

  Future<void> _deleteSelectedAccounts() async {
    if (_selectedAccountIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${_selectedAccountIds.length} حساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // Convert string IDs to integers
        final accountIds = _selectedAccountIds.map((id) => int.parse(id)).toList();
        await _controller.deleteAccounts(accountIds);
        _exitSelectionMode();
        await loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الحسابات بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف الحسابات: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _generateReportForSelectedAccounts() async {
    if (_selectedAccountIds.isEmpty) return;

    // Resolve selected accounts across all categories by ID
    final selectedIdInts = _selectedAccountIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    final List<AccountModel> selectedAccounts = [];
    _state.accountsByCategory.forEach((_, accounts) {
      for (final account in accounts) {
        if (selectedIdInts.contains(account.id)) {
          selectedAccounts.add(account);
        }
      }
    });

    if (selectedAccounts.isEmpty) return;

    await HomeReportCoordinator.generateSelectedAccountsReport(
      selected: selectedAccounts,
      currencyFilterName: _selectedCurrencyFilter,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _categoryScrollController = ScrollController();

    _state = _controller.state;
    if (_state.categories.isEmpty) {
      loadData(showBlockingLoader: true);
    } else {
      loadDataPreservingCategory(background: true);
    }
    // Listen for category events
    _categoryEventSubscription = CategoryEventBus().events.listen((event) {
      // Refresh data when categories change
      loadDataPreservingCategory(background: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkForUpdateAndPrompt(context);
      }
    });
  }

  Future<void> loadData({bool showBlockingLoader = false}) async {
    final swTotal = Stopwatch()..start();
    if (showBlockingLoader) {
      setState(() => _state = _state.copyWith(isLoading: true));
    } else {
      if (mounted) {
        setState(() => _isRefreshing = true);
      }
    }

    try {
      final swLoad = Stopwatch()..start();
      final newState = await _controller.load(currencyFilter: _selectedCurrencyFilter);
      _debugPerf('HomeScreen.loadData.controller.load', swLoad);
      final swCurrencies = Stopwatch()..start();
      final currencies = await DatabaseHelper().getDistinctTransactionCurrencies();
      _debugPerf('HomeScreen.loadData.getDistinctTransactionCurrencies', swCurrencies);
      if (!mounted) return;
      setState(() {
        _state = newState;
        _availableCurrencies = currencies;
        _isRefreshing = false;
      });
      _debugPerf('HomeScreen.loadData.total', swTotal);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(isLoading: false);
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> loadDataPreservingCategory({bool background = false}) async {
    final swTotal = Stopwatch()..start();
    // Save current category name to preserve selection
    String? currentCategoryName;
    if (_state.categories.isNotEmpty && _selectedCategoryIndex < _state.categories.length) {
      currentCategoryName = _state.categories[_selectedCategoryIndex].name;
    }

    if (background) {
      if (mounted) {
        setState(() => _isRefreshing = true);
      }
    } else {
      setState(() => _state = _state.copyWith(isLoading: true));
    }
    try {
      final swLoad = Stopwatch()..start();
      final newState = await _controller.load(currencyFilter: _selectedCurrencyFilter);
      _debugPerf('HomeScreen.loadDataPreservingCategory.controller.load', swLoad);
      final swCurrencies = Stopwatch()..start();
      final currencies = await DatabaseHelper().getDistinctTransactionCurrencies();
      _debugPerf('HomeScreen.loadDataPreservingCategory.getDistinctTransactionCurrencies', swCurrencies);
      if (!mounted) return;
      
      // Find the new index for the preserved category before updating state
      int newSelectedIndex = 0;
      if (currentCategoryName != null && newState.categories.isNotEmpty) {
        final foundIndex = newState.categories.indexWhere((cat) => cat.name == currentCategoryName);
        if (foundIndex != -1) {
          newSelectedIndex = foundIndex;
        }
      }
      
      setState(() {
        _state = newState;
        _selectedCategoryIndex = newSelectedIndex;
        _availableCurrencies = currencies;
        _isRefreshing = false;
      });
      _debugPerf('HomeScreen.loadDataPreservingCategory.total', swTotal);
      
      // Ensure PageController and CategoryScrollController are synchronized with the selected index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          // Always jump to the selected index to ensure proper synchronization
          _pageController.jumpToPage(_selectedCategoryIndex);
        }
        
        // Scroll category navigation to show selected category
        if (mounted && _categoryScrollController?.hasClients == true && _state.categories.isNotEmpty) {
          final itemWidth = 120.0; // Approximate width of each category item
          final targetOffset = _selectedCategoryIndex * itemWidth;
          final maxScrollExtent = _categoryScrollController!.position.maxScrollExtent;
          final scrollOffset = targetOffset > maxScrollExtent ? maxScrollExtent : targetOffset;
          
          _categoryScrollController!.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(isLoading: false);
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _categoryScrollController?.dispose();
    _categoryEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToCreateAccount(String category) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(accountId: null, category: category),
        ) ??
        false;
    if (result == true) await loadDataPreservingCategory(background: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading && _state.categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      endDrawer: const AppDrawer(),
      onEndDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
        widget.onDrawerChanged?.call(isOpened);
      },
      appBar: _isSelectionMode
          ? AppBar(
              title: Text(
                '${_selectedAccountIds.length} محدد',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  onPressed: _selectAllAccounts,
                  tooltip: 'تحديد الكل',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: _selectedAccountIds.isNotEmpty
                      ? _generateReportForSelectedAccounts
                      : null,
                  tooltip: 'تقرير الحسابات المحددة',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _selectedAccountIds.isNotEmpty ? _deleteSelectedAccounts : null,
                  tooltip: 'حذف',
                ),
              ],
            )
          : AppBar(
              title: const Text(
                'ديون',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: null, // Explicitly remove any leading widget
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_isRefreshing ? 2 : 0),
                child: _isRefreshing
                    ? const LinearProgressIndicator(minHeight: 2)
                    : const SizedBox.shrink(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  tooltip: 'بحث',
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/report_icons/pdf_report.svg',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _showReportOptions,
                ),
                if (!_isDrawerOpen)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppTheme.primaryColor),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
              ],
            ),
      body: _state.categories.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Filters bar (category, type, currency, date)
                _buildFiltersBar(),
                // Swipeable Category Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    itemCount: _state.categories.length,
                    itemBuilder: (context, index) {
                      final category = _state.categories[index];
                      final accounts = _state.accountsByCategory[category.name] ?? [];
                      return _buildCategoryWithStickyHeader(category, accounts);
                    },
                  ),
                ),
              ],
            ),
    );
  }
 
  Widget _buildFiltersBar() {
  final categories = _state.categories;
  if (categories.isEmpty) return const SizedBox.shrink();

  int safeIndex = _selectedCategoryIndex;
  if (safeIndex >= categories.length) safeIndex = 0;
  final selectedCategory = categories[safeIndex];

  final List<String> currencies = _availableCurrencies;

  // Helper to build a consistent minimal decoration
  InputDecoration minimalDecoration() => InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      );

  // Helper for text style to keep it professional and tiny
  const itemTextStyle = TextStyle(fontSize: 14,color: AppTheme.textSecondary,fontWeight: FontWeight.w400);

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(4), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Category with inline "+ add category" option
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedCategory.name,
              icon: const SizedBox.shrink(), // Hides the arrow
              decoration: minimalDecoration(),
              isExpanded: true,
              items: [
                ...categories.map((c) => DropdownMenuItem<String>(
                      value: c.name,
                      child: Text(
                        c.name,
                        style: itemTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                const DropdownMenuItem<String>(
                  value: '__add_new_category__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'فئة جديدة',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value == '__add_new_category__') {
                  final newCategory = await showDialog<CategoryModel>(
                    context: context,
                    builder: (dialogContext) => const CategoryDialog(),
                  );

                  if (newCategory != null) {
                    try {
                      await DatabaseHelper().insertCategory(newCategory);
                      await loadDataPreservingCategory(background: true);
                      if (!mounted) return;
                      final updatedCategories = _state.categories;
                      final newIndex = updatedCategories.indexWhere((c) => c.name == newCategory.name);
                      if (newIndex != -1) {
                        setState(() {
                          _selectedCategoryIndex = newIndex;
                        });
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            newIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في إضافة الفئة: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                  return;
                }

                if (value == null) return;
                final index = categories.indexWhere((c) => c.name == value);
                if (index == -1) return;
                setState(() => _selectedCategoryIndex = index);
                if (_pageController.hasClients) {
                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
            ),
          ),
          const SizedBox(width: 4),

          // 2. Currency
          Expanded(
            child: Builder(
              builder: (anchorContext) {
                final String label = _selectedCurrencyFilter == 'all'
                    ? 'الكل'
                    : '${_selectedCurrencyFilter}  ${_getCurrencySymbol(_selectedCurrencyFilter)}';

                return InkWell(
                  onTap: () => _showCurrencyFilterMenu(
                    anchorContext,
                    currencies: currencies,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: minimalDecoration(),
                    child: Text(
                      label,
                      style: itemTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),

          // 3. Status/Type
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTypeFilter,
              icon: const SizedBox.shrink(),
              decoration: minimalDecoration(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الحالة', style: itemTextStyle)),
                DropdownMenuItem(value: 'credit', child: Text('له', style: itemTextStyle)),
                DropdownMenuItem(value: 'debit', child: Text('عليه', style: itemTextStyle)),
              ],
              onChanged: (value) => setState(() => _selectedTypeFilter = value ?? 'all'),
            ),
          ),
          const SizedBox(width: 4),

          // 4. Date
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDateFilter,
              icon: const SizedBox.shrink(),
              decoration: minimalDecoration(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('التاريخ', style: itemTextStyle)),
                DropdownMenuItem(value: 'today', child: Text('اليوم', style: itemTextStyle)),
                DropdownMenuItem(value: 'this_month', child: Text('الشهر', style: itemTextStyle)),
                DropdownMenuItem(value: 'this_year', child: Text('السنة', style: itemTextStyle)),
              ],
              onChanged: (value) => setState(() => _selectedDateFilter = value ?? 'all'),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد فئات متاحة',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'قم بإنشاء فئات لبدء إدارة حساباتك',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryNavigation() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _state.categories.length,
        itemBuilder: (context, index) {
          final category = _state.categories[index];
          final isSelected = index == _selectedCategoryIndex;
          
          return GestureDetector(
             onTap: () {
               _pageController.animateToPage(
                 index,
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeInOut,
               );
             },
            child: Container(
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                   category.name,
                   style: TextStyle(
                     color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                     fontSize: 14,
                   ),
                 ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCategoryContent() {
    if (_state.categories.isEmpty) return const SizedBox();
    
    // Ensure selected index is within bounds
    if (_selectedCategoryIndex >= _state.categories.length) {
      _selectedCategoryIndex = 0;
    }
    
    final selectedCategory = _state.categories[_selectedCategoryIndex];
    final accounts = _state.accountsByCategory[selectedCategory.name] ?? [];
    
    return _buildCategoryWithStickyHeader(selectedCategory, accounts);
  }
List<AccountModel> _filterAccounts(List<AccountModel> accounts) {
  return accounts.where((account) {
    // 1) Type filter (credit / debit / all)
    // net > 0 => له (credit), net < 0 => عليه (debit)
    final double net = account.totalCredit - account.totalDebit;
    if (_selectedTypeFilter == 'credit' && net <= 0) {
      return false;
    }
    if (_selectedTypeFilter == 'debit' && net >= 0) {
      return false;
    }

    // 2) Date filter based on account.createdDate
    if (_selectedDateFilter != 'all') {
      final DateTime now = DateTime.now();
      final DateTime d = account.createdDate;

      if (_selectedDateFilter == 'today') {
        if (d.year != now.year || d.month != now.month || d.day != now.day) {
          return false;
        }
      } else if (_selectedDateFilter == 'this_month') {
        if (d.year != now.year || d.month != now.month) {
          return false;
        }
      } else if (_selectedDateFilter == 'this_year') {
        if (d.year != now.year) {
          return false;
        }
      }
    }

    return true;
  }).toList();
}
 Widget _buildCategoryWithStickyHeader(
  CategoryModel category,
  List<AccountModel> accounts,
) {
  final swFilter = Stopwatch()..start();
  final filteredAccounts = _filterAccounts(accounts);
  _debugPerf('HomeScreen._filterAccounts(${category.name})', swFilter);

  final List<AccountModel> accountsForFooter = filteredAccounts;

  double netTotal = 0.0;
  for (final account in accountsForFooter) {
    netTotal += (account.totalCredit - account.totalDebit);
  }
  final String netLabel;
  if (netTotal > 0) {
    netLabel = 'لهم';
  } else if (netTotal < 0) {
    netLabel = 'عليهم';
  } else {
    netLabel = 'متوازن';
  }

  final swTiles = Stopwatch()..start();
  final tiles = filteredAccounts.map((account) => _buildAccountTile(account)).toList();
  _debugPerf('HomeScreen.buildAccountTiles(${category.name})', swTiles, thresholdMs: 24);

  return Container(
    margin: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 8),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    // Account Name Header
                    const Expanded(
                      flex: 6,
                      child: Text(
                        'اسم الحساب',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    // Credit Header
                    const Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'له',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // Debit Header
                    const Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'عليه',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
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
        const Divider(height: 1, color: Colors.grey),
        // Accounts list (filtered)
        Expanded(
          child: filteredAccounts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'لا توجد حسابات في هذه الفئة',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...tiles,
                  ],
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
                    onPressed: () => _navigateToCreateAccount(category.name),
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
                      'حساب جديد',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        netLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCurrencyFilter == 'all'
                            ? NumberFormat('#,##0').format(netTotal.abs())
                            : '${NumberFormat('#,##0').format(netTotal.abs())} ${_getCurrencySymbol(_selectedCurrencyFilter)}',
                        style: TextStyle(
                          fontSize: 14,
                          // fontWeight: FontWeight.w500,
                          color: netTotal >= 0
                              ? AppTheme.creditColor
                              : AppTheme.debitColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCategoryCard(CategoryModel category) {
    final accounts = _state.accountsByCategory[category.name] ?? [];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Category Title and Add Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                      onPressed: () => _navigateToCreateAccount(category.name),
                    ),
                  ],
                ),
                // Table Header Section
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        // Account Name Header
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'اسم الحساب',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        // For You Header
                        const Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'له',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        // On You Header
                        const Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'عليه',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (accounts.isNotEmpty) const Divider(height: 1, color: Colors.grey),
          // Content Section
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'لا توجد حسابات في هذه الفئة',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...accounts.map((account) => _buildAccountTile(account)).toList(),
        ],
      ),
    );
  }

  Widget _buildAccountTile(AccountModel account) {
    final isSelected = _selectedAccountIds.contains(account.id.toString());
    
    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleAccountSelection(account.id.toString());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountTransactionsScreen(account: account),
            ),
          ).then((_) => loadDataPreservingCategory(background: true));
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(account.id.toString());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // Selection checkbox (only visible in selection mode)
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleAccountSelection(account.id.toString()),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              // Account Name Column
               Expanded(
                 flex: 3,
                 child: Text(
                   account.name,
                   style: TextStyle(
                     color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                     fontSize: 14,
                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               // For You (Credit) Column
               Expanded(
                 flex: 2,
                 child: Center(
                   child: Text(
                     '${NumberFormat('#,##0').format(account.totalCredit)}',
                     style: const TextStyle(
                       color: AppTheme.creditColor,
                       fontSize: 14,
                     ),
                   ),
                 ),
               ),
               // On You (Debit) Column
               Expanded(
                 flex: 2,
                 child: Center(
                   child: Text(
                     '${NumberFormat('#,##0').format(account.totalDebit)}',
                     style: const TextStyle(
                       color: AppTheme.debitColor,
                       fontSize: 14,
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
