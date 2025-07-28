import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../db/database_helper.dart';
import 'account_transactions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<CategoryModel> _categories = [];
  Map<String, List<AccountModel>> _accountsByCategory = {};
  Map<String, Map<String, double>> _totalsByCategory = {};
  bool _isLoading = true;

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
        final categoryAccounts = await DatabaseHelper().getAccountsByCategory(category.name);
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
    final result = await _showCreateAccountDialog(category);
    if (result == true) {
      _loadData(); // Refresh data after creating account
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

  Future<void> _deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الحساب "${account.name}"؟\nسيتم حذف جميع المعاملات المرتبطة به.'),
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
    final totals = _totalsByCategory[category.name] ?? {'debit': 0.0, 'credit': 0.0, 'net': 0.0};

    return Column(
      children: [
        // Category totals card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      category.nameArabic,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('المصروفات', style: TextStyle(color: Colors.red)),
                        Text(
                          '${NumberFormat('#,##0.00').format(totals['debit'])} ر.س',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('الدخل', style: TextStyle(color: Colors.green)),
                        Text(
                          '${NumberFormat('#,##0.00').format(totals['credit'])} ر.س',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('الصافي'),
                        Text(
                          '${NumberFormat('#,##0.00').format(totals['net'])} ر.س',
                          style: TextStyle(
                            color: totals['net']! >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Accounts list
        Expanded(
          child: accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد حسابات في هذه الفئة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اضغط على + لإضافة حساب جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            account.name.isNotEmpty ? account.name[0].toUpperCase() : 'ح',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'تم الإنشاء: ${DateFormat('dd/MM/yyyy').format(account.createdDate)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteAccount(account);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف الحساب', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToAccountTransactions(account),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأموال الشخصية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('لا توجد فئات متاحة'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأموال الشخصية'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon),
                  const SizedBox(width: 4),
                  Text(category.nameArabic),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildCategoryTab(category);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String? currentCategory;
          if (_tabController.index < _categories.length) {
            currentCategory = _categories[_tabController.index].name;
          }
          if (currentCategory != null) {
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
