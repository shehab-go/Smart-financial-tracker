class ExpenseAccountModel {
  final int? id;
  final String name;
  final String category;
  final String currencyName;
  final DateTime createdDate;

  /// Aggregated fields (not stored directly in the expense_accounts table)
  final int expenseCount;
  final double totalAmount;

  ExpenseAccountModel({
    this.id,
    required this.name,
    this.category = 'مصروفات',
    this.currencyName = 'محلي',
    required this.createdDate,
    this.expenseCount = 0,
    this.totalAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    // Only base table fields are persisted.
    return {
      'id': id,
      'name': name,
      'category': category,
      'currencyName': currencyName,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory ExpenseAccountModel.fromMap(Map<String, dynamic> map) {
    return ExpenseAccountModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'مصروفات',
      currencyName: map['currencyName'] as String? ?? 'محلي',
      createdDate:
          DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
      expenseCount: _parseInt(map['expenseCount']),
      totalAmount: _parseDouble(map['totalAmount']),
    );
  }

  ExpenseAccountModel copyWith({
    int? id,
    String? name,
    String? category,
    String? currencyName,
    DateTime? createdDate,
    int? expenseCount,
    double? totalAmount,
  }) {
    return ExpenseAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currencyName: currencyName ?? this.currencyName,
      createdDate: createdDate ?? this.createdDate,
      expenseCount: expenseCount ?? this.expenseCount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
