import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/features/home/presentation/widgets/category_stats_card.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/screens/account_transactions_screen.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/report_bottom_sheet.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:debit_credit_app/features/home/application/home_report_coordinator.dart';
import 'package:debit_credit_app/features/home/application/home_controller.dart';
import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/events/category_events.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
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
  static const double _categoryItemWidth = 120.0;
  final HomeController _controller = HomeController();
  HomeState _state = HomeState.initial();
  StreamSubscription<CategoryEvent>? _categoryEventSubscription;
  String _localCurrencyName = 'محلي';
  
  // State for category navigation
  int _selectedCategoryIndex = 0;
  late PageController _pageController;
  ScrollController? _categoryScrollController;
  bool _isDrawerOpen = false;
  
  // State for selection mode
  bool _isSelectionMode = false;
  Set<String> _selectedAccountIds = <String>{};

  void _showReportOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateReportForCurrentCategory,
        onAllCategories: _generateReportForAll,
        onEditProfile: () {
          HapticFeedback.lightImpact();
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
    final cat = _state.categories[_selectedCategoryIndex];
    if (cat.name == 'الكل') {
      await _generateReportForAll();
      return;
    }
    final accounts = _state.accountsByCategory[cat.name] ?? [];
    if (accounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا توجد حسابات مرتبطة بالفئة ${cat.name} لإنشاء التقرير'),
          ),
        );
      }
      return;
    }
    await HomeReportCoordinator.generateCategoryReport(category: cat, accounts: accounts);
  }

  Future<void> _generateReportForAll() async {
    final allAccounts = _state.categories
        .where((c) => c.name != 'الكل')
        .expand((c) => _state.accountsByCategory[c.name] ?? [])
        .cast<AccountModel>()
        .toList();
    await HomeReportCoordinator.generateAllAccountsReport(allAccounts: allAccounts);
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _categoryScrollController = ScrollController();
    loadData();
    // Listen for category events
    _categoryEventSubscription = CategoryEventBus().events.listen((event) {
      // Refresh data when categories change
      loadDataPreservingCategory();
    });
  }



  Future<void> loadData() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final defaultCurrency = await DatabaseHelper().getDefaultCurrencyName();
      final newState = await _controller.load().timeout(const Duration(seconds: 10));
      setState(() {
        _state = newState;
        _localCurrencyName = defaultCurrency ?? 'محلي';
      });
    } catch (e) {
      setState(() => _state = _state.copyWith(isLoading: false));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> loadDataPreservingCategory() async {
    // Save current category name to preserve selection
    String? currentCategoryName;
    if (_state.categories.isNotEmpty && _selectedCategoryIndex < _state.categories.length) {
      currentCategoryName = _state.categories[_selectedCategoryIndex].name;
    }
    
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final defaultCurrency = await DatabaseHelper().getDefaultCurrencyName();
      final newState = await _controller.load().timeout(const Duration(seconds: 10));
      
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
        _localCurrencyName = defaultCurrency ?? 'محلي';
      });
      
      // Ensure PageController and CategoryScrollController are synchronized with the selected index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          // Always jump to the selected index to ensure proper synchronization
          _pageController.jumpToPage(_selectedCategoryIndex);
        }
        
        // Scroll category navigation to show selected category
        _animateCategoryScrollToIndex(_selectedCategoryIndex);
      });
    } catch (e) {
      setState(() => _state = _state.copyWith(isLoading: false));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _animateCategoryScrollToIndex(int index) {
    if (_categoryScrollController?.hasClients != true) return;
    final maxScrollExtent = _categoryScrollController!.position.maxScrollExtent;
    final desiredOffset = (index * _categoryItemWidth) - (_categoryItemWidth * 0.5);
    final targetOffset =
        desiredOffset.clamp(0, maxScrollExtent).toDouble();

    _categoryScrollController!.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _categoryScrollController?.dispose();
    _categoryEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToCreateAccount(String category) async {
    final effectiveCategory = category == 'الكل' ? 'عام' : category;
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(accountId: null, category: effectiveCategory),
        ) ??
        false;
    if (result == true) await loadDataPreservingCategory();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpened) {
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
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _selectedAccountIds.isNotEmpty ? _deleteSelectedAccounts : null,
                  tooltip: 'حذف',
                ),
              ],
            )
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إدارة الديون',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.primaryColor),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
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
                  icon: const Icon(Icons.assessment_rounded),
                  onPressed: _showReportOptions,
                  tooltip: 'التقارير',
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: _state.categories.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Horizontal Category Navigation
                _buildCategoryNavigation(),
                // Swipeable Category Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                      _animateCategoryScrollToIndex(index);
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
      floatingActionButton: _state.categories.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _navigateToCreateAccount(_state.categories[_selectedCategoryIndex].name),
              backgroundColor: AppTheme.primaryColor,
              elevation: 2,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
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
      height: 60,
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        clipBehavior: Clip.none,
        itemCount: _state.categories.length,
        itemBuilder: (context, index) {
          final category = _state.categories[index];
          final isSelected = index == _selectedCategoryIndex;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _animateCategoryScrollToIndex(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppTheme.dividerColor.withOpacity(0.8),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppTheme.cardShadow,
              ),
              child: Center(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildCategoryWithStickyHeader(CategoryModel category, List<AccountModel> accounts) {
    final Widget emptyState = Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد حسابات مسجلة في هذه الفئة حالياً',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return CategoryAccountsTab(
      category: category,
      accounts: accounts,
      tileBuilder: _buildAccountTile,
      emptyState: emptyState,
      localCurrencyName: _localCurrencyName,
    );
  }

  Widget _buildAccountTile(AccountModel account) {
    final isSelected = _selectedAccountIds.contains(account.id.toString());
    
    // Map and merge currency stats to treat 'محلي' and _localCurrencyName as equivalent
    final List<AccountCurrencyStats> stats = [];
    final Map<String, AccountCurrencyStats> statsMap = {};
    for (final s in account.currencyStats) {
      final name = (s.currencyName.trim() == 'محلي' || s.currencyName.trim() == _localCurrencyName.trim())
          ? _localCurrencyName.trim()
          : s.currencyName.trim();
      if (statsMap.containsKey(name)) {
        final existing = statsMap[name]!;
        statsMap[name] = AccountCurrencyStats(
          currencyName: name,
          totalDebit: existing.totalDebit + s.totalDebit,
          totalCredit: existing.totalCredit + s.totalCredit,
          transactionCount: existing.transactionCount + s.transactionCount,
        );
      } else {
        statsMap[name] = AccountCurrencyStats(
          currencyName: name,
          totalDebit: s.totalDebit,
          totalCredit: s.totalCredit,
          transactionCount: s.transactionCount,
        );
      }
    }
    stats.addAll(statsMap.values);
    final isMultiCurrency = stats.length > 1;

    double creditVal = 0.0;
    double debitVal = 0.0;

    if (stats.isNotEmpty) {
      for (final s in stats) {
        creditVal += s.totalCredit;
        debitVal += s.totalDebit;
      }
    } else {
      creditVal = account.totalCredit;
      debitVal = account.totalDebit;
    }

    final double totalVal = creditVal + debitVal;
    
    double creditRatio = 0.0;
    double debitRatio = 0.0;
    if (totalVal > 0) {
      creditRatio = creditVal / totalVal;
      debitRatio = debitVal / totalVal;
    }
    
    // Primary side colors
    final Color sideBarColor = creditVal >= debitVal
        ? AppTheme.creditColor
        : AppTheme.debitColor;

    final String displayCurrency;
    if (isMultiCurrency) {
      displayCurrency = 'عملات متعددة';
    } else {
      final rawName = stats.isNotEmpty ? stats.first.currencyName : account.currencyName;
      displayCurrency = rawName == 'محلي' ? _localCurrencyName : rawName;
    }
        
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.4)
              : AppTheme.dividerColor.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          // Colored Left/Right border accent bar
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: sideBarColor,
                width: 5,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_isSelectionMode) {
                  HapticFeedback.lightImpact();
                  _toggleAccountSelection(account.id.toString());
                } else {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AccountTransactionsScreen(account: account),
                    ),
                  ).then((_) => loadDataPreservingCategory());
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                if (!_isSelectionMode) {
                  _enterSelectionMode(account.id.toString());
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer row main info
                      Row(
                        children: [
                          if (_isSelectionMode)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) {
                                    HapticFeedback.lightImpact();
                                    _toggleAccountSelection(account.id.toString());
                                  },
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            
                          // Customer Avatar icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: sideBarColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Customer name
                          Expanded(
                            child: Text(
                              account.name,
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Currency Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMultiCurrency 
                                  ? AppTheme.primaryColor.withOpacity(0.08) 
                                  : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayCurrency,
                              style: TextStyle(
                                color: isMultiCurrency 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Account Balances Section
                      if (!isMultiCurrency) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Credit Balance Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded, color: AppTheme.creditColor, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'ديون لك',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat('#,##0').format(creditVal),
                                    style: const TextStyle(
                                      color: AppTheme.creditColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Divider
                            Container(
                              width: 1,
                              height: 28,
                              color: AppTheme.dividerColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 16),
                            
                            // Debit Balance Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded, color: AppTheme.debitColor, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'ديون عليك',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat('#,##0').format(debitVal),
                                    style: const TextStyle(
                                      color: AppTheme.debitColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Repayment Progress Bar
                        if (totalVal > 0) ...[
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    creditVal >= debitVal ? 'حساب مائل للائتمان' : 'حساب مائل للمديونية',
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    creditVal >= debitVal
                                        ? '${(creditRatio * 100).toStringAsFixed(0)}% لصالحك'
                                        : '${(debitRatio * 100).toStringAsFixed(0)}% مستحقة',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: creditVal >= debitVal ? AppTheme.creditColor : AppTheme.debitColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Micro visual progress indicator
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: creditVal >= debitVal ? creditRatio : debitRatio,
                                    backgroundColor: AppTheme.backgroundColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(sideBarColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        // Multi-currency list
                        ...stats.map((s) {
                          final String statCurrencyName = s.currencyName == 'محلي' ? _localCurrencyName : s.currencyName;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                // Currency Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statCurrencyName,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Credit (له)
                                // Credit (ديون لك)
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, color: AppTheme.creditColor, size: 10),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'ديون لك: ',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        NumberFormat('#,##0').format(s.totalCredit),
                                        style: const TextStyle(
                                          color: AppTheme.creditColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: AppTheme.dividerColor.withOpacity(0.5),
                                ),
                                // Debit (ديون عليك)
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, color: AppTheme.debitColor, size: 10),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'ديون عليك: ',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        NumberFormat('#,##0').format(s.totalDebit),
                                        style: const TextStyle(
                                          color: AppTheme.debitColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



}

class CategoryAccountsTab extends StatefulWidget {
  final CategoryModel category;
  final List<AccountModel> accounts;
  final Widget Function(AccountModel) tileBuilder;
  final Widget emptyState;
  final String localCurrencyName;

  const CategoryAccountsTab({
    super.key,
    required this.category,
    required this.accounts,
    required this.tileBuilder,
    required this.emptyState,
    required this.localCurrencyName,
  });

  @override
  State<CategoryAccountsTab> createState() => _CategoryAccountsTabState();
}

class _CategoryAccountsTabState extends State<CategoryAccountsTab> {
  late ScrollController _scrollController;
  bool _isSnapping = false;

  // Local filter states
  String _sortBy = 'last_transaction'; // 'last_transaction', 'name', 'credit_desc', 'debit_desc', 'recent'
  String _filterBy = 'all'; // 'all', 'credit_only', 'debit_only'
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _maxScrollDistance {
    if (widget.accounts.isEmpty) return 0.0;
    
    final Map<String, List<AccountModel>> currencyGroups = {};
    for (var account in widget.accounts) {
      final String mappedName = (account.currencyName.trim() == 'محلي' && widget.localCurrencyName.trim().isNotEmpty)
          ? widget.localCurrencyName.trim()
          : account.currencyName.trim();
      currencyGroups.putIfAbsent(mappedName, () => []).add(account);
    }

    String primaryCurrency = currencyGroups.keys.first;
    int maxCount = 0;
    currencyGroups.forEach((currency, list) {
      if (list.length > maxCount) {
        maxCount = list.length;
        primaryCurrency = currency;
      }
    });

    bool hasOtherCurrenciesWithBalances = false;
    currencyGroups.forEach((currency, list) {
      if (currency != primaryCurrency) {
        double cred = 0;
        double deb = 0;
        for (var a in list) {
          cred += a.totalCredit;
          deb += a.totalDebit;
        }
        if (cred > 0 || deb > 0) {
          hasOtherCurrenciesWithBalances = true;
        }
      }
    });

    final bool isSmall = MediaQuery.of(context).size.width < 360;
    final double cardHeight = hasOtherCurrenciesWithBalances
        ? (isSmall ? 310.0 : 340.0)
        : (isSmall ? 210.0 : 240.0);
        
    final double collapsedHeight = isSmall ? 56.0 : 64.0;
    
    return cardHeight - collapsedHeight;
  }

  /// Snaps the card to fully open (offset=0) or fully closed (offset=maxScroll)
  /// after the user lifts their finger, so it never stays mid-animation.
  void _snapCard() {
    if (!_scrollController.hasClients) return;
    if (_isSnapping) return;
    final double maxScroll = _maxScrollDistance;
    if (maxScroll <= 0.0) return;

    final double offset = _scrollController.offset;
    
    // Clamp the max scroll distance to the maximum scrollable extent of the list
    // to prevent infinite loops if the list is too short to scroll to maxScroll.
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double effectiveMaxScroll = maxScroll.clamp(0.0, maxScrollExtent);
    
    if (effectiveMaxScroll <= 0.0) return;
    if (offset <= 0.0 || offset >= effectiveMaxScroll) return;

    final double targetOffset = offset >= (effectiveMaxScroll / 2) ? effectiveMaxScroll : 0.0;
    
    // Avoid triggering animation if already extremely close to targetOffset
    if ((offset - targetOffset).abs() < 0.1) return;

    _isSnapping = true;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      _isSnapping = false;
    }).catchError((_) {
      _isSnapping = false;
    });
  }

  List<AccountModel> get _processedAccounts {
    List<AccountModel> list = List.from(widget.accounts);
    
    // 1. Filter by Status
    if (_filterBy == 'credit_only') {
      list = list.where((a) => a.totalCredit > a.totalDebit).toList();
    } else if (_filterBy == 'debit_only') {
      list = list.where((a) => a.totalDebit > a.totalCredit).toList();
    }
    
    // 2. Filter by Date
    final DateTime now = DateTime.now();
    if (_dateFilter == 'today') {
      list = list.where((a) {
        return a.createdDate.year == now.year &&
            a.createdDate.month == now.month &&
            a.createdDate.day == now.day;
      }).toList();
    } else if (_dateFilter == 'week') {
      final DateTime weekAgo = now.subtract(const Duration(days: 7));
      list = list.where((a) => a.createdDate.isAfter(weekAgo)).toList();
    } else if (_dateFilter == 'month') {
      final DateTime monthAgo = now.subtract(const Duration(days: 30));
      list = list.where((a) => a.createdDate.isAfter(monthAgo)).toList();
    } else if (_dateFilter == 'custom' && _customStartDate != null && _customEndDate != null) {
      list = list.where((a) {
        final DateTime start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        final DateTime end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
        return a.createdDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            a.createdDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }
    
    // 3. Sort
    if (_sortBy == 'name') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'credit_desc') {
      list.sort((a, b) => b.totalCredit.compareTo(a.totalCredit));
    } else if (_sortBy == 'debit_desc') {
      list.sort((a, b) => b.totalDebit.compareTo(a.totalDebit));
    } else if (_sortBy == 'recent') {
      list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } else if (_sortBy == 'last_transaction') {
      list.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));
    }
    
    return list;
  }

  Widget _buildSortChip({
    required StateSetter setModalState,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          setModalState(() {
            _sortBy = value;
          });
          setState(() {
            _sortBy = value;
          });
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.5),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDatePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      child: Localizations.override(
        context: context,
        locale: const Locale('ar'),
        child: child!,
      ),
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context, StateSetter setModalState) async {
    // If not set, initialize to today for smooth selection
    _customStartDate ??= DateTime.now();
    _customEndDate ??= DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _customStartDate!, end: _customEndDate!),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: AppTheme.primaryColor, // Force AppBar background to be emerald green
              foregroundColor: Colors.white, // Force icons/back buttons to be white
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              actionsIconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppTheme.primaryColor,
              headerForegroundColor: Colors.white,
              rangePickerHeaderBackgroundColor: AppTheme.primaryColor,
              rangePickerHeaderForegroundColor: Colors.white,
              backgroundColor: Colors.white,
              rangeSelectionBackgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              dayForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.textTertiary;
                }
                return AppTheme.textPrimary;
              }),
              headerHeadlineStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headerHelpStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.white70,
              ),
              rangePickerHeaderHeadlineStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              rangePickerHeaderHelpStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.white70,
              ),
              dayStyle: const TextStyle(fontFamily: 'Cairo'),
              weekdayStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
              yearStyle: const TextStyle(fontFamily: 'Cairo'),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Force the 'Save' text button in AppBar to be white
                textStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('ar'),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setModalState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _dateFilter = 'custom';
      });
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _dateFilter = 'custom';
      });
    }
  }

  Widget _buildDateFilterChip({
    required StateSetter setModalState,
    required String label,
    required String value,
  }) {
    final isSelected = _dateFilter == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Center(
        child: Text(label),
      ),
      selected: isSelected,
      onSelected: (selected) async {
        HapticFeedback.selectionClick();
        if (value == 'custom') {
          await _selectCustomDateRange(context, setModalState);
        } else if (selected) {
          setModalState(() {
            _dateFilter = value;
          });
          setState(() {
            _dateFilter = value;
          });
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required StateSetter setModalState,
    required String label,
    required String value,
  }) {
    final isSelected = _filterBy == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Center(
        child: Text(label),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          setModalState(() {
            _filterBy = value;
          });
          setState(() {
            _filterBy = value;
          });
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'تصفية وترتيب القائمة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Sort Options
                            const Text(
                              'الترتيب حسب',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSortChip(
                                  setModalState: setModalState,
                                  label: 'آخر عملية (تلقائي)',
                                  value: 'last_transaction',
                                  icon: Icons.history_rounded,
                                ),
                                _buildSortChip(
                                  setModalState: setModalState,
                                  label: 'الاسم (أبجدياً)',
                                  value: 'name',
                                  icon: Icons.sort_by_alpha_rounded,
                                ),
                                _buildSortChip(
                                  setModalState: setModalState,
                                  label: 'الديون لك (الأعلى)',
                                  value: 'credit_desc',
                                  icon: Icons.trending_up_rounded,
                                ),
                                _buildSortChip(
                                  setModalState: setModalState,
                                  label: 'الديون عليك (الأعلى)',
                                  value: 'debit_desc',
                                  icon: Icons.trending_down_rounded,
                                ),
                                _buildSortChip(
                                  setModalState: setModalState,
                                  label: 'المضافة حديثاً',
                                  value: 'recent',
                                  icon: Icons.schedule_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Section 2: Filter Options
                            const Text(
                              'تصفية حسب الحالة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterChip(
                                    setModalState: setModalState,
                                    label: 'الكل',
                                    value: 'all',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterChip(
                                    setModalState: setModalState,
                                    label: 'ديون لك',
                                    value: 'credit_only',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterChip(
                                    setModalState: setModalState,
                                    label: 'ديون عليك',
                                    value: 'debit_only',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Section 3: Date Filter Options
                            const Text(
                              'تصفية حسب التاريخ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildDateFilterChip(
                                  setModalState: setModalState,
                                  label: 'الكل',
                                  value: 'all',
                                ),
                                _buildDateFilterChip(
                                  setModalState: setModalState,
                                  label: 'اليوم',
                                  value: 'today',
                                ),
                                _buildDateFilterChip(
                                  setModalState: setModalState,
                                  label: 'آخر 7 أيام',
                                  value: 'week',
                                ),
                                _buildDateFilterChip(
                                  setModalState: setModalState,
                                  label: 'آخر 30 يوم',
                                  value: 'month',
                                ),
                                _buildDateFilterChip(
                                  setModalState: setModalState,
                                  label: 'مخصص 📅',
                                  value: 'custom',
                                ),
                              ],
                            ),
                            if (_dateFilter == 'custom') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _customStartDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: _customEndDate ?? DateTime.now().add(const Duration(days: 365)),
                                          locale: const Locale('ar'),
                                          builder: (context, child) => _buildDatePickerTheme(context, child),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _customStartDate = picked;
                                          });
                                          setState(() {
                                            _customStartDate = picked;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _customStartDate != null 
                                                ? AppTheme.primaryColor.withOpacity(0.3) 
                                                : AppTheme.dividerColor.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'من تاريخ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _customStartDate != null ? _formatDate(_customStartDate!) : 'اختر تاريخ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                    color: _customStartDate != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _customEndDate ?? DateTime.now(),
                                          firstDate: _customStartDate ?? DateTime(2020),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                          locale: const Locale('ar'),
                                          builder: (context, child) => _buildDatePickerTheme(context, child),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _customEndDate = picked;
                                          });
                                          setState(() {
                                            _customEndDate = picked;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _customEndDate != null 
                                                ? AppTheme.primaryColor.withOpacity(0.3) 
                                                : AppTheme.dividerColor.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'إلى تاريخ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.event_rounded, size: 14, color: AppTheme.primaryColor),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _customEndDate != null ? _formatDate(_customEndDate!) : 'اختر تاريخ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                    color: _customEndDate != null ? AppTheme.textPrimary : AppTheme.textTertiary,
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
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _selectCustomDateRange(context, setModalState),
                                  icon: const Icon(Icons.date_range_rounded, size: 14),
                                  label: const Text(
                                    'تعديل النطاق بالكامل',
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.06),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تطبيق التصفية',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final processedList = _processedAccounts;
    final bool isOriginalListEmpty = widget.accounts.isEmpty;

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          // Snap the stats card to fully open or fully closed on scroll settle
          _snapCard();
        }
        return false; // let the notification bubble up
      },
      child: CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. SliverPersistentHeader containing CategoryStatsCard
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryStatsHeaderDelegate(
            accounts: widget.accounts,
            isSmall: MediaQuery.of(context).size.width < 360,
            localCurrencyName: widget.localCurrencyName,
          ),
        ),

        // 2. Table Header Label + Filter Button
        if (!isOriginalListEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'قائمة العملاء والحسابات المسجلة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Filter Action Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showFilterBottomSheet(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_sortBy != 'last_transaction' || _filterBy != 'all' || _dateFilter != 'all') 
                              ? AppTheme.primaryColor.withOpacity(0.08) 
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_sortBy != 'last_transaction' || _filterBy != 'all' || _dateFilter != 'all') 
                                ? AppTheme.primaryColor.withOpacity(0.3) 
                                : AppTheme.dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: (_sortBy != 'last_transaction' || _filterBy != 'all' || _dateFilter != 'all') 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'تصفية',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (_sortBy != 'last_transaction' || _filterBy != 'all' || _dateFilter != 'all') 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            if (_sortBy != 'last_transaction' || _filterBy != 'all' || _dateFilter != 'all') ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Accounts list, original empty state, or filtered empty state
        isOriginalListEmpty
            ? SliverToBoxAdapter(child: widget.emptyState)
            : processedList.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_list_off_rounded,
                              size: 48,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد حسابات تطابق خيارات التصفية الحالية',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _sortBy = 'last_transaction';
                                  _filterBy = 'all';
                                  _dateFilter = 'all';
                                  _customStartDate = null;
                                  _customEndDate = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              child: const Text('إعادة تعيين التصفية'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return widget.tileBuilder(processedList[index]);
                        },
                        childCount: processedList.length,
                      ),
                    ),
                  ),
      ],
    ),
  );
}
}

