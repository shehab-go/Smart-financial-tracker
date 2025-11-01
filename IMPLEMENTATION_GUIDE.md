# Implementation Guide: Priority Enhancements

This guide provides step-by-step implementation for the most impactful improvements to your lending management app.

## Priority 1: Enhanced Person Management

### Step 1: Create Enhanced Person Model

Create `lib/core/models/person.dart`:

```dart
class PersonModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final double creditLimit;
  final CreditRating rating;
  final DateTime createdDate;
  final String? profilePhoto;
  
  // Calculated fields
  final double totalBorrowed;
  final double totalRepaid;
  final double currentBalance;
  final int lendingHistory;

  PersonModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.creditLimit = 0.0,
    this.rating = CreditRating.good,
    required this.createdDate,
    this.profilePhoto,
    this.totalBorrowed = 0.0,
    this.totalRepaid = 0.0,
    this.currentBalance = 0.0,
    this.lendingHistory = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'creditLimit': creditLimit,
      'rating': rating.index,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'profilePhoto': profilePhoto,
    };
  }

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      creditLimit: (map['creditLimit'] ?? 0.0).toDouble(),
      rating: CreditRating.values[map['rating'] ?? 1],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      profilePhoto: map['profilePhoto'],
      totalBorrowed: (map['totalBorrowed'] ?? 0.0).toDouble(),
      totalRepaid: (map['totalRepaid'] ?? 0.0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      lendingHistory: map['lendingHistory'] ?? 0,
    );
  }

  PersonModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? creditLimit,
    CreditRating? rating,
    DateTime? createdDate,
    String? profilePhoto,
    double? totalBorrowed,
    double? totalRepaid,
    double? currentBalance,
    int? lendingHistory,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      creditLimit: creditLimit ?? this.creditLimit,
      rating: rating ?? this.rating,
      createdDate: createdDate ?? this.createdDate,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      totalBorrowed: totalBorrowed ?? this.totalBorrowed,
      totalRepaid: totalRepaid ?? this.totalRepaid,
      currentBalance: currentBalance ?? this.currentBalance,
      lendingHistory: lendingHistory ?? this.lendingHistory,
    );
  }
}

enum CreditRating {
  excellent, // ممتاز
  good,      // جيد
  fair,      // مقبول
  poor,      // ضعيف
  blocked    // محظور
}

extension CreditRatingExtension on CreditRating {
  String get arabicName {
    switch (this) {
      case CreditRating.excellent:
        return 'ممتاز';
      case CreditRating.good:
        return 'جيد';
      case CreditRating.fair:
        return 'مقبول';
      case CreditRating.poor:
        return 'ضعيف';
      case CreditRating.blocked:
        return 'محظور';
    }
  }

  Color get color {
    switch (this) {
      case CreditRating.excellent:
        return Colors.green;
      case CreditRating.good:
        return Colors.lightGreen;
      case CreditRating.fair:
        return Colors.orange;
      case CreditRating.poor:
        return Colors.red;
      case CreditRating.blocked:
        return Colors.grey;
    }
  }
}
```

### Step 2: Update Database Schema

Update `lib/core/db/database_helper.dart` to add persons table:

```dart
// Add to _createDatabase method
await db.execute('''
  CREATE TABLE persons (
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

// Update accounts table to link to persons
await db.execute('''
  ALTER TABLE accounts ADD COLUMN personId INTEGER REFERENCES persons(id)
''');

// Add indexes for better performance
await db.execute('CREATE INDEX idx_persons_name ON persons(name)');
await db.execute('CREATE INDEX idx_accounts_person ON accounts(personId)');
```

### Step 3: Add Person CRUD Operations

Add to `DatabaseHelper` class:

