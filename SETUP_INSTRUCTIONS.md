# Setup Instructions for Enhanced Lending Management

This guide will help you implement the professional recommendations step by step.

## Phase 1: Database Enhancement (Priority: HIGH)

### Step 1: Update Database Helper

1. **Update `lib/core/db/database_helper.dart`**:
   - Change the database version from 1 to 2
   - Add the migration helper import
   - Update the `_createDatabase` method to handle migrations

```dart
// Add this import at the top
import 'migration_helper.dart';

// Update the database version
static const int _databaseVersion = 2;

// Update the _createDatabase method
Future<Database> _createDatabase(String path) async {
  return await openDatabase(
    path,
    version: _databaseVersion,
    onCreate: _onCreate,
    onUpgrade: MigrationHelper.migrate, // Add this line
  );
}
```

### Step 2: Add New Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # New dependencies for enhanced features
  flutter_local_notifications: ^17.0.0
  url_launcher: ^6.2.2
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  flutter_contacts: ^1.1.7+1
  
dev_dependencies:
  # Existing dev dependencies...
```

Run: `flutter pub get`

### Step 3: Test Database Migration

1. **Create a test file** `test/migration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/core/db/migration_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database migration should work', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, version) async {
        // Create old schema (version 1)
        await db.execute('''
          CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT)
        ''');
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY,
            name TEXT,
            category TEXT,
            currencyCode TEXT,
            phone TEXT,
            createdDate INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY,
            accountId INTEGER,
            amount REAL,
            type TEXT,
            category TEXT,
            date INTEGER,
            description TEXT
          )
        ''');
      },
      onUpgrade: MigrationHelper.migrate,
    );

    // Test that new tables and columns exist
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((t) => t['name']).toList();
    
    expect(tableNames, contains('persons'));
    
    // Test that new columns exist in transactions
    final transactionInfo = await db.rawQuery('PRAGMA table_info(transactions)');
    final columnNames = transactionInfo.map((c) => c['name']).toList();
    
    expect(columnNames, contains('dueDate'));
    expect(columnNames, contains('interestRate'));
    expect(columnNames, contains('status'));
    
    await db.close();
  });
}
```

Run: `flutter test test/migration_test.dart`

## Phase 2: Enhanced Models (Priority: HIGH)

### Step 1: Create Person Model

1. **Create** `lib/core/models/person.dart` (use the code from IMPLEMENTATION_GUIDE.md)

### Step 2: Update Transaction Model

1. **Update** `lib/core/models/transaction.dart` (use the enhanced version from IMPLEMENTATION_GUIDE.md)

### Step 3: Update Database Helper with New Operations

1. **Add to** `lib/core/db/database_helper.dart`:
   - Import the new models
   - Add person CRUD operations
   - Add the extension methods from migration_helper.dart

## Phase 3: Enhanced UI (Priority: MEDIUM)

### Step 1: Update Add Transaction Dialog

1. **Update** `lib/features/accounts/presentation/dialogs/add_transaction_dialog.dart`
   - Use the enhanced version from IMPLEMENTATION_GUIDE.md
   - Add person selection
   - Add due date picker
   - Add interest rate field

### Step 2: Create Lending Dashboard

1. **Create** `lib/features/home/presentation/widgets/lending_dashboard.dart`
2. **Update** `lib/features/home/presentation/screens/home_screen.dart` to include the dashboard

### Step 3: Create Person Management Screen

1. **Create** `lib/features/persons/` directory structure:
   ```
   lib/features/persons/
   ├── presentation/
   │   ├── screens/
   │   │   ├── persons_screen.dart
   │   │   └── person_details_screen.dart
   │   ├── widgets/
   │   │   ├── person_card.dart
   │   │   └── person_stats_widget.dart
   │   └── dialogs/
   │       └── add_person_dialog.dart
   └── application/
       └── persons_controller.dart
   ```

## Phase 4: Notifications & Reminders (Priority: MEDIUM)

### Step 1: Setup Local Notifications

1. **Create** `lib/core/services/notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  static Future<void> schedulePaymentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Payment Reminders',
          channelDescription: 'Reminders for upcoming payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
```

2. **Update** `lib/main.dart` to initialize notifications:

```dart
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(MyApp());
}
```

## Phase 5: Testing & Validation

### Step 1: Create Test Data

1. **Create** `test/test_data.dart`:

```dart
import '../lib/core/models/person.dart';
import '../lib/core/models/transaction.dart';

class TestData {
  static List<PersonModel> getTestPersons() {
    return [
      PersonModel(
        id: 1,
        name: 'أحمد محمد',
        phone: '+966501234567',
        email: 'ahmed@example.com',
        createdDate: DateTime.now().subtract(const Duration(days: 30)),
        rating: CreditRating.good,
        creditLimit: 10000,
      ),
      PersonModel(
        id: 2,
        name: 'فاطمة علي',
        phone: '+966507654321',
        createdDate: DateTime.now().subtract(const Duration(days: 15)),
        rating: CreditRating.excellent,
        creditLimit: 15000,
      ),
    ];
  }

  static List<TransactionModel> getTestTransactions() {
    return [
      TransactionModel(
        id: 1,
        accountId: 1,
        amount: 5000,
        type: 'debit',
        category: 'قروض شخصية',
        date: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 20)),
        interestRate: 5.0,
        description: 'قرض شخصي',
        status: LendingStatus.active,
      ),
      TransactionModel(
        id: 2,
        accountId: 2,
        amount: 2000,
        type: 'credit',
        category: 'قروض شخصية',
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'دفعة جزئية',
        status: LendingStatus.paid,
      ),
    ];
  }
}
```

### Step 2: Test the Enhanced Features

1. Run the app and test:
   - Creating new persons
   - Adding transactions with due dates
   - Viewing the lending dashboard
   - Setting up payment reminders

## Phase 6: Advanced Features (Priority: LOW)

### Optional Enhancements:

1. **Interest Calculation Service**
2. **PDF Report Generation with Lending Details**
3. **WhatsApp Integration for Reminders**
4. **Backup/Restore with Person Data**
5. **Advanced Analytics Dashboard**

## Troubleshooting

### Common Issues:

1. **Database Migration Fails**:
   - Check that all column additions are wrapped in try-catch
   - Verify that the migration helper is properly imported
   - Test with a fresh database first

2. **Notification Permissions**:
   - Add notification permissions to Android manifest
   - Handle iOS notification permissions properly

3. **Performance Issues**:
   - Ensure database indexes are created
   - Use pagination for large datasets
   - Optimize queries with proper WHERE clauses

## Success Metrics

After implementation, you should have:

✅ Enhanced person management with credit ratings
✅ Transactions with due dates and interest calculation
✅ Payment reminders and notifications
✅ Professional lending dashboard
✅ Improved data organization and reporting
✅ Better user experience for lending management

## Next Steps

Once Phase 1-3 are complete:
1. Gather user feedback
2. Implement advanced features based on usage patterns
3. Consider adding web dashboard for desktop management
4. Explore integration with accounting software

---

**Note**: Implement these changes incrementally. Test each phase thoroughly before moving to the next one. Keep backups of your current working version before making major changes.