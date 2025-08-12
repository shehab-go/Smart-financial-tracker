import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Helper class for managing database migrations
class MigrationHelper {
  static const int currentVersion = 4;
  
  /// Migrate database from old version to new version
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
  }
  
  /// Migration to version 2: Add lending management features
  static Future<void> _migrateToV2(Database db) async {
    try {
      // Create persons table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS persons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          notes TEXT,
          creditLimit REAL DEFAULT 0.0,
          rating INTEGER DEFAULT 1,
          createdDate INTEGER NOT NULL,
          profilePhoto TEXT
        )
      ''');
      
      // Add new columns to transactions table
      await _addColumnIfNotExists(db, 'transactions', 'dueDate', 'INTEGER');
      await _addColumnIfNotExists(db, 'transactions', 'interestRate', 'REAL');
      await _addColumnIfNotExists(db, 'transactions', 'guarantor', 'TEXT');
      await _addColumnIfNotExists(db, 'transactions', 'status', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'transactions', 'reminderEnabled', 'INTEGER DEFAULT 1');
      await _addColumnIfNotExists(db, 'transactions', 'reminderDaysBefore', 'INTEGER DEFAULT 3');
      
      // Add personId to accounts table
      await _addColumnIfNotExists(db, 'accounts', 'personId', 'INTEGER');
      
      // Add currencyCode to accounts table if it doesn't exist
      await _addColumnIfNotExists(db, 'accounts', 'currencyCode', 'TEXT NOT NULL DEFAULT "LOC"');
      
      // Create indexes for better performance
      await _createIndexIfNotExists(db, 'idx_persons_name', 'persons', 'name');
      await _createIndexIfNotExists(db, 'idx_accounts_person', 'accounts', 'personId');
      await _createIndexIfNotExists(db, 'idx_transactions_due_date', 'transactions', 'dueDate');
      await _createIndexIfNotExists(db, 'idx_transactions_status', 'transactions', 'status');
      
      print('Migration to v2 completed successfully');
    } catch (e) {
      print('Error during migration to v2: $e');
      rethrow;
    }
  }
  
  /// Migration to version 3: Ensure currencyCode column exists
  static Future<void> _migrateToV3(Database db) async {
    try {
      // Add currencyCode to accounts table if it doesn't exist
      await _addColumnIfNotExists(db, 'accounts', 'currencyCode', 'TEXT NOT NULL DEFAULT "LOC"');
      
      print('Migration to v3 completed successfully');
    } catch (e) {
      print('Error during migration to v3: $e');
      rethrow;
    }
  }

  /// Migration to version 4: Fix date column type from TEXT to INTEGER
  static Future<void> _migrateToV4(Database db) async {
    try {
      print('DEBUG: Starting migration to v4 - checking date column type');
      // Check if date column is TEXT type
      final result = await db.rawQuery('PRAGMA table_info(transactions)');
      print('DEBUG: Current transactions table structure: $result');
      final dateColumn = result.firstWhere((column) => column['name'] == 'date', orElse: () => {});
      print('DEBUG: Date column info: $dateColumn');
      
      if (dateColumn.isNotEmpty && dateColumn['type'] == 'TEXT') {
        print('DEBUG: Date column is TEXT, proceeding with migration');
        // Create new transactions table with correct schema
        await db.execute('''
          CREATE TABLE transactions_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            accountId INTEGER NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date INTEGER NOT NULL,
            description TEXT,
            dueDate INTEGER,
            interestRate REAL,
            guarantor TEXT,
            status INTEGER DEFAULT 0,
            reminderEnabled INTEGER DEFAULT 1,
            reminderDaysBefore INTEGER DEFAULT 3,
            FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
          )
        ''');
        
        // Copy data from old table, converting date from TEXT to INTEGER
        // Only copy columns that exist in the old table
        await db.execute('''
          INSERT INTO transactions_new (id, accountId, amount, type, category, date, description)
          SELECT id, accountId, amount, type, category, 
                 CASE 
                   WHEN date GLOB '[0-9]*' THEN CAST(date AS INTEGER)
                   ELSE strftime('%s', date) * 1000
                 END as date,
                 description
          FROM transactions
        ''');
        
        // Drop old table and rename new one
        await db.execute('DROP TABLE transactions');
        await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
        
        print('DEBUG: Fixed date column type from TEXT to INTEGER');
        
        // Verify the new table structure
        final newResult = await db.rawQuery('PRAGMA table_info(transactions)');
        print('DEBUG: New transactions table structure: $newResult');
      } else {
        print('DEBUG: Date column is already INTEGER type, no migration needed');
      }
      
      print('DEBUG: Migration to v4 completed successfully');
    } catch (e) {
      print('Error during migration to v4: $e');
      rethrow;
    }
  }
  
  /// Add column to table if it doesn't exist
  static Future<void> _addColumnIfNotExists(
    Database db, 
    String tableName, 
    String columnName, 
    String columnDefinition
  ) async {
    try {
      // Check if column exists
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = result.any((column) => column['name'] == columnName);
      
      if (!columnExists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
        print('Added column $columnName to $tableName');
      }
    } catch (e) {
      print('Error adding column $columnName to $tableName: $e');
    }
  }
  
  /// Create index if it doesn't exist
  static Future<void> _createIndexIfNotExists(
    Database db,
    String indexName,
    String tableName,
    String columnName
  ) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $tableName($columnName)');
      print('Created index $indexName');
    } catch (e) {
      print('Error creating index $indexName: $e');
    }
  }
  
  /// Migrate existing accounts to persons
  static Future<void> migrateAccountsToPersons(Database db) async {
    try {
      // Get all accounts with phone numbers
      final accounts = await db.query(
        'accounts',
        where: 'phone IS NOT NULL AND phone != ""',
      );
      
      for (final account in accounts) {
        // Check if person already exists
        final existingPersons = await db.query(
          'persons',
          where: 'name = ? AND phone = ?',
          whereArgs: [account['name'], account['phone']],
        );
        
        int personId;
        if (existingPersons.isEmpty) {
          // Create new person
          personId = await db.insert('persons', {
            'name': account['name'],
            'phone': account['phone'],
            'createdDate': account['createdDate'] ?? DateTime.now().millisecondsSinceEpoch,
            'rating': 1, // Default to good rating
            'creditLimit': 0.0,
          });
        } else {
          personId = existingPersons.first['id'] as int;
        }
        
        // Link account to person
        await db.update(
          'accounts',
          {'personId': personId},
          where: 'id = ?',
          whereArgs: [account['id']],
        );
      }
      
      print('Successfully migrated ${accounts.length} accounts to persons');
    } catch (e) {
      print('Error migrating accounts to persons: $e');
    }
  }
  
  /// Add default lending categories
  static Future<void> addLendingCategories(Database db) async {
    try {
      final lendingCategories = [
        {'name': 'قروض شخصية'},
        {'name': 'قروض تجارية'},
        {'name': 'قروض طارئة'},
        {'name': 'قروض عائلية'},
      ];
      
      for (final category in lendingCategories) {
        // Check if category already exists
        final existing = await db.query(
          'categories',
          where: 'name = ?',
          whereArgs: [category['name']],
        );
        
        if (existing.isEmpty) {
          await db.insert('categories', category);
        }
      }
      
      print('Added lending categories');
    } catch (e) {
      print('Error adding lending categories: $e');
    }
  }
  
  /// Run post-migration tasks
  static Future<void> runPostMigrationTasks() async {
    try {
      final db = await DatabaseHelper().database;
      
      // Migrate existing accounts to persons
      await migrateAccountsToPersons(db);
      
      // Add lending categories
      await addLendingCategories(db);
      
      print('Post-migration tasks completed');
    } catch (e) {
      print('Error in post-migration tasks: $e');
    }
  }
}

/// Extension methods for DatabaseHelper to support new features
extension DatabaseHelperExtension on DatabaseHelper {
  /// Get lending summary statistics
  Future<Map<String, dynamic>> getLendingSummary() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'debit' THEN amount ELSE 0 END), 0) as totalLent,
        COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as totalReceived,
        COUNT(CASE WHEN type = 'debit' AND (status = 0 OR status IS NULL) THEN 1 END) as activeLoans,
        COUNT(CASE WHEN type = 'debit' AND dueDate < ? AND (status = 0 OR status IS NULL) THEN 1 END) as overdueLoans
      FROM transactions
    ''', [DateTime.now().millisecondsSinceEpoch]);
    
    return result.first;
  }
  
  /// Get top borrowers by outstanding amount
  Future<List<Map<String, dynamic>>> getTopBorrowers({int limit = 5}) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT p.*, 
             COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE -t.amount END), 0) as currentBalance
      FROM persons p
      LEFT JOIN accounts a ON a.personId = p.id
      LEFT JOIN transactions t ON t.accountId = a.id
      GROUP BY p.id
      HAVING currentBalance > 0
      ORDER BY currentBalance DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }
  
  /// Get upcoming payments within specified days
  Future<List<Map<String, dynamic>>> getUpcomingPayments({int days = 7}) async {
    final db = await database;
    
    final endDate = DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
    
    final result = await db.rawQuery('''
      SELECT t.*, a.name as accountName, p.name as personName
      FROM transactions t
      JOIN accounts a ON a.id = t.accountId
      LEFT JOIN persons p ON p.id = a.personId
      WHERE t.type = 'debit' 
        AND t.dueDate IS NOT NULL 
        AND t.dueDate <= ?
        AND (t.status = 0 OR t.status IS NULL)
      ORDER BY t.dueDate ASC
    ''', [endDate]);
    
    return result;
  }
  
  /// Link account to person
  Future<void> linkAccountToPerson(int accountId, int personId) async {
    final db = await database;
    await db.update(
      'accounts',
      {'personId': personId},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
  
  /// Get person with calculated statistics
  Future<Map<String, dynamic>?> getPersonWithStats(int personId) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT p.*, 
             COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE 0 END), 0) as totalBorrowed,
             COALESCE(SUM(CASE WHEN t.type = 'credit' THEN t.amount ELSE 0 END), 0) as totalRepaid,
             COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE -t.amount END), 0) as currentBalance,
             COUNT(DISTINCT t.id) as lendingHistory
      FROM persons p
      LEFT JOIN accounts a ON a.personId = p.id
      LEFT JOIN transactions t ON t.accountId = a.id
      WHERE p.id = ?
      GROUP BY p.id
    ''', [personId]);
    
    return result.isNotEmpty ? result.first : null;
  }
}