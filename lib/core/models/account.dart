class AccountCurrencyStats {
  final String currencyName;
  final double totalDebit;
  final double totalCredit;
  final int transactionCount;

  AccountCurrencyStats({
    required this.currencyName,
    required this.totalDebit,
    required this.totalCredit,
    required this.transactionCount,
  });

  factory AccountCurrencyStats.fromMap(Map<String, dynamic> map) {
    return AccountCurrencyStats(
      currencyName: map['currencyName'] ?? 'محلي',
      totalDebit: (map['totalDebit'] ?? 0.0) is num
          ? (map['totalDebit'] ?? 0.0).toDouble()
          : double.tryParse(map['totalDebit'].toString()) ?? 0.0,
      totalCredit: (map['totalCredit'] ?? 0.0) is num
          ? (map['totalCredit'] ?? 0.0).toDouble()
          : double.tryParse(map['totalCredit'].toString()) ?? 0.0,
      transactionCount: (map['transactionCount'] ?? 0) is int
          ? map['transactionCount'] ?? 0
          : int.tryParse(map['transactionCount'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currencyName': currencyName,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'transactionCount': transactionCount,
    };
  }
}

class AccountModel {
  final int? id;
  final String name;
  final String category;
  final String currencyName;
  final String? phone;
  final String? address;
  final String? workDetails;
  // Calculated fields (not stored in accounts table directly)
  final int transactionCount;
  final double totalDebit;
  final double totalCredit;
  final DateTime createdDate;
  final DateTime lastTransactionDate;
  final List<AccountCurrencyStats> currencyStats;

  AccountModel({
    this.id,
    required this.name,
    required this.category,
    this.currencyName = 'محلي',
    this.phone,
    this.address,
    this.workDetails,
    required this.createdDate,
    DateTime? lastTransactionDate,
    this.transactionCount = 0,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.currencyStats = const [],
  }) : lastTransactionDate = lastTransactionDate ?? createdDate;

  Map<String, dynamic> toMap() {
    // Only base account fields saved; calculated fields ignored

    return {
      'id': id,
      'name': name,
      'category': category,
      'currencyName': currencyName,
      'phone': phone,
      'address': address,
      'workDetails': workDetails,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    // map may contain aggregated columns

    return AccountModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      currencyName: map['currencyName'] ?? 'محلي',
      phone: map['phone'],
      address: map['address'],
      workDetails: map['workDetails'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      lastTransactionDate: map['lastTransactionDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastTransactionDate']) : null,
      transactionCount: (map['transactionCount'] ?? 0) is int ? map['transactionCount'] ?? 0 : int.tryParse(map['transactionCount'].toString()) ?? 0,
      totalDebit: (map['totalDebit'] ?? 0.0) is num ? (map['totalDebit'] ?? 0.0).toDouble() : double.tryParse(map['totalDebit'].toString()) ?? 0.0,
      totalCredit: (map['totalCredit'] ?? 0.0) is num ? (map['totalCredit'] ?? 0.0).toDouble() : double.tryParse(map['totalCredit'].toString()) ?? 0.0,
      currencyStats: map['currencyStats'] as List<AccountCurrencyStats>? ?? const [],
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? category,
    String? currencyName,
    String? phone,
    String? address,
    String? workDetails,
    DateTime? createdDate,
    DateTime? lastTransactionDate,
    int? transactionCount,
    double? totalDebit,
    double? totalCredit,
    List<AccountCurrencyStats>? currencyStats,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currencyName: currencyName ?? this.currencyName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      workDetails: workDetails ?? this.workDetails,
      createdDate: createdDate ?? this.createdDate,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      transactionCount: transactionCount ?? this.transactionCount,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      currencyStats: currencyStats ?? this.currencyStats,
    );
  }
}

