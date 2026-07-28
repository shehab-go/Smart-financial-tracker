import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_theme.dart';
import '../../../../services/financial_tracker_service.dart';
import '../../../../core/db/database_helper.dart';
import '../../../../core/models/expense.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/financial_insight_model.dart';
import '../../../accounts/presentation/dialogs/add_transaction_dialog.dart';
import '../../../expenses/presentation/dialogs/add_expense_dialog.dart';
import '../../../expenses/domain/expense_repository.dart';
import '../../../expenses/application/expense_controller.dart';
import '../../../../core/events/financial_events.dart';
import 'package:debit_credit_app/features/home/application/debt_insights_engine.dart';
import '../../../expenses/application/financial_insights_engine.dart';

class SmartRadarScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;

  const SmartRadarScreen({super.key, this.onDrawerChanged});

  @override
  State<SmartRadarScreen> createState() => _SmartRadarScreenState();
}

class _SmartRadarScreenState extends State<SmartRadarScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Set<String> _newTransactionIds = {};
  bool _dialogOpen = false;
  List<Map<String, dynamic>> _transactions = [];
  List<AccountModel> _allAccounts = [];
  List<ExpenseModel> _allExpenses = [];
  bool _isLoading = true;
  StreamSubscription? _txSubscription;
  StreamSubscription<FinancialEvent>? _financialEventSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkPermissionsAndShowDialog();
    _startListeningToTransactions();

    _financialEventSubscription = FinancialEventBus().events.listen((event) {
      _loadData();
    });
  }

  void _startListeningToTransactions() {
    _txSubscription?.cancel();
    _txSubscription = FinancialTrackerService.transactionStream.listen((newTx) {
      if (!mounted) return;
      final String newId = newTx['referenceId']?.toString() ?? newTx['timestamp']?.toString() ?? '';
      if (newId.isEmpty) return;

      final existingIndex = _transactions.indexWhere((t) {
        final tId = t['referenceId']?.toString() ?? t['timestamp']?.toString();
        return tId == newId;
      });

      if (existingIndex == -1) {
        setState(() {
          _transactions.insert(0, newTx);
          _newTransactionIds.add(newId);
          _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txSubscription?.cancel();
    _financialEventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _dialogOpen = false;
      }
      _checkPermissionsAndShowDialog();
    }
  }

  Future<void> _checkPermissionsAndShowDialog() async {
    final isGranted = await FinancialTrackerService.isNotificationPermissionGranted();
    if (mounted) {
      if (!isGranted && !_dialogOpen) {
        _dialogOpen = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('صلاحية مطلوبة', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontWeight: FontWeight.bold)),
                content: const Text(
                  'لكي يتمكن "الراصد" من التقاط العمليات المالية تلقائياً، يجب تفعيل صلاحية "قراءة الإشعارات" (Notification Access) للتطبيق من إعدادات النظام.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', height: 1.5, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _dialogOpen = false;
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    onPressed: () async {
                      await FinancialTrackerService.requestNotificationPermission();
                    },
                    child: const Text('تفعيل الصلاحية', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final txs = await FinancialTrackerService.getAllTransactions();
    final db = DatabaseHelper();
    final accounts = await db.getAccounts();
    final expenses = await db.getExpenses();

    if (mounted) {
      setState(() {
        _transactions = txs;
        _allAccounts = accounts;
        _allExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  List<FinancialInsight> get _insights {
    return [
      ...DebtInsightsEngine.generateInsights(_allAccounts),
      ...FinancialInsightsEngine.generateInsights(_allExpenses),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final insightsList = _insights;
    final unclassifiedList = _transactions.where((tx) {
      return !(tx['isClassified'] == true || tx['isClassified'] == 1);
    }).toList();

    return PopScope(
      canPop: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              'الراصد والذكاء المالي',
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radar_rounded, size: 20),
                      const SizedBox(width: 6),
                      const Text('الراصد الآلي'),
                      if (unclassifiedList.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${unclassifiedList.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 20),
                      const SizedBox(width: 6),
                      const Text('التنبيهات الذكية'),
                      if (insightsList.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${insightsList.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Unclassified Radar Messages
                  _buildRadarTab(unclassifiedList),
                  // Tab 2: Smart Financial Insights
                  _buildInsightsTab(insightsList),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildRadarTab(List<Map<String, dynamic>> unclassifiedList) {
    if (unclassifiedList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد عمليات جديدة غير مصنفة 👍',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيقوم الراصد بالتقاط أي إشعار بنكي أو رسالة جديدة فور وصولها.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: unclassifiedList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = unclassifiedList[index];
          return _buildRadarCard(tx);
        },
      ),
    );
  }

  Widget _buildRadarCard(Map<String, dynamic> tx) {
    final String sender = tx['sender']?.toString() ?? 'إشعار مالي';
    final String body = tx['body']?.toString() ?? tx['rawBody']?.toString() ?? '';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String bankName = tx['bankName']?.toString() ?? sender;
    final int timestamp = (tx['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final String refId = tx['referenceId']?.toString() ?? '$timestamp';
    final String counterpart = tx['counterpart']?.toString() ?? 'غير محدد';
    final String currency = tx['currency']?.toString() ?? 'ر.ي';
    final bool isOutbound = !tx['transactionType'].toString().contains('In');
    final bool isParsed = tx['isParsed'] == true || tx['isParsed'] == 1;

    final String formattedAmountNumber = NumberFormat("#,##0.##", "en").format(amount);
    final String formattedSign = isOutbound ? '-' : '+';
    final Color statusColor = isOutbound ? AppTheme.errorColor : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vertical Status Accent Bar on Right Side (RTL)
              Container(
                width: 5,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Bank Avatar, Counterpart & Subtitle, Amount Block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Right: Bank Avatar Logo
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: bankName.contains('STC')
                                ? const Icon(Icons.account_balance_wallet_rounded, size: 26, color: AppTheme.primaryColor)
                                : Image.asset(
                                    'assets/images/jaeeb.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor, size: 24),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Middle: Name and Direction Tag
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  counterpart.isEmpty ? bankName : counterpart,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isOutbound ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            size: 12,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOutbound ? 'عملية دفع صادرة' : 'استلام أموال',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MM/dd • hh:mm a', 'ar').format(DateTime.fromMillisecondsSinceEpoch(timestamp)),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Left: Amount Container in LTR text direction
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '$formattedSign$formattedAmountNumber',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                              ),
                              Text(
                                currency,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // SMS Content Box
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            body,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                        ),
                      ],

                      // Smart Recommended Category Chips (if parsed)
                      if (isParsed) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _buildDynamicCategoryChips(tx, isOutbound: isOutbound),
                        ),
                      ],

                      const SizedBox(height: 14),
                      // Primary Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text(
                                'تسجيل كـ دين',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final isOutbound = !tx['transactionType'].toString().contains('In');
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AddTransactionDialog(
                                    category: 'عام',
                                    accountId: null,
                                    initialAccountName: counterpart,
                                    initialAmount: amount > 0 ? amount : null,
                                    initialType: isOutbound ? 'debit' : 'credit',
                                    initialDetails: 'تسديد عبر الإشعارات الآلية',
                                  ),
                                );

                                if (result == true) {
                                  await FinancialTrackerService.markAsClassified(refId, isOutbound ? 'سداد دين' : 'استلام دين');
                                  FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionAdded, referenceId: refId));
                                  FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.radarClassified, referenceId: refId));
                                  _loadData();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                              label: const Text(
                                'تسجيل كـ مصروف',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                String suggestedName = counterpart;
                                String suggestedCategory = 'عام';

                                if (counterpart.contains('يمن موبايل') ||
                                    counterpart.contains('يمن نت') ||
                                    counterpart.contains('سبأفون') ||
                                    counterpart.toLowerCase().contains('mtn') ||
                                    counterpart.toLowerCase().contains('you')) {
                                  suggestedName = counterpart.split(' للرقم ').first;
                                  suggestedCategory = 'فاتورة الهاتف';
                                } else if (counterpart.contains('كهرباء') || counterpart.contains('مياه')) {
                                  suggestedName = counterpart;
                                  suggestedCategory = 'فواتير عامة';
                                }

                                final String bankName = tx['packageName']?.toString().contains('stc') == true ? 'STC Pay' : 'محفظة جيب';
                                final balances = await DatabaseHelper().getIncomeBalances();
                                int? matchedBalanceId;
                                try {
                                  matchedBalanceId = balances.firstWhere((b) => b.name.toLowerCase().contains(bankName.contains('STC') ? 'stc' : 'جيب')).id;
                                } catch (_) {}

                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => AddExpenseDialog(
                                    expense: ExpenseModel(
                                      name: suggestedName,
                                      amount: amount,
                                      detail: 'عبر الإشعار الآلي ($counterpart)',
                                      category: suggestedCategory,
                                      currency: tx['currency']?.toString() ?? 'محلي',
                                      createdDate: DateTime.now(),
                                    ),
                                    forceLinkToBalance: true,
                                    defaultBalanceId: matchedBalanceId,
                                  ),
                                );

                                if (result != null) {
                                  final expense = result['expense'] as ExpenseModel;
                                  final allocations = result['allocations'] as List<ExpenseAllocationInput>? ?? [];
                                  await ExpenseController().addExpense(expense, allocations: allocations);
                                  await FinancialTrackerService.markAsClassified(refId, 'مصروفات');
                                  FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.expenseAdded, referenceId: refId));
                                  FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.radarClassified, referenceId: refId));
                                  _loadData();
                                }
                              },
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

  List<Widget> _buildDynamicCategoryChips(Map<String, dynamic> tx, {required bool isOutbound}) {
    if (!isOutbound) {
      return [
        _buildQuickCategoryChip(
          label: 'تسديد دين لي 💰',
          tx: tx,
          isDebt: true,
          isBestSuggestion: true,
        ),
      ];
    }

    final String counterpart = tx['counterpart']?.toString() ?? '';
    final bool isUtility = counterpart.contains('يمن موبايل') ||
        counterpart.contains('يمن نت') ||
        counterpart.contains('سبأفون') ||
        counterpart.toLowerCase().contains('mtn') ||
        counterpart.toLowerCase().contains('you') ||
        counterpart.contains('كهرباء') ||
        counterpart.contains('مياه');

    return [
      if (!isUtility)
        _buildQuickCategoryChip(
          label: 'سداد دين علي 💳',
          tx: tx,
          isDebt: true,
          isBestSuggestion: false,
        ),
      _buildQuickCategoryChip(
        label: 'تسجيل كمصروف 🛒',
        tx: tx,
        isGeneralExpense: true,
        isBestSuggestion: true,
      ),
    ];
  }

  Widget _buildQuickCategoryChip({
    required String label,
    required Map<String, dynamic> tx,
    bool isDebt = false,
    bool isGeneralExpense = false,
    bool isBestSuggestion = false,
  }) {
    final bool isPrimary = isBestSuggestion;
    final bgColor = isPrimary ? AppTheme.primaryColor : Colors.white;
    final textColor = isPrimary ? Colors.white : AppTheme.primaryColor;
    final borderColor = isPrimary ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();

        if (isDebt) {
          final isOutbound = !tx['transactionType'].toString().contains('In');
          final String counterpart = tx['counterpart']?.toString() ?? 'غير محدد';
          final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final String refId = tx['referenceId']?.toString() ?? '';

          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AddTransactionDialog(
              category: 'عام',
              accountId: null,
              initialAccountName: counterpart,
              initialAmount: amount > 0 ? amount : null,
              initialType: isOutbound ? 'debit' : 'credit',
              initialDetails: 'تسديد عبر الإشعارات الآلية',
            ),
          );

          if (result == true) {
            await FinancialTrackerService.markAsClassified(refId, isOutbound ? 'سداد دين' : 'استلام دين');
            FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionAdded, referenceId: refId));
            FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.radarClassified, referenceId: refId));
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تسديد الدين بنجاح!'),
                  backgroundColor: AppTheme.successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        }

        if (isGeneralExpense) {
          final String counterpart = tx['counterpart']?.toString() ?? 'غير محدد';
          final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final String refId = tx['referenceId']?.toString() ?? '';

          String suggestedName = counterpart;
          String suggestedCategory = 'عام';

          if (counterpart.contains('يمن موبايل') ||
              counterpart.contains('يمن نت') ||
              counterpart.contains('سبأفون') ||
              counterpart.toLowerCase().contains('mtn') ||
              counterpart.toLowerCase().contains('you')) {
            suggestedName = counterpart.split(' للرقم ').first;
            suggestedCategory = 'فاتورة الهاتف';
          } else if (counterpart.contains('كهرباء') || counterpart.contains('مياه')) {
            suggestedName = counterpart;
            suggestedCategory = 'فواتير عامة';
          }

          final String bankName = tx['packageName']?.toString().contains('stc') == true ? 'STC Pay' : 'محفظة جيب';
          final balances = await DatabaseHelper().getIncomeBalances();
          int? matchedBalanceId;
          try {
            matchedBalanceId = balances.firstWhere((b) => b.name.toLowerCase().contains(bankName.contains('STC') ? 'stc' : 'جيب')).id;
          } catch (_) {}

          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: true,
            builder: (context) => AddExpenseDialog(
              expense: ExpenseModel(
                name: suggestedName,
                amount: amount,
                detail: 'عبر الإشعار الآلي ($counterpart)',
                category: suggestedCategory,
                currency: tx['currency']?.toString() ?? 'محلي',
                createdDate: DateTime.now(),
              ),
              forceLinkToBalance: true,
              defaultBalanceId: matchedBalanceId,
            ),
          );

          if (result != null) {
            final expense = result['expense'] as ExpenseModel;
            final allocations = result['allocations'] as List<ExpenseAllocationInput>? ?? [];
            await ExpenseController().addExpense(expense, allocations: allocations);
            await FinancialTrackerService.markAsClassified(refId, 'مصروفات');
            FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.expenseAdded, referenceId: refId));
            FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.radarClassified, referenceId: refId));
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تسجيل المصروف بنجاح!'),
                  backgroundColor: AppTheme.successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab(List<FinancialInsight> insightsList) {
    if (insightsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'لا توجد تنبيهات أو مخاطر ماليّة حالياً 👍',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيقوم المحرك الذكي بتحليل مصروفاتك وتنبيهك فور وجود أي تغيّرات مهمة.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: insightsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = insightsList[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: item.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.primaryColor,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
