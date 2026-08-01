import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull-to-dismiss bar indicator
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 1. Report Current Category
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'تقرير الفئة الحالية',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onCurrentCategory();
                },
              ),
              const Divider(height: 1, color: Colors.black12),

              // 2. Report All Categories
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'تقرير جميع الفئات',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onAllCategories();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
