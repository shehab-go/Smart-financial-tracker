class IncomeResourceModel {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdDate;

  IncomeResourceModel({
    this.id,
    required this.name,
    this.description,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory IncomeResourceModel.fromMap(Map<String, dynamic> map) {
    return IncomeResourceModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
    );
  }

  IncomeResourceModel copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdDate,
  }) {
    return IncomeResourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
