enum CategoryType {
  Need,
  Want,
  Investment,
}

class Category {
  final int? id;
  final String name;
  final CategoryType type;

  Category({this.id, required this.name, this.type = CategoryType.Want});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name, // Store enum name as string
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.Want, // Default if type is invalid
      ),
    );
  }
}
