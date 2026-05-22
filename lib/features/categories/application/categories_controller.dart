import 'package:flutter/foundation.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/categories/application/categories_state.dart';
import 'package:debit_credit_app/features/categories/domain/categories_repository.dart';
import 'package:debit_credit_app/core/events/category_events.dart';

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
      // Emit category added event
      CategoryEventBus().emit(CategoryEvent(
        type: CategoryEventType.added,
        categoryName: category.name,
      ));
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
      // Emit category updated event
      CategoryEventBus().emit(CategoryEvent(
        type: CategoryEventType.updated,
        categoryName: category.name,
        categoryId: category.id,
      ));
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
      // Emit category deleted event
      CategoryEventBus().emit(CategoryEvent(
        type: CategoryEventType.deleted,
        categoryId: id,
      ));
    } catch (e) {
      String errorMessage = e.toString();
      // Clean up the error message if it contains 'Exception: '
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _state = _state.copyWith(error: errorMessage);
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final List<CategoryModel> updatedList = List.from(_state.categories);
    final CategoryModel category = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, category);

    // Update state locally first for smooth animations
    _state = _state.copyWith(categories: updatedList);
    notifyListeners();

    try {
      await _repository.updateCategoriesOrder(updatedList);
      
      // Emit category reordered event
      CategoryEventBus().emit(CategoryEvent(
        type: CategoryEventType.reordered,
      ));
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      rethrow;
    }
  }
}
