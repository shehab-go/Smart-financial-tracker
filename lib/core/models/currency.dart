import 'package:world_countries/world_countries.dart';

class CurrencyModel {
  final int? id;
  final String name;

  static Iterable<FiatCurrency>? _allFiatCurrencies;
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

  static Iterable<FiatCurrency> _getAllFiatCurrencies() {
    if (_allFiatCurrencies != null) {
      return _allFiatCurrencies!;
    }
    _allFiatCurrencies = FiatCurrency.list.toList(growable: false);
    return _allFiatCurrencies!;
  }

  static FiatCurrency? _findFiatByDisplayName(String displayName) {
    final String name = displayName.trim();
    if (name.isEmpty) return null;

    const typedLocale = BasicLocale(LangAra());
    final all = _getAllFiatCurrencies();

    for (final c in all) {
      final common = c.translations.firstWhere((e) => e.language == typedLocale.language, orElse: () => TranslatedName(typedLocale.language, name: '')).name;
      if (common != null && common == name) {
        return c;
      }
      if (c.internationalName == name) {
        return c;
      }
    }
    return null;
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

    final fiat = _findFiatByDisplayName(name);
    if (fiat == null) {
      _symbolCache[name] = name;
      return name;
    }

    switch (fiat.code) {
      case 'SAR':
        _symbolCache[name] = 'ر.س';
        return 'ر.س';
      case 'AED':
        _symbolCache[name] = 'د.إ';
        return 'د.إ';
      case 'EGP':
        _symbolCache[name] = 'ج.م';
        return 'ج.م';
      case 'YER':
        _symbolCache[name] = 'ر.ي';
        return 'ر.ي';
      case 'QAR':
        _symbolCache[name] = 'ر.ق';
        return 'ر.ق';
      case 'OMR':
        _symbolCache[name] = 'ر.ع';
        return 'ر.ع';
      default:
        break;
    }

    if (fiat.symbol != null && fiat.symbol!.isNotEmpty) {
      // Some symbols (notably the Rial sign U+FDFC: "﷼") can crash PDF rendering
      // depending on embedded font support. Prefer a safe fallback in that case.
      if (fiat.symbol!.contains('\uFDFC')) {
        _symbolCache[name] = fiat.code;
        return fiat.code;
      }
      _symbolCache[name] = fiat.symbol!;
      return fiat.symbol!;
    }

    String? symbol;
    if (fiat.disambiguateSymbol != null && fiat.disambiguateSymbol!.isNotEmpty) {
      symbol = fiat.disambiguateSymbol;
    } else if (fiat.alternateSymbols != null && fiat.alternateSymbols!.isNotEmpty) {
      symbol = fiat.alternateSymbols!.first;
    }

    if (symbol != null && symbol.isNotEmpty) {
      if (symbol.contains('\uFDFC')) {
        _symbolCache[name] = fiat.code;
        return fiat.code;
      }
      _symbolCache[name] = symbol;
      return symbol;
    }

    _symbolCache[name] = fiat.code;
    return fiat.code;
  }
}
