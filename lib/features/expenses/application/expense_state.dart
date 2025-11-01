import 'package:debit_credit_app/core/models/expense.dart';

class ExpenseState {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final double totalExpenses;
  final String? error;

  const ExpenseState({
    required this.isLoading,
    required this.expenses,
    required this.totalExpenses,
    this.error,
  });

  factory ExpenseState.initial() => const ExpenseState(
        isLoading: true,
        expenses: [],
        totalExpenses: 0.0,
      );

  ExpenseState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    double? totalExpenses,
    String? error,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      error: error ?? this.error,
    );
  }

  ExpenseState clearError() {
    return copyWith(error: null);
  }

  @override
  String toString() {
    return 'ExpenseState(isLoading: $isLoading, expenses: ${expenses.length}, totalExpenses: $totalExpenses, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseState &&
        other.isLoading == isLoading &&
        other.expenses == expenses &&
        other.totalExpenses == totalExpenses &&
        other.error == error;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        expenses.hashCode ^
        totalExpenses.hashCode ^
        error.hashCode;
  }
}