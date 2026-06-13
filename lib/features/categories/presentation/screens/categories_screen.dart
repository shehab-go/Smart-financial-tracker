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
  final int initialTabIndex;
  final bool autoOpenAddExpenseCategory;
  final bool autoAddForceNoParent;
  final String? autoAddParentName;

  const CategoriesScreen({
    super.key,
    this.initialTabIndex = 0,
    this.autoOpenAddExpenseCategory = false,
    this.autoAddForceNoParent = false,
    this.autoAddParentName,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final CategoriesController _controller;
  late final TabController _tabController;
  bool _hasChanges = false;
  
  // Keys for scrolling could go here if needed, but omitted for simplicity

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _controller = CategoriesController();
    _controller.addListener(_onStateChanged);
    _controller.loadCategories();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) HapticFeedback.selectionClick();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoOpenAddExpenseCategory) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _showCategoryDialog(
            defaultType: 'expense',
            defaultParentName: widget.autoAddParentName,
            forceNoParent: widget.autoAddForceNoParent,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primaryColor,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  tabs: const [
                    Tab(text: 'فئات الحسابات'),
                    Tab(text: 'فئات المصروفات'),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Accounts tab
                      _buildCategoryList(state.generalCategories, 'general'),
                      // Expenses tab
                      _buildCategoryList(state.expenseCategories, 'expense'),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_categories',
            onPressed: () {
              HapticFeedback.mediumImpact();
              final defaultType = _tabController.index == 0 ? 'general' : 'expense';
              _showCategoryDialog(defaultType: defaultType);
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

  Widget _buildCategoryList(List<CategoryModel> categories, String type) {
    if (categories.isEmpty) {
      return const CategoryEmptyState();
    }

    final Map<String, List<CategoryModel>> childrenMap = {};
    final Map<String, CategoryModel> parentModels = {};

    for (var cat in categories) {
      if (cat.parentName == null || cat.parentName!.isEmpty) {
        parentModels[cat.name] = cat;
      } else {
        childrenMap.putIfAbsent(cat.parentName!, () => []).add(cat);
      }
    }

    final allParentNames = {...parentModels.keys, ...childrenMap.keys}.toList();
    allParentNames.sort();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
      physics: const BouncingScrollPhysics(),
      itemCount: allParentNames.length + 1,
      itemBuilder: (context, index) {
        if (index == allParentNames.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: ActionChip(
                label: const Text('إضافة فئة رئيسية', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                avatar: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.primaryColor),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                side: const BorderSide(color: Colors.transparent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showCategoryDialog(defaultType: type, forceNoParent: true);
                },
              ),
            ),
          );
        }

        final parentName = allParentNames[index];
        final parentModel = parentModels[parentName];
        final children = childrenMap[parentName] ?? [];
        final hasChildren = children.isNotEmpty;

        final Color iconColor = parentModel?.colorValue != null ? Color(parentModel!.colorValue!) : AppTheme.primaryColor;
        final IconData iconData = parentModel?.iconCodePoint != null ? IconData(parentModel!.iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.folder_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5), width: 1),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              collapsedIconColor: AppTheme.textSecondary,
              iconColor: AppTheme.primaryColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              initiallyExpanded: type == 'expense' && index == 0,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(iconData, color: iconColor, size: 24)),
              ),
              title: Text(
                parentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
              subtitle: type == 'general' ? null : Text(
                hasChildren ? '${children.length} فروع' : 'لا يوجد فروع',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 13, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _editParentCategory(parentName, parentModel, children, type);
                        },
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 13, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _deleteParentCategory(parentName, parentModel, children);
                        },
                      ),
                    ],
                  ),
                ),
                if (children.isNotEmpty)
                  ...children.map((child) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CategoryListItem(
                          category: child,
                          index: children.indexOf(child),
                          onEdit: () => _editCategory(child),
                          onDelete: () => _deleteCategory(child),
                        ),
                      )).toList(),
                if (type != 'general')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('إضافة فرع', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showCategoryDialog(defaultType: type, defaultParentName: parentName);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addCategory() => _showCategoryDialog();

  void _editCategory(CategoryModel category) => _showCategoryDialog(category: category);

  Future<void> _showCategoryDialog({CategoryModel? category, String? defaultType, String? defaultParentName, bool forceNoParent = false}) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        defaultType: defaultType,
        defaultParentName: defaultParentName,
        forceNoParent: forceNoParent,
      ),
    );

    if (result != null && mounted) {
      try {
        if (result is List<CategoryModel>) {
          final mainCat = result[0];
          final subCat = result[1];
          await _controller.addCategory(mainCat);
          await _controller.addCategory(subCat);
          _hasChanges = true;
          
          _showSuccessMessage('تم إضافة الفئة بنجاح');
        } else if (result is CategoryModel) {
          if (category != null) {
            await _controller.updateCategory(result);
            _hasChanges = true;
            _showSuccessMessage('تم تعديل الفئة بنجاح');
          } else {
            await _controller.addCategory(result);
            _hasChanges = true;
            _showSuccessMessage('تم إضافة الفئة بنجاح');
          }
        }
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          _showErrorMessage('عذراً، هذا الاسم موجود مسبقاً. يرجى اختيار اسم آخر.');
        } else {
          _showErrorMessage('خطأ: $e');
        }
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

  void _deleteParentCategory(String parentName, CategoryModel? parentModel, List<CategoryModel> children) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف الفئة الرئيسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textPrimary)),
        content: Text(
          'هل أنت متأكد من حذف القائمة الرئيسية "$parentName"؟\n\n'
          'سيتم حذف هذه الفئة وجميع الفروع التابعة لها (${children.length} فروع) بشكل نهائي.',
          style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textSecondary, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              HapticFeedback.vibrate();
              Navigator.pop(context);
              try {
                if (parentModel != null && parentModel.id != null) {
                  await _controller.deleteCategory(parentModel.id!);
                }
                for (var child in children) {
                  if (child.id != null) {
                    await _controller.deleteCategory(child.id!);
                  }
                }
                _hasChanges = true;
                if (mounted) _showSuccessMessage('تم حذف الفئة والفروع بنجاح');
              } catch (e) {
                if (mounted) _showErrorMessage('خطأ: $e');
              }
            },
            child: const Text('حذف الجميع'),
          ),
        ],
      ),
    );
  }

  Future<void> _editParentCategory(String oldParentName, CategoryModel? parentModel, List<CategoryModel> children, String type) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => CategoryDialog(
        category: parentModel ?? CategoryModel(name: oldParentName, type: type),
        defaultType: type,
        forceNoParent: true,
      ),
    );

    if (result != null && mounted && result is CategoryModel) {
      try {
        final newName = result.name;
        
        if (parentModel != null) {
          await _controller.updateCategory(result);
        } else {
          await _controller.addCategory(result);
        }
        
        if (newName != oldParentName) {
          for (var child in children) {
            final updatedChild = CategoryModel(
              id: child.id,
              name: child.name,
              type: child.type,
              colorValue: child.colorValue,
              iconCodePoint: child.iconCodePoint,
              sortOrder: child.sortOrder,
              parentName: newName,
            );
            await _controller.updateCategory(updatedChild);
          }
        }
        
        _hasChanges = true;
        _showSuccessMessage('تم تعديل الفئة الرئيسية بنجاح');
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          _showErrorMessage('عذراً، هذا الاسم موجود مسبقاً.');
        } else {
          _showErrorMessage('خطأ: $e');
        }
      }
    }
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
