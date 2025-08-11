import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class HomeDefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onShowReportOptions;
  final TabController tabController;
  final List<CategoryModel> categories;
  final PreferredSizeWidget bottom;

  const HomeDefaultAppBar({
    super.key,
    required this.onShowReportOptions,
    required this.tabController,
    required this.categories,
    required this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom.preferredSize.height));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.assessment_rounded,
              color: AppTheme.primaryColor,
            ),
            tooltip: 'تقرير',
            onPressed: onShowReportOptions,
          ),
        ),
        titleSpacing: 16,
        title: AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            if (tabController.index < categories.length) {
              final currentCategory = categories[tabController.index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة الأموال الشخصية',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    currentCategory.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              );
            }
            return Text(
              'إدارة الأموال الشخصية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'القائمة',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ],
        bottom: bottom,
      ),
    );
  }
}

