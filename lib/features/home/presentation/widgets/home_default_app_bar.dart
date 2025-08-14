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
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.description,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'تقرير',
            onPressed: onShowReportOptions,
          ),
        ),
        titleSpacing: 16,
        title: Text(
          'إدارة الأموال الشخصية',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
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

