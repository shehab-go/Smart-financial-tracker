class AccountModel {
  final int? id;
  final String name;
  final String category;
  final String currencyCode;
  final String? phone;
  // Calculated fields (not stored in accounts table directly)
  final int transactionCount;
  final double totalDebit;
  final double totalCredit;
  final DateTime createdDate;

  AccountModel({
    this.id,
    required this.name,
    required this.category,
    String this.currencyCode = 'LOC',
    this.phone,
    required this.createdDate,
    this.transactionCount = 0,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
  });

  Map<String, dynamic> toMap() {
    // Only base account fields saved; calculated fields ignored

    return {
      'id': id,
      'name': name,
      'category': category,
      'currencyCode': currencyCode,
      'phone': phone,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    // map may contain aggregated columns

    return AccountModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      currencyCode: map['currencyCode'] ?? 'LOC',
      phone: map['phone'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      transactionCount: (map['transactionCount'] ?? 0) is int ? map['transactionCount'] ?? 0 : int.tryParse(map['transactionCount'].toString()) ?? 0,
      totalDebit: (map['totalDebit'] ?? 0.0) is num ? (map['totalDebit'] ?? 0.0).toDouble() : double.tryParse(map['totalDebit'].toString()) ?? 0.0,
      totalCredit: (map['totalCredit'] ?? 0.0) is num ? (map['totalCredit'] ?? 0.0).toDouble() : double.tryParse(map['totalCredit'].toString()) ?? 0.0,
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? category,
    String? currencyCode,
    String? phone,
    DateTime? createdDate,
    int? transactionCount,
    double? totalDebit,
    double? totalCredit,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currencyCode: currencyCode ?? this.currencyCode,
      phone: phone ?? this.phone,
      createdDate: createdDate ?? this.createdDate,
      transactionCount: transactionCount ?? this.transactionCount,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
    );
  }
}
