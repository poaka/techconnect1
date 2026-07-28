class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      iconName: json['icon_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
    };
  }
}
