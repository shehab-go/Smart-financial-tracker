import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/financial_insight_model.dart';
import 'package:intl/intl.dart';

class DebtInsightsEngine {
  /// Generates real-time financial insights for Debts & Credits accounts
  static List<FinancialInsight> generateInsights(List<AccountModel> accounts) {
    final List<FinancialInsight> insights = [];
    if (accounts.isEmpty) return insights;

    final now = DateTime.now();
    double totalDebit = 0; // Total money owed to user (لك)
    double totalCredit = 0; // Total money user owes to others (عليك)

    AccountModel? topDebtor;
    double maxNetDebit = 0;

    int inactiveOverdueCount = 0;

    for (var acc in accounts) {
      final netBalance = acc.totalDebit - acc.totalCredit;
      totalDebit += acc.totalDebit;
      totalCredit += acc.totalCredit;

      // Find largest debtor
      if (netBalance > maxNetDebit) {
        maxNetDebit = netBalance;
        topDebtor = acc;
      }

      // Check inactive overdue accounts (>30 days without transactions)
      final daysSinceLastTx = now.difference(acc.lastTransactionDate).inDays;
      if (netBalance.abs() > 0 && daysSinceLastTx >= 30) {
        inactiveOverdueCount++;
      }
    }

    // 1. Largest Debtor Concentration Alert
    if (topDebtor != null && totalDebit > 0 && maxNetDebit > 0) {
      final double ratio = (maxNetDebit / totalDebit) * 100;
      if (ratio >= 25) {
        final formattedAmount = NumberFormat('#,##0', 'ar').format(maxNetDebit);
        insights.add(
          FinancialInsight(
            id: 'top_debtor_${topDebtor.id}',
            title: 'تركّز الديون الحاد',
            description: 'يمثّل الحساب (${topDebtor.name}) نسبة ${ratio.toStringAsFixed(0)}% من إجمالي الديون المستحقة لك بمبلغ $formattedAmount ر.ي.',
            type: FinancialInsightType.warning,
            category: topDebtor.category,
            icon: Icons.person_search_rounded,
            primaryColor: const Color(0xFFFF9800),
          ),
        );
      }
    }

    // 2. Overdue / Inactive Accounts Alert
    if (inactiveOverdueCount > 0) {
      insights.add(
        FinancialInsight(
          id: 'overdue_accounts',
          title: 'ديون راكدة متأخرة',
          description: 'تنبيه: يوجد $inactiveOverdueCount حسابات مستحقة الدفع لم يُسجل عليها أي نشاط أو سداد منذ أكثر من 30 يوماً.',
          type: FinancialInsightType.increase,
          icon: Icons.history_toggle_off_rounded,
          primaryColor: const Color(0xFFE53935),
        ),
      );
    }

    // 3. Overall Debts vs Credits Net Position Summary
    final double netTotal = totalDebit - totalCredit;
    final formattedNet = NumberFormat('#,##0', 'ar').format(netTotal.abs());
    final formattedDebit = NumberFormat('#,##0', 'ar').format(totalDebit);
    final formattedCredit = NumberFormat('#,##0', 'ar').format(totalCredit);

    if (totalDebit > 0 || totalCredit > 0) {
      if (netTotal >= 0) {
        insights.add(
          FinancialInsight(
            id: 'debt_net_positive',
            title: 'ميزان الالتزامات والديون',
            description: 'إجمالي ما لك ($formattedDebit) يتجاوز إجمالي ما عليك ($formattedCredit) بصفاء مالي قدره $formattedNet ر.ي.',
            type: FinancialInsightType.success,
            icon: Icons.account_balance_rounded,
            primaryColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        insights.add(
          FinancialInsight(
            id: 'debt_net_negative',
            title: 'تحذير ميزان الديون',
            description: 'تنبيه: إجمالي الديون المطلوبة منك ($formattedCredit) تفوق مستحقاتك لدى الآخرين ($formattedDebit) بفارق $formattedNet ر.ي.',
            type: FinancialInsightType.warning,
            icon: Icons.account_balance_rounded,
            primaryColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }

    return insights;
  }
}
