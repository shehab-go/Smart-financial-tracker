import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/features/accounts/presentation/screens/account_transactions_screen.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/report_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/category_accounts_tab.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/accounts_header_row.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/home_selection_app_bar.dart';
import 'package:debit_credit_app/features/home/presentation/widgets/home_default_app_bar.dart';
import 'package:debit_credit_app/features/home/application/home_report_coordinator.dart';
import 'package:debit_credit_app/features/home/application/selection_controller.dart';
import 'package:debit_credit_app/features/home/application/home_controller.dart';
import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SelectionController _selection = SelectionController();
  final HomeController _controller = HomeController();
  HomeState _state = HomeState.initial();

  void _toggleAccountSelect(AccountModel acc) {
    _selection.toggle(acc.id);
    setState(() {});
  }

  void _clearAccountSelect() {
    _selection.clear();
    setState(() {});
  }

  Future<void> _deleteSelectedAccounts() async {
    if (!_selection.isActive) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('سيتم حذف ${_selection.count} حساب ومعاملاته. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _controller.deleteAccounts(_selection.ids);
    _clearAccountSelect();
    await _loadData();
  }

  void _shareSelectedAccounts() {
    if (!_selection.isActive) return;
    final sel = _state.categories
        .expand((cat) => _state.accountsByCategory[cat.name] ?? [])
        .where((a) => _selection.contains(a.id))
        .toList();
    final lines = sel
        .map((a) => '${a.name}: لك ${a.totalCredit.toStringAsFixed(0)} - عليك ${a.totalDebit.toStringAsFixed(0)}')
        .join('\n');
    Share.share(lines, subject: 'حسابات مختارة');
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReportBottomSheet(
        onCurrentCategory: _generateReportForCurrentCategory,
        onAllCategories: _generateReportForAll,
      ),
    );
  }

  Future<void> _generateReportForCurrentCategory() async {
    if (_tabController.index >= _state.categories.length) return;
    final cat = _state.categories[_tabController.index];
    final accounts = _state.accountsByCategory[cat.name] ?? [];
    await HomeReportCoordinator.generateCategoryReport(category: cat, accounts: accounts);
  }

  Future<void> _generateReportForAll() async {
    final allAccounts = _state.categories
        .expand((c) => _state.accountsByCategory[c.name] ?? [])
        .cast<AccountModel>()
        .toList();
    await HomeReportCoordinator.generateAllAccountsReport(allAccounts: allAccounts);
  }

  late TabController _tabController;
  bool get _accSelectionMode => _selection.isActive;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final newState = await _controller.load();
      
      // Preserve current tab index when reloading data
      int currentIndex = 0;
      try {
        if (!_tabController.indexIsChanging) {
          currentIndex = _tabController.index;
        }
        // Dispose old controller
        _tabController.dispose();
      } catch (e) {
        // TabController not initialized yet, use default index 0
      }
      
      _tabController = TabController(length: newState.categories.length, vsync: this);
      
      // Restore tab index if it's still valid
      if (currentIndex < newState.categories.length) {
        _tabController.index = currentIndex;
      }
      
      setState(() => _state = newState);
    } catch (e) {
      setState(() => _state = _state.copyWith(isLoading: false));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _navigateToCreateAccount(String category) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(accountId: null, category: category),
        ) ??
        false;
    if (result == true) await _loadData();
  }



  Widget _buildCategoryTab(CategoryModel category) {
    final accounts = _state.accountsByCategory[category.name] ?? [];
    return CategoryAccountsTab(
      category: category,
      accounts: accounts,
      selectedAccountIds: _selection.ids,
      onTapAccount: (account) => _accSelectionMode
          ? _toggleAccountSelect(account)
          : Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccountTransactionsScreen(account: account),
              ),
            ).then((updatedAccount) {
              if (updatedAccount != null && updatedAccount is AccountModel) {
                // Update the specific account in the state instead of reloading all data
                _loadData();
              }
            }),
      onLongPressAccount: _toggleAccountSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_state.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأموال الشخصية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('لا توجد فئات متاحة')),
      );
    }

    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: _state.categories
          .map((category) => Tab(
                text: category.name,
              ))
          .toList(),
    );

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: _accSelectionMode
          ? HomeSelectionAppBar(
              selectedCount: _selection.count,
              onClearSelection: _clearAccountSelect,
              onSelectAll: () {
                final allIds = _state.categories
                    .expand((c) => _state.accountsByCategory[c.name] ?? [])
                    .map((e) => e.id!)
                    .whereType<int>();
                setState(() => _selection.toggleSelectAll(allIds));
              },
              onDelete: _deleteSelectedAccounts,
              onPrint: () async {
                final selected = _state.categories
                    .expand((cat) => _state.accountsByCategory[cat.name] ?? [])
                    .where((a) => _selection.contains(a.id))
                    .cast<AccountModel>()
                    .toList();
                await HomeReportCoordinator.generateSelectedAccountsReport(selected: selected);
              },
              onShare: _shareSelectedAccounts,
            )
          : HomeDefaultAppBar(
              onShowReportOptions: _showReportOptions,
              tabController: _tabController,
              categories: _state.categories,
              bottom: tabBar,
            ),
      body: Column(
        children: [
          const AccountsHeaderRow(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _state.categories.map((category) => _buildCategoryTab(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (_tabController.index < _state.categories.length) {
              final currentCategory = _state.categories[_tabController.index].name;
              _navigateToCreateAccount(currentCategory);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
