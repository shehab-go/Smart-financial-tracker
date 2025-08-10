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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.category)
              ),
              validator: (value) => (value == null || value.trim().isEmpty) 
                  ? 'يرجى إدخال اسم الفئة' 
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
      );
      Navigator.pop(context, category);
    }
  }
}
