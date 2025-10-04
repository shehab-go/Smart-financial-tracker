import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Helper class for managing database migrations
/// 
/// This class provides methods to migrate the database schema from older versions
/// to newer versions, ensuring data integrity and backward compatibility.
/// 
/// Migration process:
/// - Each version increment adds new features or modifies existing schema
/// - Migrations are applied sequentially from old version to new version
/// - All migrations are wrapped in try-catch blocks for error handling
/// - Detailed logging is provided for debugging and monitoring
class MigrationHelper {
  /// Current database schema version
  static const int currentVersion = 6;
  
  // Constants for default values and common strings
  static const String defaultCurrencyName = 'محلي';
  static const int defaultReminderDaysBefore = 3;
  static const int defaultStatus = 0;
  static const int defaultReminderEnabled = 1;
  static const double defaultCreditLimit = 0.0;
  static const int defaultRating = 1;
  
  // Table and column names
  static const String personsTable = 'persons';
  static const String accountsTable = 'accounts';
  static const String transactionsTable = 'transactions';
  static const String categoriesTable = 'categories';
  static const String userProfileTable = 'user_profile';
  
  /// Migrates database from old version to new version
  /// 
  /// This method applies all necessary schema changes sequentially from
  /// [oldVersion] to [newVersion]. Each migration is applied in order
  /// and wrapped in error handling.
  /// 
  /// Parameters:
  /// - [db]: The database instance to migrate
  /// - [oldVersion]: Current database version
  /// - [newVersion]: Target database version
  /// 
  /// Throws: Exception if any migration step fails
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    try {
      print('[MigrationHelper] Starting database migration from version $oldVersion to $newVersion');
      
      if (oldVersion < 2) {
        print('[MigrationHelper] Applying migration to version 2');
        await _migrateToV2(db);
      }
      if (oldVersion < 3) {
        print('[MigrationHelper] Applying migration to version 3');
        await _migrateToVersion3(db);
      }
      if (oldVersion < 4) {
        print('[MigrationHelper] Applying migration to version 4');
        await _migrateToV4(db);
      }
      if (oldVersion < 5) {
        print('[MigrationHelper] Applying migration to version 5');
        await _migrateToV5(db);
      }
      if (oldVersion < 6) {
        print('[MigrationHelper] Applying migration to version 6');
        await _migrateToV6(db);
      }
      
      print('[MigrationHelper] Database migration completed successfully');
    } catch (e, stackTrace) {
      print('[MigrationHelper] ERROR: Database migration failed: $e');
      print('[MigrationHelper] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Migration to version 2: Add lending management features
  static Future<void> _migrateToV2(Database db) async {
    try {
      // Create persons table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $personsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          notes TEXT,
          creditLimit REAL DEFAULT $defaultCreditLimit,
          rating INTEGER DEFAULT $defaultRating,
          createdDate INTEGER NOT NULL,
          profilePhoto TEXT
        )
      ''');
      
      // Add new columns to transactions table
      await _addColumnIfNotExists(db, transactionsTable, 'dueDate', 'INTEGER');
      await _addColumnIfNotExists(db, transactionsTable, 'interestRate', 'REAL');
      await _addColumnIfNotExists(db, transactionsTable, 'guarantor', 'TEXT');
      await _addColumnIfNotExists(db, transactionsTable, 'status', 'INTEGER DEFAULT $defaultStatus');
      await _addColumnIfNotExists(db, transactionsTable, 'reminderEnabled', 'INTEGER DEFAULT $defaultReminderEnabled');
      await _addColumnIfNotExists(db, transactionsTable, 'reminderDaysBefore', 'INTEGER DEFAULT $defaultReminderDaysBefore');
      
      // Add personId to accounts table
      await _addColumnIfNotExists(db, accountsTable, 'personId', 'INTEGER');
      
      // Add currencyName to accounts table if it doesn't exist
      await _addColumnIfNotExists(db, accountsTable, 'currencyName', 'TEXT NOT NULL DEFAULT "$defaultCurrencyName"');
      
      // Create indexes for better performance
      await _createIndexIfNotExists(db, 'idx_persons_name', personsTable, 'name');
      await _createIndexIfNotExists(db, 'idx_accounts_person', accountsTable, 'personId');
      await _createIndexIfNotExists(db, 'idx_transactions_due_date', transactionsTable, 'dueDate');
      await _createIndexIfNotExists(db, 'idx_transactions_status', transactionsTable, 'status');
      
      print('[MigrationHelper] Migration to v2 completed successfully');
    } catch (e) {
      print('[MigrationHelper] ERROR: Migration to v2 failed: $e');
      rethrow;
    }
  }
  
  /// Migration to version 3: Reserved for future use
  static Future<void> _migrateToVersion3(Database db) async {
    try {
      print('[MigrationHelper] Migrating to version 3...');
      // currencyName column is already handled in v2 migration
      // This version is reserved for future schema changes
      
      print('[MigrationHelper] Migration to v3 completed successfully');
    } catch (e) {
      print('[MigrationHelper] ERROR: Migration to v3 failed: $e');
      rethrow;
    }
  }

  /// Migration to version 4: Fix date column type from TEXT to INTEGER
  static Future<void> _migrateToV4(Database db) async {
    try {
      print('[MigrationHelper] Starting migration to v4 - checking date column type');
      // Check if date column is TEXT type
      final result = await db.rawQuery('PRAGMA table_info(transactions)');
      print('[MigrationHelper] Current transactions table structure: $result');
      final dateColumn = result.firstWhere((column) => column['name'] == 'date', orElse: () => {});
      print('[MigrationHelper] Date column info: $dateColumn');
      
      if (dateColumn.isNotEmpty && dateColumn['type'] == 'TEXT') {
        print('[MigrationHelper] Date column is TEXT, proceeding with migration');
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
        
        print('[MigrationHelper] Fixed date column type from TEXT to INTEGER');
        
        // Verify the new table structure
        final newResult = await db.rawQuery('PRAGMA table_info(transactions)');
        print('[MigrationHelper] New transactions table structure: $newResult');
      } else {
        print('[MigrationHelper] Date column is already INTEGER type, no migration needed');
      }
      
      print('[MigrationHelper] Migration to v4 completed successfully');
    } catch (e) {
      print('[MigrationHelper] ERROR: Migration to v4 failed: $e');
      rethrow;
    }
  }
  
  /// Adds a column to a table if it doesn't already exist
  /// 
  /// This method safely adds a new column to an existing table, handling
  /// NOT NULL constraints by first adding the column as nullable, updating
  /// existing records with default values, then altering to NOT NULL if needed.
  /// 
  /// Parameters:
  /// - [db]: Database instance
  /// - [tableName]: Name of the table to modify
  /// - [columnName]: Name of the column to add
  /// - [columnDefinition]: Full column definition (e.g., 'TEXT NOT NULL DEFAULT "value"')
  /// 
  /// Throws: Exception if column addition fails
  static Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnDefinition) async {
    try {
      // Check if column exists
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = result.any((column) => column['name'] == columnName);
      
      if (!columnExists) {
        // Parse the column definition to handle NOT NULL columns properly
        String actualDefinition = columnDefinition;
        String? defaultValue;
        
        // Extract default value if present
        defaultValue = _extractDefaultValue(columnDefinition);
        
        // If column is NOT NULL, add it as nullable first
        if (columnDefinition.toUpperCase().contains('NOT NULL')) {
          // Remove NOT NULL from definition for initial addition
          actualDefinition = columnDefinition.replaceAll(RegExp(r'NOT\s+NULL', caseSensitive: false), '').trim();
          // Clean up any double spaces
          actualDefinition = actualDefinition.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        
        // Add the column
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $actualDefinition');
        print('[MigrationHelper] Added column $columnName to $tableName');
        
        // If there was a default value and the original was NOT NULL, update existing records
        if (defaultValue != null && columnDefinition.toUpperCase().contains('NOT NULL')) {
          await db.execute('UPDATE $tableName SET $columnName = ? WHERE $columnName IS NULL', [defaultValue]);
          print('[MigrationHelper] Updated existing records in $tableName with default value for $columnName');
        }
      }
    } catch (e) {
      print('[MigrationHelper] ERROR: Failed to add column $columnName to $tableName: $e');
      rethrow;
    }
  }
  
  /// Extracts default value from a column definition string
  /// 
  /// Parses column definition to find DEFAULT clause and extracts the value,
  /// handling both quoted and unquoted values.
  /// 
  /// Parameters:
  /// - [columnDefinition]: Column definition string (e.g., 'TEXT NOT NULL DEFAULT "value"')
  /// 
  /// Returns: Default value string or null if no default found
  static String? _extractDefaultValue(String columnDefinition) {
    if (!columnDefinition.toUpperCase().contains('DEFAULT')) {
      return null;
    }
    
    final parts = columnDefinition.split(RegExp(r'DEFAULT\s+', caseSensitive: false));
    if (parts.length <= 1) {
      return null;
    }
    
    String defaultValue = parts[1].trim();
    
    // Remove quotes if present
    if ((defaultValue.startsWith('"') && defaultValue.endsWith('"')) ||
        (defaultValue.startsWith("'") && defaultValue.endsWith("'"))) {
      defaultValue = defaultValue.substring(1, defaultValue.length - 1);
    }
    
    // Remove any trailing parts after the default value
    final spaceIndex = defaultValue.indexOf(' ');
    if (spaceIndex != -1) {
      defaultValue = defaultValue.substring(0, spaceIndex);
    }
    
    return defaultValue;
  }
  
  /// Creates an index if it doesn't already exist
  /// 
  /// Parameters:
  /// - [db]: Database instance
  /// - [indexName]: Name of the index to create
  /// - [tableName]: Name of the table to index
  /// - [columnName]: Name of the column to index
  static Future<void> _createIndexIfNotExists(
    Database db,
    String indexName,
    String tableName,
    String columnName
  ) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $tableName($columnName)');
      print('[MigrationHelper] Created index $indexName');
    } catch (e) {
      print('[MigrationHelper] ERROR: Failed to create index $indexName: $e');
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
      
      print('[MigrationHelper] Successfully migrated ${accounts.length} accounts to persons');
    } catch (e) {
      print('[MigrationHelper] ERROR: Failed to migrate accounts to persons: $e');
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
      
      print('[MigrationHelper] Added lending categories');
    } catch (e) {
      print('[MigrationHelper] ERROR: Failed to add lending categories: $e');
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
      
      print('[MigrationHelper] Post-migration tasks completed');
    } catch (e) {
      print('[MigrationHelper] ERROR: Post-migration tasks failed: $e');
    }
  }

  /// Migration to version 5: Add user profile table
  static Future<void> _migrateToV5(Database db) async {
    try {
      // Create user profile table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
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
      
      print('[MigrationHelper] Migration to v5 completed successfully - User profile table created');
    } catch (e) {
      print('[MigrationHelper] ERROR: Migration to v5 failed: $e');
      rethrow;
    }
  }

  /// Migration to version 6: Add imagePaths column to transactions table
  static Future<void> _migrateToV6(Database db) async {
    try {
      // Add imagePaths column to transactions table
      await _addColumnIfNotExists(db, 'transactions', 'imagePaths', 'TEXT');
      
      print('[MigrationHelper] Migration to v6 completed successfully - imagePaths column added to transactions table');
    } catch (e) {
      print('[MigrationHelper] ERROR: Migration to v6 failed: $e');
      rethrow;
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