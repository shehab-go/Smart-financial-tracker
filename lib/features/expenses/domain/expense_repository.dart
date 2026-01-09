import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/expense_balance_allocation.dart';

class ExpenseAllocationInput {
  final int balanceId;
  final double amount;

  const ExpenseAllocationInput({
    required this.balanceId,
    required this.amount,
  });
}

class ExpenseRepository {
  final DatabaseHelper _db;
  ExpenseRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<ExpenseModel>> fetchExpenses() {
    return _db.getExpenses();
  }

  Future<ExpenseModel?> fetchExpenseById(int id) {
    return _db.getExpenseById(id);
  }

  Future<int> addExpense(ExpenseModel expense) {
    return _db.insertExpense(expense);
  }

  Future<void> addExpenseWithAllocations(
    ExpenseModel expense,
    List<ExpenseAllocationInput> allocations,
  ) async {
    final expenseId = await _db.insertExpense(expense);
    if (allocations.isEmpty) return;

    final models = allocations
        .map(
          (a) => ExpenseBalanceAllocation(
            expenseId: expenseId,
            balanceId: a.balanceId,
            allocatedAmount: a.amount,
          ),
        )
        .toList();
    await _db.insertExpenseAllocations(models);
  }

  Future<int> updateExpense(ExpenseModel expense) {
    return _db.updateExpense(expense);
  }

  Future<void> updateExpenseWithAllocations(
    ExpenseModel expense,
    List<ExpenseAllocationInput> allocations,
  ) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID is required to update allocations');
    }

    await _db.updateExpense(expense);
    await _db.deleteExpenseAllocations(expense.id!);

    if (allocations.isEmpty) return;

    final models = allocations
        .map(
          (a) => ExpenseBalanceAllocation(
            expenseId: expense.id!,
            balanceId: a.balanceId,
            allocatedAmount: a.amount,
          ),
        )
        .toList();
    await _db.insertExpenseAllocations(models);
  }

  Future<int> deleteExpense(int id) {
    return _db.deleteExpense(id);
  }

  Future<double> getTotalExpenses() {
    return _db.getTotalExpenses();
  }

  Future<void> deleteExpenses(Iterable<int> ids) async {
    for (final id in ids) {
      await _db.deleteExpense(id);
    }
  }
}