import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeSelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final bool isDrawerOpen;

  const HomeSelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onDelete,
    required this.onPrint,
    required this.onShare,
    this.isDrawerOpen = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: onClearSelection),
      title: Text('تم تحديد $selectedCount'),
      // Edge-to-edge handled globally; avoid direct system bar styling.
      actions: [
        IconButton(icon: const Icon(Icons.select_all), tooltip: 'تحديد الكل', onPressed: onSelectAll),
        IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        IconButton(icon: const Icon(Icons.print), onPressed: onPrint),
        IconButton(icon: const Icon(Icons.share), onPressed: onShare),
        if (!isDrawerOpen)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
      ],
    );
  }
}

