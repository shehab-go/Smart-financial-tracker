import 'package:flutter/material.dart';

class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد فئات', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600]
            )
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة فئة جديدة', 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500]
            )
          ),
        ],
      ),
    );
  }
}
