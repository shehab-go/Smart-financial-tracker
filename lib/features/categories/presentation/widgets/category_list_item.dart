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
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(category.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          category.nameArabic, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text(
          category.name, 
          style: TextStyle(color: Colors.grey[600])
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
