import 'package:debit_credit_app/features/expenses/application/expense_state.dart';
import 'package:debit_credit_app/features/expenses/domain/expense_repository.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_account.dart';

class ExpenseController {
  final ExpenseRepository _repo;
  ExpenseState _state = ExpenseState.initial();

  ExpenseState get state => _state;

  ExpenseController({ExpenseRepository? repo}) : _repo = repo ?? ExpenseRepository();

  Future<ExpenseState> load() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);

      await _repo.cleanupOrphanedExpenses();

      final expenses = await _repo.fetchExpenses();
      final accounts = await _repo.fetchExpenseAccountsWithStats();
      final totalExpenses = await _repo.getTotalExpenses();

      _state = _state.copyWith(
        isLoading: false,
        expenses: expenses,
        expenseAccounts: accounts,
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
      ExpenseModel finalExpense = expense;

      // If this is a brand new expense without an associated expense account,
      // automatically create a matching expense account (similar to migration
      // behavior where each expense had its own main account).
      if (expense.id == null && expense.expenseAccountId == null) {
        final ExpenseAccountModel account = ExpenseAccountModel(
          name: expense.name,
          category: expense.category,
          currencyName: expense.currency,
          createdDate: expense.createdDate,
        );

        final int accountId = await _repo.addExpenseAccount(account);
        finalExpense = expense.copyWith(expenseAccountId: accountId);
      }

      if (allocations.isEmpty) {
        await _repo.addExpense(finalExpense);
      } else {
        await _repo.addExpenseWithAllocations(finalExpense, allocations);
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

      // Sync the parent account if needed
      if (expense.expenseAccountId != null) {
        final accounts = await _repo.fetchExpenseAccountsWithStats();
        final account = accounts.firstWhere(
            (a) => a.id == expense.expenseAccountId,
            orElse: () => ExpenseAccountModel(name: '', category: '', currencyName: '', createdDate: DateTime.now()));
            
        // Only auto-update the account name/category if the account has only 1 expense
        // OR if the user is editing it from the main screen where they perceive it as 1 item.
        // Actually, if it has 1 expense, it's perfectly safe to sync it.
        if (account.id != null && account.expenseCount <= 1) {
          if (account.name != expense.name || account.category != expense.category || account.currencyName != expense.currency) {
            await _repo.updateExpenseAccount(account.copyWith(
              name: expense.name,
              category: expense.category,
              currencyName: expense.currency,
            ));
          }
        }
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

  Future<bool> updateExpenseAccount(ExpenseAccountModel account) async {
    try {
      await _repo.updateExpenseAccount(account);
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to update expense account: $e');
      return false;
    }
  }

  Future<bool> deleteExpenseAccount(int id) async {
    try {
      await _repo.deleteExpenseAccount(id);
      await load(); // Refresh the list
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete expense account: $e');
      return false;
    }
  }

  void clearError() {
    _state = _state.clearError();
  }
}