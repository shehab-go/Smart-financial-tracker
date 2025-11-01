import 'package:debit_credit_app/core/models/category.dart';

class CategoriesState {
  final bool isLoading;
  final List<CategoryModel> categories;
  final String? error;

  const CategoriesState({
    required this.isLoading,
    required this.categories,
    this.error,
  });

  factory CategoriesState.initial() => const CategoriesState(
    isLoading: true,
    categories: [],
  );

  CategoriesState copyWith({
    bool? isLoading,
    List<CategoryModel>? categories,
    String? error,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      error: error ?? this.error,
    );
  }
}
