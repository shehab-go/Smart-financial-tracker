import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryModel? category;
  final String? defaultType;
  final String? defaultParentName;
  final bool forceNoParent;

  const CategoryDialog({
    super.key, 
    this.category, 
    this.defaultType,
    this.defaultParentName,
    this.forceNoParent = false,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _subCategoryNameController;
  final _formKey = GlobalKey<FormState>();

  int? _selectedColorValue;
  int? _selectedIconCode;

  final List<Color> _colors = [
    AppTheme.primaryColor,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.blueAccent,
    Colors.lightBlueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightGreenAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.brown,
    Colors.blueGrey,
  ];

  final List<IconData> _icons = [
    Icons.folder_rounded,
    Icons.shopping_cart_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.directions_car_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.home_rounded,
    Icons.electrical_services_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.phone_iphone_rounded,
    Icons.medical_services_rounded,
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.checkroom_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.savings_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.attach_money_rounded,
    Icons.credit_card_rounded,
    Icons.receipt_long_rounded,
    Icons.devices_other_rounded,
    Icons.build_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _parentNameController = TextEditingController(text: widget.category?.parentName ?? widget.defaultParentName ?? '');
    _subCategoryNameController = TextEditingController();
    
    _selectedColorValue = widget.category?.colorValue;
    _selectedIconCode = widget.category?.iconCodePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _subCategoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final isMainCategory = widget.forceNoParent;
    final Color activeColor = _selectedColorValue != null ? Color(_selectedColorValue!) : AppTheme.primaryColor;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedIconCode != null ? IconData(_selectedIconCode!, fontFamily: 'MaterialIcons') : Icons.category_rounded,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'تعديل الفئة' : (isMainCategory ? 'إضافة فئة رئيسية' : 'إضافة فرع جديد'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textPrimary),
                        ),
                        Text(
                          isEditing ? 'تحديث بيانات الفئة المحددة' : 'أدخل تفاصيل الفئة الجديدة',
                          style: const TextStyle(fontSize: 12, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 15, color: AppTheme.textPrimary),
                        decoration: _buildInputDecoration(
                          label: (isMainCategory && !isEditing) ? 'اسم الفئة الرئيسية' : 'اسم الفئة',
                          icon: Icons.title_rounded,
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم الفئة' : null,
                      ),
                      
                      if (!isMainCategory) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _parentNameController,
                          style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 15, color: AppTheme.textPrimary),
                          decoration: _buildInputDecoration(
                            label: 'الفئة الرئيسية (اختياري)',
                            icon: Icons.folder_open_rounded,
                          ),
                        ),
                      ],

                      if (isMainCategory && !isEditing && widget.defaultType != 'general') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subCategoryNameController,
                          style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 15, color: AppTheme.textPrimary),
                          decoration: _buildInputDecoration(
                            label: 'اسم الفئة الفرعية الأولى (مطلوب)',
                            icon: Icons.subdirectory_arrow_right_rounded,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'يجب إضافة فئة فرعية تابعة لها' : null,
                        ),
                      ],
                      
                      const SizedBox(height: 28),
                      const Text('اللون المميز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textPrimary)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          clipBehavior: Clip.none,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _colors.length,
                          itemBuilder: (context, index) {
                            final color = _colors[index];
                            final isSelected = _selectedColorValue == color.value || (_selectedColorValue == null && index == 0);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColorValue = color.value);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                margin: EdgeInsets.only(left: 12, right: index == 0 ? 4 : 0, top: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: AppTheme.surfaceColor, width: 3) : null,
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 2))
                                  ] : null,
                                ),
                                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 24) : null,
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      const Text('الأيقونة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'ArbFONTSIBMPlexArabicText', color: AppTheme.textPrimary)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _icons.map((icon) {
                          final isSelected = _selectedIconCode == icon.codePoint || (_selectedIconCode == null && icon == _icons.first);
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedIconCode = icon.codePoint);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isSelected ? activeColor.withOpacity(0.12) : AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? activeColor : AppTheme.dividerColor.withOpacity(0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? activeColor : AppTheme.textSecondary,
                                size: 28,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _submitForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: activeColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? 'حفظ التعديلات' : 'إضافة واعتماد',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 13, color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.surfaceColor,
      prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.errorColor)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5)),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final isEditing = widget.category != null;
      
      final colorVal = _selectedColorValue ?? _colors.first.value;
      final iconVal = _selectedIconCode ?? _icons.first.codePoint;

      if (widget.forceNoParent && !isEditing && widget.defaultType != 'general') {
        final subName = _subCategoryNameController.text.trim();
        final mainCat = CategoryModel(
          name: name,
          parentName: null,
          type: widget.defaultType ?? 'expense',
          colorValue: colorVal,
          iconCodePoint: iconVal,
        );
        final subCat = CategoryModel(
          name: subName,
          parentName: name,
          type: widget.defaultType ?? 'expense',
          colorValue: colorVal,
          iconCodePoint: iconVal,
        );
        Navigator.pop(context, [mainCat, subCat]);
      } else {
        final parentName = (widget.forceNoParent || widget.defaultType == 'general') 
            ? null 
            : (_parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim());
        
        final newCategory = widget.category?.copyWith(
          name: name,
          parentName: parentName,
          type: widget.defaultType,
          colorValue: colorVal,
          iconCodePoint: iconVal,
        ) ?? CategoryModel(
          name: name,
          parentName: parentName,
          type: widget.defaultType ?? 'expense',
          colorValue: colorVal,
          iconCodePoint: iconVal,
        );
        Navigator.pop(context, newCategory);
      }
    }
  }
}
