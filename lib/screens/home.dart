import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/account.dart';
import '../models/category.dart';
import '../db/database_helper.dart';
import '../widgets/app_drawer.dart';
import 'account_transactions.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/report_bottom_sheet.dart';
import '../services/report_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- Account selection helpers ---
  void _toggleAccountSelect(AccountModel acc) {
    if (acc.id == null) return;
    setState(() {
      if (_selectedAccountIds.contains(acc.id)) {
        _selectedAccountIds.remove(acc.id);
      } else {
        _selectedAccountIds.add(acc.id!);
      }
    });
  }

  void _clearAccountSelect() => setState(() => _selectedAccountIds.clear());

  Future<void> _deleteSelectedAccounts() async {
    if (_selectedAccountIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('سيتم حذف ${_selectedAccountIds.length} حساب ومعاملاته. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      for (final id in _selectedAccountIds) {
        await DatabaseHelper().deleteAccount(id);
      }
      _clearAccountSelect();
      _loadData();
    }
  }

  void _shareSelectedAccounts() {
    if (_selectedAccountIds.isEmpty) return;
    final sel = _categories.expand((cat) => _accountsByCategory[cat.name] ?? []).where((a) => _selectedAccountIds.contains(a.id)).toList();
    final lines = sel.map((a) => '${a.name}: له ${a.totalCredit.toStringAsFixed(0)} - عليه ${a.totalDebit.toStringAsFixed(0)}').join('\n');
    Share.share(lines, subject: 'حسابات مختارة');
  }

  Future<void> _printSelectedAccounts() async {
    if (_selectedAccountIds.isEmpty) return;
    final sel = _categories.expand((cat) => _accountsByCategory[cat.name] ?? []).where((a) => _selectedAccountIds.contains(a.id)).toList();
    final rows = sel.map((a) => [a.name, a.totalCredit.toStringAsFixed(0), a.totalDebit.toStringAsFixed(0)]).toList();
    final table = pw.Table.fromTextArray(headers: ['الحساب', 'له', 'عليه'], data: rows);
    await ReportService.generateAndOpenPdf(title: 'حسابات مختارة', content: [table]);
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
    if (_tabController.index >= _categories.length) return;
    final cat = _categories[_tabController.index];
    final accounts = _accountsByCategory[cat.name] ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد حسابات في هذه الفئة')));
      return;
    }
    // إجمالي لتحديد عنوان العمود الديناميكي
    final totalCredit = accounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebit = accounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netHeaderLabel = totalCredit >= totalDebit ?  'المتبقي عليك':'المتبقي لك' ;

    final rows = accounts.map((a) {
      final net = a.totalCredit - a.totalDebit;
      return [
        NumberFormat('#,##0').format(net.abs()),
        NumberFormat('#,##0').format(a.totalDebit),
        NumberFormat('#,##0').format(a.totalCredit),
        a.name,             
      ];
    }).toList();
    final table = pw.Table.fromTextArray(
        headers: [netHeaderLabel, 'عليه','له' ,'الحساب' ], data: rows);
    await ReportService.generateAndOpenPdf(
      title: 'تقرير فئة ${cat.name}',
      content: [table],
    );
  }

  Future<void> _generateReportForAll() async {
    final allAccounts = _categories
        .expand((c) => _accountsByCategory[c.name] ?? [])
        .toList();
    if (allAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد حسابات لعرضها')));
      return;
    }
    final totalCreditAll = allAccounts.fold<double>(0, (s, a) => s + a.totalCredit);
    final totalDebitAll = allAccounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final netHeaderLabelAll = totalCreditAll >= totalDebitAll ? 'المتبقي لك' :'المتبقي عليك' ;

    final rows = allAccounts.map((a) {
      final net = a.totalCredit - a.totalDebit;
      return [
        NumberFormat('#,##0').format(net.abs()),
        NumberFormat('#,##0').format(a.totalDebit),
        NumberFormat('#,##0').format(a.totalCredit),
        a.category,
        a.name, 
      ];
    }).toList();
    final table = pw.Table.fromTextArray(
        headers: [netHeaderLabelAll,'عليه' , 'له','الفئة' ,'الحساب'], data: rows);
    await ReportService.generateAndOpenPdf(
      title: 'تقرير جميع الحسابات',
      content: [table],
    );
  }

  late TabController _tabController;
  List<CategoryModel> _categories = [];
  Map<String, List<AccountModel>> _accountsByCategory = {};
  Map<String, Map<String, double>> _totalsByCategory = {};
  bool _isLoading = true;

  // Multi-select for accounts
  final Set<int> _selectedAccountIds = {};
  bool get _accSelectionMode => _selectedAccountIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await DatabaseHelper().getCategories();

      // Group accounts by category
      Map<String, List<AccountModel>> accountsByCategory = {};
      Map<String, Map<String, double>> totalsByCategory = {};

      for (CategoryModel category in categories) {
        final categoryAccounts =
            await DatabaseHelper().getAccountsWithStatsByCategory(category.name);
        accountsByCategory[category.name] = categoryAccounts;

        // Calculate totals for this category
        final totals = await DatabaseHelper().getCategoryTotals(category.name);
        totalsByCategory[category.name] = totals;
      }

      // Initialize tab controller after we have categories
      _tabController = TabController(length: categories.length, vsync: this);

      setState(() {
        _categories = categories;
        _accountsByCategory = accountsByCategory;
        _totalsByCategory = totalsByCategory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCreateAccount(String category) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(
            accountId: null,
            category: category,
          ),
        ) ??
        false;

    if (result == true) {
      _loadData();
    }
  }

  Future<bool?> _showCreateAccountDialog(String category) async {
    final nameController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء حساب جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الحساب',
                hintText: 'مثال: مطعم الورود، أحمد محمد، إلخ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  final account = AccountModel(
                    name: nameController.text.trim(),
                    category: category,
                    createdDate: DateTime.now(),
                  );
                  await DatabaseHelper().insertAccount(account);
                  Navigator.of(context).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في إنشاء الحساب: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAccountTransactions(AccountModel account) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountTransactionsScreen(account: account),
      ),
    );

    if (result == true) {
      _loadData(); // Refresh data when returning from account screen
    }
  }

  Future<void> _addTransactionForAccount(AccountModel account) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddTransactionDialog(
            accountId: account.id,
            category: account.category,
          ),
        ) ??
        false;

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل أنت متأكد من حذف الحساب "${account.name}"؟\nسيتم حذف جميع المعاملات المرتبطة به.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().deleteAccount(account.id!);
        _loadData(); // Refresh data after deletion
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحساب بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الحساب: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildCategoryTab(CategoryModel category) {
    final accounts = _accountsByCategory[category.name] ?? [];
    const headerStyle = TextStyle(fontWeight: FontWeight.bold);

    Widget _emptyState() => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('لا توجد حسابات في هذه الفئة',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('اضغط على + لإضافة حساب جديد',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
      
          
          const SizedBox(height: 16),

          // ترويسة الجدول
          Container(
            // Removed margin, padding, and background color
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(children: [
                Expanded(flex: 3, child: Text('الاسم', style: headerStyle)),
                Expanded(
                    flex: 2,
                    child: Center(child: Text('العملة', style: headerStyle))),
                Expanded(
                    flex: 2,
                    child: Center(
                        child: Text('عليه',
                            style: headerStyle.copyWith(color: Colors.red)))),
                Expanded(
                    flex: 2,
                    child: Center(
                        child: Text('له',
                            style: headerStyle.copyWith(color: Colors.green)))),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          // قائمة الحسابات أو حالة فارغة
          Expanded(
            child: accounts.isEmpty
                ? _emptyState()
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              child: InkWell(
                                  onTap: _accSelectionMode
                                       ? () => _toggleAccountSelect(account)
                                       : () => _navigateToAccountTransactions(account),
                                   onLongPress: () => _toggleAccountSelect(account),
                                  child: Container(
                                color: _selectedAccountIds.contains(account.id) ? Colors.blue.withOpacity(0.2) : null,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Row(children: [
                                          Expanded(
                                             flex: 3,
                                             child: Row(
                                               children: [
                                                 Flexible(
                                                   child: Text(
                                                     account.name,
                                                     overflow: TextOverflow.ellipsis,
                                                     style: const TextStyle(fontWeight: FontWeight.bold),
                                                   ),
                                                 ),
                                                 const SizedBox(width: 4),
                                                 Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                   decoration: BoxDecoration(
                                                     color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                     borderRadius: BorderRadius.circular(12),
                                                   ),
                                                   child: Text(
                                                     account.transactionCount.toString(),
                                                     style: const TextStyle(fontSize: 12, color: Colors.white),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                          // العملة
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                                child:
                                                    Text(account.currencyCode)),
                                          ),
                                          // له
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                  NumberFormat('#,##0')
                                                      .format(
                                                          account.totalDebit),
                                                  style: const TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ),
                                          // عليه
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                  NumberFormat('#,##0')
                                                      .format(
                                                          account.totalCredit),
                                                  style: const TextStyle(
                                                      color: Colors.green)),
                                            ),
                                          ),
                                          // عدد + أيقونة إضافة
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () =>
                                                    _addTransactionForAccount(
                                                        account),
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                                ),
                                                            
                                                          
                                                       
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ))));
                        }),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading indicator
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No categories
    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأموال الشخصية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('لا توجد فئات متاحة')),
      );
    }

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: _accSelectionMode
        ? AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearAccountSelect,
            ),
            title: Text('تم تحديد ${_selectedAccountIds.length}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'تحديد الكل',
                onPressed: () {
                  final allIds = _categories
                      .expand((c) => _accountsByCategory[c.name] ?? [])
                      .map((e) => e.id!)
                      .whereType<int>()
                      .toList();
                  setState(() {
                    if (_selectedAccountIds.length == allIds.length) {
                      _selectedAccountIds.clear();
                    } else {
                      _selectedAccountIds
                        ..clear()
                        ..addAll(allIds);
                    }
                  });
                },
              ),
              IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelectedAccounts),
              IconButton(icon: const Icon(Icons.print), onPressed: _printSelectedAccounts),
              IconButton(icon: const Icon(Icons.share), onPressed: _shareSelectedAccounts),
            ],
          )
        : AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.print),
          tooltip: 'تقرير',
          onPressed: _showReportOptions,
        ),
        titleSpacing: 0,
        title: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            if (_tabController.index < _categories.length) {
              final currentCategory = _categories[_tabController.index];
              return Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(currentCategory.nameArabic),
                    const SizedBox(width: 8),
                    Text(currentCategory.icon),
                  ],
                ),
              );
            }
            return const Text('إدارة الأموال الشخصية');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'القائمة',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) {
            return Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(category.icon),
                const SizedBox(width: 4),
                Text(category.nameArabic),
              ]),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _categories.map((category) => _buildCategoryTab(category)).toList(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index < _categories.length) {
            final currentCategory = _categories[_tabController.index].name;
            _navigateToCreateAccount(currentCategory);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
