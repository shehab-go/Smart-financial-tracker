class CurrencyModel {
  final int? id;
  final String name;

  CurrencyModel({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'],
      name: map['name'],
    );
  }

  CurrencyModel copyWith({
    int? id,
    String? name,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Default currencies
  static CurrencyModel defaultLocal() {
    return CurrencyModel(
      name: 'محلي',
    );
  }

  static List<CurrencyModel> getDefaultCurrencies() {
    return [
      CurrencyModel(
        name: 'محلي',
      ),
      CurrencyModel(
        name: 'ريال سعودي',
      ),
      CurrencyModel(
        name: 'دولار أمريكي',
      ),
    ];
  }
}
