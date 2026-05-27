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
  
  String? _selectedGeneralParent;
  String? _selectedExpenseParent;
  final GlobalKey _generalChipKey = GlobalKey();
  final GlobalKey _expenseChipKey = GlobalKey();

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
              String? activeParent = _tabController.index == 0 ? _selectedGeneralParent : _selectedExpenseParent;
              _showCategoryDialog(defaultType: defaultType, defaultParentName: activeParent);
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
    // 1. Get Main Categories (categories with no parent)
    final rootCategories = categories.where((c) => c.parentName == null || c.parentName!.isEmpty).map((c) => c.name).toSet();
    
    // Also include any parentNames that exist in subcategories just in case
    final explicitParentNames = categories.map((c) => c.parentName).where((p) => p != null && p.isNotEmpty).cast<String>().toSet();
    
    final parentNames = {...rootCategories, ...explicitParentNames}.toList();
    parentNames.sort();

    // 2. Determine selected parent
    String? selectedParent = type == 'general' ? _selectedGeneralParent : _selectedExpenseParent;
    
    if (selectedParent == null && parentNames.isNotEmpty) {
      selectedParent = parentNames.first;
    } else if (selectedParent != null && !parentNames.contains(selectedParent) && parentNames.isNotEmpty) {
      selectedParent = parentNames.first;
    } else if (parentNames.isEmpty) {
      selectedParent = null;
    }
    
    // 3. Filter list to show subcategories and the parent itself
    List<CategoryModel> filteredCategories = [];
    if (selectedParent != null) {
      filteredCategories = categories.where((c) => 
        c.parentName == selectedParent || 
        (c.name == selectedParent && (c.parentName == null || c.parentName!.isEmpty))
      ).toList();
    } else {
      // If no parents exist at all, just show everything (fallback)
      filteredCategories = categories;
    }

    if (type == 'general') {
      return categories.isEmpty
          ? const CategoryEmptyState()
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 88),
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
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) async {
                HapticFeedback.mediumImpact();
                try {
                  await _controller.reorderCategories(oldIndex, newIndex, type);
                  _hasChanges = true;
                } catch (e) {
                  _showErrorMessage('خطأ أثناء إعادة الترتيب: $e');
                }
              },
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryListItem(
                  key: ValueKey(category.id ?? index),
                  category: category,
                  index: index,
                  onEdit: () => _editCategory(category),
                  onDelete: () => _deleteCategory(category),
                );
              },
            );
    }

    return Column(
      children: [
        // Horizontal scroll for parents
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(parentNames.length + 1, (index) {
                if (index == parentNames.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
                    child: ActionChip(
                      label: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.primaryColor),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showCategoryDialog(defaultType: type, forceNoParent: true);
                      },
                    ),
                  );
                }
                final parent = parentNames[index];
                final isSelected = parent == selectedParent;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
                  child: ChoiceChip(
                    key: isSelected ? (type == 'general' ? _generalChipKey : _expenseChipKey) : null,
                    label: Text(parent, style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    )),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                      width: 1,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (type == 'general') {
                            _selectedGeneralParent = parent;
                          } else {
                            _selectedExpenseParent = parent;
                          }
                        });
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
        
        // List of categories for the selected parent
        Expanded(
          child: filteredCategories.isEmpty
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
                  itemCount: filteredCategories.length,
                  onReorder: (oldIndex, newIndex) async {
                    HapticFeedback.mediumImpact();
                    try {
                      await _controller.reorderCategories(oldIndex, newIndex, type);
                      _hasChanges = true;
                    } catch (e) {
                      _showErrorMessage('خطأ أثناء إعادة الترتيب: $e');
                    }
                  },
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
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

          setState(() {
            if (mainCat.type == 'general') {
              _selectedGeneralParent = mainCat.name;
            } else {
              _selectedExpenseParent = mainCat.name;
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final key = mainCat.type == 'general' ? _generalChipKey : _expenseChipKey;
            if (key.currentContext != null) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: 0.5,
              );
            }
          });
          
          _showSuccessMessage('تم إضافة الفئة بنجاح');
        } else if (result is CategoryModel) {
          if (category != null) {
            await _controller.updateCategory(result);
            _hasChanges = true;
            _showSuccessMessage('تم تعديل الفئة بنجاح');
          } else {
            await _controller.addCategory(result);
            _hasChanges = true;
            
            if (result.parentName != null && result.parentName!.isNotEmpty) {
              setState(() {
                if (result.type == 'general') {
                  _selectedGeneralParent = result.parentName;
                } else {
                  _selectedExpenseParent = result.parentName;
                }
              });
            } else if (result.parentName == null || result.parentName!.isEmpty) {
              setState(() {
                if (result.type == 'general') {
                  _selectedGeneralParent = result.name;
                } else {
                  _selectedExpenseParent = result.name;
                }
              });
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final key = result.type == 'general' ? _generalChipKey : _expenseChipKey;
                if (key.currentContext != null) {
                  Scrollable.ensureVisible(
                    key.currentContext!,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    alignment: 0.5,
                  );
                }
              });
            }
            
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
