import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/categories/application/categories_controller.dart';
import 'package:debit_credit_app/features/categories/presentation/widgets/category_header.dart';
import 'package:debit_credit_app/features/categories/presentation/widgets/category_empty_state.dart';
import 'package:debit_credit_app/features/categories/presentation/widgets/category_list_item.dart';
import 'package:debit_credit_app/features/categories/presentation/dialogs/category_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = CategoriesController();
    _controller.addListener(_onStateChanged);
    _controller.loadCategories();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }



  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: Colors.white,
          title: const Text('إدارة الفئات'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.loadCategories(),
            ),
          ],
        ),
      body: Container(
        color: Colors.white,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const CategoryHeader(),
                  Expanded(
                    child: state.categories.isEmpty
                        ? const CategoryEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.categories.length,
                            itemBuilder: (context, index) {
                              final category = state.categories[index];
                              return CategoryListItem(
                                category: category,
                                onEdit: () => _editCategory(category),
                                onDelete: () => _deleteCategory(category),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    ),
    );
  }



  void _addCategory() => _showCategoryDialog();

  void _editCategory(CategoryModel category) => _showCategoryDialog(category: category);

  Future<void> _showCategoryDialog({CategoryModel? category}) async {
    final result = await showDialog<CategoryModel>(
      context: context,
      builder: (context) => CategoryDialog(category: category),
    );

    if (result != null && mounted) {
      try {
        if (category != null) {
          await _controller.updateCategory(result);
          _hasChanges = true;
          _showSuccessMessage('تم تعديل الفئة بنجاح');
        } else {
          await _controller.addCategory(result);
          _hasChanges = true;
          _showSuccessMessage('تم إضافة الفئة بنجاح');
        }
      } catch (e) {
        _showErrorMessage('خطأ: $e');
      }
    }
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('حذف الفئة'),
        content: Text(
          'هل أنت متأكد من حذف فئة "${category.name}"؟\n\n'
          'سيتم حذف جميع الحسابات والمعاملات المرتبطة بهذه الفئة.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteCategory(category.id!);
                _hasChanges = true;
                if (mounted) {
                  _showSuccessMessage('تم حذف الفئة بنجاح');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorMessage('خطأ في حذف الفئة: $e');
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.green
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.red
      ),
    );
  }
}
