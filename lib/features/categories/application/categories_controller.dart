import 'package:flutter/foundation.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/categories/application/categories_state.dart';
import 'package:debit_credit_app/features/categories/domain/categories_repository.dart';
import 'package:debit_credit_app/core/events/category_events.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';

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
      // Repair corrupted categories that were inserted with NULL type previously
      await _repository.repairCategories();

      final allCategories = await _repository.fetchCategories();
      final generalCats = allCategories.where((c) => c.type == 'general').toList();
      final expenseCats = allCategories.where((c) => c.type == 'expense').toList();

      _state = _state.copyWith(
        isLoading: false,
        generalCategories: generalCats,
        expenseCategories: expenseCats,
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

  Future<void> reorderCategories(int oldIndex, int newIndex, String type) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final bool isGeneral = type == 'general';
    final List<CategoryModel> updatedList = List.from(isGeneral ? _state.generalCategories : _state.expenseCategories);
    final CategoryModel category = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, category);

    // Update state locally first for smooth animations
    if (isGeneral) {
      _state = _state.copyWith(generalCategories: updatedList);
    } else {
      _state = _state.copyWith(expenseCategories: updatedList);
    }
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

  Future<void> updateCategoriesSortOrder(List<CategoryModel> orderedCategories) async {
    try {
      await _repository.updateCategoriesOrder(orderedCategories);
      await loadCategories();
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
