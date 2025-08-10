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

  Future<Map<String, double>> fetchCategoryTotals(String category) {
    return _db.getCategoryTotals(category);
  }

  Future<void> deleteAccounts(Iterable<int> ids) async {
    for (final id in ids) {
      await _db.deleteAccount(id);
    }
  }
}