```dart
// Person operations
Future<List<PersonModel>> getPersons() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT p.*, 
           COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE 0 END), 0) as totalBorrowed,
           COALESCE(SUM(CASE WHEN t.type = 'credit' THEN t.amount ELSE 0 END), 0) as totalRepaid,
           COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE -t.amount END), 0) as currentBalance,
           COUNT(DISTINCT t.id) as lendingHistory
    FROM persons p
    LEFT JOIN accounts a ON a.personId = p.id
    LEFT JOIN transactions t ON t.accountId = a.id
    GROUP BY p.id
    ORDER BY p.name
  ''');
  return List.generate(maps.length, (i) => PersonModel.fromMap(maps[i]));
}

Future<int> insertPerson(PersonModel person) async {
  final db = await database;
  return await db.insert('persons', person.toMap());
}

Future<int> updatePerson(PersonModel person) async {
  final db = await database;
  return await db.update(
    'persons',
    person.toMap(),
    where: 'id = ?',
    whereArgs: [person.id],
  );
}

Future<int> deletePerson(int id) async {
  final db = await database;
  // Delete associated accounts and transactions (cascade)
  await db.delete('transactions', where: 'accountId IN (SELECT id FROM accounts WHERE personId = ?)', whereArgs: [id]);
  await db.delete('accounts', where: 'personId = ?', whereArgs: [id]);
  return await db.delete('persons', where: 'id = ?', whereArgs: [id]);
}

Future<PersonModel?> getPersonById(int id) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
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
  ''', [id]);
  
  if (maps.isNotEmpty) {
    return PersonModel.fromMap(maps.first);
  }
  return null;
}
```

## Priority 2: Enhanced Transaction Model with Due Dates

### Step 1: Update Transaction Model

Update `lib/core/models/transaction.dart`:

```dart
class TransactionModel {
  final int? id;
  final int accountId;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String category;
  final DateTime date;
  final String? description;
  
  // New lending-specific fields
  final DateTime? dueDate;
  final double? interestRate;
  final String? guarantor;
  final LendingStatus status;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  TransactionModel({
    this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.dueDate,
    this.interestRate,
    this.guarantor,
    this.status = LendingStatus.active,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'interestRate': interestRate,
      'guarantor': guarantor,
      'status': status.index,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      accountId: map['accountId'],
      amount: map['amount'] is num
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount'].toString()) ?? 0.0,
      type: map['type'],
      category: map['category'],
      date: map['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      description: map['description'],
      dueDate: map['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      interestRate: map['interestRate']?.toDouble(),
      guarantor: map['guarantor'],
      status: LendingStatus.values[map['status'] ?? 0],
      reminderEnabled: (map['reminderEnabled'] ?? 1) == 1,
      reminderDaysBefore: map['reminderDaysBefore'] ?? 3,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (dueDate == null || type != 'debit') return false;
    return DateTime.now().isAfter(dueDate!) && status == LendingStatus.active;
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  double get totalAmountWithInterest {
    if (interestRate == null || interestRate == 0) return amount;
    final days = DateTime.now().difference(date).inDays;
    return amount + (amount * interestRate! * days / 365 / 100);
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? description,
    DateTime? dueDate,
    double? interestRate,
    String? guarantor,
    LendingStatus? status,
    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      guarantor: guarantor ?? this.guarantor,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }
}

enum LendingStatus {
  active,        // نشط
  paid,          // مدفوع
  overdue,       // متأخر
  partiallyPaid  // مدفوع جزئياً
}

extension LendingStatusExtension on LendingStatus {
  String get arabicName {
    switch (this) {
      case LendingStatus.active:
        return 'نشط';
      case LendingStatus.paid:
        return 'مدفوع';
      case LendingStatus.overdue:
        return 'متأخر';
      case LendingStatus.partiallyPaid:
        return 'مدفوع جزئياً';
    }
  }

  Color get color {
    switch (this) {
      case LendingStatus.active:
        return Colors.blue;
      case LendingStatus.paid:
        return Colors.green;
      case LendingStatus.overdue:
        return Colors.red;
      case LendingStatus.partiallyPaid:
        return Colors.orange;
    }
  }
}
```

### Step 2: Update Database Schema for Enhanced Transactions

```dart
// Add to database migration
await db.execute('''
  ALTER TABLE transactions ADD COLUMN dueDate INTEGER
''');
await db.execute('''
  ALTER TABLE transactions ADD COLUMN interestRate REAL
''');
await db.execute('''
  ALTER TABLE transactions ADD COLUMN guarantor TEXT
''');
await db.execute('''
  ALTER TABLE transactions ADD COLUMN status INTEGER DEFAULT 0
''');
await db.execute('''
  ALTER TABLE transactions ADD COLUMN reminderEnabled INTEGER DEFAULT 1
''');
await db.execute('''
  ALTER TABLE transactions ADD COLUMN reminderDaysBefore INTEGER DEFAULT 3
''');

// Add indexes
await db.execute('CREATE INDEX idx_transactions_due_date ON transactions(dueDate)');
await db.execute('CREATE INDEX idx_transactions_status ON transactions(status)');
```

