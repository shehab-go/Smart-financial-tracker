import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int sortOrder;
  final String? parentName;
  final int? iconCodePoint;
  final int? colorValue;
  final String? type; // 'expense', 'income', 'general'

  CategoryModel({
    this.id,
    required this.name,
    this.sortOrder = 0,
    this.parentName,
    this.iconCodePoint,
    this.colorValue,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
      'parentName': parentName,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'type': type,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? sortOrder,
    String? parentName,
    int? iconCodePoint,
    int? colorValue,
    String? type,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      parentName: parentName ?? this.parentName,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      sortOrder: map['sortOrder'] ?? 0,
      parentName: map['parentName'],
      iconCodePoint: map['iconCodePoint'],
      colorValue: map['colorValue'],
      type: map['type'],
    );
  }

  // Default categories
  static List<CategoryModel> getDefaultCategories() {
    return [
      CategoryModel(name: 'عام', type: 'general'),
      CategoryModel(name: 'مورد', type: 'general'),
      CategoryModel(name: 'عميل', type: 'general'),
      CategoryModel(name: 'أخرى', type: 'general'),
      
      // 1. المصروفات الثابتة والأساسية
      ..._buildCategoryGroup('السكن والمنزل', Icons.home, 0xFF4CAF50, [
        'الإيجار / التمويل العقاري',
        'الفواتير الخدمية',
        'الصيانة المنزلية',
        'أثاث وأجهزة',
      ]),
      ..._buildCategoryGroup('النقل والمواصلات', Icons.directions_car, 0xFF2196F3, [
        'وقود السيارة',
        'المواصلات العامة',
        'صيانة السيارة',
        'مصاريف حكومية للسيارة',
      ]),
      ..._buildCategoryGroup('الطعام والشراب', Icons.shopping_cart, 0xFFFF9800, [
        'مشتريات السوبرماركت',
        'مياه الشرب',
      ]),
      ..._buildCategoryGroup('الصحة والرعاية', Icons.local_hospital, 0xFFF44336, [
        'الأدوية والصيدلية',
        'زيارات الأطباء',
        'التأمين الصحي',
        'الفحوصات والتحاليل',
      ]),
      ..._buildCategoryGroup('الاتصالات والتكنولوجيا', Icons.phone_android, 0xFF9C27B0, [
        'فاتورة الهاتف',
        'إنترنت المنزلي',
        'خدمات التخزين السحابي',
      ]),
      ..._buildCategoryGroup('التعليم والأبناء', Icons.school, 0xFFFFC107, [
        'الرسوم الدراسية',
        'الكتب والأدوات',
        'مصروف الأبناء',
        'ألعاب وملابس',
      ]),
      ..._buildCategoryGroup('الالتزامات المالية', Icons.account_balance_wallet, 0xFF607D8B, [
        'سداد بطاقات الائتمان',
        'أقساط القروض',
        'الضرائب والزكاة',
      ]),

      // 2. المصروفات المتغيرة والاختيارية
      ..._buildCategoryGroup('الترفيه والمطاعم', Icons.restaurant, 0xFFE91E63, [
        'المطاعم والمقاهي',
        'وجبات التوصيل',
        'السينما والألعاب',
      ]),
      ..._buildCategoryGroup('التسوق والمظهر', Icons.shopping_bag, 0xFF00BCD4, [
        'الملابس والأحذية',
        'العناية الشخصية',
        'الإلكترونيات',
      ]),
      ..._buildCategoryGroup('السفر والسياحة', Icons.flight, 0xFF3F51B5, [
        'تذاكر الطيران والفنادق',
        'التنزّه أثناء السفر',
        'تأشيرات السفر',
      ]),
      ..._buildCategoryGroup('الاشتراكات الدورية', Icons.subscriptions, 0xFF795548, [
        'منصات الترفيه',
        'الاشتراكات الرياضية',
      ]),
      ..._buildCategoryGroup('هدايا ومناسبات', Icons.card_giftcard, 0xFFFF5722, [
        'هدايا الأصدقاء والعائلة',
        'مصاريف الحفلات والأعياد',
      ]),
      ..._buildCategoryGroup('الحيوانات الأليفة', Icons.pets, 0xFF8D6E63, [
        'طعام ومستلزمات',
        'الرعاية البيطرية',
      ]),

      // 3. فئات إضافية
      CategoryModel(name: 'مصروفات نقدية', parentName: 'فئات إضافية', iconCodePoint: Icons.money.codePoint, colorValue: 0xFF4CAF50, type: 'expense'),
      CategoryModel(name: 'طوارئ وغرامات', parentName: 'فئات إضافية', iconCodePoint: Icons.warning.codePoint, colorValue: 0xFFF44336, type: 'expense'),
      CategoryModel(name: 'تحويلات / استثمار', parentName: 'فئات إضافية', iconCodePoint: Icons.sync_alt.codePoint, colorValue: 0xFF2196F3, type: 'expense'),
      CategoryModel(name: 'غير مصنف', parentName: 'فئات إضافية', iconCodePoint: Icons.category.codePoint, colorValue: 0xFF9E9E9E, type: 'expense'),
    ];
  }

  static List<CategoryModel> _buildCategoryGroup(String parent, IconData icon, int color, List<String> items) {
    return items.map((item) => CategoryModel(
      name: item,
      parentName: parent,
      iconCodePoint: icon.codePoint,
      colorValue: color,
      type: 'expense',
    )).toList();
  }
}

