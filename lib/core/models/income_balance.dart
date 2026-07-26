class IncomeBalanceModel {
  final int? id;
  final int resourceId;
  final String name;
  final String currencyName;
  final double initialAmount;
  final bool isDefault;
  final DateTime createdDate;

  IncomeBalanceModel({
    this.id,
    required this.resourceId,
    required this.name,
    this.currencyName = 'محلي',
    this.initialAmount = 0.0,
    this.isDefault = false,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    String normalizedCurrency = currencyName;
    if (normalizedCurrency.trim() == 'ريلح يمني') {
      normalizedCurrency = 'ريال يمني';
    }
    return {
      'id': id,
      'resourceId': resourceId,
      'name': name,
      'currencyName': normalizedCurrency,
      'initialAmount': initialAmount,
      'isDefault': isDefault ? 1 : 0,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory IncomeBalanceModel.fromMap(Map<String, dynamic> map) {
    String normalizedCurrency = (map['currencyName'] ?? 'محلي').toString();
    if (normalizedCurrency.trim() == 'ريلح يمني') {
      normalizedCurrency = 'ريال يمني';
    }
    return IncomeBalanceModel(
      id: map['id'],
      resourceId: map['resourceId'],
      name: map['name'] ?? '',
      currencyName: normalizedCurrency,
      initialAmount: (map['initialAmount'] as num?)?.toDouble() ?? 0.0,
      isDefault: (map['isDefault'] ?? 0) == 1,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
    );
  }

  IncomeBalanceModel copyWith({
    int? id,
    int? resourceId,
    String? name,
    String? currencyName,
    double? initialAmount,
    bool? isDefault,
    DateTime? createdDate,
  }) {
    return IncomeBalanceModel(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      name: name ?? this.name,
      currencyName: currencyName ?? this.currencyName,
      initialAmount: initialAmount ?? this.initialAmount,
      isDefault: isDefault ?? this.isDefault,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