## Priority 3: Enhanced Add Transaction Dialog

### Step 1: Update Add Transaction Dialog

Update `lib/features/accounts/presentation/dialogs/add_transaction_dialog.dart`:

```dart
class AddTransactionDialog extends StatefulWidget {
  final String category;
  final int? accountId;
  final TransactionModel? transaction;
  final PersonModel? person; // New parameter

  const AddTransactionDialog({
    super.key,
    required this.category,
    this.accountId,
    this.transaction,
    this.person,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _guarantorController = TextEditingController();
  final _interestRateController = TextEditingController();
  
  String _selectedType = 'debit';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  bool _isNewAccount = false;
  bool _isEditing = false;
  bool _reminderEnabled = true;
  int _reminderDaysBefore = 3;
  List<CurrencyModel> _currencies = [];
  List<PersonModel> _persons = [];
  PersonModel? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaction != null;
    _isNewAccount = widget.accountId == null && !_isEditing;
    _selectedPerson = widget.person;
    
    if (_isEditing) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _detailsController.text = t.description ?? '';
      _selectedType = t.type;
      _selectedDate = t.date;
      _selectedDueDate = t.dueDate;
      _guarantorController.text = t.guarantor ?? '';
      _interestRateController.text = t.interestRate?.toString() ?? '';
      _reminderEnabled = t.reminderEnabled;
      _reminderDaysBefore = t.reminderDaysBefore;
    }
    
    _initData();
  }

  Future<void> _initData() async {
    await _initCurrency();
    await _initPersons();
  }

  Future<void> _initPersons() async {
    final persons = await DatabaseHelper().getPersons();
    if (mounted) {
      setState(() {
        _persons = persons;
      });
    }
  }

  // ... existing methods ...

  Widget _buildDueDatePicker() {
    return ListTile(
      title: const Text('تاريخ الاستحقاق (اختياري)'),
      subtitle: Text(
        _selectedDueDate != null 
          ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
          : 'لم يتم تحديد تاريخ',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedDueDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDueDate = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) {
                setState(() => _selectedDueDate = date);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonSelector() {
    return DropdownButtonFormField<PersonModel>(
      value: _selectedPerson,
      decoration: const InputDecoration(
        labelText: 'اختر الشخص',
        hintText: 'اختر من القائمة أو أضف جديد',
      ),
      items: [
        const DropdownMenuItem<PersonModel>(
          value: null,
          child: Text('شخص جديد'),
        ),
        ..._persons.map((person) => DropdownMenuItem<PersonModel>(
          value: person,
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: person.rating.color,
                child: Text(
                  person.name[0],
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(person.name),
                    Text(
                      'الرصيد: ${person.currentBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: person.currentBalance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
      onChanged: (person) {
        setState(() {
          _selectedPerson = person;
          if (person != null) {
            _accountNameController.text = person.name;
            _phoneController.text = person.phone ?? '';
            _isNewAccount = false;
          } else {
            _accountNameController.clear();
            _phoneController.clear();
            _isNewAccount = true;
          }
        });
      },
    );
  }

  Widget _buildInterestRateField() {
    if (_selectedType != 'debit') return const SizedBox.shrink();
    
    return TextFormField(
      controller: _interestRateController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'معدل الفائدة السنوي % (اختياري)',
        hintText: '0.0',
      ),
    );
  }

  Widget _buildGuarantorField() {
    if (_selectedType != 'debit') return const SizedBox.shrink();
    
    return TextFormField(
      controller: _guarantorController,
      decoration: const InputDecoration(
        labelText: 'الضامن (اختياري)',
        hintText: 'اسم الشخص الضامن',
      ),
    );
  }

  Widget _buildReminderSettings() {
    if (_selectedType != 'debit' || _selectedDueDate == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        SwitchListTile(
          title: const Text('تفعيل التذكير'),
          value: _reminderEnabled,
          onChanged: (value) => setState(() => _reminderEnabled = value),
        ),
        if (_reminderEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('التذكير قبل'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _reminderDaysBefore,
                  items: [1, 2, 3, 5, 7, 14].map((days) => DropdownMenuItem(
                    value: days,
                    child: Text('$days ${days == 1 ? "يوم" : "أيام"}'),
                  )).toList(),
                  onChanged: (value) => setState(() => _reminderDaysBefore = value ?? 3),
                ),
                const Text('من تاريخ الاستحقاق'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل معاملة' : 'إضافة معاملة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEditing) _buildPersonSelector(),
              if (_isNewAccount || _selectedPerson == null)
                TextFormField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(hintText: 'اسم الشخص'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'المبلغ'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'debit',
                        groupValue: _selectedType,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('عليه', style: TextStyle(color: Colors.red)),
                        onChanged: (val) => setState(() => _selectedType = val ?? 'debit'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'credit',
                        groupValue: _selectedType,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('له', style: TextStyle(color: Colors.green)),
                        onChanged: (val) => setState(() => _selectedType = val ?? 'credit'),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDatePicker(context),
              _buildDueDatePicker(),
              _buildInterestRateField(),
              _buildGuarantorField(),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(hintText: 'التفاصيل'),
              ),
              if (_isNewAccount || _selectedPerson == null)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(hintText: 'رقم الهاتف'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.contact_phone),
                      onPressed: _pickContact,
                    )
                  ],
                ),
              _buildReminderSettings(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator() : const Text('حفظ'),
        )
      ],
    );
  }

  // Update _save method to handle new fields
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      int accountId = widget.accountId ?? -1;
      int? personId = _selectedPerson?.id;
      
      // Create or update person if needed
      if (_selectedPerson == null && (_isNewAccount || widget.accountId == null)) {
        final person = PersonModel(
          name: _accountNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          createdDate: DateTime.now(),
        );
        personId = await DatabaseHelper().insertPerson(person);
      }
      
      // Create account if needed
      if (_isNewAccount || widget.accountId == null) {
        final account = AccountModel(
          name: _accountNameController.text.trim(),
          category: widget.category,
          currencyCode: _currencies.isNotEmpty ? _currencies.first.symbol : 'LOC',
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          createdDate: DateTime.now(),
        );
        accountId = await DatabaseHelper().insertAccount(account);
        
        // Link account to person
        if (personId != null) {
          await DatabaseHelper().linkAccountToPerson(accountId, personId);
        }
      }

      final transaction = TransactionModel(
        id: _isEditing ? widget.transaction!.id : null,
        accountId: accountId,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: widget.category,
        date: _selectedDate,
        description: _detailsController.text.trim(),
        dueDate: _selectedDueDate,
        interestRate: _interestRateController.text.isEmpty 
            ? null 
            : double.tryParse(_interestRateController.text),
        guarantor: _guarantorController.text.trim().isEmpty 
            ? null 
            : _guarantorController.text.trim(),
        reminderEnabled: _reminderEnabled,
        reminderDaysBefore: _reminderDaysBefore,
      );

      if (_isEditing) {
        await DatabaseHelper().updateTransaction(transaction);
      } else {
        await DatabaseHelper().insertTransaction(transaction);
        
        // Schedule reminder if enabled
        if (_reminderEnabled && _selectedDueDate != null && _selectedType == 'debit') {
          await _schedulePaymentReminder(transaction);
        }
      }
      
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _schedulePaymentReminder(TransactionModel transaction) async {
    // Implementation for scheduling local notifications
    // This would use flutter_local_notifications package
  }
}
```

