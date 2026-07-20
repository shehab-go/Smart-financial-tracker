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

    // Repair bug where categories were inserted with NULL type by updating them to 'general'
    await db.execute("UPDATE categories SET type = 'general' WHERE type IS NULL");

    // Migrate old flat expense categories to be under "فئات اضافية - غير مصنف"
    final metaKeyUncategorized = 'uncategorized_migration_v1';
    final uncatRows = await db.query('app_meta', where: 'key = ?', whereArgs: [metaKeyUncategorized]);
    if (uncatRows.isEmpty || uncatRows.first['value'] != 'true') {
      final String groupName = 'فئات اضافية - غير مصنف';
      
      // 1. Ensure the parent category exists
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

      // 2. Get all root expense categories
      final rootCategories = await db.query(
        'categories', 
        where: "(parentName IS NULL OR parentName = '') AND type = ? AND name != ?",
        whereArgs: ['expense', groupName]
      );

      for (var cat in rootCategories) {
        final catName = cat['name'] as String;
        // 3. Check if this root category has any children
        final children = await db.query('categories', where: 'parentName = ?', whereArgs: [catName]);
        if (children.isEmpty) {
          // 4. Update it to be a child of 'فئات اضافية - غير مصنف'
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
      
      // Update if exists to add icons/colors/type, or insert if new
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
      version: 19,
      onCreate: _createDatabase,
      onUpgrade: MigrationHelper.migrate,
      onOpen: (db) async {
        await _runPostOpenMaintenance(db);
        await _ensureCategoriesSeeded(db);
      },
    );
  }

  /// Returns the configured default currency display name, or null if none set.
  /// This is stored in app_meta under the key 'default_currency'.
  Future<String?> getDefaultCurrencyName() async {
    final raw = await getMetaValue('default_currency');
    if (raw == null || raw.trim().isEmpty) return 'محلي';
    return raw.trim();
  }

  /// Sets the global default currency display name used for new transactions,
  /// expenses, and balances.
  Future<void> setDefaultCurrencyName(String name) async {
    await setMetaValue('default_currency', name);
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create categories table
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

    // Create app_meta table for storing global app flags (e.g., currency migration)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
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

    // Create expense accounts table
    await db.execute('''
      CREATE TABLE expense_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'مصروفات',
        currencyName TEXT NOT NULL DEFAULT 'محلي',
        createdDate INTEGER NOT NULL
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

    final existingDefaultBalance = await db.query(
      'income_balances',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (existingDefaultBalance.isEmpty) {
      await db.insert('income_balances', {
        'resourceId': resourceId,
        'name': 'الرصيد الأساسي',
        'currencyName': 'محلي',
        'initialAmount': 0.0,
        'isDefault': 1,
        'createdDate': now,
      });
    }

    // Insert default categories
    final defaultCategories = CategoryModel.getDefaultCategories();
    for (int i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      final categoryWithOrder = category.copyWith(
        sortOrder: i,
      );
      await db.insert('categories', categoryWithOrder.toMap());
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
    return compute(_parseCurrencies, maps);
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

  /// Returns usage counts (accounts, income balances, expenses) for each
  /// currency name present in the currencies table, keyed by the currency
  /// display name stored in `currencies.name`.
  ///
  /// The inner map uses keys: `accounts`, `balances`, `expenses`.
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
      final Object? nameValue = row['name'];
      if (nameValue == null) continue;
      final String name = nameValue.toString();

      final int accounts = (row['accountsCount'] as num?)?.toInt() ?? 0;
      final int balances = (row['balancesCount'] as num?)?.toInt() ?? 0;
      final int expenses = (row['expensesCount'] as num?)?.toInt() ?? 0;

      result[name] = <String, int>{
        'accounts': accounts,
        'balances': balances,
        'expenses': expenses,
      };
    }

    return result;
  }

  /// Returns the set of favorite currency display names as stored in app_meta.
  Future<Set<String>> getFavoriteCurrencies() async {
    final raw = await getMetaValue('favorite_currencies');
    if (raw == null || raw.trim().isEmpty) return <String>{};

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toSet();
    } catch (_) {
      // If anything goes wrong with parsing, treat as no favorites.
      return <String>{};
    }
  }

  /// Persists the given set of favorite currency display names into app_meta.
  Future<void> setFavoriteCurrencies(Set<String> favorites) async {
    final String encoded = jsonEncode(favorites.toList());
    await setMetaValue('favorite_currencies', encoded);
  }

  /// Register that a user actually used this currency in a transaction or expense.
  ///
  /// - If no global default currency is set yet, this currency becomes the default.
  /// - The currency is also added to the favorites set so it appears in quick-pick lists.
  Future<void> registerCurrencyUsage(String displayName) async {
    final String name = displayName.trim();
    if (name.isEmpty) return;

    // 1) Ensure there is a sensible global default.
    final String? currentDefault = await getDefaultCurrencyName();
    if (currentDefault == null || currentDefault.trim().isEmpty) {
      await setDefaultCurrencyName(name);
    }

    // 2) Ensure this currency is in the favorites list.
    final Set<String> favorites = await getFavoriteCurrencies();
    if (!favorites.contains(name)) {
      favorites.add(name);
      await setFavoriteCurrencies(favorites);
    }
  }

  // App meta operations (key-value storage for global flags)
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

  Future<bool> isCurrencyMigrationCompleted() async {
    final value = await getMetaValue('currency_migration_completed');
    return value == 'true';
  }

  /// Returns all distinct legacy currency names that are actually used
  /// in accounts with transactions, income balances with allocations,
  /// or expenses. Used to drive the world_countries migration UI.
  Future<List<String>> getUsedCurrenciesForMigration() async {
    final db = await database;
    final Set<String> names = {};

    // Accounts that have transactions
    final List<Map<String, Object?>> accountRows = await db.rawQuery('''
      SELECT DISTINCT a.currencyName AS name
      FROM accounts a
      JOIN transactions t ON t.accountId = a.id
      WHERE a.currencyName IS NOT NULL AND a.currencyName != ''
    ''');
    for (final row in accountRows) {
      final Object? nameValue = row['name'];
      if (nameValue == null) continue;
      final String name = nameValue.toString().trim();
      if (name.isNotEmpty) names.add(name);
    }

    // Income balances that have any allocations (transactions or expenses)
    final List<Map<String, Object?>> balanceRows = await db.rawQuery('''
      SELECT DISTINCT b.currencyName AS name
      FROM income_balances b
      JOIN transaction_balance_allocations ta ON ta.balanceId = b.id
      JOIN transactions t ON t.id = ta.transactionId
      WHERE b.currencyName IS NOT NULL AND b.currencyName != ''
      UNION
      SELECT DISTINCT b.currencyName AS name
      FROM income_balances b
      JOIN expense_balance_allocations ea ON ea.balanceId = b.id
      JOIN expenses e ON e.id = ea.expenseId
      WHERE b.currencyName IS NOT NULL AND b.currencyName != ''
    ''');
    for (final row in balanceRows) {
      final Object? nameValue = row['name'];
      if (nameValue == null) continue;
      final String name = nameValue.toString().trim();
      if (name.isNotEmpty) names.add(name);
    }

    // Expenses
    final List<Map<String, Object?>> expenseRows = await db.rawQuery('''
      SELECT DISTINCT currency AS name
      FROM expenses
      WHERE currency IS NOT NULL AND currency != ''
    ''');
    for (final row in expenseRows) {
      final Object? nameValue = row['name'];
      if (nameValue == null) continue;
      final String name = nameValue.toString().trim();
      if (name.isNotEmpty) names.add(name);
    }

    return names.toList();
  }

  /// Applies a mapping from legacy currency display names to new
  /// world_countries-based display names (Arabic), updating all
  /// relevant tables and marking the migration as completed.
  Future<void> applyCurrencyMappings(Map<String, String> mappings) async {
    if (mappings.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      for (final entry in mappings.entries) {
        final String oldName = entry.key;
        final String newName = entry.value;

        // Update accounts
        await txn.update(
          'accounts',
          {'currencyName': newName},
          where: 'currencyName = ?',
          whereArgs: [oldName],
        );

        // Update income balances
        await txn.update(
          'income_balances',
          {'currencyName': newName},
          where: 'currencyName = ?',
          whereArgs: [oldName],
        );

        // Update expenses
        await txn.update(
          'expenses',
          {'currency': newName},
          where: 'currency = ?',
          whereArgs: [oldName],
        );

        // Update currencies table
        await txn.update(
          'currencies',
          {'name': newName},
          where: 'name = ?',
          whereArgs: [oldName],
        );
      }

      // Mark migration as completed
      await txn.insert(
        'app_meta',
        {
          'key': 'currency_migration_completed',
          'value': 'true',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }



  Future<List<AccountModel>> _attachCurrencyStats(List<AccountModel> accounts) async {
    if (accounts.isEmpty) return accounts;
    final db = await database;
    final List<int> ids = accounts.map((a) => a.id).whereType<int>().toList();
    if (ids.isEmpty) return accounts;

    // Query all currency stats for these accounts
    final String idPlaceholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> statsMaps = await db.rawQuery('''
      SELECT * FROM account_currency_stats
      WHERE accountId IN ($idPlaceholders)
    ''', ids);

    // Group stats by accountId
    final Map<int, List<AccountCurrencyStats>> statsByAccountId = {};
    for (final map in statsMaps) {
      final int accountId = map['accountId'] as int;
      final stats = AccountCurrencyStats.fromMap(map);
      (statsByAccountId[accountId] ??= []).add(stats);
    }

    // Attach to accounts
    return accounts.map((account) {
      if (account.id == null) return account;
      final stats = statsByAccountId[account.id] ?? [];
      return account.copyWith(currencyStats: stats);
    }).toList();
  }

  // Account operations
  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
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
    final accounts = await compute(_parseAccounts, maps);
    return await _attachCurrencyStats(accounts);
  }

  /// Returns accounts in a category along with aggregated stats
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

  Future<List<AccountModel>> getAccountsWithStatsByCurrencyAllCategories(
    String currencyName,
  ) async {
    final db = await database;
    final String cur = currencyName.trim().isNotEmpty ? currencyName.trim() : 'محلي';
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

  Future<List<AccountModel>> getAccountsWithStatsByCategoryUsingAccountCurrency(
    String category,
  ) async {
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

  Future<List<AccountModel>> getAccountsWithStatsByCategoryAndCurrency(
    String category,
    String currencyName,
  ) async {
    final db = await database;
    final String cur = currencyName.trim().isNotEmpty ? currencyName.trim() : 'محلي';
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
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT DISTINCT currencyName AS currencyName FROM account_currency_stats ORDER BY currencyName ASC',
    );

    final List<String> result = [];
    for (final row in rows) {
      final Object? value = row['currencyName'];
      if (value == null) continue;
      final String name = value.toString().trim();
      if (name.isEmpty) continue;
      result.add(name);
    }
    if (result.isEmpty) return ['محلي'];
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

  Future<Map<String, Map<String, double>>> getCategoryTotalsByCurrency(
    String currencyName,
  ) async {
    final db = await database;
    final String cur = currencyName.trim().isNotEmpty ? currencyName.trim() : 'محلي';

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

    final Map<String, Map<String, double>> result = <String, Map<String, double>>{};
    for (final row in rows) {
      final Object? category = row['category'];
      if (category == null) continue;
      final String cat = category.toString();
      final double debit = (row['totalDebit'] as num?)?.toDouble() ?? 0.0;
      final double credit = (row['totalCredit'] as num?)?.toDouble() ?? 0.0;
      result[cat] = <String, double>{
        'debit': debit,
        'credit': credit,
        'net': credit - debit,
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
      final account = AccountModel.fromMap(maps.first);
      final attached = await _attachCurrencyStats([account]);
      return attached.first;
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
    return compute(_parseTransactions, maps);
  }

  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return compute(_parseTransactions, maps);
  }

  Future<List<TransactionModel>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return compute(_parseTransactions, maps);
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
    return compute(_parseTransactions, maps);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    final normalized = transaction.copyWith(
      type: _normalizeTransactionType(transaction.type),
    );
    return await db.insert('transactions', normalized.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    final normalized = transaction.copyWith(
      type: _normalizeTransactionType(transaction.type),
    );
    return await db.update(
      'transactions',
      normalized.toMap(),
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
    return compute(_parseExpenses, maps);
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

  // Expense account operations
  Future<List<ExpenseAccountModel>> getExpenseAccountsWithStats() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT ea.*, 
             COUNT(e.id) AS expenseCount,
             IFNULL(SUM(e.amount), 0) AS totalAmount
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
    return await db.update(
      'expense_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteExpenseAccount(int id) async {
    final db = await database;
    int count = 0;
    await db.transaction((txn) async {
      // First delete all expenses associated with this account
      await txn.delete(
        'expenses',
        where: 'expenseAccountId = ?',
        whereArgs: [id],
      );
      // Then delete the account itself
      count = await txn.delete(
        'expense_accounts',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    return count;
  }

  Future<void> cleanupOrphanedExpenses() async {
    final db = await database;
    // Delete any expense where expenseAccountId is not null but does not exist in expense_accounts table
    await db.rawDelete('''
      DELETE FROM expenses 
      WHERE expenseAccountId IS NOT NULL 
      AND expenseAccountId NOT IN (SELECT id FROM expense_accounts)
    ''');
  }

  Future<List<ExpenseModel>> getExpensesByAccountId(int expenseAccountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'expenseAccountId = ?',
      whereArgs: [expenseAccountId],
      orderBy: 'createdDate DESC',
    );
    return compute(_parseExpenses, maps);
  }

  // Income resources operations
  Future<List<IncomeResourceModel>> getIncomeResources() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_resources',
      orderBy: 'createdDate DESC',
    );
    return compute(_parseIncomeResources, maps);
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
    return compute(_parseIncomeBalances, maps);
  }

  Future<List<IncomeBalanceModel>> getIncomeBalancesByResource(int resourceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'income_balances',
      where: 'resourceId = ?',
      whereArgs: [resourceId],
      orderBy: 'createdDate DESC',
    );
    return compute(_parseIncomeBalances, maps);
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
    return compute(_parseTransactionAllocations, maps);
  }

  Future<List<ExpenseBalanceAllocation>> getExpenseAllocations(
      int expenseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_balance_allocations',
      where: 'expenseId = ?',
      whereArgs: [expenseId],
    );
    return compute(_parseExpenseAllocations, maps);
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

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    // Reset instance so subsequent calls reopen a fresh connection
    _database = null;
  }
}

List<CategoryModel> _parseCategories(List<Map<String, dynamic>> maps) {
  return maps.map((map) => CategoryModel.fromMap(map)).toList();
}

List<CurrencyModel> _parseCurrencies(List<Map<String, dynamic>> maps) {
  return maps.map((map) => CurrencyModel.fromMap(map)).toList();
}

List<AccountModel> _parseAccounts(List<Map<String, dynamic>> maps) {
  return maps.map((map) => AccountModel.fromMap(map)).toList();
}

List<TransactionModel> _parseTransactions(List<Map<String, dynamic>> maps) {
  return maps.map((map) => TransactionModel.fromMap(map)).toList();
}

List<ExpenseModel> _parseExpenses(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseModel.fromMap(map)).toList();
}

List<ExpenseAccountModel> _parseExpenseAccounts(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseAccountModel.fromMap(map)).toList();
}

List<IncomeResourceModel> _parseIncomeResources(List<Map<String, dynamic>> maps) {
  return maps.map((map) => IncomeResourceModel.fromMap(map)).toList();
}

List<IncomeBalanceModel> _parseIncomeBalances(List<Map<String, dynamic>> maps) {
  return maps.map((map) => IncomeBalanceModel.fromMap(map)).toList();
}

List<TransactionBalanceAllocation> _parseTransactionAllocations(List<Map<String, dynamic>> maps) {
  return maps.map((map) => TransactionBalanceAllocation.fromMap(map)).toList();
}

List<ExpenseBalanceAllocation> _parseExpenseAllocations(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseBalanceAllocation.fromMap(map)).toList();
}
