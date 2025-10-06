import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/models/expense.dart';
import '../../../../core/db/database_helper.dart';
import '../../../accounts/presentation/screens/account_transactions_screen.dart';
import '../../../expenses/presentation/screens/expense_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _searchService.globalSearch(query);
      if (mounted && query == _lastQuery) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchResultTap(SearchResult result) async {
    switch (result.type) {
      case 'account':
        final account = result.data as AccountModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountTransactionsScreen(
              account: account,
            ),
          ),
        );
        break;
      case 'transaction':
        final transaction = result.data as TransactionModel;
        // Get the account for this transaction
        final account = await DatabaseHelper().getAccountById(transaction.accountId);
        if (account != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountTransactionsScreen(
                account: account,
                highlightTransactionId: transaction.id,
              ),
            ),
          );
        }
        break;
      case 'expense':
        final expense = result.data as ExpenseModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseScreen(
              highlightExpenseId: expense.id,
            ),
          ),
        );
        break;
    }
  }

  Widget _buildSearchResult(SearchResult result) {
    IconData icon;
    Color iconColor;
    
    switch (result.type) {
      case 'account':
        icon = Icons.person;
        iconColor = AppTheme.primaryColor;
        break;
      case 'transaction':
        icon = Icons.receipt_long;
        iconColor = Colors.orange;
        break;
      case 'expense':
        icon = Icons.shopping_cart;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.search;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          result.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: result.category != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.category!,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        onTap: () => _onSearchResultTap(result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: TextField(
            controller: _searchController,
            autofocus: true,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'ابحث في الحسابات والمعاملات والمصروفات...',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
            onChanged: (value) {
              // Debounce search to avoid too many API calls
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_searchController.text == value) {
                  _performSearch(value);
                }
              });
            },
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                    _lastQuery = '';
                  });
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
            : _searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResult(_searchResults[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'ابحث في جميع بياناتك',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك البحث في الحسابات والمعاملات والمصروفات',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
  }
}