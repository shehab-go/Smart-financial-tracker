class CurrencyModel {
  final int? id;
  final String name;
  final String symbol;

  CurrencyModel({
    this.id,
    required this.name,
    required this.symbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
    );
  }

  CurrencyModel copyWith({
    int? id,
    String? name,
    String? symbol,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
    );
  }

  // Default currencies
  static CurrencyModel defaultLocal() {
    return CurrencyModel(
      name: 'محلي',
      symbol: '¤',
    );
  }

  static List<CurrencyModel> getDefaultCurrencies() {
    return [
      CurrencyModel(
        name: 'محلي',
        symbol: '¤',
      ),
      CurrencyModel(
        name: 'ريال سعودي',
        symbol: 'ر.س',
      ),
      CurrencyModel(
        name: 'دولار أمريكي',
        symbol: '\$',
      ),
    ];
  }
}
