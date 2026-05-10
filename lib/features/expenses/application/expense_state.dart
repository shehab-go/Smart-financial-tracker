import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';

class ExpenseState {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final double totalExpenses;
  final List<ExpenseAccountModel> expenseAccounts;
  final String? error;

  const ExpenseState({
    required this.isLoading,
    required this.expenses,
    required this.totalExpenses,
    required this.expenseAccounts,
    this.error,
  });

  factory ExpenseState.initial() => const ExpenseState(
        isLoading: true,
        expenses: [],
        totalExpenses: 0.0,
        expenseAccounts: [],
      );

  ExpenseState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    double? totalExpenses,
    List<ExpenseAccountModel>? expenseAccounts,
    String? error,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expenseAccounts: expenseAccounts ?? this.expenseAccounts,
      error: error ?? this.error,
    );
  }

  ExpenseState clearError() {
    return copyWith(error: null);
  }

  @override
  String toString() {
    return 'ExpenseState(isLoading: $isLoading, expenses: ${expenses.length}, expenseAccounts: ${expenseAccounts.length}, totalExpenses: $totalExpenses, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseState &&
        other.isLoading == isLoading &&
        other.expenses == expenses &&
        other.expenseAccounts == expenseAccounts &&
        other.totalExpenses == totalExpenses &&
        other.error == error;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        expenses.hashCode ^
        expenseAccounts.hashCode ^
        totalExpenses.hashCode ^
        error.hashCode;
  }
}