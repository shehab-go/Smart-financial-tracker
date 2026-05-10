import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';

class HomeRepository {
  final DatabaseHelper _db;
  HomeRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<CategoryModel>> fetchCategories() {
    return _db.getCategories();
  }

  Future<List<AccountModel>> fetchAccountsWithStatsByCategory(String category) {
    return _db.getAccountsWithStatsByCategory(category);
  }

  Future<List<AccountModel>> fetchAccountsWithStatsByCategoryAndCurrency(
    String category,
    String currencyName,
  ) {
    return _db.getAccountsWithStatsByCategoryAndCurrency(category, currencyName);
  }

  Future<List<AccountModel>> fetchAccountsWithStatsByCategoryUsingAccountCurrency(
    String category,
  ) {
    return _db.getAccountsWithStatsByCategoryUsingAccountCurrency(category);
  }

  Future<List<AccountModel>> fetchAccountsWithStatsUsingAccountCurrencyAllCategories() {
    return _db.getAccountsWithStatsUsingAccountCurrencyAllCategories();
  }

  Future<List<AccountModel>> fetchAccountsWithStatsByCurrencyAllCategories(
    String currencyName,
  ) {
    return _db.getAccountsWithStatsByCurrencyAllCategories(currencyName);
  }

  Future<List<String>> fetchDistinctTransactionCurrencies() {
    return _db.getDistinctTransactionCurrencies();
  }

  Future<String?> fetchDefaultCurrencyName() {
    return _db.getDefaultCurrencyName();
  }

  Future<Map<String, double>> fetchCategoryTotals(String category) {
    return _db.getCategoryTotals(category);
  }

  Future<Map<String, Map<String, double>>> fetchCategoryTotalsByCurrency(
    String currencyName,
  ) {
    return _db.getCategoryTotalsByCurrency(currencyName);
  }

  Future<void> deleteAccounts(Iterable<int> ids) async {
    for (final id in ids) {
      await _db.deleteAccount(id);
    }
  }
}
