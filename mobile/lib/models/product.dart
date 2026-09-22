enum ProductStatus { available, soldOut }

ProductStatus _statusFromString(String? raw) {
  return (raw ?? '').toUpperCase() == 'SOLD_OUT' ? ProductStatus.soldOut : ProductStatus.available;
}

/// Mirrors the backend's `Product` resource (renamed from the old
/// "menu item" — same concept, same `GET /api/products` shape, now
/// with a real nested `category` object instead of a free-text
/// string).
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int? categoryId;
  final String categoryName;
  final String imageUrl;
  final ProductStatus status;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.status,
  });

  bool get isAvailable => status == ProductStatus.available;

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: categoryJson?['id'] as int? ?? json['categoryId'] as int?,
      categoryName: categoryJson?['name'] as String? ?? json['category'] as String? ?? 'Other',
      imageUrl: json['imageUrl'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
    );
  }

  /// Request body for POST/PUT /api/products. The backend wants the FK
  /// (`categoryId`), not the nested category object.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'imageUrl': imageUrl,
        'status': status == ProductStatus.soldOut ? 'SOLD_OUT' : 'AVAILABLE',
      };

  /// For the local sqflite cache (offline fallback).
  Map<String, dynamic> toDbRow() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'status': status == ProductStatus.soldOut ? 'SOLD_OUT' : 'AVAILABLE',
      };

  factory Product.fromDbRow(Map<String, dynamic> row) => Product(
        id: row['id'] as int,
        name: row['name'] as String,
        description: row['description'] as String,
        price: (row['price'] as num).toDouble(),
        categoryId: row['categoryId'] as int?,
        categoryName: row['categoryName'] as String? ?? 'Other',
        imageUrl: row['imageUrl'] as String,
        status: _statusFromString(row['status'] as String?),
      );
}
