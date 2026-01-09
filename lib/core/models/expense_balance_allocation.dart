class ExpenseBalanceAllocation {
  final int? id;
  final int expenseId;
  final int balanceId;
  final double allocatedAmount;

  ExpenseBalanceAllocation({
    this.id,
    required this.expenseId,
    required this.balanceId,
    required this.allocatedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'balanceId': balanceId,
      'allocatedAmount': allocatedAmount,
    };
  }

  factory ExpenseBalanceAllocation.fromMap(Map<String, dynamic> map) {
    return ExpenseBalanceAllocation(
      id: map['id'],
      expenseId: map['expenseId'],
      balanceId: map['balanceId'],
      allocatedAmount: (map['allocatedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ExpenseBalanceAllocation copyWith({
    int? id,
    int? expenseId,
    int? balanceId,
    double? allocatedAmount,
  }) {
    return ExpenseBalanceAllocation(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      balanceId: balanceId ?? this.balanceId,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
    );
  }
}
