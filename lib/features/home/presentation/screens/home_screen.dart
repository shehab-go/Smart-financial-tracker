import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  HomeState _state = HomeState.initial();
  StreamSubscription<CategoryEvent>? _categoryEventSubscription;

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
    if (_state.categories.isEmpty) return;
    final cat = _state.categories.first;
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

  @override
  void initState() {
    super.initState();
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
      final newState = await _controller.load();
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
    if (result == true) await loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'إدارة الأموال الشخصية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_rounded, color: AppTheme.primaryColor),
            onPressed: _showReportOptions,
          ),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section
                  ..._state.categories.map((category) => Column(
                    children: [
                      _buildCategoryCard(category),
                      const SizedBox(height: 16),
                    ],
                  )).toList(),
                ],
              ),
            ),
      floatingActionButton: _state.categories.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddAccountDialog(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'قم بإنشاء فئات لبدء إدارة حساباتك',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryCard(CategoryModel category) {
    final accounts = _state.accountsByCategory[category.name] ?? [];
    
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                  onPressed: () => _navigateToCreateAccount(category.name),
                ),
              ],
            ),
          ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        account.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            'لك: ${NumberFormat('#,##0').format(account.totalCredit)}',
            style: const TextStyle(
              color: AppTheme.creditColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'عليك: ${NumberFormat('#,##0').format(account.totalDebit)}',
            style: const TextStyle(
              color: AppTheme.debitColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textTertiary,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AccountTransactionsScreen(account: account),
        ),
      ).then((_) => loadData()),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showAddAccountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر الفئة لإضافة حساب جديد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ..._state.categories.map((category) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(category.name),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreateAccount(category.name);
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _categoryEventSubscription?.cancel();
    super.dispose();
  }
}
