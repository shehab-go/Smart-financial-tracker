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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
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
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
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
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
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
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0, // Reduces gap between back button and search field
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 12.0), // Padding on both edges
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA), // Cleaner soft grey/blue background
                borderRadius: BorderRadius.circular(24), // Capsule style
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
                 decoration: InputDecoration(
                  filled: false,
                  hintText: 'ابحث عن حساب، معاملة، مصروف...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    fontSize: 13,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _lastQuery = '';
                            });
                          },
                        )
                      : null,
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
            ),
          ),
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
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ما الذي تبحث عنه؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ابحث في الحسابات، المعاملات، والمصروفات بسهولة',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
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
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لم نجد أي نتائج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم العثور على أية بيانات تطابق "${_searchController.text}"',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}