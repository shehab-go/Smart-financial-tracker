import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/features/home/domain/home_repository.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:flutter/foundation.dart';

class _CategoryLoadResult {
  final String categoryName;
  final List<AccountModel> accounts;
  final Map<String, double> totals;

  const _CategoryLoadResult({
    required this.categoryName,
    required this.accounts,
    required this.totals,
  });
}

class HomeController {
  final HomeRepository _repo;
  HomeState _state = HomeState.initial();
  static HomeState? _cachedState;
  String _effectiveCurrencyName = 'محلي';

  HomeState get state => _state;
  String get effectiveCurrencyName => _effectiveCurrencyName;

  void _debugPerf(String label, Stopwatch sw, {int thresholdMs = 16}) {
    if (!kDebugMode) return;
    final ms = sw.elapsedMilliseconds;
    if (ms < thresholdMs) return;
    debugPrint('PERF $label: ${ms}ms');
  }

  HomeController({HomeRepository? repo}) : _repo = repo ?? HomeRepository() {
    final cached = _cachedState;
    if (cached != null) {
      _state = cached;
    }
  }

  Future<HomeState> load({String currencyFilter = 'all'}) async {
    final swTotal = Stopwatch()..start();
    _state = _state.copyWith(isLoading: true);

    final swCategories = Stopwatch()..start();
    final categories = await _repo.fetchCategories();
    _debugPerf('HomeController.load.fetchCategories', swCategories);

    final List<CategoryModel> updatedCategories = [
      CategoryModel(id: -1, name: 'الكل'),
      ...categories,
    ];

    final String effectiveCurrency;
    final bool isAllCurrencies = currencyFilter.trim().isEmpty || currencyFilter == 'all';
    if (isAllCurrencies) {
      final String? rawDefault = await _repo.fetchDefaultCurrencyName();
      final String cleaned = rawDefault?.trim() ?? '';
      effectiveCurrency = cleaned.isNotEmpty ? cleaned : 'محلي';
    } else {
      effectiveCurrency = currencyFilter.trim();
    }
    _effectiveCurrencyName = effectiveCurrency;

    Map<String, Map<String, double>> totalsByCategoryForEffectiveCurrency =
        const <String, Map<String, double>>{};
    if (isAllCurrencies) {
      final swBatchTotals = Stopwatch()..start();
      totalsByCategoryForEffectiveCurrency =
          await _repo.fetchCategoryTotalsByCurrency(effectiveCurrency);
      _debugPerf('HomeController.load.fetchCategoryTotalsByCurrency', swBatchTotals);
    }

    final swAllAccounts = Stopwatch()..start();
    final List<AccountModel> allAccounts = isAllCurrencies
        ? await _repo.fetchAccountsWithStatsUsingAccountCurrencyAllCategories()
        : await _repo.fetchAccountsWithStatsByCurrencyAllCategories(effectiveCurrency);
    _debugPerf('HomeController.load.fetchAllAccounts', swAllAccounts);

    final Map<String, List<AccountModel>> accountsByCategory = <String, List<AccountModel>>{};
    for (final account in allAccounts) {
      (accountsByCategory[account.category] ??= <AccountModel>[]).add(account);
    }
    accountsByCategory['الكل'] = allAccounts;

    final swAllCategories = Stopwatch()..start();
    final List<_CategoryLoadResult> results = await Future.wait(
      updatedCategories.map((category) async {
        final accounts = accountsByCategory[category.name] ?? const <AccountModel>[];

        final swTotals = Stopwatch()..start();
        double debit = 0.0;
        double credit = 0.0;
        if (category.name == 'الكل') {
          if (isAllCurrencies) {
            for (final totals in totalsByCategoryForEffectiveCurrency.values) {
              debit += totals['debit'] ?? 0.0;
              credit += totals['credit'] ?? 0.0;
            }
          } else {
            for (final a in accounts) {
              debit += a.totalDebit;
              credit += a.totalCredit;
            }
          }
        } else {
          if (isAllCurrencies) {
            // Totals should not mix currencies. When showing all currencies,
            // compute category totals using the effectiveCurrencyName only.
            final totals = totalsByCategoryForEffectiveCurrency[category.name];
            if (totals != null) {
              debit = totals['debit'] ?? 0.0;
              credit = totals['credit'] ?? 0.0;
            }
          } else {
            for (final a in accounts) {
              debit += a.totalDebit;
              credit += a.totalCredit;
            }
          }
        }
        _debugPerf('HomeController.load.computeTotals(${category.name})', swTotals);
        final totals = <String, double>{
          'debit': debit,
          'credit': credit,
          'net': credit - debit,
        };
        return _CategoryLoadResult(
          categoryName: category.name,
          accounts: accounts,
          totals: totals,
        );
      }),
    );
    _debugPerf('HomeController.load.allCategories', swAllCategories);

    final Map<String, List<AccountModel>> accountsMap = {
      for (final r in results) r.categoryName: r.accounts,
    };
    final Map<String, Map<String, double>> totalsMap = {
      for (final r in results) r.categoryName: r.totals,
    };

    _state = _state.copyWith(
      isLoading: false,
      categories: updatedCategories,
      accountsByCategory: accountsMap.map((k, v) => MapEntry(k, List<AccountModel>.from(v))),
      totalsByCategory: totalsMap,
    );

    _cachedState = _state;

    _debugPerf('HomeController.load.total', swTotal);

    return _state;
  }

  Future<void> deleteAccounts(Iterable<int> ids) async {
    await _repo.deleteAccounts(ids);
  }
}
