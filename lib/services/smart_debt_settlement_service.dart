import 'dart:async';
import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/services/financial_tracker_service.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/transaction.dart' as app_tx;

class SmartDebtSettlementService {
  static final SmartDebtSettlementService _instance = SmartDebtSettlementService._internal();
  factory SmartDebtSettlementService() => _instance;
  SmartDebtSettlementService._internal();

  StreamSubscription? _subscription;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Store the global navigator key to show dialogs from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initialize() {
    if (_subscription != null) return;
    
    _subscription = FinancialTrackerService.transactionStream.listen((transaction) {
      _processIncomingTransaction(transaction);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _processIncomingTransaction(Map<String, dynamic> tx) async {
    final bool isParsed = tx['amount'] != null;
    if (!isParsed) return;

    final String counterpart = tx['counterpart']?.toString() ?? '';
    final String transactionType = tx['transactionType']?.toString() ?? '';
    final double amount = (tx['amount'] as num).toDouble();
    
    // Only care about Transfer In (Incoming Money) for now
    if (transactionType != 'Transfer In' && !tx['transactionType'].toString().contains('In')) {
      return;
    }

    if (counterpart.isEmpty) return;

    // Fetch all accounts to find a match
    final accounts = await _dbHelper.getAccounts();
    
    // Simple Matching: Check if counterpart name exists in account name or vice versa
    AccountModel? matchedAccount;
    for (var account in accounts) {
      final accName = account.name.trim();
      final cpName = counterpart.trim();
      if (accName.contains(cpName) || cpName.contains(accName)) {
        matchedAccount = account;
        break;
      }
    }

    if (matchedAccount != null) {
      // We found a match! Let's check if they owe us money.
      // In this app, we need to see their balance. 
      // This is a complex query, but we can just show the prompt and let the user decide.
      _showSettlementPrompt(matchedAccount, amount, counterpart);
    }
  }

  void _showSettlementPrompt(AccountModel account, double amount, String rawName) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('المحاسب الذكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'يبدو أن "$rawName" قام بتحويل مبلغ $amount إليك للتو عبر المحفظة.\n\nهل ترغب في تسجيل هذا المبلغ كسداد لدينه (أو جزء منه) في حسابه "${account.name}"؟',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تجاهل', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _settleDebt(account, amount);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تسجيل السداد بنجاح!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('نعم، سجل السداد'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _settleDebt(AccountModel account, double amount) async {
    // Determine the default currency
    String currency = 'محلي';
    try {
      currency = await _dbHelper.getDefaultCurrencyName() ?? 'محلي';
    } catch (_) {}

    // In this app structure, if they owe us, they are "debit" (عليك). 
    // To settle it, we add a "credit" (له) transaction.
    final tx = app_tx.TransactionModel(
      accountId: account.id!,
      amount: amount,
      type: 'credit', // credit means they paid us
      date: DateTime.now(),
      description: 'تسديد سحري تلقائي عبر المحفظة',
      currencyName: currency,
      category: 'تسديد',
    );

    await _dbHelper.insertTransaction(tx);
  }
}