## Priority 4: Enhanced Dashboard

### Step 1: Create Lending Dashboard Widget

Create `lib/features/home/presentation/widgets/lending_dashboard.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/person.dart';
import '../../../core/models/transaction.dart';
import '../../../core/db/database_helper.dart';

class LendingDashboard extends StatefulWidget {
  const LendingDashboard({super.key});

  @override
  State<LendingDashboard> createState() => _LendingDashboardState();
}

class _LendingDashboardState extends State<LendingDashboard> {
  double _totalLent = 0.0;
  double _totalReceived = 0.0;
  double _outstanding = 0.0;
  int _activeLoans = 0;
  int _overdueLoans = 0;
  List<PersonModel> _topBorrowers = [];
  List<TransactionModel> _upcomingPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseHelper();
      
      // Get summary statistics
      final summary = await db.getLendingSummary();
      _totalLent = summary['totalLent'] ?? 0.0;
      _totalReceived = summary['totalReceived'] ?? 0.0;
      _outstanding = _totalLent - _totalReceived;
      _activeLoans = summary['activeLoans'] ?? 0;
      _overdueLoans = summary['overdueLoans'] ?? 0;
      
      // Get top borrowers
      _topBorrowers = await db.getTopBorrowers(limit: 5);
      
      // Get upcoming payments
      _upcomingPayments = await db.getUpcomingPayments(days: 7);
      
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            if (_overdueLoans > 0) ..[
              _buildOverdueSection(),
              const SizedBox(height: 16),
            ],
            if (_upcomingPayments.isNotEmpty) ..[
              _buildUpcomingPayments(),
              const SizedBox(height: 16),
            ],
            _buildTopBorrowers(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'إجمالي المُقرض',
            amount: _totalLent,
            color: Colors.blue,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'إجمالي المُستلم',
            amount: _totalReceived,
            color: Colors.green,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat('#,##0').format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'إقراض جديد',
                  onTap: () => _showNewLendingDialog(),
                ),
                _buildQuickActionButton(
                  icon: Icons.payment,
                  label: 'تسجيل دفعة',
                  onTap: () => _showPaymentDialog(),
                ),
                _buildQuickActionButton(
                  icon: Icons.assessment,
                  label: 'التقارير',
                  onTap: () => _showReportsDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مدفوعات متأخرة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  Text(
                    '$_overdueLoans قرض متأخر',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showOverdueLoans(),
              child: const Text('عرض'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPayments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مدفوعات قادمة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._upcomingPayments.take(3).map((payment) => _buildUpcomingPaymentTile(payment)),
            if (_upcomingPayments.length > 3)
              TextButton(
                onPressed: () => _showAllUpcomingPayments(),
                child: Text('عرض الكل (${_upcomingPayments.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPaymentTile(TransactionModel payment) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: payment.isOverdue ? Colors.red : Colors.orange,
        child: Text(
          payment.daysUntilDue.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text('مبلغ: ${NumberFormat('#,##0').format(payment.amount)}'),
      subtitle: Text(
        'الاستحقاق: ${DateFormat('dd/MM/yyyy').format(payment.dueDate!)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.notification_add),
        onPressed: () => _sendReminder(payment),
      ),
    );
  }

  Widget _buildTopBorrowers() {
    if (_topBorrowers.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أكبر المقترضين',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._topBorrowers.map((person) => _buildBorrowerTile(person)),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowerTile(PersonModel person) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: person.rating.color,
        child: Text(
          person.name[0],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(person.name),
      subtitle: Text(
        'الرصيد: ${NumberFormat('#,##0').format(person.currentBalance)}',
      ),
      trailing: Chip(
        label: Text(
          person.rating.arabicName,
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: person.rating.color.withOpacity(0.2),
      ),
      onTap: () => _showPersonDetails(person),
    );
  }

  // Action methods
  void _showNewLendingDialog() {
    // Navigate to add transaction dialog with lending category
  }

  void _showPaymentDialog() {
    // Show dialog to record a payment
  }

  void _showReportsDialog() {
    // Show reports options
  }

  void _showOverdueLoans() {
    // Navigate to overdue loans screen
  }

  void _showAllUpcomingPayments() {
    // Navigate to upcoming payments screen
  }

  void _sendReminder(TransactionModel payment) {
    // Send payment reminder
  }

  void _showPersonDetails(PersonModel person) {
    // Navigate to person details screen
  }
}
```

## Next Steps

1. **Test the Enhanced Person Management**: Create and test the new person model and database operations
2. **Update Transaction Dialog**: Implement the enhanced transaction dialog with due dates and interest
3. **Create Dashboard**: Build the lending dashboard with summary cards and quick actions
4. **Add Reminder System**: Implement local notifications for payment reminders
5. **Enhance Reporting**: Add lending-specific reports and analytics

This implementation guide provides the foundation for transforming your basic lending tracker into a comprehensive lending management system. Each step builds upon the previous one, ensuring a smooth development process.