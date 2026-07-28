import 'package:flutter/foundation.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/installment_plan.dart';
import 'package:debit_credit_app/core/models/transaction.dart';
import 'package:debit_credit_app/core/models/expense.dart';
import 'package:debit_credit_app/core/events/financial_events.dart';

class InstallmentService {
  static final InstallmentService instance = InstallmentService._internal();
  factory InstallmentService() => instance;
  InstallmentService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  DateTime calculateNextDueDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      case 'monthly':
      default:
        int newYear = current.year;
        int newMonth = current.month + 1;
        if (newMonth > 12) {
          newYear++;
          newMonth = 1;
        }
        int maxDay = DateTime(newYear, newMonth + 1, 0).day;
        int newDay = current.day > maxDay ? maxDay : current.day;
        return DateTime(newYear, newMonth, newDay, current.hour, current.minute);
    }
  }

  Future<bool> savePlan(InstallmentPlanModel plan) async {
    try {
      if (plan.id == null) {
        await _db.insertInstallmentPlan(plan);
      } else {
        await _db.updateInstallmentPlan(plan);
      }
      FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionAdded));
      return true;
    } catch (e) {
      debugPrint('Error saving installment plan: $e');
      return false;
    }
  }

  Future<bool> deletePlan(int planId) async {
    try {
      await _db.deleteInstallmentPlan(planId);
      FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionDeleted));
      return true;
    } catch (e) {
      debugPrint('Error deleting installment plan: $e');
      return false;
    }
  }

  Future<bool> payInstallment(InstallmentPlanModel plan, {String? notes}) async {
    try {
      final now = DateTime.now();
      int? createdTxId;
      int? createdExpId;

      // 1. Record debt transaction if linked to an account
      if (plan.accountId != null) {
        final tx = TransactionModel(
          accountId: plan.accountId!,
          amount: plan.installmentAmount,
          type: 'debit',
          category: plan.expenseCategory ?? 'قسط',
          currencyName: plan.currencyName,
          date: now,
          description: 'سداد دفعة قسط: ${plan.title} (دفعة ${plan.paidCount + 1})',
        );
        createdTxId = await _db.insertTransaction(tx);
      } else if (plan.expenseCategory != null && plan.expenseCategory!.isNotEmpty) {
        // 2. Record expense if linked to an expense category
        final exp = ExpenseModel(
          name: '${plan.title} (دفعة ${plan.paidCount + 1})',
          amount: plan.installmentAmount,
          category: plan.expenseCategory!,
          currency: plan.currencyName,
          createdDate: now,
          detail: 'سداد التزام مجدول تلقائي: ${plan.title}',
        );
        createdExpId = await _db.insertExpense(exp);
      }

      // 3. Record installment payment entry
      final payment = InstallmentPaymentModel(
        planId: plan.id!,
        installmentNumber: plan.paidCount + 1,
        dueDate: plan.nextDueDate,
        paidDate: now,
        amount: plan.installmentAmount,
        currencyName: plan.currencyName,
        status: 'paid',
        transactionId: createdTxId,
        expenseId: createdExpId,
        notes: notes,
      );
      await _db.insertInstallmentPayment(payment);

      // 4. Update plan state
      final newPaidCount = plan.paidCount + 1;
      final bool isPlanFullyPaid = plan.totalCount != null && newPaidCount >= plan.totalCount!;
      final nextDue = calculateNextDueDate(plan.nextDueDate, plan.frequency);

      final updatedPlan = plan.copyWith(
        paidCount: newPaidCount,
        nextDueDate: nextDue,
        status: isPlanFullyPaid ? 'completed' : plan.status,
      );

      await _db.updateInstallmentPlan(updatedPlan);
      FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionAdded));
      return true;
    } catch (e) {
      debugPrint('Error paying installment: $e');
      return false;
    }
  }
}
