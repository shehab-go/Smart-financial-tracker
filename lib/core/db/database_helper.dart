import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/currency.dart';
import 'migration_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(
      path,
      version: 4,
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
        name TEXT NOT NULL,
        symbol TEXT NOT NULL
      )
    ''');

    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        createdDate INTEGER NOT NULL,
        currencyCode TEXT NOT NULL DEFAULT 'LOC',
        phone TEXT
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
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

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

  Future<int> deleteCategory(int id) async {
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

  Future<int> deleteCurrency(int id) async {
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

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
