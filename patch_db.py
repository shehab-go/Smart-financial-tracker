import re
import os

filepath = r"e:\hemmah\debit_credit_app\lib\core\db\database_helper.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add the import
if "package:flutter/foundation.dart" not in content:
    content = content.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'package:flutter/foundation.dart';")

# Replacements for List.generate(...)

replacements = [
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return CategoryModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseCategories, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return CurrencyModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseCurrencies, maps);"),
    (r"final accounts = List\.generate\(maps\.length, \(i\) \{\s*return AccountModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"final accounts = await compute(_parseAccounts, maps);"),
    (r"final accounts = List\.generate\(maps\.length, \(i\) => AccountModel\.fromMap\(maps\[i\]\)\);", 
     r"final accounts = await compute(_parseAccounts, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return TransactionModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseTransactions, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return ExpenseModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseExpenses, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) => ExpenseModel\.fromMap\(maps\[i\]\)\);", 
     r"return compute(_parseExpenses, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return IncomeResourceModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseIncomeResources, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return IncomeBalanceModel\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseIncomeBalances, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return TransactionBalanceAllocation\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseTransactionAllocations, maps);"),
    (r"return List\.generate\(maps\.length, \(i\) \{\s*return ExpenseBalanceAllocation\.fromMap\(maps\[i\]\);\s*\}\);", 
     r"return compute(_parseExpenseAllocations, maps);"),
]

for pattern, replacement in replacements:
    content = re.sub(pattern, replacement, content)

# Also there's one for ExpenseAccountModel
content = re.sub(r"return List\.generate\(rows\.length, \(i\) => ExpenseAccountModel\.fromMap\(rows\[i\]\)\);", 
                 r"return compute(_parseExpenseAccounts, rows);", content)

# Add the parsing functions at the bottom
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

if "_parseTransactions" not in content:
    content += parsers

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
