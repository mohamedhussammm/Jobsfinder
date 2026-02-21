/// Category model — matches the `categories` table in Supabase
class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  const CategoryModel({required this.id, required this.name, this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};

  @override
  String toString() => 'CategoryModel($id, $name)';
}
