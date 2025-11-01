class CategoryModel {
  final int? id;
  final String name;

  CategoryModel({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
    );
  }

  // Default categories
  static List<CategoryModel> getDefaultCategories() {
    return [
      CategoryModel(name: 'عام'),
      CategoryModel(name: 'مورد'),
      CategoryModel(name: 'عميل'),
      CategoryModel(name: 'مصروفات'),
      CategoryModel(name: 'إيجار'),
      CategoryModel(name: 'أعمال'),
      CategoryModel(name: 'فواتير'),
      CategoryModel(name: 'أخرى'),
    ];
  }
}
