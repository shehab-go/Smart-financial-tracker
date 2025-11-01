import 'package:flutter/material.dart';

class ReportBottomSheet extends StatelessWidget {
  final VoidCallback onCurrentCategory;
  final VoidCallback onAllCategories;

  const ReportBottomSheet({
    super.key,
    required this.onCurrentCategory,
    required this.onAllCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('تقرير الفئة الحالية'),
          onTap: () {
            Navigator.pop(context);
            onCurrentCategory();
          },
        ),
        ListTile(
          leading: const Icon(Icons.receipt),
          title: const Text('تقرير جميع الفئات'),
          onTap: () {
            Navigator.pop(context);
            onAllCategories();
          },
        ),
      ],
    );
  }
}
