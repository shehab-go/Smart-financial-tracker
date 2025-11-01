class ExpenseModel {
  final int? id;
  final String name;
  final double amount;
  final String detail;
  final String category;
  final String currency;
  final DateTime createdDate;
  final DateTime? updatedDate;

  ExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.detail,
    this.category = 'مصروفات',
    this.currency = 'محلي',
    required this.createdDate,
    this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'detail': detail,
      'category': category,
      'currency': currency,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'updatedDate': updatedDate?.millisecondsSinceEpoch,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      detail: map['detail'] ?? '',
      category: map['category'] ?? 'مصروفات',
      currency: map['currency'] ?? 'محلي',
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      updatedDate: map['updatedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedDate'])
          : null,
    );
  }

  ExpenseModel copyWith({
    int? id,
    String? name,
    double? amount,
    String? detail,
    String? category,
    String? currency,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      detail: detail ?? this.detail,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, name: $name, amount: $amount, detail: $detail, category: $category, currency: $currency, createdDate: $createdDate, updatedDate: $updatedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.detail == detail &&
        other.category == category &&
        other.currency == currency &&
        other.createdDate == createdDate &&
        other.updatedDate == updatedDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        amount.hashCode ^
        detail.hashCode ^
        category.hashCode ^
        currency.hashCode ^
        createdDate.hashCode ^
        updatedDate.hashCode;
  }
}