class TransactionBalanceAllocation {
  final int? id;
  final int transactionId;
  final int balanceId;
  final double allocatedAmount;

  TransactionBalanceAllocation({
    this.id,
    required this.transactionId,
    required this.balanceId,
    required this.allocatedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'balanceId': balanceId,
      'allocatedAmount': allocatedAmount,
    };
  }

  factory TransactionBalanceAllocation.fromMap(Map<String, dynamic> map) {
    return TransactionBalanceAllocation(
      id: map['id'],
      transactionId: map['transactionId'],
      balanceId: map['balanceId'],
      allocatedAmount: (map['allocatedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  TransactionBalanceAllocation copyWith({
    int? id,
    int? transactionId,
    int? balanceId,
    double? allocatedAmount,
  }) {
    return TransactionBalanceAllocation(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      balanceId: balanceId ?? this.balanceId,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
    );
  }
}
