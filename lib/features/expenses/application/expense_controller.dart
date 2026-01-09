import 'package:debit_credit_app/features/expenses/application/expense_state.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/core/models/expense.dart';

class ExpenseController {
  final ExpenseRepository _repo;
  ExpenseState _state = ExpenseState.initial();

  ExpenseState get state => _state;

  ExpenseController({ExpenseRepository? repo}) : _repo = repo ?? ExpenseRepository();

  Future<ExpenseState> load() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);

      final expenses = await _repo.fetchExpenses();
      final totalExpenses = await _repo.getTotalExpenses();

      _state = _state.copyWith(
        isLoading: false,
        expenses: expenses,
        totalExpenses: totalExpenses,
      );

      return _state;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load expenses: $e',
      );
      return _state;
    }
  }

  Future<bool> addExpense(
    ExpenseModel expense, {
    List<ExpenseAllocationInput> allocations = const [],
  }) async {
    try {
      if (allocations.isEmpty) {
        await _repo.addExpense(expense);
      } else {
        await _repo.addExpenseWithAllocations(expense, allocations);
      }
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to add expense: $e');
      return false;
    }
  }

  Future<bool> updateExpense(
    ExpenseModel expense, {
    List<ExpenseAllocationInput> allocations = const [],
  }) async {
    try {
      if (allocations.isEmpty) {
        await _repo.updateExpense(expense);
      } else {
        await _repo.updateExpenseWithAllocations(expense, allocations);
      }
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to update expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _repo.deleteExpense(id);
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpenses(Iterable<int> ids) async {
    try {
      await _repo.deleteExpenses(ids);
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete expenses: $e');
      return false;
    }
  }

  void clearError() {
    _state = _state.clearError();
  }
}