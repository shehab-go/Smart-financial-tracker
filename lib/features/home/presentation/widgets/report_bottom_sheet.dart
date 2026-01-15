import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          leading: SvgPicture.asset(
            'assets/images/report_icons/pdf_report.svg',
            width: 24,
            height: 24,
          ),
          title: const Text('تقرير الفئة الحالية'),
          onTap: () {
            Navigator.pop(context);
            onCurrentCategory();
          },
        ),
        ListTile(
          leading: SvgPicture.asset(
            'assets/images/report_icons/pdf_report.svg',
            width: 24,
            height: 24,
          ),
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
