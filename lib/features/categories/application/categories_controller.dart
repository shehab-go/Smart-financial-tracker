import 'package:flutter/foundation.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/categories/application/categories_state.dart';
import 'package:debit_credit_app/features/categories/domain/categories_repository.dart';

class CategoriesController extends ChangeNotifier {
  final CategoriesRepository _repository;
  CategoriesState _state = CategoriesState.initial();

  CategoriesController({CategoriesRepository? repository}) 
      : _repository = repository ?? CategoriesRepository();

  CategoriesState get state => _state;

  Future<void> loadCategories() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final categories = await _repository.fetchCategories();
      _state = _state.copyWith(
        isLoading: false,
        categories: categories,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _repository.addCategory(category);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
