/// Category model — matches the `categories` collection in the backend
class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  const CategoryModel({required this.id, required this.name, this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    icon: json['icon']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};

  @override
  String toString() => 'CategoryModel($id, $name)';
}
