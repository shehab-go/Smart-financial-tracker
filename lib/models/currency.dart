class CurrencyModel {
  final int? id;
  final String name;
  final String nameArabic;
  final String symbol;
  final String code;
  final bool isDefault;

  CurrencyModel({
    this.id,
    required this.name,
    required this.nameArabic,
    required this.symbol,
    required this.code,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameArabic': nameArabic,
      'symbol': symbol,
      'code': code,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'],
      name: map['name'],
      nameArabic: map['nameArabic'],
      symbol: map['symbol'],
      code: map['code'],
      isDefault: map['isDefault'] == 1,
    );
  }

  CurrencyModel copyWith({
    int? id,
    String? name,
    String? nameArabic,
    String? symbol,
    String? code,
    bool? isDefault,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameArabic: nameArabic ?? this.nameArabic,
      symbol: symbol ?? this.symbol,
      code: code ?? this.code,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Default currencies
  static CurrencyModel defaultLocal() {
    return CurrencyModel(
      name: 'Local',
      nameArabic: 'محلي',
      symbol: '¤',
      code: 'LOC',
      isDefault: true,
    );
  }

  static List<CurrencyModel> getDefaultCurrencies() {
    return [
      CurrencyModel(
        name: 'Local',
        nameArabic: 'محلي',
        symbol: '¤',
        code: 'محلي',
        isDefault: true,
      ),
      CurrencyModel(
        name: 'Saudi Riyal',
        nameArabic: 'ريال سعودي',
        symbol: 'ر.س',
        code: 'سعودي',
      ),
      CurrencyModel(
        name: 'US Dollar',
        nameArabic: 'دولار أمريكي',
        symbol: '\$',
        code: 'دولار',
      ),
    ];
  }
}
