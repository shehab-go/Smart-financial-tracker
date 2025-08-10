class TransactionModel {
  final int? id;
  final int accountId;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String category;
  final DateTime date;
  final String? description; // Optional description for the transaction

  TransactionModel({
    this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
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
    );
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? description,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
