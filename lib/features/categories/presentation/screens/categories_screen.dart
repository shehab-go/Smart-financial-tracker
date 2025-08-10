import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await DatabaseHelper().getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الفئات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفئات'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إدارة فئات الحسابات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يمكنك إضافة وتعديل وحذف فئات الحسابات',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('لا توجد فئات', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('اضغط على زر + لإضافة فئة جديدة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                                ),
                                title: Text(category.nameArabic, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(category.name, style: TextStyle(color: Colors.grey[600])),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: Icon(Icons.edit, color: Theme.of(context).primaryColor), onPressed: () => _editCategory(category)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(category)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCategory() => _showCategoryDialog();
  void _editCategory(CategoryModel category) => _showCategoryDialog(category: category);

  void _showCategoryDialog({CategoryModel? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final nameArabicController = TextEditingController(text: category?.nameArabic ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameArabicController,
                decoration: const InputDecoration(labelText: 'اسم الفئة بالعربية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.translate)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم الفئة بالعربية' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الفئة بالإنجليزية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.abc)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم الفئة بالإنجليزية' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'رمز الفئة (إيموجي)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.emoji_emotions), hintText: '🏠 🚗 🍽️ 💼'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال رمز للفئة' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final newCategory = CategoryModel(
                    id: category?.id,
                    name: nameController.text.trim(),
                    nameArabic: nameArabicController.text.trim(),
                    icon: iconController.text.trim(),
                  );
                  if (isEditing) {
                    await DatabaseHelper().updateCategory(newCategory);
                  } else {
                    await DatabaseHelper().insertCategory(newCategory);
                  }
                  Navigator.pop(context);
                  _loadCategories();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'تم تعديل الفئة بنجاح' : 'تم إضافة الفئة بنجاح'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'تعديل' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل أنت متأكد من حذف فئة "${category.nameArabic}"؟\n\nسيتم حذف جميع الحسابات والمعاملات المرتبطة بهذه الفئة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await DatabaseHelper().deleteCategory(category.id!);
                Navigator.pop(context);
                _loadCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الفئة بنجاح'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في حذف الفئة: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
