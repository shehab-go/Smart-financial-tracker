import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/currency.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/income_resource.dart';
import '../models/income_balance.dart';
import '../models/transaction_balance_allocation.dart';
import '../models/expense_balance_allocation.dart';
import 'migration_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    // Ensure we don't return a closed database instance
    if (_database == null || !(_database!.isOpen)) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDatabase,
      onUpgrade: MigrationHelper.migrate,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create currencies table
    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        createdDate INTEGER NOT NULL,
        currencyName TEXT NOT NULL DEFAULT 'محلي',
        phone TEXT,
        address TEXT,
        workDetails TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE income_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdDate INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE income_balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resourceId INTEGER NOT NULL,
        name TEXT NOT NULL,
        currencyName TEXT NOT NULL DEFAULT 'محلي',
        initialAmount REAL NOT NULL DEFAULT 0,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdDate INTEGER NOT NULL,
        FOREIGN KEY (resourceId) REFERENCES income_resources (id) ON DELETE CASCADE
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        imagePaths TEXT,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Create user profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        logoPath TEXT,
        businessName TEXT,
        tradingActivity TEXT,
        createdDate INTEGER NOT NULL,
        updatedDate INTEGER
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        detail TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'مصروفات',
        currency TEXT NOT NULL DEFAULT 'محلي',
        createdDate INTEGER NOT NULL,
        updatedDate INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_balance_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        balanceId INTEGER NOT NULL,
        allocatedAmount REAL NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (balanceId) REFERENCES income_balances (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_balance_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expenseId INTEGER NOT NULL,
        balanceId INTEGER NOT NULL,
        allocatedAmount REAL NOT NULL,
        FOREIGN KEY (expenseId) REFERENCES expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (balanceId) REFERENCES income_balances (id) ON DELETE CASCADE
      )
    ''');

    final int now = DateTime.now().millisecondsSinceEpoch;

    int resourceId;
    final existingResources = await db.query(
      'income_resources',
      limit: 1,
    );
    if (existingResources.isEmpty) {
      resourceId = await db.insert('income_resources', {
        'name': 'المصدر الرئيسي',
        'description': 'المصدر الافتراضي للرصيد',
        'createdDate': now,
      });
    } else {
      resourceId = existingResources.first['id'] as int;
    }

    int defaultBalanceId;
    final existingDefaultBalance = await db.query(
      'income_balances',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (existingDefaultBalance.isEmpty) {
      defaultBalanceId = await db.insert('income_balances', {
        'resourceId': resourceId,
        'name': 'الرصيد الأساسي',
        'currencyName': 'محلي',
        'initialAmount': 0.0,
        'isDefault': 1,
        'createdDate': now,
      });
    } else {
      defaultBalanceId = existingDefaultBalance.first['id'] as int;
    }

    // Insert default categories
    final defaultCategories = CategoryModel.getDefaultCategories();
    for (CategoryModel category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }

    // Insert default currencies
    final defaultCurrencies = CurrencyModel.getDefaultCurrencies();
    for (CurrencyModel currency in defaultCurrencies) {
      await db.insert('currencies', currency.toMap());
    }
  }



  // Category operations
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return CategoryModel.fromMap(maps[i]);
    });
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<bool> hasCategoryRelatedRecords(int categoryId) async {
    final db = await database;
    
    // Get category name first
    final categoryResult = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    
    if (categoryResult.isEmpty) return false;
    
    final categoryName = categoryResult.first['name'] as String;
    
    // Check for accounts in this category
    final accountResult = await db.query(
      'accounts',
      where: 'category = ?',
      whereArgs: [categoryName],
      limit: 1,
    );
    
    if (accountResult.isNotEmpty) return true;
    
    // Check for transactions in this category
    final transactionResult = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [categoryName],
      limit: 1,
    );
    
    return transactionResult.isNotEmpty;
  }

  Future<int> deleteCategory(int id) async {
    // Check if category has related records
    final hasRelatedRecords = await hasCategoryRelatedRecords(id);
    if (hasRelatedRecords) {
      throw Exception('لا يمكن حذف هذه الفئة لأنها تحتوي على حسابات أو معاملات مرتبطة بها');
    }
    
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Currency operations
  Future<List<CurrencyModel>> getCurrencies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('currencies');
    return List.generate(maps.length, (i) {
      return CurrencyModel.fromMap(maps[i]);
    });
  }

  Future<int> insertCurrency(CurrencyModel currency) async {
    final db = await database;
    return await db.insert('currencies', currency.toMap());
  }

  Future<int> updateCurrency(CurrencyModel currency) async {
    final db = await database;
    return await db.update(
      'currencies',
      currency.toMap(),
      where: 'id = ?',
      whereArgs: [currency.id],
    );
  }

  Future<bool> hasCurrencyRelatedRecords(int currencyId) async {
    final db = await database;
    
    // Get currency name first
    final currencyResult = await db.query(
      'currencies',
      where: 'id = ?',
      whereArgs: [currencyId],
    );
    
    if (currencyResult.isEmpty) return false;
    
    final currencyName = currencyResult.first['name'] as String;
    
    // Check for accounts using this currency
    final accountResult = await db.query(
      'accounts',
      where: 'currencyName = ?',
      whereArgs: [currencyName],
      limit: 1,
    );
    
    return accountResult.isNotEmpty;
  }

  Future<int> deleteCurrency(int id) async {
    // Check if currency has related records
    final hasRelatedRecords = await hasCurrencyRelatedRecords(id);
    if (hasRelatedRecords) {
      throw Exception('لا يمكن حذف هذه العملة لأنها مستخدمة في حسابات موجودة');
    }
    
    final db = await database;
    return await db.delete(
      'currencies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  // Account operations
  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return AccountModel.fromMap(maps[i]);
    });
  }

  Future<List<AccountModel>> getAccountsByCategory(String category) async {
    // Original simple method kept for compatibility
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return AccountModel.fromMap(maps[i]);
    });
  }

  /// Returns accounts in a category along with aggregated stats
  Future<List<AccountModel>> getAccountsWithStatsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
             COUNT(t.id)                  AS transactionCount,
             SUM(CASE WHEN t.type = "debit"  THEN t.amount ELSE 0 END) AS totalDebit,
             SUM(CASE WHEN t.type = "credit" THEN t.amount ELSE 0 END) AS totalCredit
      FROM accounts a
      LEFT JOIN transactions t ON t.accountId = a.id
      WHERE a.category = ?
      GROUP BY a.id
      ORDER BY a.createdDate DESC
    ''', [category]);

    return List.generate(maps.length, (i) => AccountModel.fromMap(maps[i]));
  }

  Future<Map<String, double>> getCategoryTotals(String category) async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN t.type = "debit"  THEN t.amount ELSE 0 END)  AS totalDebit,
        SUM(CASE WHEN t.type = "credit" THEN t.amount ELSE 0 END) AS totalCredit
      FROM transactions t
      INNER JOIN accounts a ON a.id = t.accountId
      WHERE a.category = ?
    ''', [category]);

    double debit = 0.0;
    double credit = 0.0;
    if (rows.isNotEmpty) {
      final row = rows.first;
      debit = (row['totalDebit'] as num?)?.toDouble() ?? 0.0;
      credit = (row['totalCredit'] as num?)?.toDouble() ?? 0.0;
    }
    return {
      'debit': debit,
      'credit': credit,
      'net': credit - debit,
    };
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<AccountModel?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AccountModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get overall totals
  Future<Map<String, double>> getOverallTotals() async {
    final db = await database;

    // Get total debits
    final debitResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['debit'],
    );
    double totalDebit = debitResult.first['total'] as double? ?? 0.0;

    // Get total credits
    final creditResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['credit'],
    );
    double totalCredit = creditResult.first['total'] as double? ?? 0.0;

    return {
      'debit': totalDebit,
      'credit': totalCredit,
      'net': totalCredit - totalDebit,
    };
  }

  // User Profile operations
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toMap());
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteUserProfile(int id) async {
    final db = await database;
    return await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense operations
  Future<List<ExpenseModel>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return ExpenseModel.fromMap(maps[i]);
    });
  }

  Future<ExpenseModel?> getExpenseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ExpenseModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return result.first['total'] as double? ?? 0.0;
  }

  // Income resources operations
  Future<List<IncomeResourceModel>> getIncomeResources() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_resources',
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return IncomeResourceModel.fromMap(maps[i]);
    });
  }

  Future<int> insertIncomeResource(IncomeResourceModel resource) async {
    final db = await database;
    return await db.insert('income_resources', resource.toMap());
  }

  Future<int> updateIncomeResource(IncomeResourceModel resource) async {
    final db = await database;
    return await db.update(
      'income_resources',
      resource.toMap(),
      where: 'id = ?',
      whereArgs: [resource.id],
    );
  }

  Future<int> deleteIncomeResource(int id) async {
    final db = await database;
    return await db.delete(
      'income_resources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Income balances operations
  Future<List<IncomeBalanceModel>> getIncomeBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_balances',
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return IncomeBalanceModel.fromMap(maps[i]);
    });
  }

  Future<List<IncomeBalanceModel>> getIncomeBalancesByResource(int resourceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_balances',
      where: 'resourceId = ?',
      whereArgs: [resourceId],
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return IncomeBalanceModel.fromMap(maps[i]);
    });
  }

  Future<IncomeBalanceModel?> getDefaultIncomeBalance() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_balances',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IncomeBalanceModel.fromMap(maps.first);
  }

  Future<int> insertIncomeBalance(IncomeBalanceModel balance) async {
    final db = await database;
    return await db.insert('income_balances', balance.toMap());
  }

  Future<int> updateIncomeBalance(IncomeBalanceModel balance) async {
    final db = await database;
    return await db.update(
      'income_balances',
      balance.toMap(),
      where: 'id = ?',
      whereArgs: [balance.id],
    );
  }

  Future<int> deleteIncomeBalance(int id) async {
    final db = await database;
    return await db.delete(
      'income_balances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<int, double>> getIncomeBalanceCurrentAmounts() async {
    final db = await database;

    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        b.id AS id,
        b.initialAmount
          + IFNULL((
              SELECT SUM(
                       ta.allocatedAmount * CASE
                         WHEN t.type = 'credit' THEN 1
                         WHEN t.type = 'debit'  THEN -1
                         ELSE 0
                       END
                     )
              FROM transaction_balance_allocations ta
              JOIN transactions t ON t.id = ta.transactionId
              WHERE ta.balanceId = b.id
            ), 0)
          - IFNULL((
              SELECT SUM(ea.allocatedAmount)
              FROM expense_balance_allocations ea
              WHERE ea.balanceId = b.id
            ), 0) AS currentAmount
      FROM income_balances b
    ''');

    final Map<int, double> result = {};
    for (final row in rows) {
      final Object? idValue = row['id'];
      if (idValue == null) continue;

      int id;
      if (idValue is int) {
        id = idValue;
      } else if (idValue is num) {
        id = idValue.toInt();
      } else {
        continue;
      }

      final num? current = row['currentAmount'] as num?;
      result[id] = current?.toDouble() ?? 0.0;
    }

    return result;
  }

  Future<List<Map<String, Object?>>> getBalanceTransactionAllocationsWithDetails(
      int balanceId) async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        ta.id AS allocationId,
        t.id AS transactionId,
        t.amount AS transactionAmount,
        t.type AS transactionType,
        t.date AS transactionDate,
        t.description AS transactionDescription,
        a.name AS accountName,
        ta.allocatedAmount AS allocatedAmount
      FROM transaction_balance_allocations ta
      JOIN transactions t ON t.id = ta.transactionId
      JOIN accounts a ON a.id = t.accountId
      WHERE ta.balanceId = ?
      ORDER BY t.date DESC, ta.id DESC
    ''', [balanceId]);
    return rows;
  }

  Future<List<Map<String, Object?>>> getBalanceExpenseAllocationsWithDetails(
      int balanceId) async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        ea.id AS allocationId,
        e.id AS expenseId,
        e.name AS expenseName,
        e.amount AS expenseAmount,
        e.createdDate AS expenseDate,
        e.detail AS expenseDetail,
        ea.allocatedAmount AS allocatedAmount
      FROM expense_balance_allocations ea
      JOIN expenses e ON e.id = ea.expenseId
      WHERE ea.balanceId = ?
      ORDER BY e.createdDate DESC, ea.id DESC
    ''', [balanceId]);
    return rows;
  }

  Future<List<TransactionBalanceAllocation>> getTransactionAllocations(
      int transactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_balance_allocations',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    return List.generate(maps.length, (i) {
      return TransactionBalanceAllocation.fromMap(maps[i]);
    });
  }

  Future<List<ExpenseBalanceAllocation>> getExpenseAllocations(
      int expenseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_balance_allocations',
      where: 'expenseId = ?',
      whereArgs: [expenseId],
    );
    return List.generate(maps.length, (i) {
      return ExpenseBalanceAllocation.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, Object?>>> getResourceTransactionAllocationsWithDetails(
      int resourceId) async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        ta.id AS allocationId,
        t.id AS transactionId,
        t.amount AS transactionAmount,
        t.type AS transactionType,
        t.date AS transactionDate,
        t.description AS transactionDescription,
        a.name AS accountName,
        b.name AS balanceName,
        ta.allocatedAmount AS allocatedAmount
      FROM transaction_balance_allocations ta
      JOIN transactions t ON t.id = ta.transactionId
      JOIN accounts a ON a.id = t.accountId
      JOIN income_balances b ON b.id = ta.balanceId
      WHERE b.resourceId = ?
      ORDER BY t.date DESC, ta.id DESC
    ''', [resourceId]);
    return rows;
  }

  Future<List<Map<String, Object?>>> getResourceExpenseAllocationsWithDetails(
      int resourceId) async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        ea.id AS allocationId,
        e.id AS expenseId,
        e.name AS expenseName,
        e.amount AS expenseAmount,
        e.createdDate AS expenseDate,
        e.detail AS expenseDetail,
        b.name AS balanceName,
        ea.allocatedAmount AS allocatedAmount
      FROM expense_balance_allocations ea
      JOIN expenses e ON e.id = ea.expenseId
      JOIN income_balances b ON b.id = ea.balanceId
      WHERE b.resourceId = ?
      ORDER BY e.createdDate DESC, ea.id DESC
    ''', [resourceId]);
    return rows;
  }

  Future<void> insertTransactionAllocations(
      List<TransactionBalanceAllocation> allocations) async {
    final db = await database;
    final batch = db.batch();
    for (final allocation in allocations) {
      batch.insert('transaction_balance_allocations', allocation.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertExpenseAllocations(List<ExpenseBalanceAllocation> allocations) async {
    final db = await database;
    final batch = db.batch();
    for (final allocation in allocations) {
      batch.insert('expense_balance_allocations', allocation.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteTransactionAllocations(int transactionId) async {
    final db = await database;
    await db.delete(
      'transaction_balance_allocations',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  Future<void> deleteExpenseAllocations(int expenseId) async {
    final db = await database;
    await db.delete(
      'expense_balance_allocations',
      where: 'expenseId = ?',
      whereArgs: [expenseId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    // Reset instance so subsequent calls reopen a fresh connection
    _database = null;
  }
}
