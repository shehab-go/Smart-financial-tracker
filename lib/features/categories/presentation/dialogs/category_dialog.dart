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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _parentNameController = TextEditingController(text: widget.category?.parentName ?? widget.defaultParentName ?? '');
    _subCategoryNameController = TextEditingController();
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
    
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
          color: AppTheme.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: (widget.forceNoParent && !isEditing) ? 'اسم الفئة الرئيسية' : 'اسم الفئة',
                labelStyle: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) 
                  ? 'يرجى إدخال اسم الفئة' 
                  : null,
            ),
            if (!widget.forceNoParent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentNameController,
                style: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'الفئة الرئيسية (اختياري)',
                  labelStyle: const TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ],
            if (widget.forceNoParent && !isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _subCategoryNameController,
                style: const TextStyle(
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'اسم الفئة الفرعية الأولى (مطلوب)',
                  labelStyle: const TextStyle(
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  ),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) 
                    ? 'يجب إضافة فئة فرعية تابعة لها' 
                    : null,
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'إلغاء',
            style: TextStyle(
              fontFamily: 'ArbFONTSIBMPlexArabicText',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _submitForm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isEditing ? 'حفظ التعديل' : 'إضافة الفئة',
            style: const TextStyle(
              fontFamily: 'ArbFONTSIBMPlexArabicText',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final isEditing = widget.category != null;

      if (widget.forceNoParent && !isEditing) {
        final subName = _subCategoryNameController.text.trim();
        final mainCat = CategoryModel(
          name: name,
          parentName: null,
          type: widget.defaultType ?? 'expense',
          colorValue: widget.category?.colorValue,
          iconCodePoint: widget.category?.iconCodePoint,
        );
        final subCat = CategoryModel(
          name: subName,
          parentName: name,
          type: widget.defaultType ?? 'expense',
          colorValue: widget.category?.colorValue,
          iconCodePoint: widget.category?.iconCodePoint,
        );
        Navigator.pop(context, [mainCat, subCat]);
      } else {
        final parentName = widget.forceNoParent 
            ? null 
            : (_parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim());
        
        final newCategory = widget.category?.copyWith(
          name: name,
          parentName: parentName,
          type: widget.defaultType,
        ) ?? CategoryModel(
          name: name,
          parentName: parentName,
          type: widget.defaultType ?? 'expense',
        );
        Navigator.pop(context, newCategory);
      }
    }
  }
}
