/// Mirrors the backend's `Category` resource (`GET /api/categories`,
/// public). Used to drive the Menu screen's category chip row and the
/// admin Product form's category picker — replaces the old free-text
/// `category` string that used to live directly on the menu item.
class Category {
  final int id;
  final String name;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
