import '../db/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/expense.dart';

class SearchResult {
  final String type; // 'account', 'transaction', 'expense'
  final dynamic data;
  final String title;
  final String subtitle;
  final String? category;
  
  SearchResult({
    required this.type,
    required this.data,
    required this.title,
    required this.subtitle,
    this.category,
  });
}

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<SearchResult>> globalSearch(String query) async {
    if (query.trim().isEmpty) return [];
    
    final List<SearchResult> results = [];
    final searchTerm = query.toLowerCase().trim();

    // Search in accounts
    final accounts = await _searchAccounts(searchTerm);
    results.addAll(accounts);

    // Search in transactions
    final transactions = await _searchTransactions(searchTerm);
    results.addAll(transactions);

    // Search in expenses
    final expenses = await _searchExpenses(searchTerm);
    results.addAll(expenses);

    return results;
  }

  Future<List<SearchResult>> _searchAccounts(String searchTerm) async {
    final accounts = await _dbHelper.getAccounts();
    final List<SearchResult> results = [];

    for (final account in accounts) {
      if (_matchesSearchTerm(account.name, searchTerm) ||
          _matchesSearchTerm(account.category, searchTerm) ||
          _matchesSearchTerm(account.phone ?? '', searchTerm) ||
          _matchesSearchTerm(account.address ?? '', searchTerm) ||
          _matchesSearchTerm(account.workDetails ?? '', searchTerm)) {
        
        results.add(SearchResult(
          type: 'account',
          data: account,
          title: account.name,
          subtitle: 'حساب في فئة ${account.category}',
          category: account.category,
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchTransactions(String searchTerm) async {
    final transactions = await _dbHelper.getTransactions();
    final accounts = await _dbHelper.getAccounts();
    final accountMap = {for (var account in accounts) account.id: account};
    
    final List<SearchResult> results = [];

    for (final transaction in transactions) {
      final account = accountMap[transaction.accountId];
      final accountName = account?.name ?? 'حساب غير معروف';
      
      if (_matchesSearchTerm(transaction.description ?? '', searchTerm) ||
          _matchesSearchTerm(transaction.category, searchTerm) ||
          _matchesSearchTerm(accountName, searchTerm) ||
          _matchesSearchTerm(transaction.amount.toString(), searchTerm)) {
        
        final typeText = transaction.type == 'debit' ? 'مدين' : 'دائن';
        results.add(SearchResult(
          type: 'transaction',
          data: transaction,
          title: '${transaction.description ?? 'معاملة'} - $accountName',
          subtitle: '$typeText: ${transaction.amount} - ${transaction.category}',
          category: transaction.category,
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchExpenses(String searchTerm) async {
    final expenses = await _dbHelper.getExpenses();
    final List<SearchResult> results = [];

    for (final expense in expenses) {
      if (_matchesSearchTerm(expense.name, searchTerm) ||
          _matchesSearchTerm(expense.detail, searchTerm) ||
          _matchesSearchTerm(expense.category, searchTerm) ||
          _matchesSearchTerm(expense.amount.toString(), searchTerm)) {
        
        results.add(SearchResult(
          type: 'expense',
          data: expense,
          title: expense.name,
          subtitle: '${expense.amount} - ${expense.category}',
          category: expense.category,
        ));
      }
    }

    return results;
  }

  bool _matchesSearchTerm(String text, String searchTerm) {
    return text.toLowerCase().contains(searchTerm);
  }

  Future<List<SearchResult>> searchByCategory(String category) async {
    final List<SearchResult> results = [];

    // Get accounts in category
    final accounts = await _dbHelper.getAccountsByCategory(category);
    for (final account in accounts) {
      results.add(SearchResult(
        type: 'account',
        data: account,
        title: account.name,
        subtitle: 'حساب في فئة ${account.category}',
        category: account.category,
      ));
    }

    // Get transactions in category
    final transactions = await _dbHelper.getTransactionsByCategory(category);
    final allAccounts = await _dbHelper.getAccounts();
    final accountMap = {for (var account in allAccounts) account.id: account};
    
    for (final transaction in transactions) {
      final account = accountMap[transaction.accountId];
      final accountName = account?.name ?? 'حساب غير معروف';
      final typeText = transaction.type == 'debit' ? 'مدين' : 'دائن';
      
      results.add(SearchResult(
        type: 'transaction',
        data: transaction,
        title: '${transaction.description ?? 'معاملة'} - $accountName',
        subtitle: '$typeText: ${transaction.amount}',
        category: transaction.category,
      ));
    }

    return results;
  }
}