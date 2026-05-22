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

  Future<void> updateCategoriesOrder(List<CategoryModel> categories) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        if (category.id != null) {
          await txn.update(
            'categories',
            {'sortOrder': i},
            where: 'id = ?',
            whereArgs: [category.id],
          );
        }
      }
    });
  }
}
