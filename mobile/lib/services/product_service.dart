import '../models/product.dart';
import 'api_client.dart';

/// Wraps /api/products on the Caffora backend (renamed from the old
/// /api/menu — same resource, now backed by a real Category table
/// instead of a free-text category string). Public reads — reachable
/// by guests too, which is why `auth: false` is passed on reads.
class ProductService {
  final ApiClient _client;
  ProductService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Product>> fetchProducts({int? categoryId, String? search}) async {
    final query = <String, dynamic>{};
    if (categoryId != null) query['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) query['search'] = search;
    final json = await _client.get('/products', query: query, auth: false);
    final list = (json as List<dynamic>? ?? []);
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> createProduct(Product product) async {
    final json = await _client.post('/products', body: product.toJson()) as Map<String, dynamic>;
    return Product.fromJson(json);
  }

  Future<Product> updateProduct(Product product) async {
    final json = await _client.put('/products/${product.id}', body: product.toJson()) as Map<String, dynamic>;
    return Product.fromJson(json);
  }

  Future<Product> toggleAvailability(int id) async {
    final json = await _client.patch('/products/$id/toggle-availability') as Map<String, dynamic>;
    return Product.fromJson(json);
  }

  Future<void> deleteProduct(int id) async {
    await _client.delete('/products/$id');
  }
}
