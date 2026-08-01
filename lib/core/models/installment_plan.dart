class InstallmentPlanModel {
  final int? id;
  final String title;
  final String planType; // 'installment' or 'recurring_bill'
  final int? accountId;
  final String? accountName;
  final String? expenseCategory;
  final double? totalAmount;
  final double installmentAmount;
  final String currencyName;
  final int? totalCount;
  final int paidCount;
  final String frequency; // 'monthly', 'weekly', 'yearly'
  final DateTime firstDueDate;
  final DateTime nextDueDate;
  final int remindDaysBefore;
  final String status; // 'active', 'completed', 'paused'
  final String? notes;
  final DateTime createdDate;

  InstallmentPlanModel({
    this.id,
    required this.title,
    required this.planType,
    this.accountId,
    this.accountName,
    this.expenseCategory,
    this.totalAmount,
    required this.installmentAmount,
    this.currencyName = 'محلي',
    this.totalCount,
    this.paidCount = 0,
    this.frequency = 'monthly',
    required this.firstDueDate,
    required this.nextDueDate,
    this.remindDaysBefore = 3,
    this.status = 'active',
    this.notes,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'planType': planType,
      'accountId': accountId,
      'accountName': accountName,
      'expenseCategory': expenseCategory,
      'totalAmount': totalAmount,
      'installmentAmount': installmentAmount,
      'currencyName': currencyName,
      'totalCount': totalCount,
      'paidCount': paidCount,
      'frequency': frequency,
      'firstDueDate': firstDueDate.millisecondsSinceEpoch,
      'nextDueDate': nextDueDate.millisecondsSinceEpoch,
      'remindDaysBefore': remindDaysBefore,
      'status': status,
      'notes': notes,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory InstallmentPlanModel.fromMap(Map<String, dynamic> map) {
    return InstallmentPlanModel(
      id: map['id'] as int?,
      title: map['title']?.toString() ?? '',
      planType: map['planType']?.toString() ?? 'installment',
      accountId: map['accountId'] as int?,
      accountName: map['accountName']?.toString(),
      expenseCategory: map['expenseCategory']?.toString(),
      totalAmount: map['totalAmount'] != null ? (map['totalAmount'] as num).toDouble() : null,
      installmentAmount: map['installmentAmount'] != null ? (map['installmentAmount'] as num).toDouble() : 0.0,
      currencyName: map['currencyName']?.toString() ?? 'محلي',
      totalCount: map['totalCount'] as int?,
      paidCount: (map['paidCount'] as int?) ?? 0,
      frequency: map['frequency']?.toString() ?? 'monthly',
      firstDueDate: DateTime.fromMillisecondsSinceEpoch(map['firstDueDate'] as int),
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['nextDueDate'] as int),
      remindDaysBefore: (map['remindDaysBefore'] as int?) ?? 3,
      status: map['status']?.toString() ?? 'active',
      notes: map['notes']?.toString(),
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
    );
  }

  InstallmentPlanModel copyWith({
    int? id,
    String? title,
    String? planType,
    int? accountId,
    String? accountName,
    String? expenseCategory,
    double? totalAmount,
    double? installmentAmount,
    String? currencyName,
    int? totalCount,
    int? paidCount,
    String? frequency,
    DateTime? firstDueDate,
    DateTime? nextDueDate,
    int? remindDaysBefore,
    String? status,
    String? notes,
    DateTime? createdDate,
  }) {
    return InstallmentPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      planType: planType ?? this.planType,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      currencyName: currencyName ?? this.currencyName,
      totalCount: totalCount ?? this.totalCount,
      paidCount: paidCount ?? this.paidCount,
      frequency: frequency ?? this.frequency,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  bool get isCompleted => (totalCount != null && paidCount >= totalCount!) || status == 'completed';

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  bool get isOverdue => daysUntilDue < 0 && status == 'active';
  bool get isDueToday => daysUntilDue == 0 && status == 'active';
  bool get isDueSoon => daysUntilDue > 0 && daysUntilDue <= remindDaysBefore && status == 'active';
}

class InstallmentPaymentModel {
  final int? id;
  final int planId;
  final int installmentNumber;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double amount;
  final String currencyName;
  final String status; // 'pending', 'paid', 'overdue', 'skipped'
  final int? transactionId;
  final int? expenseId;
  final String? notes;

  InstallmentPaymentModel({
    this.id,
    required this.planId,
    required this.installmentNumber,
    required this.dueDate,
    this.paidDate,
    required this.amount,
    this.currencyName = 'محلي',
    this.status = 'pending',
    this.transactionId,
    this.expenseId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'installmentNumber': installmentNumber,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'paidDate': paidDate?.millisecondsSinceEpoch,
      'amount': amount,
      'currencyName': currencyName,
      'status': status,
      'transactionId': transactionId,
      'expenseId': expenseId,
      'notes': notes,
    };
  }

  factory InstallmentPaymentModel.fromMap(Map<String, dynamic> map) {
    return InstallmentPaymentModel(
      id: map['id'] as int?,
      planId: map['planId'] as int,
      installmentNumber: (map['installmentNumber'] as int?) ?? 1,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      paidDate: map['paidDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['paidDate'] as int) : null,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : 0.0,
      currencyName: map['currencyName']?.toString() ?? 'محلي',
      status: map['status']?.toString() ?? 'pending',
      transactionId: map['transactionId'] as int?,
      expenseId: map['expenseId'] as int?,
      notes: map['notes']?.toString(),
    );
  }
}
