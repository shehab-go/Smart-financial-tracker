class CategoryModel {
  final int? id;
  final String name;
  final String nameArabic;
  final String icon;

  CategoryModel({
    this.id,
    required this.name,
    required this.nameArabic,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameArabic': nameArabic,
      'icon': icon,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      nameArabic: map['nameArabic'],
      icon: map['icon'],
    );
  }

  // Default categories
  static List<CategoryModel> getDefaultCategories() {
    return [
      CategoryModel(name: 'General', nameArabic: 'عام', icon: '📋'),
      CategoryModel(name: 'Supplier', nameArabic: 'مورد', icon: '🏭'),
      CategoryModel(name: 'Customer', nameArabic: 'عميل', icon: '👤'),
      CategoryModel(name: 'Food', nameArabic: 'طعام', icon: '🍽️'),
      CategoryModel(name: 'Transport', nameArabic: 'مواصلات', icon: '🚗'),
      CategoryModel(name: 'Rent', nameArabic: 'إيجار', icon: '🏠'),
      CategoryModel(name: 'Business', nameArabic: 'أعمال', icon: '💼'),
      CategoryModel(name: 'Entertainment', nameArabic: 'ترفيه', icon: '🎬'),
      CategoryModel(name: 'Healthcare', nameArabic: 'صحة', icon: '🏥'),
      CategoryModel(name: 'Shopping', nameArabic: 'تسوق', icon: '🛍️'),
      CategoryModel(name: 'Education', nameArabic: 'تعليم', icon: '📚'),
      CategoryModel(name: 'Utilities', nameArabic: 'فواتير', icon: '💡'),
      CategoryModel(name: 'Other', nameArabic: 'أخرى', icon: '📝'),
    ];
  }
}
