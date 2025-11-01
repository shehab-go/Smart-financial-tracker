import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/category.dart';

class CategoriesRepository {
  final DatabaseHelper _db;
  
  CategoriesRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<CategoryModel>> fetchCategories() async {
    return await _db.getCategories();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.insertCategory(category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.updateCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
  }
}
