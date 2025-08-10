import 'package:debit_credit_app/features/home/application/home_state.dart';
import 'package:debit_credit_app/features/home/domain/home_repository.dart';
import 'package:debit_credit_app/core/models/account.dart';

class HomeController {
  final HomeRepository _repo;
  HomeState _state = HomeState.initial();

  HomeState get state => _state;

  HomeController({HomeRepository? repo}) : _repo = repo ?? HomeRepository();

  Future<HomeState> load() async {
    _state = _state.copyWith(isLoading: true);

    final categories = await _repo.fetchCategories();
    final Map<String, List<AccountModel>> accountsMap = {};
    final Map<String, Map<String, double>> totalsMap = {};

    for (final category in categories) {
      final accounts = await _repo.fetchAccountsWithStatsByCategory(category.name);
      accountsMap[category.name] = accounts;
      final totals = await _repo.fetchCategoryTotals(category.name);
      totalsMap[category.name] = totals;
    }

    _state = _state.copyWith(
      isLoading: false,
      categories: categories,
      accountsByCategory: accountsMap.map((k, v) => MapEntry(k, List<AccountModel>.from(v))),
      totalsByCategory: totalsMap,
    );

    return _state;
  }

  Future<void> deleteAccounts(Iterable<int> ids) async {
    await _repo.deleteAccounts(ids);
  }
}
