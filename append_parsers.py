import os

filepath = r"e:\hemmah\debit_credit_app\lib\core\db\database_helper.dart"

parsers = """
List<CategoryModel> _parseCategories(List<Map<String, dynamic>> maps) {
  return maps.map((map) => CategoryModel.fromMap(map)).toList();
}

List<CurrencyModel> _parseCurrencies(List<Map<String, dynamic>> maps) {
  return maps.map((map) => CurrencyModel.fromMap(map)).toList();
}

List<AccountModel> _parseAccounts(List<Map<String, dynamic>> maps) {
  return maps.map((map) => AccountModel.fromMap(map)).toList();
}

List<TransactionModel> _parseTransactions(List<Map<String, dynamic>> maps) {
  return maps.map((map) => TransactionModel.fromMap(map)).toList();
}

List<ExpenseModel> _parseExpenses(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseModel.fromMap(map)).toList();
}

List<ExpenseAccountModel> _parseExpenseAccounts(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseAccountModel.fromMap(map)).toList();
}

List<IncomeResourceModel> _parseIncomeResources(List<Map<String, dynamic>> maps) {
  return maps.map((map) => IncomeResourceModel.fromMap(map)).toList();
}

List<IncomeBalanceModel> _parseIncomeBalances(List<Map<String, dynamic>> maps) {
  return maps.map((map) => IncomeBalanceModel.fromMap(map)).toList();
}

List<TransactionBalanceAllocation> _parseTransactionAllocations(List<Map<String, dynamic>> maps) {
  return maps.map((map) => TransactionBalanceAllocation.fromMap(map)).toList();
}

List<ExpenseBalanceAllocation> _parseExpenseAllocations(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ExpenseBalanceAllocation.fromMap(map)).toList();
}
"""

with open(filepath, 'a', encoding='utf-8') as f:
    f.write(parsers)
print("Appended parsers")
