class PredefinedCurrency {
  final String name;
  final String code;
  final String symbol;

  const PredefinedCurrency({
    required this.name,
    required this.code,
    required this.symbol,
  });
}

const List<PredefinedCurrency> predefinedCurrencies = [
  PredefinedCurrency(name: 'ريال سعودي', code: 'SAR', symbol: 'ر.س'),
  PredefinedCurrency(name: 'دولار أمريكي', code: 'USD', symbol: '\$'),
  PredefinedCurrency(name: 'يورو', code: 'EUR', symbol: '€'),
  PredefinedCurrency(name: 'درهم إماراتي', code: 'AED', symbol: 'د.إ'),
  PredefinedCurrency(name: 'جنيه مصري', code: 'EGP', symbol: 'ج.م'),
  PredefinedCurrency(name: 'ريال يمني', code: 'YER', symbol: 'ر.ي'),
  PredefinedCurrency(name: 'دينار كويتي', code: 'KWD', symbol: 'د.ك'),
  PredefinedCurrency(name: 'ريال قطري', code: 'QAR', symbol: 'ر.ق'),
  PredefinedCurrency(name: 'ريال عماني', code: 'OMR', symbol: 'ر.ع'),
  PredefinedCurrency(name: 'دينار بحريني', code: 'BHD', symbol: 'د.ب'),
  PredefinedCurrency(name: 'دينار أردني', code: 'JOD', symbol: 'د.أ'),
  PredefinedCurrency(name: 'ليرة سورية', code: 'SYP', symbol: 'ل.س'),
  PredefinedCurrency(name: 'ليرة لبنانية', code: 'LBP', symbol: 'ل.ل'),
  PredefinedCurrency(name: 'دينار عراقي', code: 'IQD', symbol: 'د.ع'),
  PredefinedCurrency(name: 'درهم مغربي', code: 'MAD', symbol: 'د.م'),
  PredefinedCurrency(name: 'دينار تونسي', code: 'TND', symbol: 'د.ت'),
  PredefinedCurrency(name: 'دينار ليبي', code: 'LYD', symbol: 'د.ل'),
  PredefinedCurrency(name: 'جنيه سوداني', code: 'SDG', symbol: 'ج.س'),
  PredefinedCurrency(name: 'أوقية موريتانية', code: 'MRU', symbol: 'أ.م'),
  PredefinedCurrency(name: 'فرنك جيبوتي', code: 'DJF', symbol: 'ف.ج'),
  PredefinedCurrency(name: 'شلن صومالي', code: 'SOS', symbol: 'ش.ص'),
  PredefinedCurrency(name: 'جنيه إسترليني', code: 'GBP', symbol: '£'),
  PredefinedCurrency(name: 'دولار كندي', code: 'CAD', symbol: 'C\$'),
  PredefinedCurrency(name: 'دولار أسترالي', code: 'AUD', symbol: 'A\$'),
  PredefinedCurrency(name: 'ين ياباني', code: 'JPY', symbol: '¥'),
  PredefinedCurrency(name: 'يوان صيني', code: 'CNY', symbol: '¥'),
  PredefinedCurrency(name: 'روبية هندية', code: 'INR', symbol: '₹'),
  PredefinedCurrency(name: 'ليرة تركية', code: 'TRY', symbol: '₺'),
  PredefinedCurrency(name: 'روبل روسي', code: 'RUB', symbol: '₽'),
  PredefinedCurrency(name: 'فرنك سويسري', code: 'CHF', symbol: 'CHF'),
];

class CurrencyModel {
  final int? id;
  final String name;

  static final Map<String, String> _symbolCache = <String, String>{};

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

  static String symbolFor(String currencyDisplayName) {
    final String name = currencyDisplayName.trim();
    final cached = _symbolCache[name];
    if (cached != null) return cached;

    if (name.isEmpty || name == 'all') {
      _symbolCache[name] = '';
      return '';
    }
    if (name == 'محلي') {
      _symbolCache[name] = 'م';
      return 'م';
    }

    // Search predefined list
    for (final c in predefinedCurrencies) {
      if (c.name == name || c.code == name) {
        _symbolCache[name] = c.symbol;
        return c.symbol;
      }
    }

    _symbolCache[name] = name;
    return name;
  }

  static String? codeFor(String currencyDisplayName) {
    final String name = currencyDisplayName.trim();
    if (name.isEmpty || name == 'all') return null;
    if (name == 'محلي') return 'LOCAL';

    // Search predefined list
    for (final c in predefinedCurrencies) {
      if (c.name == name || c.code == name) {
        return c.code;
      }
    }
    return null;
  }
}
