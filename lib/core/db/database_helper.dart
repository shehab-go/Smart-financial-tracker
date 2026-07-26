import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/currency.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/expense_account.dart';
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

  static const String _metaKeyTxTypeNormalizedV1 = 'tx_type_normalized_v1';

  String _normalizeTransactionType(String type) {
    final t = type.trim().toLowerCase();
    if (t == 'credit') return 'credit';
    if (t == 'debit') return 'debit';
    if (t == 'له') return 'credit';
    if (t == 'عليه') return 'debit';
    if (t == 'لك') return 'credit';
    if (t == 'عليك') return 'debit';
    if (t == 'ديون لك') return 'credit';
    if (t == 'ديون عليك') return 'debit';
    return t;
  }

  Future<void> _runPostOpenMaintenance(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    final List<Map<String, dynamic>> rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_metaKeyTxTypeNormalizedV1],
      limit: 1,
    );
    final String? current = rows.isNotEmpty ? rows.first['value']?.toString() : null;
    if (current == 'true') return;

    await db.update(
      'transactions',
      {'type': 'credit'},
      where: "TRIM(LOWER(type)) IN (?, ?)",
      whereArgs: ['credit', 'له'],
    );
    await db.update(
      'transactions',
      {'type': 'debit'},
      where: "TRIM(LOWER(type)) IN (?, ?)",
      whereArgs: ['debit', 'عليه'],
    );

    await db.execute('DELETE FROM account_currency_stats');
    await db.execute('''
      INSERT INTO account_currency_stats (accountId, currencyName, transactionCount, totalDebit, totalCredit)
      SELECT
        t.accountId AS accountId,
        t.currencyName AS currencyName,
        COUNT(t.id) AS transactionCount,
        SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE 0 END) AS totalDebit,
        SUM(CASE WHEN t.type = 'credit' THEN t.amount ELSE 0 END) AS totalCredit
      FROM transactions t
      GROUP BY t.accountId, t.currencyName
    ''');

    await db.execute("UPDATE categories SET type = 'general' WHERE type IS NULL");

    final metaKeyUncategorized = 'uncategorized_migration_v1';
    final uncatRows = await db.query('app_meta', where: 'key = ?', whereArgs: [metaKeyUncategorized]);
    if (uncatRows.isEmpty || uncatRows.first['value'] != 'true') {
      final String groupName = 'فئات اضافية - غير مصنف';
      
      final existingParent = await db.query('categories', where: 'name = ? AND type = ?', whereArgs: [groupName, 'expense']);
      if (existingParent.isEmpty) {
        await db.insert('categories', {
          'name': groupName,
          'sortOrder': 999,
          'parentName': null,
          'iconCodePoint': 0xe14ea, 
          'colorValue': 0xFF9E9E9E, 
          'type': 'expense',
        });
      }

      final rootCategories = await db.query(
        'categories', 
        where: "(parentName IS NULL OR parentName = '') AND type = ? AND name != ?",
        whereArgs: ['expense', groupName]
      );

      for (var cat in rootCategories) {
        final catName = cat['name'] as String;
        final children = await db.query('categories', where: 'parentName = ?', whereArgs: [catName]);
        if (children.isEmpty) {
          await db.update(
            'categories', 
            {'parentName': groupName}, 
            where: 'name = ? AND type = ?', 
            whereArgs: [catName, 'expense']
          );
        }
      }
      
      await db.insert('app_meta', {'key': metaKeyUncategorized, 'value': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await db.insert(
      'app_meta',
      {'key': _metaKeyTxTypeNormalizedV1, 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _ensureCategoriesSeeded(Database db) async {
    final metaKey = 'categories_v18_seeded';
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [metaKey]);
    if (rows.isNotEmpty && rows.first['value'] == 'true') return;

    final defaultCategories = CategoryModel.getDefaultCategories();
    for (int i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      final Map<String, dynamic> data = {
        'name': category.name,
        'sortOrder': i,
        'parentName': category.parentName,
        'iconCodePoint': category.iconCodePoint,
        'colorValue': category.colorValue,
        'type': category.type ?? 'expense',
      };
      
      final existing = await db.query('categories', where: 'name = ?', whereArgs: [category.name]);
      if (existing.isNotEmpty) {
        await db.update('categories', data, where: 'name = ?', whereArgs: [category.name]);
      } else {
        await db.insert('categories', data);
      }
    }
    await db.insert('app_meta', {'key': metaKey, 'value': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Database> get database async {
    if (_database == null || !(_database!.isOpen)) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(
      path,
      version: 19,
      onCreate: _createDatabase,
      onUpgrade: MigrationHelper.migrate,
      onOpen: (db) async {
        await _runPostOpenMaintenance(db);
        await _ensureCategoriesSeeded(db);
      },
    );
  }

  Future<String?> getMetaValue(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final Object? value = rows.first['value'];
    return value?.toString();
  }

  Future<void> setMetaValue(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getDefaultCurrencyName() async {
    final raw = await getMetaValue('default_currency');
    if (raw == null || raw.trim().isEmpty) return 'محلي';
    return raw.trim();
  }

  Future<void> setDefaultCurrencyName(String name) async {
    await setMetaValue('default_currency', name);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sortOrder INTEGER DEFAULT 0,
        parentName TEXT,
        iconCodePoint INTEGER,
        colorValue INTEGER,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        currencyName TEXT NOT NULL DEFAULT 'محلي',
        date INTEGER NOT NULL,
        description TEXT,
        imagePaths TEXT,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE account_currency_stats (
        accountId INTEGER NOT NULL,
        currencyName TEXT NOT NULL,
        transactionCount INTEGER NOT NULL DEFAULT 0,
        totalDebit REAL NOT NULL DEFAULT 0,
        totalCredit REAL NOT NULL DEFAULT 0,
        PRIMARY KEY (accountId, currencyName)
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_accounts_category ON accounts(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_accounts_currencyName ON accounts(currencyName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_accountId ON transactions(accountId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_currencyName ON transactions(currencyName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions(accountId, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_account_currency_stats_currencyName ON account_currency_stats(currencyName)');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_tx_ai_stats
      AFTER INSERT ON transactions
      BEGIN
        INSERT OR IGNORE INTO account_currency_stats (
          accountId,
          currencyName,
          transactionCount,
          totalDebit,
          totalCredit
        ) VALUES (
          NEW.accountId,
          NEW.currencyName,
          0,
          0,
          0
        );

        UPDATE account_currency_stats
        SET
          transactionCount = transactionCount + 1,
          totalDebit = totalDebit + (CASE WHEN NEW.type = 'debit' THEN NEW.amount ELSE 0 END),
          totalCredit = totalCredit + (CASE WHEN NEW.type = 'credit' THEN NEW.amount ELSE 0 END)
        WHERE accountId = NEW.accountId AND currencyName = NEW.currencyName;
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_tx_ad_stats
      AFTER DELETE ON transactions
      BEGIN
        UPDATE account_currency_stats
        SET
          transactionCount = transactionCount - 1,
          totalDebit = totalDebit - (CASE WHEN OLD.type = 'debit' THEN OLD.amount ELSE 0 END),
          totalCredit = totalCredit - (CASE WHEN OLD.type = 'credit' THEN OLD.amount ELSE 0 END)
        WHERE accountId = OLD.accountId AND currencyName = OLD.currencyName;

        DELETE FROM account_currency_stats
        WHERE accountId = OLD.accountId AND currencyName = OLD.currencyName AND transactionCount <= 0;
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_tx_au_stats
      AFTER UPDATE ON transactions
      BEGIN
        UPDATE account_currency_stats
        SET
          transactionCount = transactionCount - 1,
          totalDebit = totalDebit - (CASE WHEN OLD.type = 'debit' THEN OLD.amount ELSE 0 END),
          totalCredit = totalCredit - (CASE WHEN OLD.type = 'credit' THEN OLD.amount ELSE 0 END)
        WHERE accountId = OLD.accountId AND currencyName = OLD.currencyName;

        DELETE FROM account_currency_stats
        WHERE accountId = OLD.accountId AND currencyName = OLD.currencyName AND transactionCount <= 0;

        INSERT OR IGNORE INTO account_currency_stats (
          accountId,
          currencyName,
          transactionCount,
          totalDebit,
          totalCredit
        ) VALUES (
          NEW.accountId,
          NEW.currencyName,
          0,
          0,
          0
        );

        UPDATE account_currency_stats
        SET
          transactionCount = transactionCount + 1,
          totalDebit = totalDebit + (CASE WHEN NEW.type = 'debit' THEN NEW.amount ELSE 0 END),
          totalCredit = totalCredit + (CASE WHEN NEW.type = 'credit' THEN NEW.amount ELSE 0 END)
        WHERE accountId = NEW.accountId AND currencyName = NEW.currencyName;
      END;
    ''');

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

    await db.execute('''
      CREATE TABLE expense_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'مصروفات',
        currencyName TEXT NOT NULL DEFAULT 'محلي',
        createdDate INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        detail TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'مصروفات',
        currency TEXT NOT NULL DEFAULT 'محلي',
        createdDate INTEGER NOT NULL,
        updatedDate INTEGER,
        expenseAccountId INTEGER
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
    int resourceId = await db.insert('income_resources', {
      'name': 'المصدر الرئيسي',
      'description': 'المصدر الافتراضي للرصيد',
      'createdDate': now,
    });

    await db.insert('income_balances', {
      'resourceId': resourceId,
      'name': 'الرصيد الأساسي',
      'currencyName': 'محلي',
      'initialAmount': 0.0,
      'isDefault': 1,
      'createdDate': now,
    });

    final defaultCategories = CategoryModel.getDefaultCategories();
    for (int i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i].copyWith(sortOrder: i);
      await db.insert('categories', category.toMap());
    }

    final defaultCurrencies = CurrencyModel.getDefaultCurrencies();
    for (CurrencyModel currency in defaultCurrencies) {
      await db.insert('currencies', currency.toMap());
    }
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('accounts');
      await txn.delete('expenses');
      await txn.delete('expense_accounts');
      await txn.delete('income_balances');
      await txn.delete('income_resources');
      await txn.delete('account_currency_stats');
    });
  }

  Future<void> cleanTemporaryData() async {
    await vacuum();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Category operations
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'sortOrder ASC');
    return compute(_parseCategories, maps);
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT MAX(sortOrder) as maxOrder FROM categories');
    final int maxOrder = (result.first['maxOrder'] as num?)?.toInt() ?? -1;
    final categoryWithOrder = CategoryModel(
      id: category.id,
      name: category.name,
      sortOrder: maxOrder + 1,
      parentName: category.parentName,
      iconCodePoint: category.iconCodePoint,
      colorValue: category.colorValue,
      type: category.type,
    );
    return await db.insert('categories', categoryWithOrder.toMap());
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
    final categoryResult = await db.query('categories', where: 'id = ?', whereArgs: [categoryId]);
    if (categoryResult.isEmpty) return false;
    final categoryName = categoryResult.first['name'] as String;
    final accountResult = await db.query('accounts', where: 'category = ?', whereArgs: [categoryName], limit: 1);
    if (accountResult.isNotEmpty) return true;
    final transactionResult = await db.query('transactions', where: 'category = ?', whereArgs: [categoryName], limit: 1);
    return transactionResult.isNotEmpty;
  }

  Future<int> deleteCategory(int id) async {
    if (await hasCategoryRelatedRecords(id)) {
      throw Exception('لا يمكن حذف هذه الفئة لأنها تحتوي على بيانات مرتبطة');
    }
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Currency operations
  Future<List<CurrencyModel>> getCurrencies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('currencies');
    return compute(_parseCurrencies, maps);
  }

  Future<int> insertCurrency(CurrencyModel currency) async {
    final db = await database;
    return await db.insert('currencies', currency.toMap());
  }

  Future<int> updateCurrency(CurrencyModel currency) async {
    final db = await database;
    return await db.update('currencies', currency.toMap(), where: 'id = ?', whereArgs: [currency.id]);
  }

  Future<bool> hasCurrencyRelatedRecords(int currencyId) async {
    final db = await database;
    final currencyResult = await db.query('currencies', where: 'id = ?', whereArgs: [currencyId]);
    if (currencyResult.isEmpty) return false;
    final currencyName = currencyResult.first['name'] as String;
    final accountResult = await db.query('accounts', where: 'currencyName = ?', whereArgs: [currencyName], limit: 1);
    return accountResult.isNotEmpty;
  }

  Future<int> deleteCurrency(int id) async {
    if (await hasCurrencyRelatedRecords(id)) {
      throw Exception('لا يمكن حذف هذه العملة لأنها مستخدمة');
    }
    final db = await database;
    return await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Map<String, int>>> getCurrencyUsageCountsByName() async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT c.name AS name,
        (SELECT COUNT(*) FROM accounts a WHERE a.currencyName = c.name) AS accountsCount,
        (SELECT COUNT(*) FROM income_balances b WHERE b.currencyName = c.name) AS balancesCount,
        (SELECT COUNT(*) FROM expenses e WHERE e.currency = c.name) AS expensesCount
      FROM currencies c
    ''');

    final Map<String, Map<String, int>> result = {};
    for (final row in rows) {
      final name = row['name']?.toString() ?? '';
      result[name] = {
        'accounts': (row['accountsCount'] as num?)?.toInt() ?? 0,
        'balances': (row['balancesCount'] as num?)?.toInt() ?? 0,
        'expenses': (row['expensesCount'] as num?)?.toInt() ?? 0,
      };
    }
    return result;
  }

  Future<Set<String>> getFavoriteCurrencies() async {
    final raw = await getMetaValue('favorite_currencies');
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> setFavoriteCurrencies(Set<String> favorites) async {
    await setMetaValue('favorite_currencies', jsonEncode(favorites.toList()));
  }

  Future<void> registerCurrencyUsage(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) return;
    if (await getDefaultCurrencyName() == null) await setDefaultCurrencyName(name);
    final favorites = await getFavoriteCurrencies();
    if (favorites.add(name)) await setFavoriteCurrencies(favorites);
  }

  Future<bool> isCurrencyMigrationCompleted() async {
    return await getMetaValue('currency_migration_completed') == 'true';
  }

  Future<List<String>> getUsedCurrenciesForMigration() async {
    final db = await database;
    final Set<String> names = {};

    final accountRows = await db.rawQuery('SELECT DISTINCT currencyName FROM accounts');
    for (final row in accountRows) names.add(row['currencyName'].toString().trim());

    final balanceRows = await db.rawQuery('SELECT DISTINCT currencyName FROM income_balances');
    for (final row in balanceRows) names.add(row['currencyName'].toString().trim());

    final expenseRows = await db.rawQuery('SELECT DISTINCT currency FROM expenses');
    for (final row in expenseRows) names.add(row['currency'].toString().trim());

    return names.where((n) => n.isNotEmpty).toList();
  }

  Future<void> applyCurrencyMappings(Map<String, String> mappings) async {
    if (mappings.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in mappings.entries) {
        await txn.update('accounts', {'currencyName': entry.value}, where: 'currencyName = ?', whereArgs: [entry.key]);
        await txn.update('income_balances', {'currencyName': entry.value}, where: 'currencyName = ?', whereArgs: [entry.key]);
        await txn.update('expenses', {'currency': entry.value}, where: 'currency = ?', whereArgs: [entry.key]);
        await txn.update('currencies', {'name': entry.value}, where: 'name = ?', whereArgs: [entry.key]);
      }
      await txn.insert('app_meta', {'key': 'currency_migration_completed', 'value': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<AccountModel>> _attachCurrencyStats(List<AccountModel> accounts) async {
    if (accounts.isEmpty) return accounts;
    final db = await database;
    final ids = accounts.map((a) => a.id).whereType<int>().toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final statsMaps = await db.query('account_currency_stats', where: 'accountId IN ($placeholders)', whereArgs: ids);

    final Map<int, List<AccountCurrencyStats>> groupedStats = {};
    for (final map in statsMaps) {
      final accountId = map['accountId'] as int;
      (groupedStats[accountId] ??= []).add(AccountCurrencyStats.fromMap(map));
    }

    return accounts.map((a) => a.copyWith(currencyStats: groupedStats[a.id] ?? [])).toList();
  }

  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts', where: 'category = ?', whereArgs: [category], orderBy: 'createdDate DESC');
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsWithStatsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
             COUNT(t.id)                  AS transactionCount,
             SUM(CASE WHEN t.type = "debit"  THEN t.amount ELSE 0 END) AS totalDebit,
             SUM(CASE WHEN t.type = "credit" THEN t.amount ELSE 0 END) AS totalCredit,
             MAX(t.date)                  AS lastTransactionDate
      FROM accounts a
      LEFT JOIN transactions t ON t.accountId = a.id
      WHERE a.category = ?
      GROUP BY a.id
      ORDER BY a.createdDate DESC
    ''', [category]);
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsWithStatsUsingAccountCurrencyAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*,
             COALESCE(s.transactionCount, 0) AS transactionCount,
             COALESCE(s.totalDebit, 0) AS totalDebit,
             COALESCE(s.totalCredit, 0) AS totalCredit,
             (SELECT MAX(date) FROM transactions WHERE accountId = a.id) AS lastTransactionDate
      FROM accounts a
      LEFT JOIN account_currency_stats s
        ON s.accountId = a.id AND s.currencyName = a.currencyName
      ORDER BY a.category ASC, a.createdDate DESC
    ''');
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsWithStatsByCurrencyAllCategories(String currencyName) async {
    final db = await database;
    final cur = currencyName.trim().isEmpty ? 'محلي' : currencyName.trim();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*,
             COALESCE(s.transactionCount, 0) AS transactionCount,
             COALESCE(s.totalDebit, 0) AS totalDebit,
             COALESCE(s.totalCredit, 0) AS totalCredit,
             (SELECT MAX(date) FROM transactions WHERE accountId = a.id) AS lastTransactionDate
      FROM accounts a
      LEFT JOIN account_currency_stats s
        ON s.accountId = a.id AND s.currencyName = ?
      ORDER BY a.category ASC, a.createdDate DESC
    ''', [cur]);
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsWithStatsByCategoryUsingAccountCurrency(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*,
             COALESCE(s.transactionCount, 0) AS transactionCount,
             COALESCE(s.totalDebit, 0) AS totalDebit,
             COALESCE(s.totalCredit, 0) AS totalCredit,
             (SELECT MAX(date) FROM transactions WHERE accountId = a.id) AS lastTransactionDate
      FROM accounts a
      LEFT JOIN account_currency_stats s
        ON s.accountId = a.id AND s.currencyName = a.currencyName
      WHERE a.category = ?
      ORDER BY a.createdDate DESC
    ''', [category]);
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<AccountModel>> getAccountsWithStatsByCategoryAndCurrency(String category, String currencyName) async {
    final db = await database;
    final cur = currencyName.trim().isEmpty ? 'محلي' : currencyName.trim();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*,
             COALESCE(s.transactionCount, 0) AS transactionCount,
             COALESCE(s.totalDebit, 0) AS totalDebit,
             COALESCE(s.totalCredit, 0) AS totalCredit,
             (SELECT MAX(date) FROM transactions WHERE accountId = a.id) AS lastTransactionDate
      FROM accounts a
      LEFT JOIN account_currency_stats s
        ON s.accountId = a.id AND s.currencyName = ?
      WHERE a.category = ?
      ORDER BY a.createdDate DESC
    ''', [cur, category]);
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  Future<List<String>> getDistinctTransactionCurrencies() async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.query('account_currency_stats', columns: ['DISTINCT currencyName'], orderBy: 'currencyName ASC');
    final result = rows.map((r) => r['currencyName'].toString().trim()).where((n) => n.isNotEmpty).toList();
    if (!result.contains('محلي')) result.insert(0, 'محلي');
    return result;
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

    final double debit = (rows.first['totalDebit'] as num?)?.toDouble() ?? 0.0;
    final double credit = (rows.first['totalCredit'] as num?)?.toDouble() ?? 0.0;
    return {'debit': debit, 'credit': credit, 'net': credit - debit};
  }

  Future<Map<String, Map<String, double>>> getCategoryTotalsByCurrency(String currencyName) async {
    final db = await database;
    final cur = currencyName.trim().isEmpty ? 'محلي' : currencyName.trim();
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        a.category AS category,
        SUM(COALESCE(s.totalDebit, 0))  AS totalDebit,
        SUM(COALESCE(s.totalCredit, 0)) AS totalCredit
      FROM accounts a
      LEFT JOIN account_currency_stats s
        ON s.accountId = a.id AND s.currencyName = ?
      GROUP BY a.category
    ''', [cur]);

    final Map<String, Map<String, double>> result = {};
    for (final row in rows) {
      final cat = row['category'].toString();
      result[cat] = {
        'debit': (row['totalDebit'] as num?)?.toDouble() ?? 0.0,
        'credit': (row['totalCredit'] as num?)?.toDouble() ?? 0.0,
        'net': ((row['totalCredit'] as num?)?.toDouble() ?? 0.0) - ((row['totalDebit'] as num?)?.toDouble() ?? 0.0),
      };
    }
    return result;
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    return await db.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  Future<AccountModel?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    final account = AccountModel.fromMap(maps.first);
    final attached = await _attachCurrencyStats([account]);
    return attached.first;
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction operations
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return compute(_parseTransactions, maps);
  }

  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'category = ?', whereArgs: [category], orderBy: 'date DESC');
    return compute(_parseTransactions, maps);
  }

  Future<List<TransactionModel>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'accountId = ?', whereArgs: [accountId], orderBy: 'date DESC');
    return compute(_parseTransactions, maps);
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'date >= ? AND date <= ?', whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch], orderBy: 'date DESC');
    return compute(_parseTransactions, maps);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.copyWith(type: _normalizeTransactionType(transaction.type)).toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update('transactions', transaction.copyWith(type: _normalizeTransactionType(transaction.type)).toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getOverallTotals() async {
    final db = await database;
    final dResult = await db.rawQuery('SELECT SUM(amount) as total FROM transactions WHERE type = "debit"');
    final cResult = await db.rawQuery('SELECT SUM(amount) as total FROM transactions WHERE type = "credit"');
    final double d = (dResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final double c = (cResult.first['total'] as num?)?.toDouble() ?? 0.0;
    return {'debit': d, 'credit': c, 'net': c - d};
  }

  // User Profile operations
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', limit: 1);
    return maps.isNotEmpty ? UserProfile.fromMap(maps.first) : null;
  }

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toMap());
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update('user_profile', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  // Expense operations
  Future<List<ExpenseModel>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'createdDate DESC');
    return compute(_parseExpenses, maps);
  }

  Future<ExpenseModel?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? ExpenseModel.fromMap(maps.first) : null;
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Expense account operations
  Future<List<ExpenseAccountModel>> getExpenseAccountsWithStats() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT ea.*, COUNT(e.id) AS expenseCount, IFNULL(SUM(e.amount), 0) AS totalAmount
      FROM expense_accounts ea
      LEFT JOIN expenses e ON e.expenseAccountId = ea.id
      GROUP BY ea.id
      ORDER BY ea.createdDate DESC
    ''');
    return compute(_parseExpenseAccounts, rows);
  }

  Future<int> insertExpenseAccount(ExpenseAccountModel account) async {
    final db = await database;
    return await db.insert('expense_accounts', account.toMap());
  }

  Future<int> updateExpenseAccount(ExpenseAccountModel account) async {
    final db = await database;
    return await db.update('expense_accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  Future<int> deleteExpenseAccount(int id) async {
    final db = await database;
    int count = 0;
    await db.transaction((txn) async {
      await txn.delete('expenses', where: 'expenseAccountId = ?', whereArgs: [id]);
      count = await txn.delete('expense_accounts', where: 'id = ?', whereArgs: [id]);
    });
    return count;
  }

  Future<void> cleanupOrphanedExpenses() async {
    final db = await database;
    await db.rawDelete('DELETE FROM expenses WHERE expenseAccountId IS NOT NULL AND expenseAccountId NOT IN (SELECT id FROM expense_accounts)');
  }

  Future<List<ExpenseModel>> getExpensesByAccountId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', where: 'expenseAccountId = ?', whereArgs: [id], orderBy: 'createdDate DESC');
    return compute(_parseExpenses, maps);
  }

  // Income resources operations
  Future<List<IncomeResourceModel>> getIncomeResources() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('income_resources', orderBy: 'createdDate DESC');
    return compute(_parseIncomeResources, maps);
  }

  Future<int> insertIncomeResource(IncomeResourceModel resource) async {
    final db = await database;
    return await db.insert('income_resources', resource.toMap());
  }

  Future<int> updateIncomeResource(IncomeResourceModel resource) async {
    final db = await database;
    return await db.update('income_resources', resource.toMap(), where: 'id = ?', whereArgs: [resource.id]);
  }

  Future<int> deleteIncomeResource(int id) async {
    final db = await database;
    return await db.delete('income_resources', where: 'id = ?', whereArgs: [id]);
  }

  // Income balances operations
  Future<List<IncomeBalanceModel>> getIncomeBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('income_balances', orderBy: 'createdDate DESC');
    return compute(_parseIncomeBalances, maps);
  }

  Future<IncomeBalanceModel?> getDefaultIncomeBalance() async {
    final db = await database;
    final maps = await db.query('income_balances', where: 'isDefault = ?', whereArgs: [1], limit: 1);
    return maps.isNotEmpty ? IncomeBalanceModel.fromMap(maps.first) : null;
  }

  Future<int> insertIncomeBalance(IncomeBalanceModel balance) async {
    final db = await database;
    return await db.insert('income_balances', balance.toMap());
  }

  Future<int> updateIncomeBalance(IncomeBalanceModel balance) async {
    final db = await database;
    return await db.update('income_balances', balance.toMap(), where: 'id = ?', whereArgs: [balance.id]);
  }

  Future<int> deleteIncomeBalance(int id) async {
    final db = await database;
    return await db.delete('income_balances', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, double>> getIncomeBalanceCurrentAmounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.id AS id, b.initialAmount + IFNULL((SELECT SUM(ta.allocatedAmount * CASE WHEN t.type = "credit" THEN 1 WHEN t.type = "debit" THEN -1 ELSE 0 END) FROM transaction_balance_allocations ta JOIN transactions t ON t.id = ta.transactionId WHERE ta.balanceId = b.id), 0) - IFNULL((SELECT SUM(ea.allocatedAmount) FROM expense_balance_allocations ea WHERE ea.balanceId = b.id), 0) AS currentAmount
      FROM income_balances b
    ''');
    final Map<int, double> result = {};
    for (final row in rows) {
      final id = (row['id'] as num).toInt();
      result[id] = (row['currentAmount'] as num?)?.toDouble() ?? 0.0;
    }
    return result;
  }

  Future<List<Map<String, Object?>>> getBalanceTransactionAllocationsWithDetails(int id) async {
    final db = await database;
    return await db.rawQuery('SELECT ta.id AS allocationId, t.id AS transactionId, t.amount AS transactionAmount, t.type AS transactionType, t.date AS transactionDate, t.description AS transactionDescription, a.name AS accountName, ta.allocatedAmount AS allocatedAmount FROM transaction_balance_allocations ta JOIN transactions t ON t.id = ta.transactionId JOIN accounts a ON a.id = t.accountId WHERE ta.balanceId = ? ORDER BY t.date DESC, ta.id DESC', [id]);
  }

  Future<List<Map<String, Object?>>> getBalanceExpenseAllocationsWithDetails(int id) async {
    final db = await database;
    return await db.rawQuery('SELECT ea.id AS allocationId, e.id AS expenseId, e.name AS expenseName, e.amount AS expenseAmount, e.createdDate AS expenseDate, e.detail AS expenseDetail, ea.allocatedAmount AS allocatedAmount FROM expense_balance_allocations ea JOIN expenses e ON e.id = ea.expenseId WHERE ea.balanceId = ? ORDER BY e.createdDate DESC, ea.id DESC', [id]);
  }

  Future<List<TransactionBalanceAllocation>> getTransactionAllocations(int id) async {
    final db = await database;
    final maps = await db.query('transaction_balance_allocations', where: 'transactionId = ?', whereArgs: [id]);
    return compute(_parseTransactionAllocations, maps);
  }

  Future<List<ExpenseBalanceAllocation>> getExpenseAllocations(int id) async {
    final db = await database;
    final maps = await db.query('expense_balance_allocations', where: 'expenseId = ?', whereArgs: [id]);
    return compute(_parseExpenseAllocations, maps);
  }

  Future<List<Map<String, Object?>>> getResourceTransactionAllocationsWithDetails(int id) async {
    final db = await database;
    return await db.rawQuery('SELECT ta.id AS allocationId, t.id AS transactionId, t.amount AS transactionAmount, t.type AS transactionType, t.date AS transactionDate, t.description AS transactionDescription, a.name AS accountName, b.name AS balanceName, ta.allocatedAmount AS allocatedAmount FROM transaction_balance_allocations ta JOIN transactions t ON t.id = ta.transactionId JOIN accounts a ON a.id = t.accountId JOIN income_balances b ON b.id = ta.balanceId WHERE b.resourceId = ? ORDER BY t.date DESC, ta.id DESC', [id]);
  }

  Future<List<Map<String, Object?>>> getResourceExpenseAllocationsWithDetails(int id) async {
    final db = await database;
    return await db.rawQuery('SELECT ea.id AS allocationId, e.id AS expenseId, e.name AS expenseName, e.amount AS expenseAmount, e.createdDate AS expenseDate, e.detail AS expenseDetail, b.name AS balanceName, ea.allocatedAmount AS allocatedAmount FROM expense_balance_allocations ea JOIN expenses e ON e.id = ea.expenseId JOIN income_balances b ON b.id = ea.balanceId WHERE b.resourceId = ? ORDER BY e.createdDate DESC, ea.id DESC', [id]);
  }

  Future<void> insertTransactionAllocations(List<TransactionBalanceAllocation> list) async {
    final db = await database;
    final batch = db.batch();
    for (final a in list) batch.insert('transaction_balance_allocations', a.toMap());
    await batch.commit(noResult: true);
  }

  Future<void> insertExpenseAllocations(List<ExpenseBalanceAllocation> list) async {
    final db = await database;
    final batch = db.batch();
    for (final a in list) batch.insert('expense_balance_allocations', a.toMap());
    await batch.commit(noResult: true);
  }

  Future<void> deleteTransactionAllocations(int id) async {
    final db = await database;
    await db.delete('transaction_balance_allocations', where: 'transactionId = ?', whereArgs: [id]);
  }

  Future<void> deleteExpenseAllocations(int id) async {
    final db = await database;
    await db.delete('expense_balance_allocations', where: 'expenseId = ?', whereArgs: [id]);
  }
}

List<CategoryModel> _parseCategories(List<Map<String, dynamic>> maps) => maps.map((m) => CategoryModel.fromMap(m)).toList();
List<CurrencyModel> _parseCurrencies(List<Map<String, dynamic>> maps) => maps.map((m) => CurrencyModel.fromMap(m)).toList();
List<AccountModel> _parseAccounts(List<Map<String, dynamic>> maps) => maps.map((m) => AccountModel.fromMap(m)).toList();
List<TransactionModel> _parseTransactions(List<Map<String, dynamic>> maps) => maps.map((m) => TransactionModel.fromMap(m)).toList();
List<ExpenseModel> _parseExpenses(List<Map<String, dynamic>> maps) => maps.map((m) => ExpenseModel.fromMap(m)).toList();
List<ExpenseAccountModel> _parseExpenseAccounts(List<Map<String, dynamic>> maps) => maps.map((m) => ExpenseAccountModel.fromMap(m)).toList();
List<IncomeResourceModel> _parseIncomeResources(List<Map<String, dynamic>> maps) => maps.map((m) => IncomeResourceModel.fromMap(m)).toList();
List<IncomeBalanceModel> _parseIncomeBalances(List<Map<String, dynamic>> maps) => maps.map((m) => IncomeBalanceModel.fromMap(m)).toList();
List<TransactionBalanceAllocation> _parseTransactionAllocations(List<Map<String, dynamic>> maps) => maps.map((m) => TransactionBalanceAllocation.fromMap(m)).toList();
List<ExpenseBalanceAllocation> _parseExpenseAllocations(List<Map<String, dynamic>> maps) => maps.map((m) => ExpenseBalanceAllocation.fromMap(m)).toList();
