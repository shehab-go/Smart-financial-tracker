import 'package:debit_credit_app/core/models/category.dart';

class CategoriesState {
  final bool isLoading;
  final List<CategoryModel> generalCategories;
  final List<CategoryModel> expenseCategories;
  final String? error;

  const CategoriesState({
    required this.isLoading,
    required this.generalCategories,
    required this.expenseCategories,
    this.error,
  });

  factory CategoriesState.initial() => const CategoriesState(
    isLoading: true,
    generalCategories: [],
    expenseCategories: [],
  );

  CategoriesState copyWith({
    bool? isLoading,
    List<CategoryModel>? generalCategories,
    List<CategoryModel>? expenseCategories,
    String? error,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      generalCategories: generalCategories ?? this.generalCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      error: error ?? this.error,
    );
  }
}
