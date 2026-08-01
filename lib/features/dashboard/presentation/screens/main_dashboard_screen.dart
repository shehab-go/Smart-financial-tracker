import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/features/home/application/home_controller.dart';
import 'package:debit_credit_app/features/home/application/debt_insights_engine.dart';
import 'package:debit_credit_app/features/expenses/application/financial_insights_engine.dart';
import 'package:debit_credit_app/features/accounts/presentation/dialogs/add_transaction_dialog.dart';
import 'package:debit_credit_app/features/expenses/presentation/dialogs/add_expense_dialog.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/core/events/financial_events.dart';
import 'package:debit_credit_app/features/expenses/application/expense_controller.dart';
import 'package:debit_credit_app/features/home/presentation/screens/smart_radar_screen.dart';
import 'package:debit_credit_app/features/installments/presentation/screens/installments_screen.dart';
import 'package:debit_credit_app/services/financial_tracker_service.dart';

class MainDashboardScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;
  final VoidCallback? onOpenRadar;

  const MainDashboardScreen({
    super.key,
    this.onDrawerChanged,
    this.onOpenRadar,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final HomeController _homeController = HomeController();
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  StreamSubscription<FinancialEvent>? _financialEventSubscription;

  int _unclassifiedCount = 0;
  List<AccountModel> _allAccounts = [];
  List<ExpenseModel> _allExpenses = [];
  double _totalDebit = 0.0; // ما لك
  double _totalCredit = 0.0; // ما عليك
  double _totalMonthlyExpenses = 0.0; // مصروفات الشهر الحالي
  Map<String, double> _categoryExpensesMap = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    _financialEventSubscription = FinancialEventBus().events.listen((event) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _financialEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      HomeController.clearCache();
      final homeState = await _homeController.load();
      final accountsList = homeState.accountsByCategory['الكل'] ?? [];
      final expensesList = await _db.getExpenses();

      int unclassified = 0;
      try {
        final txs = await FinancialTrackerService.getAllTransactions();
        unclassified = txs.where((tx) => !(tx['isClassified'] == true || tx['isClassified'] == 1)).length;
      } catch (_) {}

      double debitSum = 0.0;   // ما عليك الصافي
      double creditSum = 0.0;  // ما لك الصافي
      for (var acc in accountsList) {
        // صافي كل حساب = ما لك - ما عليك
        final double netForAccount = acc.totalCredit - acc.totalDebit;
        if (netForAccount > 0) {
          creditSum += netForAccount;       // ما لك (لصالحك)
        } else if (netForAccount < 0) {
          debitSum += netForAccount.abs();  // ما عليك
        }
      }

      final now = DateTime.now();
      final currentMonthExpenses = expensesList.where((e) {
        final date = e.createdDate;
        return date.month == now.month && date.year == now.year;
      }).toList();

      double monthlyExpenseSum = 0.0;
      final Map<String, double> catMap = {};
      for (var e in currentMonthExpenses) {
        monthlyExpenseSum += e.amount;
        final cat = e.category.isEmpty ? 'عام' : e.category;
        catMap[cat] = (catMap[cat] ?? 0.0) + e.amount;
      }

      if (mounted) {
        setState(() {
          _unclassifiedCount = unclassified;
          _allAccounts = accountsList;
          _allExpenses = expensesList;
          _totalDebit = debitSum;
          _totalCredit = creditSum;
          _totalMonthlyExpenses = monthlyExpenseSum;
          _categoryExpensesMap = catMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'ar');
    final combinedInsights = [
      ...DebtInsightsEngine.generateInsights(_allAccounts),
      ...FinancialInsightsEngine.generateInsights(_allExpenses),
    ];
    final int totalBadgeCount = _unclassifiedCount + combinedInsights.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'الرئيسية',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.radar_rounded, size: 26, color: AppTheme.primaryColor),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SmartRadarScreen()),
                  );
                },
              ),
              if (totalBadgeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$totalBadgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
        widget.onDrawerChanged?.call(isOpened);
      },
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                children: [
                  // 1. Executive Overview Summary Card
                  _buildExecutiveOverviewCard(currencyFormat),

                  const SizedBox(height: 16),

                  // 3. Quick Action Buttons Bar
                  _buildQuickActionsBar(context),

                  const SizedBox(height: 20),

                  // 4. Monthly Expense Distribution Chart
                  if (_categoryExpensesMap.isNotEmpty) ...[
                    _buildExpensesChartCard(currencyFormat),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildExecutiveOverviewCard(NumberFormat formatter) {
    // صافي المركز المالي = إجمالي ما لك - إجمالي ما عليك
    final double netBalance = _totalCredit - _totalDebit;
    final bool isPositiveNet = netBalance >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'صافي المركز المالي',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositiveNet ? '+' : ''}${formatter.format(netBalance)} ر.ي',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummarySubItem(
                  title: 'إجمالي ما لك (ديون)',
                  amount: '${formatter.format(_totalCredit)} ر.ي',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFF81C784),
                ),
              ),
              Container(height: 30, width: 1, color: Colors.white24),
              Expanded(
                child: _buildSummarySubItem(
                  title: 'إجمالي ما عليك',
                  amount: '${formatter.format(_totalDebit)} ر.ي',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFFE57373),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'مصروفات هذا الشهر:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatter.format(_totalMonthlyExpenses)} ر.ي',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySubItem({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'إضافة دين',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppTheme.primaryColor,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await showDialog(
                      context: context,
                      builder: (context) => const AddTransactionDialog(accountId: null, category: 'عام'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  title: 'إضافة مصروف',
                  icon: Icons.add_shopping_cart_rounded,
                  color: AppTheme.warningColor,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const AddExpenseDialog(),
                    );
                    if (result != null) {
                      final expense = result['expense'] as ExpenseModel;
                      final allocations = result['allocations'] as List<ExpenseAllocationInput>? ?? [];
                      await ExpenseController().addExpense(expense, allocations: allocations);
                      FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.expenseAdded));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  title: 'الأقساط',
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InstallmentsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesChartCard(NumberFormat formatter) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.warningColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      const Color(0xFF805AD5),
      const Color(0xFF319795),
    ];

    int colorIndex = 0;
    final List<PieChartSectionData> sections = [];
    _categoryExpensesMap.forEach((cat, amount) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final double percentage = _totalMonthlyExpenses > 0 ? (amount / _totalMonthlyExpenses) * 100 : 0;
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع المصروفات الشهرية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: _categoryExpensesMap.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '${formatter.format(e.value)} ر.ي',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
