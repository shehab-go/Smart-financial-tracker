import 'package:flutter_test/flutter_test.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/events/category_events.dart';
import 'package:debit_credit_app/features/categories/domain/categories_repository.dart';
import 'package:debit_credit_app/features/categories/application/categories_controller.dart';

class MockCategoriesRepository extends CategoriesRepository {
  List<CategoryModel> categories = [
    CategoryModel(id: 1, name: 'Category 1', sortOrder: 0, type: 'general'),
    CategoryModel(id: 2, name: 'Category 2', sortOrder: 1, type: 'general'),
    CategoryModel(id: 3, name: 'Category 3', sortOrder: 2, type: 'general'),
  ];
  
  bool updateOrderCalled = false;
  List<CategoryModel>? updatedOrderList;

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    return categories;
  }

  @override
  Future<void> updateCategoriesOrder(List<CategoryModel> categoriesList) async {
    updateOrderCalled = true;
    updatedOrderList = categoriesList;
    categories = categoriesList;
  }

  @override
  Future<void> repairCategories() async {
    // No-op for testing reordering behavior
  }
}

void main() {
  group('CategoriesController Reordering Tests', () {
    late MockCategoriesRepository repository;
    late CategoriesController controller;

    setUp(() {
      repository = MockCategoriesRepository();
      controller = CategoriesController(repository: repository);
    });

    test('loadCategories loads list sorted by sortOrder', () async {
      await controller.loadCategories();
      expect(controller.state.generalCategories.length, 3);
      expect(controller.state.generalCategories[0].name, 'Category 1');
      expect(controller.state.generalCategories[1].name, 'Category 2');
      expect(controller.state.generalCategories[2].name, 'Category 3');
    });

    test('reorderCategories moves item down (oldIndex < newIndex)', () async {
      await controller.loadCategories();
      
      // Move 'Category 1' (index 0) to after 'Category 2' (newIndex will be 2)
      await controller.reorderCategories(0, 2, 'general');

      expect(controller.state.generalCategories[0].name, 'Category 2');
      expect(controller.state.generalCategories[1].name, 'Category 1');
      expect(controller.state.generalCategories[2].name, 'Category 3');

      expect(repository.updateOrderCalled, true);
      expect(repository.updatedOrderList![0].name, 'Category 2');
      expect(repository.updatedOrderList![1].name, 'Category 1');
      expect(repository.updatedOrderList![2].name, 'Category 3');
    });

    test('reorderCategories moves item up (oldIndex > newIndex)', () async {
      await controller.loadCategories();
      
      // Move 'Category 3' (index 2) to index 0. (newIndex = 0, oldIndex = 2)
      await controller.reorderCategories(2, 0, 'general');

      expect(controller.state.generalCategories[0].name, 'Category 3');
      expect(controller.state.generalCategories[1].name, 'Category 1');
      expect(controller.state.generalCategories[2].name, 'Category 2');

      expect(repository.updateOrderCalled, true);
    });

    test('reorderCategories emits a CategoryEvent.reordered event', () async {
      await controller.loadCategories();

      CategoryEvent? emittedEvent;
      final subscription = CategoryEventBus().events.listen((event) {
        emittedEvent = event;
      });

      await controller.reorderCategories(0, 2, 'general');

      await Future.delayed(Duration.zero);

      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.type, CategoryEventType.reordered);

      await subscription.cancel();
    });
  });
}
