import 'dart:async';

/// Types of financial data change events
enum FinancialEventType {
  transactionAdded,
  transactionUpdated,
  transactionDeleted,
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  balanceUpdated,
  radarClassified,
}

/// Event model representing a financial data change
class FinancialEvent {
  final FinancialEventType type;
  final String? referenceId;
  final dynamic data;

  FinancialEvent({
    required this.type,
    this.referenceId,
    this.data,
  });
}

/// Global Reactive Event Bus for financial state management
class FinancialEventBus {
  static final FinancialEventBus _instance = FinancialEventBus._internal();
  factory FinancialEventBus() => _instance;
  FinancialEventBus._internal();

  final StreamController<FinancialEvent> _controller = StreamController<FinancialEvent>.broadcast();

  /// Reactive Stream of financial events
  Stream<FinancialEvent> get events => _controller.stream;

  /// Emit a new financial event to all listeners
  void emit(FinancialEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Dispose event bus controller
  void dispose() {
    _controller.close();
  }
}
