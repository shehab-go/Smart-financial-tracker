import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/screens/account_transactions_screen.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/report_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/home/application/home_report_coordinator.dart';
import 'package:debit_credit_app/features/home/application/home_controller.dart';
import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/events/category_events.dart';
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
  
  // State for category navigation
  int _selectedCategoryIndex = 0;
  late PageController _pageController;
  ScrollController? _categoryScrollController;
  bool _isDrawerOpen = false;
  
  // State for selection mode
  bool _isSelectionMode = false;
  Set<String> _selectedAccountIds = <String>{};

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateReportForCurrentCategory,
        onAllCategories: _generateReportForAll,
        onEditProfile: () {},
      ),
    );
  }

  Future<void> _generateReportForCurrentCategory() async {
    if (_state.categories.isEmpty) return;
    final cat = _state.categories[_selectedCategoryIndex];
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
      loadData();
    });
  }



  Future<void> loadData() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final newState = await _controller.load().timeout(const Duration(seconds: 10));
      setState(() => _state = newState);
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
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(accountId: null, category: category),
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
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _selectedAccountIds.isNotEmpty ? _deleteSelectedAccounts : null,
                  tooltip: 'حذف',
                ),
              ],
            )
          : AppBar(
              title: const Text(
                'الديون',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: null, // Explicitly remove any leading widget
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
                  icon: const Icon(Icons.assessment_rounded, color: AppTheme.primaryColor),
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
               _animateCategoryScrollToIndex(index);
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

  Widget _buildCategoryWithStickyHeader(CategoryModel category, List<AccountModel> accounts) {
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
                       // Currency Header
                       const Expanded(
                         flex: 2,
                         child: Align(
                           alignment: Alignment.centerLeft,
                           child: Text(
                             'العملة',
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
          // Accounts list - Scrollable
          Expanded(
            child: accounts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
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
                      ...accounts.map((account) => _buildAccountTile(account)).toList(),
                      const SizedBox(height: 16),
                    ],
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
                        // Currency Header
                        const Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'العملة',
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AccountTransactionsScreen(account: account),
            ),
          ).then((_) => loadDataPreservingCategory());
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
               // Currency Column (moved to end)
               Expanded(
                 flex: 1,
                 child: Center(
                   child: Text(
                     account.currencyName,
                     style: const TextStyle(
                       color: AppTheme.textSecondary,
                       fontSize: 14,
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     textAlign: TextAlign.center,
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
