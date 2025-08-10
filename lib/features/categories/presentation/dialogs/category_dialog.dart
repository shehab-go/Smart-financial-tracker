import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const CategoryDialog({super.key, this.category});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _nameArabicController;
  late final TextEditingController _iconController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _nameArabicController = TextEditingController(text: widget.category?.nameArabic ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArabicController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameArabicController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة بالعربية', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.translate)
              ),
              validator: (value) => (value == null || value.trim().isEmpty) 
                  ? 'يرجى إدخال اسم الفئة بالعربية' 
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة بالإنجليزية', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.abc)
              ),
              validator: (value) => (value == null || value.trim().isEmpty) 
                  ? 'يرجى إدخال اسم الفئة بالإنجليزية' 
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'رمز الفئة (إيموجي)', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.emoji_emotions), 
                hintText: '🏠 🚗 🍽️ 💼'
              ),
              validator: (value) => (value == null || value.trim().isEmpty) 
                  ? 'يرجى إدخال رمز للفئة' 
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('إلغاء')
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(isEditing ? 'تعديل' : 'إضافة'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final category = CategoryModel(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        nameArabic: _nameArabicController.text.trim(),
        icon: _iconController.text.trim(),
      );
      Navigator.pop(context, category);
    }
  }
}
