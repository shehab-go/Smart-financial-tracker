import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class ReportBottomSheet extends StatelessWidget {
  final VoidCallback onCurrentCategory;
  final VoidCallback onAllCategories;
  final VoidCallback onEditProfile;

  const ReportBottomSheet({
    super.key,
    required this.onCurrentCategory,
    required this.onAllCategories,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: SvgPicture.asset(
              'assets/images/report_icons/pdf_report.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppTheme.primaryColor,
                BlendMode.srcIn,
              ),
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
              colorFilter: const ColorFilter.mode(
                AppTheme.primaryColor,
                BlendMode.srcIn,
              ),
            ),
            title: const Text('تقرير جميع الفئات'),
            onTap: () {
              Navigator.pop(context);
              onAllCategories();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            title: const Text(
              'تعديل الملف الشخصي',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onEditProfile();
            },
          ),
        ],
      ),
    );
  }
}
