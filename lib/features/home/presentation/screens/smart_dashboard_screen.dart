import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';

import '../../../../services/financial_tracker_service.dart';
import '../../../../core/db/database_helper.dart';
import '../../../../core/models/expense.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/transaction.dart' as app_tx;
import '../../../accounts/presentation/dialogs/add_transaction_dialog.dart';
import '../../../expenses/presentation/dialogs/add_expense_dialog.dart';
import '../../../expenses/domain/expense_repository.dart';
import '../../../expenses/application/expense_controller.dart';

class SmartDashboardScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;

  const SmartDashboardScreen({super.key, this.onDrawerChanged});

  @override
  State<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends State<SmartDashboardScreen> with WidgetsBindingObserver {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Set<String> _newTransactionIds = {};
  bool _dialogOpen = false;
  List<Map<String, dynamic>> _transactions = [];
  List<CategoryModel> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndShowDialog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop(); // Force close dialog on resume
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
                      // Keep dialog open, wait for resume
                    },
                    child: const Text('تفعيل الصلاحية', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
        _dialogOpen = false;
        // Check again after dialog closes (if user cancelled)
        final recheck = await FinancialTrackerService.isNotificationPermissionGranted();
        if (recheck && mounted && _transactions.isEmpty) {
          _loadData();
        }
      } else if (isGranted && _isLoading) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    final transactions = await FinancialTrackerService.getAllTransactions();
    // Filter out transactions that are already classified
    final unclassifiedTx = transactions.where((tx) {
      final isClassified = tx['isClassified'] == true || tx['isClassified'] == 1;
      return !isClassified;
    }).toList();

    final dbHelper = DatabaseHelper();
    final categories = await dbHelper.getCategories();
    final expenses = categories.where((c) => c.type == 'expense' || c.type == 'general').toList();

    setState(() {
      _transactions = unclassifiedTx;
      _expenseCategories = expenses.isNotEmpty ? expenses : CategoryModel.getDefaultCategories().where((c) => c.type == 'expense').toList();
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() { _isLoading = true; });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      onDrawerChanged: widget.onDrawerChanged,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الراصد',
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
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshData();
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, dynamic>>(
              stream: FinancialTrackerService.transactionStream,
              builder: (context, snapshot) {
                // If there's new data in the stream, add it to our list
                if (snapshot.hasData && snapshot.data != null) {
                  final newTx = snapshot.data!;
                  final String newId = newTx['referenceId']?.toString() ?? newTx['timestamp'].toString();
                  final existingIndex = _transactions.indexWhere((t) {
                    final tId = t['referenceId']?.toString() ?? t['timestamp'].toString();
                    return tId == newId;
                  });
                  if (existingIndex == -1) {
                    _transactions.insert(0, newTx);
                    _newTransactionIds.add(newId);
                    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
                    HapticFeedback.heavyImpact(); 
                  }
                }

                if (_transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.radar,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'الراصد جاهز',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'أي عملية مالية تصلك عبر الإشعارات ستظهر هنا تلقائياً دون تدخل منك.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.all(16),
                  initialItemCount: _transactions.length,
                  itemBuilder: (context, index, animation) {
                    final tx = _transactions[index];
                    final String counterpart = tx['counterpart']?.toString() ?? 'غير محدد';
                    final bool isParsed = tx['amount'] != null;
                    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                    final String bankName = tx['packageName']?.toString().contains('stc') == true ? 'STC Pay' : 'محفظة جيب';
                    
                    final String currency = tx['currency']?.toString() ?? 'ر.س';
                    final int timestamp = tx['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
                    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final String formattedDate = DateFormat('yyyy/MM/dd • hh:mm a').format(date);
                    
                    final isOutbound = !tx['transactionType'].toString().contains('In');
                    
                    final String txId = tx['referenceId']?.toString() ?? tx['timestamp'].toString();
                    final bool isNew = _newTransactionIds.contains(txId);
                    
                    return SizeTransition(
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: Dismissible(
                          key: Key(txId),
                          direction: DismissDirection.endToStart, // Swipe Left to dismiss
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                                // Dismiss
                                final removedTx = _transactions.removeAt(index);
                                _listKey.currentState?.removeItem(
                                  index,
                                  (context, animation) => const SizedBox(), // Simplified removal animation
                                  duration: const Duration(milliseconds: 300),
                                );
                                if (tx['referenceId'] != null) {
                                  FinancialTrackerService.markAsClassified(tx['referenceId'].toString(), 'تجاهل');
                                }
                                return true;
                            }
                            return false;
                          },
                          child: Stack(
                            children: [
                              Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bankName.contains('STC') ? const Color(0xFF4F008C).withValues(alpha: 0.03) : const Color(0xFF00B4D8).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(
                          color: bankName.contains('STC') 
                              ? const Color(0xFF4F008C).withValues(alpha: 0.08) 
                              : const Color(0xFF00B4D8).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bankName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              Text(formattedDate, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Middle Section: Prominent Icon, Counterpart, Amount
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Prominent App Logo (Jaeeb/STC)
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: bankName.contains('STC') 
                                    ? Icon(Icons.account_balance_wallet, size: 32, color: AppTheme.primaryColor)
                                    : Image.asset('assets/images/jaeeb.png', fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      counterpart,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isOutbound ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isOutbound ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            size: 12,
                                            color: isOutbound ? AppTheme.errorColor : AppTheme.successColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isOutbound ? 'عملية دفع صادرة' : 'استلام أموال',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Amount column
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    currency,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isOutbound ? AppTheme.errorColor.withOpacity(0.9) : AppTheme.successColor.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    NumberFormat("#,##0.##").format(amount),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isOutbound ? AppTheme.errorColor : AppTheme.successColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOutbound ? '-' : '+',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isOutbound ? AppTheme.errorColor : AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Quick Categorization (Step 5)
                          if (isParsed && tx['category'] == null) ...[
                            const SizedBox(height: 24),
                            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                            const SizedBox(height: 16),
                            const Text(
                              'كيف نصنف هذه العملية؟',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _buildDynamicCategoryChips(tx, isOutbound: isOutbound),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isNew)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
                  },
                );
              },
            ),
    );
  }

  List<Widget> _buildDynamicCategoryChips(Map<String, dynamic> tx, {required bool isOutbound}) {
    if (!isOutbound) {
      // For inbound (إيراد)
      return [
        _buildQuickCategoryChip(CategoryModel(name: 'تسديد دين لي', type: 'general', iconCodePoint: Icons.account_balance_wallet.codePoint), tx, isDebt: true, isBestSuggestion: true),
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

    // For outbound (مصروف أو سداد دين)
    return [
      if (!isUtility)
        _buildQuickCategoryChip(CategoryModel(name: 'سداد دين علي', type: 'general', iconCodePoint: Icons.money_off.codePoint), tx, isDebt: true, isBestSuggestion: false),
      _buildQuickCategoryChip(CategoryModel(name: 'تسجيل كمصروف', type: 'expense', iconCodePoint: Icons.receipt_long.codePoint), tx, isGeneralExpense: true, isBestSuggestion: true),
    ];
  }

  Widget _buildQuickCategoryChip(CategoryModel category, Map<String, dynamic> tx, {bool isDebt = false, bool isGeneralExpense = false, bool isBestSuggestion = false}) {
    final bool isPrimary = isBestSuggestion;
    final bgColor = isPrimary ? AppTheme.primaryColor : Colors.white;
    final textColor = isPrimary ? Colors.white : AppTheme.primaryColor;
    final borderColor = isPrimary ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.2);

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
              initialAmount: amount,
              initialType: isOutbound ? 'debit' : 'credit',
              initialDetails: 'تسديد عبر المحفظة',
            ),
          );

          if (result == true) {
            await FinancialTrackerService.markAsClassified(refId, isOutbound ? 'سداد دين' : 'استلام دين');
            setState(() {
              _transactions.removeWhere((t) => t['referenceId'] == refId);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تسديد الدين بنجاح!'),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 2),
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
          
          String suggestedName = '';
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
                detail: 'عبر المحفظة ($counterpart)',
                category: suggestedCategory,
                currency: tx['currency']?.toString() ?? 'محلي',
                createdDate: DateTime.now(),
              ),
              forceLinkToBalance: true,
              defaultBalanceId: matchedBalanceId,
            ),
          );

          if (result != null) {
            final ExpenseModel expenseResult = result['expense'] as ExpenseModel;
            final allocations = result['allocations'] as List<ExpenseAllocationInput>? ?? [];
            
            final controller = ExpenseController();
            await controller.addExpense(expenseResult, allocations: allocations);
            
            await FinancialTrackerService.markAsClassified(refId, expenseResult.category);
            setState(() {
              _transactions.removeWhere((t) => t['referenceId'] == refId);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تسجيل المصروف وتحديث الأرصدة بنجاح!'),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.iconCodePoint != null) ...[
              Icon(IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons'), size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
