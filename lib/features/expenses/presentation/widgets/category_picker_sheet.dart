import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_theme.dart';

class ExpenseCategoryPickerSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? initialCategory;

  const ExpenseCategoryPickerSheet({
    Key? key,
    required this.categories,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<ExpenseCategoryPickerSheet> createState() => _ExpenseCategoryPickerSheetState();
}

class _ExpenseCategoryPickerSheetState extends State<ExpenseCategoryPickerSheet> {
  String _searchQuery = '';
  late List<CategoryModel> _filteredCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories.where((c) {
          final matchName = c.name.toLowerCase().contains(_searchQuery);
          final matchParent = (c.parentName ?? '').toLowerCase().contains(_searchQuery);
          return matchName || matchParent;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group categories by parentName or their own name if they are root
    final Map<String, List<CategoryModel>> groupedCategories = {};
    for (var cat in _filteredCategories) {
      final String groupName = (cat.parentName == null || cat.parentName!.isEmpty) ? cat.name : cat.parentName!;
      groupedCategories.putIfAbsent(groupName, () => []).add(cat);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Handle for sliding down
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اختر فئة المصروف',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فئة...',
                  hintStyle: TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            Expanded(
              child: _filteredCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'لم يتم العثور على أي فئة تطابق "$_searchQuery"',
                            style: const TextStyle(
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                      itemCount: groupedCategories.keys.length + 1,
                      itemBuilder: (context, index) {
                        if (index == groupedCategories.keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 32),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop('__MANAGE_MAIN__');
                                },
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                label: const Text('إضافة فئة رئيسية', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        final String groupName = groupedCategories.keys.elementAt(index);
                        final List<CategoryModel> groupItems = groupedCategories[groupName]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 12, top: 8),
                                child: Text(
                                  groupName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: groupItems.map((cat) {
                                  final bool isSelected = widget.initialCategory == cat.name;
                                  final int colorVal = cat.colorValue ?? AppTheme.primaryColor.value;
                                  final Color catColor = Color(colorVal);

                                  return InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).pop(cat.name);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? catColor.withOpacity(0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? catColor : Colors.grey.shade200,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (cat.iconCodePoint != null) ...[
                                            Icon(
                                              IconData(cat.iconCodePoint!, fontFamily: 'MaterialIcons'),
                                              size: 16,
                                              color: catColor,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            cat.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? catColor : AppTheme.textPrimary,
                                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList()
                                  ..add(
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.of(context).pop('__MANAGE:$groupName');
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.primaryColor.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
