import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/expense.dart';

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

  Future<int> updateExpense(ExpenseModel expense) {
    return _db.updateExpense(expense);
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