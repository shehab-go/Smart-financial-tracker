import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد فئات حالياً',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على زر الإضافة بالأسفل لإنشاء فئة جديدة وإدارة حساباتك المالية.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
