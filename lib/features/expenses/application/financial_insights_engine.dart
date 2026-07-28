import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/models/financial_insight_model.dart';
import 'package:intl/intl.dart';

class FinancialInsightsEngine {
  /// Generates real-time financial insights based on expense analysis
  static List<FinancialInsight> generateInsights(List<ExpenseModel> allExpenses) {
    final List<FinancialInsight> insights = [];
    if (allExpenses.isEmpty) return insights;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Previous month calculation
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonth = prevMonthDate.month;
    final prevYear = prevMonthDate.year;

    // Filter current month & previous month expenses
    final currentMonthExpenses = allExpenses.where((e) {
      final date = e.createdDate;
      return date.month == currentMonth && date.year == currentYear;
    }).toList();

    final prevMonthExpenses = allExpenses.where((e) {
      final date = e.createdDate;
      return date.month == prevMonth && date.year == prevYear;
    }).toList();

    // 1. Month-over-Month (MoM) Category Comparison Insights
    final Map<String, double> currentCategoryTotals = {};
    for (var e in currentMonthExpenses) {
      final cat = e.category.isEmpty ? 'عام' : e.category;
      currentCategoryTotals[cat] = (currentCategoryTotals[cat] ?? 0.0) + e.amount;
    }

    final Map<String, double> prevCategoryTotals = {};
    for (var e in prevMonthExpenses) {
      final cat = e.category.isEmpty ? 'عام' : e.category;
      prevCategoryTotals[cat] = (prevCategoryTotals[cat] ?? 0.0) + e.amount;
    }

    currentCategoryTotals.forEach((cat, currentAmount) {
      final prevAmount = prevCategoryTotals[cat] ?? 0.0;
      if (prevAmount > 0) {
        final double changePercent = ((currentAmount - prevAmount) / prevAmount) * 100;
        if (changePercent >= 20) {
          final formattedAmount = NumberFormat('#,##0', 'ar').format(currentAmount);
          insights.add(
            FinancialInsight(
              id: 'mom_inc_$cat',
              title: 'ارتفاع في إنفاق $cat',
              description: 'ارتفع إنفاقك على فئة ($cat) بنسبة ${changePercent.toStringAsFixed(0)}% مقارنة بالشهر السابق (مجموع $formattedAmount).',
              type: FinancialInsightType.increase,
              percentageChange: changePercent,
              category: cat,
              icon: Icons.trending_up_rounded,
              primaryColor: const Color(0xFFFF9800),
            ),
          );
        } else if (changePercent <= -15) {
          insights.add(
            FinancialInsight(
              id: 'mom_dec_$cat',
              title: 'وفر مالي ممتازة في $cat',
              description: 'أحسنت! انخفض إنفاقك في فئة ($cat) بنسبة ${changePercent.abs().toStringAsFixed(0)}% مقارنة بالشهر السابق.',
              type: FinancialInsightType.success,
              percentageChange: changePercent,
              category: cat,
              icon: Icons.thumb_up_alt_rounded,
              primaryColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
    });

    // 2. End-of-Month Predictive Spending Projection
    if (now.day >= 3 && currentMonthExpenses.isNotEmpty) {
      final double totalSpentSoFar = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final double dailyBurnRate = totalSpentSoFar / now.day;
      final int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final double projectedTotal = dailyBurnRate * totalDaysInMonth;

      final formattedProjected = NumberFormat('#,##0', 'ar').format(projectedTotal);
      final formattedDaily = NumberFormat('#,##0', 'ar').format(dailyBurnRate);

      insights.add(
        FinancialInsight(
          id: 'monthly_projection',
          title: 'التوقع المالي لنهاية الشهر',
          description: 'بناءً على معدل إنفاقك اليومي ($formattedDaily ر.ي/يوم)، من المتوقع أن يصل إجمالي المصروفات لـ $formattedProjected ر.ي بنهاية الشهر.',
          type: FinancialInsightType.info,
          icon: Icons.insights_rounded,
          primaryColor: const Color(0xFF2196F3),
        ),
      );
    }

    // 3. Anomaly / High Individual Expense Detection
    if (allExpenses.length > 5) {
      final double averageExpense = allExpenses.fold(0.0, (sum, e) => sum + e.amount) / allExpenses.length;
      final recentHighExpenses = currentMonthExpenses.where((e) => e.amount >= (averageExpense * 2.5)).toList();

      if (recentHighExpenses.isNotEmpty) {
        final topExpense = recentHighExpenses.first;
        final formattedAmount = NumberFormat('#,##0', 'ar').format(topExpense.amount);
        insights.add(
          FinancialInsight(
            id: 'anomaly_${topExpense.id}',
            title: 'عملية إنفاق استثنائية',
            description: 'تم تسجيل عملية بمبلغ $formattedAmount ر.ي (${topExpense.name.isNotEmpty ? topExpense.name : topExpense.category}) وهي أعلى بـ ${(topExpense.amount / averageExpense).toStringAsFixed(1)} ضعف من متوسط إنفاقك.',
            type: FinancialInsightType.warning,
            category: topExpense.category,
            icon: Icons.warning_amber_rounded,
            primaryColor: const Color(0xFFE53935),
          ),
        );
      }
    }

    return insights;
  }
}