class _CategoryStatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<AccountModel> accounts;
  final bool isSmall;
  final String localCurrencyName;

  _CategoryStatsHeaderDelegate({
    required this.accounts,
    required this.isSmall,
    required this.localCurrencyName,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double maxShrink = maxExtent - minExtent;
    final double progress = maxShrink > 0 ? (shrinkOffset / maxShrink).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: AppTheme.backgroundColor, // Sleek unified backdrop color
      child: Align(
        alignment: Alignment.topCenter,
        child: CategoryStatsCard(
          accounts: accounts,
          shrinkProgress: progress,
          localCurrencyName: localCurrencyName,
        ),
      ),
    );
  }

  @override
  double get maxExtent {
    if (accounts.isEmpty) return 0.0;

    // Group accounts by currency to find primary currency and non-zero other currencies
    final Map<String, List<AccountModel>> currencyGroups = {};
    for (var account in accounts) {
      final String mappedName = (account.currencyName.trim() == 'محلي' && localCurrencyName.trim().isNotEmpty)
          ? localCurrencyName.trim()
          : account.currencyName.trim();
      currencyGroups.putIfAbsent(mappedName, () => []).add(account);
    }

    String primaryCurrency = currencyGroups.keys.first;
    int maxCount = 0;
    currencyGroups.forEach((currency, list) {
      if (list.length > maxCount) {
        maxCount = list.length;
        primaryCurrency = currency;
      }
    });

    bool hasOtherCurrenciesWithBalances = false;
    currencyGroups.forEach((currency, list) {
      if (currency != primaryCurrency) {
        double cred = 0;
        double deb = 0;
        for (var a in list) {
          cred += a.totalCredit;
          deb += a.totalDebit;
        }
        if (cred > 0 || deb > 0) {
          hasOtherCurrenciesWithBalances = true;
        }
      }
    });

    final double cardHeight = hasOtherCurrenciesWithBalances
        ? (isSmall ? 310.0 : 340.0)
        : (isSmall ? 210.0 : 240.0);
    return cardHeight + 16.0;
  }

  @override
  double get minExtent {
    if (accounts.isEmpty) return 0.0;
    final double collapsedHeight = isSmall ? 56.0 : 64.0;
    return collapsedHeight + 16.0;
  }

  @override
  bool shouldRebuild(covariant _CategoryStatsHeaderDelegate oldDelegate) {
    return oldDelegate.accounts != accounts ||
        oldDelegate.isSmall != isSmall ||
        oldDelegate.localCurrencyName != localCurrencyName;
  }
}
