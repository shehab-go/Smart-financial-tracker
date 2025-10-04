import 'dart:async';

/// Event types for category changes
enum CategoryEventType {
  added,
  updated,
  deleted,
}

/// Category change event
class CategoryEvent {
  final CategoryEventType type;
  final String? categoryName;
  final int? categoryId;

  CategoryEvent({
    required this.type,
    this.categoryName,
    this.categoryId,
  });
}

/// Global event bus for category changes
class CategoryEventBus {
  static final CategoryEventBus _instance = CategoryEventBus._internal();
  factory CategoryEventBus() => _instance;
  CategoryEventBus._internal();

  final StreamController<CategoryEvent> _controller = StreamController<CategoryEvent>.broadcast();

  /// Stream of category events
  Stream<CategoryEvent> get events => _controller.stream;

  /// Emit a category event
  void emit(CategoryEvent event) {
    _controller.add(event);
  }

  /// Dispose the event bus
  void dispose() {
    _controller.close();
  }
}