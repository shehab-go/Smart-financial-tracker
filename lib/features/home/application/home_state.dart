import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';

class HomeState {
  final bool isLoading;
  final List<CategoryModel> categories;
  final Map<String, List<AccountModel>> accountsByCategory;
  final Map<String, Map<String, double>> totalsByCategory;

  const HomeState({
    required this.isLoading,
    required this.categories,
    required this.accountsByCategory,
    required this.totalsByCategory,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: true,
        categories: [],
        accountsByCategory: {},
        totalsByCategory: {},
      );

  HomeState copyWith({
    bool? isLoading,
    List<CategoryModel>? categories,
    Map<String, List<AccountModel>>? accountsByCategory,
    Map<String, Map<String, double>>? totalsByCategory,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      accountsByCategory: accountsByCategory ?? this.accountsByCategory,
      totalsByCategory: totalsByCategory ?? this.totalsByCategory,
    );
  }
}

