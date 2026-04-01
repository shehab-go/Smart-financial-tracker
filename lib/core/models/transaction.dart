class TransactionModel {
  final int? id;
  final int accountId;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String category;
  final String currencyName;
  final DateTime date;
  final String? description; // Optional description for the transaction
  final List<String> imagePaths; // Image paths for transaction attachments

  TransactionModel({
    this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    this.currencyName = 'محلي',
    required this.date,
    this.description,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'type': type,
      'category': category,
      'currencyName': currencyName,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'imagePaths': imagePaths.join(','), // Store as comma-separated string
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
      currencyName: (map['currencyName'] as String?) ?? 'محلي',
      date: map['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      description: map['description'],
      imagePaths: map['imagePaths'] != null && map['imagePaths'].toString().isNotEmpty
          ? map['imagePaths'].toString().split(',')
          : [],
    );
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    double? amount,
    String? type,
    String? category,
    String? currencyName,
    DateTime? date,
    String? description,
    List<String>? imagePaths,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      currencyName: currencyName ?? this.currencyName,
      date: date ?? this.date,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
