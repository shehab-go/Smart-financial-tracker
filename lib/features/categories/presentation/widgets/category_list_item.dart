import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';

class CategoryListItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          category.name, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor), 
              onPressed: onEdit
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), 
              onPressed: onDelete
            ),
          ],
        ),
      ),
    );
  }
}
