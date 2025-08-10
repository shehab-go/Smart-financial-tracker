import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/category.dart';

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
    return AppBar(
      centerTitle: false,
      leading: IconButton(icon: const Icon(Icons.print), tooltip: 'تقرير', onPressed: onShowReportOptions),
      titleSpacing: 0,
      title: AnimatedBuilder(
        animation: tabController,
        builder: (context, child) {
          if (tabController.index < categories.length) {
            final currentCategory = categories[tabController.index];
            return Align(
              alignment: Alignment.centerRight,
              child: Text(currentCategory.name),
            );
          }
          return const Text('إدارة الأموال الشخصية');
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'القائمة',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
      bottom: bottom,
    );
  }
}

