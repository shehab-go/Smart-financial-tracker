import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class HomeDefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onShowReportOptions;
  final TabController tabController;
  final List<CategoryModel> categories;
  final PreferredSizeWidget bottom;
  final bool isDrawerOpen;

  const HomeDefaultAppBar({
    super.key,
    required this.onShowReportOptions,
    required this.tabController,
    required this.categories,
    required this.bottom,
    this.isDrawerOpen = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom.preferredSize.height));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Don't add padding for status bar
        child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        // Edge-to-edge handled globally; avoid direct system bar styling.
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
            icon: SvgPicture.asset(
              'assets/images/report_icons/pdf_report.svg',
              width: 24,
              height: 24,
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
          if (!isDrawerOpen)
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
      ),
    );
  }
}

