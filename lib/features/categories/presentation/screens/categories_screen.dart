import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(_hasChanges);
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'إدارة الفئات',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppTheme.primaryColor,
              iconSize: 20,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(_hasChanges);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.primaryColor,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _controller.loadCategories();
                },
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const CategoryHeader(),
                      Expanded(
                        child: state.categories.isEmpty
                            ? const CategoryEmptyState()
                            : ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 88),
                                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (BuildContext context, Widget? child) {
                                      final double animValue = Curves.easeInOut.transform(animation.value);
                                      final double scale = 1.0 + (animValue * 0.02);
                                      return Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: 0.9,
                                          child: Material(
                                            color: Colors.transparent,
                                            elevation: 0,
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                itemCount: state.categories.length,
                                onReorder: (oldIndex, newIndex) async {
                                  HapticFeedback.mediumImpact();
                                  try {
                                    await _controller.reorderCategories(oldIndex, newIndex);
                                    _hasChanges = true;
                                  } catch (e) {
                                    _showErrorMessage('خطأ أثناء إعادة الترتيب: $e');
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final category = state.categories[index];
                                  return CategoryListItem(
                                    key: ValueKey(category.id ?? index),
                                    category: category,
                                    index: index,
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              _addCategory();
            },
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 24,
            ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'حذف الفئة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف فئة "${category.name}"؟\n\n'
          'سيتم حذف جميع الحسابات والمعاملات المرتبطة بهذه الفئة.',
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              HapticFeedback.vibrate();
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
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
